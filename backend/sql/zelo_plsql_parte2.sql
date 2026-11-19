-- ============================================================
-- PARTE 2: APOIOS, NOTIFICACOES, INDICADORES,
-- BUSCA POR PROXIMIDADE E REGRAS DE INTEGRIDADE
--
-- PRE-REQUISITO: o script zelo_plsql.sql (parte 1) ja executado.
-- COMO EXECUTAR: SQL Developer, mesmo usuario das tabelas, como
-- SCRIPT (F5). Cada bloco PL/SQL termina com "/" sozinho na linha.
-- ROTINAS CRIADAS:
--   Functions : FN_DISTANCIA_KM, FN_TOTAL_APOIOS, FN_DIAS_PARA_RESOLUCAO
--   Procedures: PRC_APOIAR_OCORRENCIA, PRC_MARCAR_NOTIFICACOES_LIDAS,
--               PRC_BUSCAR_PROXIMAS, PRC_INDICADORES_GERAIS,
--               PRC_INDICADORES_CATEGORIA
--   Triggers  : TRG_APOIO_SEM_AUTOAPOIO, TRG_HISTORICO_IMUTAVEL
-- ============================================================

-- ============================================================
-- 1. FUNCTION: FN_DISTANCIA_KM
-- Distancia em km entre dois pontos (formula de Haversine).
-- Usada para buscar ocorrencias proximas e evitar duplicidade.
-- Retorna NULL se alguma coordenada for nula.
-- ============================================================
CREATE OR REPLACE FUNCTION FN_DISTANCIA_KM (
    p_lat1 IN NUMBER,
    p_lon1 IN NUMBER,
    p_lat2 IN NUMBER,
    p_lon2 IN NUMBER
)
RETURN NUMBER
DETERMINISTIC
IS
    c_raio_terra_km CONSTANT NUMBER := 6371;
    c_graus_rad     CONSTANT NUMBER := ACOS(-1) / 180; -- converte graus em radianos
    v_dlat NUMBER;
    v_dlon NUMBER;
    v_a    NUMBER;
BEGIN
    v_dlat := (p_lat2 - p_lat1) * c_graus_rad;
    v_dlon := (p_lon2 - p_lon1) * c_graus_rad;

    v_a := POWER(SIN(v_dlat / 2), 2)
         + COS(p_lat1 * c_graus_rad) * COS(p_lat2 * c_graus_rad)
         * POWER(SIN(v_dlon / 2), 2);

    -- LEAST evita erro de arredondamento (a ligeiramente maior que 1)
    RETURN ROUND(c_raio_terra_km * 2 * ASIN(SQRT(LEAST(1, v_a))), 3);
END FN_DISTANCIA_KM;
/

-- ============================================================
-- 2. FUNCTION: FN_TOTAL_APOIOS
-- Conta os apoios de uma ocorrencia.
-- p_tipo opcional: 'APOIO' ou 'CONFIRMACAO'; nulo conta todos.
-- ============================================================
CREATE OR REPLACE FUNCTION FN_TOTAL_APOIOS (
    p_id_ocorrencia IN APOIO_OCORRENCIA.ID_OCORRENCIA%TYPE,
    p_tipo          IN APOIO_OCORRENCIA.TIPO_APOIO%TYPE DEFAULT NULL
)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT COUNT(*)
      INTO v_total
      FROM APOIO_OCORRENCIA
     WHERE ID_OCORRENCIA = p_id_ocorrencia
       AND (p_tipo IS NULL OR TIPO_APOIO = p_tipo);

    RETURN v_total;
END FN_TOTAL_APOIOS;
/

-- ============================================================
-- 3. FUNCTION: FN_DIAS_PARA_RESOLUCAO
-- Dias entre a abertura e a mudanca para RESOLVIDA (1 casa
-- decimal). Retorna NULL se a ocorrencia nao foi resolvida
-- ou nao existe.
-- ============================================================
CREATE OR REPLACE FUNCTION FN_DIAS_PARA_RESOLUCAO (
    p_id_ocorrencia IN OCORRENCIA.ID_OCORRENCIA%TYPE
)
RETURN NUMBER
IS
    v_dias NUMBER;
BEGIN
    -- Funcao de agregacao sempre devolve uma linha (NULL se nao houver
    -- historico RESOLVIDA), entao nao ha NO_DATA_FOUND a tratar.
    SELECT ROUND(CAST(MAX(h.DATA_ALTERACAO) AS DATE)
               - CAST(MAX(o.DATA_ABERTURA) AS DATE), 1)
      INTO v_dias
      FROM OCORRENCIA o
      JOIN HISTORICO_STATUS h
        ON h.ID_OCORRENCIA = o.ID_OCORRENCIA
       AND h.STATUS_NOVO = 'RESOLVIDA'
     WHERE o.ID_OCORRENCIA = p_id_ocorrencia;

    RETURN v_dias;
END FN_DIAS_PARA_RESOLUCAO;
/

-- ============================================================
-- 4. TRIGGER: TRG_APOIO_SEM_AUTOAPOIO
-- Garante no banco que o autor da ocorrencia nao apoie a propria
-- ocorrencia. Um CHECK nao resolve, pois precisa consultar outra
-- tabela. Se a ocorrencia nao existir, deixa a FK acusar o erro.
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_APOIO_SEM_AUTOAPOIO
BEFORE INSERT ON APOIO_OCORRENCIA
FOR EACH ROW
DECLARE
    v_id_autor OCORRENCIA.ID_USUARIO%TYPE;
BEGIN
    SELECT ID_USUARIO
      INTO v_id_autor
      FROM OCORRENCIA
     WHERE ID_OCORRENCIA = :NEW.ID_OCORRENCIA;

    IF v_id_autor = :NEW.ID_USUARIO THEN
        RAISE_APPLICATION_ERROR(-20021,
            'O autor nao pode apoiar a propria ocorrencia.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL; -- a FK FK_APOIO_OCORRENCIA tratara a ocorrencia inexistente
END TRG_APOIO_SEM_AUTOAPOIO;
/

-- ============================================================
-- 5. TRIGGER: TRG_HISTORICO_IMUTAVEL
-- O historico e uma trilha de auditoria: so aceita INSERT.
-- Qualquer UPDATE ou DELETE e barrado.
--
-- ATENCAO: o script de carga (zelo_carga_completa.sql) apaga o
-- historico na limpeza inicial. Antes de recarregar os dados, rode:
--   ALTER TRIGGER TRG_HISTORICO_IMUTAVEL DISABLE;
-- e depois da carga:
--   ALTER TRIGGER TRG_HISTORICO_IMUTAVEL ENABLE;
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_HISTORICO_IMUTAVEL
BEFORE UPDATE OR DELETE ON HISTORICO_STATUS
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20030,
        'O historico de status nao pode ser alterado nem excluido.');
END TRG_HISTORICO_IMUTAVEL;
/

-- ============================================================
-- 6. PROCEDURE: PRC_APOIAR_OCORRENCIA
-- Registra o apoio ou a confirmacao de um usuario a uma ocorrencia.
--   1. valida o tipo, a ocorrencia e o usuario
--   2. barra o autor e ocorrencias encerradas
--   3. insere o apoio (apoio repetido gera erro claro)
--   4. notifica o autor da ocorrencia
-- Nao faz COMMIT: quem chama controla a transacao.
-- ============================================================
CREATE OR REPLACE PROCEDURE PRC_APOIAR_OCORRENCIA (
    p_id_usuario    IN USUARIO.ID_USUARIO%TYPE,
    p_id_ocorrencia IN OCORRENCIA.ID_OCORRENCIA%TYPE,
    p_tipo_apoio    IN APOIO_OCORRENCIA.TIPO_APOIO%TYPE
)
IS
    v_status    OCORRENCIA.STATUS_ATUAL%TYPE;
    v_id_autor  OCORRENCIA.ID_USUARIO%TYPE;
    v_protocolo OCORRENCIA.PROTOCOLO%TYPE;
    v_qtd       NUMBER;
    v_titulo    NOTIFICACAO.TITULO%TYPE;
    v_mensagem  NOTIFICACAO.MENSAGEM%TYPE;
BEGIN
    -- 1a. Tipo de apoio valido
    IF p_tipo_apoio IS NULL OR p_tipo_apoio NOT IN ('APOIO', 'CONFIRMACAO') THEN
        RAISE_APPLICATION_ERROR(-20020,
            'Tipo de apoio invalido. Use APOIO ou CONFIRMACAO.');
    END IF;

    -- 1b. Ocorrencia existente
    BEGIN
        SELECT STATUS_ATUAL, ID_USUARIO, PROTOCOLO
          INTO v_status, v_id_autor, v_protocolo
          FROM OCORRENCIA
         WHERE ID_OCORRENCIA = p_id_ocorrencia;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002,
                'Ocorrencia nao encontrada: ' || p_id_ocorrencia);
    END;

    -- 1c. Usuario existente e ativo
    SELECT COUNT(*) INTO v_qtd
      FROM USUARIO
     WHERE ID_USUARIO = p_id_usuario
       AND ATIVO = 'S';

    IF v_qtd = 0 THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Usuario inexistente ou inativo: ' || p_id_usuario);
    END IF;

    -- 2a. Autor nao apoia a propria ocorrencia
    IF v_id_autor = p_id_usuario THEN
        RAISE_APPLICATION_ERROR(-20021,
            'O autor nao pode apoiar a propria ocorrencia.');
    END IF;

    -- 2b. Ocorrencia encerrada nao recebe novos apoios
    IF v_status IN ('RESOLVIDA', 'REJEITADA') THEN
        RAISE_APPLICATION_ERROR(-20022,
            'Ocorrencia encerrada (' || v_status || ') nao recebe apoio.');
    END IF;

    -- 3. Insere o apoio; a UK (usuario, ocorrencia) barra repeticao
    BEGIN
        INSERT INTO APOIO_OCORRENCIA (ID_USUARIO, ID_OCORRENCIA, TIPO_APOIO)
        VALUES (p_id_usuario, p_id_ocorrencia, p_tipo_apoio);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20023,
                'Este usuario ja apoiou a ocorrencia ' || v_protocolo || '.');
    END;

    -- 4. Avisa o autor
    IF p_tipo_apoio = 'APOIO' THEN
        v_titulo   := 'Nova ocorrencia apoiada';
        v_mensagem := 'Sua ocorrencia ' || v_protocolo || ' recebeu um novo apoio.';
    ELSE
        v_titulo   := 'Ocorrencia confirmada';
        v_mensagem := 'Sua ocorrencia ' || v_protocolo || ' foi confirmada por outro cidadao.';
    END IF;

    INSERT INTO NOTIFICACAO (ID_USUARIO, ID_OCORRENCIA, TITULO, MENSAGEM)
    VALUES (v_id_autor, p_id_ocorrencia, v_titulo, v_mensagem);
END PRC_APOIAR_OCORRENCIA;
/

-- ============================================================
-- 7. PROCEDURE: PRC_MARCAR_NOTIFICACOES_LIDAS
-- Marca como lidas as notificacoes nao lidas de um usuario.
-- Se p_id_ocorrencia for informado, marca so as dessa ocorrencia.
-- Devolve em p_qtd quantas notificacoes foram marcadas.
-- ============================================================
CREATE OR REPLACE PROCEDURE PRC_MARCAR_NOTIFICACOES_LIDAS (
    p_id_usuario    IN  NOTIFICACAO.ID_USUARIO%TYPE,
    p_qtd           OUT NUMBER,
    p_id_ocorrencia IN  NOTIFICACAO.ID_OCORRENCIA%TYPE DEFAULT NULL
)
IS
BEGIN
    UPDATE NOTIFICACAO
       SET LIDA = 'S'
     WHERE ID_USUARIO = p_id_usuario
       AND LIDA = 'N'
       AND (p_id_ocorrencia IS NULL OR ID_OCORRENCIA = p_id_ocorrencia);

    p_qtd := SQL%ROWCOUNT;
END PRC_MARCAR_NOTIFICACOES_LIDAS;
/

-- ============================================================
-- 8. PROCEDURE: PRC_BUSCAR_PROXIMAS
-- Lista ocorrencias dentro de um raio (km) de um ponto, da mais
-- proxima para a mais distante. Serve para o mapa do app e para
-- avisar o cidadao de possivel duplicidade antes de abrir uma nova.
--
--   p_resultado     : cursor com as ocorrencias encontradas
--   p_raio_km       : raio de busca (padrao 1 km)
--   p_id_categoria  : filtra por categoria (nulo = todas)
--   p_somente_ativas: 'S' ignora RESOLVIDA e REJEITADA (padrao)
-- ============================================================
CREATE OR REPLACE PROCEDURE PRC_BUSCAR_PROXIMAS (
    p_latitude       IN  NUMBER,
    p_longitude      IN  NUMBER,
    p_resultado      OUT SYS_REFCURSOR,
    p_raio_km        IN  NUMBER DEFAULT 1,
    p_id_categoria   IN  CATEGORIA.ID_CATEGORIA%TYPE DEFAULT NULL,
    p_somente_ativas IN  CHAR DEFAULT 'S'
)
IS
BEGIN
    OPEN p_resultado FOR
        SELECT *
          FROM (SELECT o.ID_OCORRENCIA,
                       o.PROTOCOLO,
                       o.TITULO,
                       c.NOME AS CATEGORIA,
                       o.STATUS_ATUAL,
                       FN_DISTANCIA_KM(p_latitude, p_longitude,
                                       o.LATITUDE, o.LONGITUDE) AS DISTANCIA_KM
                  FROM OCORRENCIA o
                  JOIN CATEGORIA c ON c.ID_CATEGORIA = o.ID_CATEGORIA
                 WHERE (p_id_categoria IS NULL OR o.ID_CATEGORIA = p_id_categoria)
                   AND (p_somente_ativas <> 'S'
                        OR o.STATUS_ATUAL NOT IN ('RESOLVIDA', 'REJEITADA')))
         WHERE DISTANCIA_KM <= p_raio_km
         ORDER BY DISTANCIA_KM;
END PRC_BUSCAR_PROXIMAS;
/

-- ============================================================
-- 9. PROCEDURE: PRC_INDICADORES_GERAIS
-- Indicadores do painel principal, com filtro opcional de periodo
-- (pela data de abertura; as duas datas sao inclusivas).
--   p_total          : total de ocorrencias
--   p_em_aberto      : ABERTA + EM_ANALISE + EM_ANDAMENTO
--   p_resolvidas     : RESOLVIDA
--   p_rejeitadas     : REJEITADA
--   p_taxa_resolucao : % de resolvidas sobre o total (1 decimal)
--   p_media_dias     : media de dias ate resolver (nulo se nenhuma)
-- ============================================================
CREATE OR REPLACE PROCEDURE PRC_INDICADORES_GERAIS (
    p_total          OUT NUMBER,
    p_em_aberto      OUT NUMBER,
    p_resolvidas     OUT NUMBER,
    p_rejeitadas     OUT NUMBER,
    p_taxa_resolucao OUT NUMBER,
    p_media_dias     OUT NUMBER,
    p_data_inicio    IN  DATE DEFAULT NULL,
    p_data_fim       IN  DATE DEFAULT NULL
)
IS
BEGIN
    -- Contagens por status em uma unica leitura da tabela
    SELECT COUNT(*),
           COUNT(CASE WHEN STATUS_ATUAL IN ('ABERTA', 'EM_ANALISE', 'EM_ANDAMENTO') THEN 1 END),
           COUNT(CASE WHEN STATUS_ATUAL = 'RESOLVIDA' THEN 1 END),
           COUNT(CASE WHEN STATUS_ATUAL = 'REJEITADA' THEN 1 END)
      INTO p_total, p_em_aberto, p_resolvidas, p_rejeitadas
      FROM OCORRENCIA
     WHERE (p_data_inicio IS NULL OR DATA_ABERTURA >= p_data_inicio)
       AND (p_data_fim IS NULL OR DATA_ABERTURA < p_data_fim + 1);

    -- Evita divisao por zero quando nao ha ocorrencias no periodo
    IF p_total = 0 THEN
        p_taxa_resolucao := 0;
    ELSE
        p_taxa_resolucao := ROUND(p_resolvidas * 100 / p_total, 1);
    END IF;

    -- Media de dias das ocorrencias resolvidas
    SELECT ROUND(AVG(FN_DIAS_PARA_RESOLUCAO(ID_OCORRENCIA)), 1)
      INTO p_media_dias
      FROM OCORRENCIA
     WHERE STATUS_ATUAL = 'RESOLVIDA'
       AND (p_data_inicio IS NULL OR DATA_ABERTURA >= p_data_inicio)
       AND (p_data_fim IS NULL OR DATA_ABERTURA < p_data_fim + 1);
END PRC_INDICADORES_GERAIS;
/

-- ============================================================
-- 10. PROCEDURE: PRC_INDICADORES_CATEGORIA
-- Indicadores por categoria (inclui categorias sem ocorrencias),
-- devolvidos em cursor, com filtro opcional de periodo.
-- Colunas: CATEGORIA, TOTAL, EM_ABERTO, RESOLVIDAS, REJEITADAS,
--          TAXA_RESOLUCAO_PCT, MEDIA_DIAS, TOTAL_APOIOS
-- ============================================================
CREATE OR REPLACE PROCEDURE PRC_INDICADORES_CATEGORIA (
    p_resultado   OUT SYS_REFCURSOR,
    p_data_inicio IN  DATE DEFAULT NULL,
    p_data_fim    IN  DATE DEFAULT NULL
)
IS
BEGIN
    OPEN p_resultado FOR
        SELECT c.NOME AS CATEGORIA,
               COUNT(o.ID_OCORRENCIA) AS TOTAL,
               COUNT(CASE WHEN o.STATUS_ATUAL IN ('ABERTA', 'EM_ANALISE', 'EM_ANDAMENTO')
                          THEN 1 END) AS EM_ABERTO,
               COUNT(CASE WHEN o.STATUS_ATUAL = 'RESOLVIDA' THEN 1 END) AS RESOLVIDAS,
               COUNT(CASE WHEN o.STATUS_ATUAL = 'REJEITADA' THEN 1 END) AS REJEITADAS,
               NVL(ROUND(100 * COUNT(CASE WHEN o.STATUS_ATUAL = 'RESOLVIDA' THEN 1 END)
                         / NULLIF(COUNT(o.ID_OCORRENCIA), 0), 1), 0) AS TAXA_RESOLUCAO_PCT,
               ROUND(AVG(CASE WHEN o.STATUS_ATUAL = 'RESOLVIDA'
                              THEN FN_DIAS_PARA_RESOLUCAO(o.ID_OCORRENCIA) END), 1) AS MEDIA_DIAS,
               NVL(SUM(FN_TOTAL_APOIOS(o.ID_OCORRENCIA)), 0) AS TOTAL_APOIOS
          FROM CATEGORIA c
          LEFT JOIN OCORRENCIA o
            ON o.ID_CATEGORIA = c.ID_CATEGORIA
           AND (p_data_inicio IS NULL OR o.DATA_ABERTURA >= p_data_inicio)
           AND (p_data_fim IS NULL OR o.DATA_ABERTURA < p_data_fim + 1)
         GROUP BY c.ID_CATEGORIA, c.NOME
         ORDER BY TOTAL DESC, c.NOME;
END PRC_INDICADORES_CATEGORIA;
/

-- ============================================================
-- 11. BLOCO DE TESTE
-- Primeiro testa so leitura (indicadores e busca), depois testa
-- as regras de escrita e termina com ROLLBACK (nenhum dado de
-- teste fica no banco). Abra o painel "Saida do SGBD".
-- Os valores esperados valem para a carga inicial, sem dados extras.
-- ============================================================
SET SERVEROUTPUT ON

DECLARE
    -- indicadores gerais
    v_total NUMBER; v_aberto NUMBER; v_resolv NUMBER; v_rejeit NUMBER;
    v_taxa  NUMBER; v_media  NUMBER;
    -- cursor reaproveitado nas consultas
    v_cur    SYS_REFCURSOR;
    v_cat    VARCHAR2(80);
    v_t NUMBER; v_ab NUMBER; v_rs NUMBER; v_rj NUMBER;
    v_pct NUMBER; v_dias NUMBER; v_apoios NUMBER;
    v_id_oc NUMBER; v_prot VARCHAR2(30); v_titulo VARCHAR2(120);
    v_status VARCHAR2(30); v_dist NUMBER;
    -- escrita
    v_id        OCORRENCIA.ID_OCORRENCIA%TYPE;
    v_protocolo OCORRENCIA.PROTOCOLO%TYPE;
    v_qtd       NUMBER;
BEGIN
    ------------------------------------------------------------
    -- A. Indicadores gerais (esperado: 15 | 11 | 3 | 1 | 20 | 3.8)
    ------------------------------------------------------------
    PRC_INDICADORES_GERAIS(v_total, v_aberto, v_resolv, v_rejeit, v_taxa, v_media);
    DBMS_OUTPUT.PUT_LINE('--- Indicadores gerais ---');
    DBMS_OUTPUT.PUT_LINE('Total=' || v_total || ' | Em aberto=' || v_aberto
        || ' | Resolvidas=' || v_resolv || ' | Rejeitadas=' || v_rejeit
        || ' | Taxa=' || v_taxa || '% | Media dias=' || v_media);

    ------------------------------------------------------------
    -- B. Indicadores por categoria
    -- Esperado: Buracos nas vias 3 / 1 resolvida / 33,3% / 4,3 dias;
    --           Calcadas danificadas 2 / 1 / 50% / 4 dias;
    --           Areas publicas abandonadas 2 / 1 / 50% / 3,2 dias.
    ------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- Indicadores por categoria ---');
    PRC_INDICADORES_CATEGORIA(v_cur);
    LOOP
        FETCH v_cur INTO v_cat, v_t, v_ab, v_rs, v_rj, v_pct, v_dias, v_apoios;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_cat || ' | total=' || v_t || ' | aberto=' || v_ab
            || ' | resolvidas=' || v_rs || ' | rejeitadas=' || v_rj
            || ' | taxa=' || v_pct || '% | dias=' || NVL(TO_CHAR(v_dias), '-')
            || ' | apoios=' || v_apoios);
    END LOOP;
    CLOSE v_cur;

    ------------------------------------------------------------
    -- C. Ocorrencias ativas a ate 2 km da Rua Augusta
    -- Esperado: varias linhas em ordem crescente de distancia;
    -- as mais proximas (cerca de 1 km) sao ZEL-2026-0002 e 0006.
    ------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- Proximas da Rua Augusta (ate 2 km) ---');
    PRC_BUSCAR_PROXIMAS(-23.5535, -46.6520, v_cur, 2);
    LOOP
        FETCH v_cur INTO v_id_oc, v_prot, v_titulo, v_cat, v_status, v_dist;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_prot || ' | ' || v_titulo || ' | ' || v_status
            || ' | ' || v_dist || ' km');
    END LOOP;
    CLOSE v_cur;

    ------------------------------------------------------------
    -- D. Regras de escrita (tudo desfeito no ROLLBACK final)
    ------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- Regras de apoio e integridade ---');

    -- Nova ocorrencia criada pelo usuario 1
    PRC_REGISTRAR_OCORRENCIA(1, 1, 'Teste de apoio', 'Ocorrencia criada pelo teste.',
                             -23.5500, -46.6300, 'Rua de Teste', v_id, v_protocolo);

    -- Apoio valido (usuario 2) -> sucesso
    PRC_APOIAR_OCORRENCIA(2, v_id, 'APOIO');
    DBMS_OUTPUT.PUT_LINE('Apoio valido registrado. Total de apoios = '
        || FN_TOTAL_APOIOS(v_id) || ' (esperado 1)');

    -- Apoio repetido -> erro -20023
    BEGIN
        PRC_APOIAR_OCORRENCIA(2, v_id, 'CONFIRMACAO');
        DBMS_OUTPUT.PUT_LINE('FALHA: apoio repetido deveria ser barrado.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro esperado (apoio repetido): ' || SQLERRM);
    END;

    -- Autor apoiando a propria ocorrencia -> erro -20021 (procedure)
    BEGIN
        PRC_APOIAR_OCORRENCIA(1, v_id, 'APOIO');
        DBMS_OUTPUT.PUT_LINE('FALHA: autoapoio deveria ser barrado.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro esperado (autoapoio, procedure): ' || SQLERRM);
    END;

    -- INSERT direto do autor, sem passar pela procedure -> erro -20021 (trigger)
    BEGIN
        INSERT INTO APOIO_OCORRENCIA (ID_USUARIO, ID_OCORRENCIA, TIPO_APOIO)
        VALUES (1, v_id, 'APOIO');
        DBMS_OUTPUT.PUT_LINE('FALHA: o trigger deveria barrar o autoapoio.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro esperado (autoapoio, trigger): ' || SQLERRM);
    END;

    -- Tipo de apoio invalido -> erro -20020
    BEGIN
        PRC_APOIAR_OCORRENCIA(3, v_id, 'CURTIR');
        DBMS_OUTPUT.PUT_LINE('FALHA: tipo invalido deveria ser barrado.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro esperado (tipo invalido): ' || SQLERRM);
    END;

    -- Ocorrencia encerrada nao recebe apoio -> erro -20022
    PRC_ALTERAR_STATUS(v_id, 10, 'REJEITADA', 'Teste: rejeitada.');
    BEGIN
        PRC_APOIAR_OCORRENCIA(3, v_id, 'APOIO');
        DBMS_OUTPUT.PUT_LINE('FALHA: ocorrencia encerrada deveria ser barrada.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro esperado (ocorrencia encerrada): ' || SQLERRM);
    END;

    -- Historico imutavel -> erro -20030
    BEGIN
        UPDATE HISTORICO_STATUS SET OBSERVACAO = 'alterado' WHERE ID_OCORRENCIA = v_id;
        DBMS_OUTPUT.PUT_LINE('FALHA: o historico deveria ser imutavel.');
    EXCEPTION WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro esperado (historico imutavel): ' || SQLERRM);
    END;

    -- Notificacoes do autor nesta ocorrencia: recebida + apoio + rejeitada = 3
    PRC_MARCAR_NOTIFICACOES_LIDAS(p_id_usuario => 1, p_qtd => v_qtd, p_id_ocorrencia => v_id);
    DBMS_OUTPUT.PUT_LINE('Notificacoes marcadas como lidas: ' || v_qtd || ' (esperado 3)');

    -- Desfaz tudo
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ROLLBACK executado.');
END;
/

-- ============================================================
-- FIM DO SCRIPT - PARTE 2
-- ============================================================
