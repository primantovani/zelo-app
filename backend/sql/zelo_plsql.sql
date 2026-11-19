-- ============================================================
-- ZELO - PL/SQL PARTE 1: PROTOCOLO, FLUXO DE STATUS E REGISTRO
-- PRE-REQUISITO: tabelas criadas e zelo_carga_completa.sql executado
-- (a sequence comeca em 16 porque a carga ja usa ZEL-2026-0001..0015).
-- COMO EXECUTAR: SQL Developer, como SCRIPT (F5).
-- ============================================================

CREATE SEQUENCE SEQ_PROTOCOLO_OCORRENCIA
    START WITH 16
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- ============================================================
-- 1. FUNCTION: FN_GERAR_PROTOCOLO
-- Devolve o proximo protocolo no formato ZEL-AAAA-NNNN.
-- A sequence nao reinicia a cada ano: o numero apenas cresce.
-- ============================================================
CREATE OR REPLACE FUNCTION FN_GERAR_PROTOCOLO
RETURN VARCHAR2
IS
    v_seq NUMBER;
BEGIN
    v_seq := SEQ_PROTOCOLO_OCORRENCIA.NEXTVAL;

    -- LPAD com largura minima 4; cresce sozinho se passar de 9999
    -- (LPAD puro cortaria o numero para 4 digitos)
    RETURN 'ZEL-' || TO_CHAR(SYSDATE, 'YYYY') || '-'
        || LPAD(TO_CHAR(v_seq), GREATEST(4, LENGTH(TO_CHAR(v_seq))), '0');
END FN_GERAR_PROTOCOLO;
/

-- ============================================================
-- 1.1 TRIGGER: TRG_OCORRENCIA_PROTOCOLO
-- Rede de seguranca: se alguem inserir uma ocorrencia sem
-- protocolo (ex.: INSERT direto), o banco gera automaticamente.
-- Um BEFORE INSERT dispara antes da checagem de NOT NULL,
-- por isso consegue preencher a coluna obrigatoria.
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_OCORRENCIA_PROTOCOLO
BEFORE INSERT ON OCORRENCIA
FOR EACH ROW
WHEN (NEW.PROTOCOLO IS NULL)
BEGIN
    :NEW.PROTOCOLO := FN_GERAR_PROTOCOLO;
END TRG_OCORRENCIA_PROTOCOLO;
/

-- ============================================================
-- 2. FUNCTION: FN_TRANSICAO_VALIDA
-- Define o fluxo permitido de status. Retorna 'S' ou 'N'.
--
--   (nulo)       -> ABERTA
--   ABERTA       -> EM_ANALISE | REJEITADA
--   EM_ANALISE   -> EM_ANDAMENTO | REJEITADA
--   EM_ANDAMENTO -> RESOLVIDA
--   RESOLVIDA e REJEITADA sao estados finais.
--
-- Para mudar a regra de negocio, altere somente esta function.
-- ============================================================
CREATE OR REPLACE FUNCTION FN_TRANSICAO_VALIDA (
    p_anterior IN VARCHAR2,
    p_novo     IN VARCHAR2
)
RETURN CHAR
DETERMINISTIC
IS
BEGIN
    -- Primeiro registro do historico: so pode nascer como ABERTA
    IF p_anterior IS NULL THEN
        RETURN CASE WHEN p_novo = 'ABERTA' THEN 'S' ELSE 'N' END;
    END IF;

    RETURN CASE
        WHEN p_anterior = 'ABERTA'       AND p_novo IN ('EM_ANALISE', 'REJEITADA')   THEN 'S'
        WHEN p_anterior = 'EM_ANALISE'   AND p_novo IN ('EM_ANDAMENTO', 'REJEITADA') THEN 'S'
        WHEN p_anterior = 'EM_ANDAMENTO' AND p_novo = 'RESOLVIDA'                    THEN 'S'
        ELSE 'N'
    END;
END FN_TRANSICAO_VALIDA;
/

-- ============================================================
-- 2.1 TRIGGER: TRG_OCORRENCIA_VALIDA_STATUS
-- Impede qualquer UPDATE de STATUS_ATUAL que viole o fluxo,
-- mesmo que feito fora da procedure (ex.: UPDATE manual).
--
-- Limitacao: o trigger so VALIDA. O historico e a notificacao
-- sao gravados pela PRC_ALTERAR_STATUS, porque o trigger nao
-- sabe qual usuario fez a mudanca. Use sempre a procedure.
-- ============================================================
CREATE OR REPLACE TRIGGER TRG_OCORRENCIA_VALIDA_STATUS
BEFORE UPDATE OF STATUS_ATUAL ON OCORRENCIA
FOR EACH ROW
WHEN (OLD.STATUS_ATUAL <> NEW.STATUS_ATUAL)
BEGIN
    IF FN_TRANSICAO_VALIDA(:OLD.STATUS_ATUAL, :NEW.STATUS_ATUAL) = 'N' THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Transicao de status invalida: '
            || :OLD.STATUS_ATUAL || ' -> ' || :NEW.STATUS_ATUAL);
    END IF;
END TRG_OCORRENCIA_VALIDA_STATUS;
/

-- ============================================================
-- 3. PROCEDURE: PRC_ALTERAR_STATUS
-- Fluxo completo de mudanca de status:
--   1. trava e le a ocorrencia (FOR UPDATE evita duas mudancas
--      simultaneas na mesma ocorrencia)
--   2. valida usuario e transicao
--   3. atualiza OCORRENCIA.STATUS_ATUAL
--   4. grava HISTORICO_STATUS (com o usuario responsavel)
--   5. notifica o dono da ocorrencia
--
-- Nao faz COMMIT: quem chama (backend ou script) controla a
-- transacao. Assim, se algo falhar depois, da para dar ROLLBACK.
-- ============================================================
CREATE OR REPLACE PROCEDURE PRC_ALTERAR_STATUS (
    p_id_ocorrencia IN OCORRENCIA.ID_OCORRENCIA%TYPE,
    p_id_usuario    IN USUARIO.ID_USUARIO%TYPE,
    p_novo_status   IN OCORRENCIA.STATUS_ATUAL%TYPE,
    p_observacao    IN HISTORICO_STATUS.OBSERVACAO%TYPE DEFAULT NULL
)
IS
    v_status_anterior OCORRENCIA.STATUS_ATUAL%TYPE;
    v_id_dono         OCORRENCIA.ID_USUARIO%TYPE;
    v_protocolo       OCORRENCIA.PROTOCOLO%TYPE;
    v_titulo          NOTIFICACAO.TITULO%TYPE;
    v_mensagem        NOTIFICACAO.MENSAGEM%TYPE;
    v_qtd             NUMBER;
BEGIN
    -- 1. Busca e trava a ocorrencia
    BEGIN
        SELECT STATUS_ATUAL, ID_USUARIO, PROTOCOLO
          INTO v_status_anterior, v_id_dono, v_protocolo
          FROM OCORRENCIA
         WHERE ID_OCORRENCIA = p_id_ocorrencia
           FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002,
                'Ocorrencia nao encontrada: ' || p_id_ocorrencia);
    END;

    -- 2a. Usuario responsavel precisa existir e estar ativo
    SELECT COUNT(*) INTO v_qtd
      FROM USUARIO
     WHERE ID_USUARIO = p_id_usuario
       AND ATIVO = 'S';

    IF v_qtd = 0 THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Usuario inexistente ou inativo: ' || p_id_usuario);
    END IF;

    -- 2b. Status novo nao pode ser igual ao atual
    IF v_status_anterior = p_novo_status THEN
        RAISE_APPLICATION_ERROR(-20004,
            'A ocorrencia ja esta no status ' || p_novo_status);
    END IF;

    -- 2c. Transicao precisa seguir o fluxo (tambem barra status inexistentes)
    IF FN_TRANSICAO_VALIDA(v_status_anterior, p_novo_status) = 'N' THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Transicao de status invalida: '
            || v_status_anterior || ' -> ' || p_novo_status);
    END IF;

    -- 3. Atualiza o status atual
    UPDATE OCORRENCIA
       SET STATUS_ATUAL = p_novo_status
     WHERE ID_OCORRENCIA = p_id_ocorrencia;

    -- 4. Registra no historico quem mudou, de qual status para qual
    INSERT INTO HISTORICO_STATUS
        (ID_OCORRENCIA, ID_USUARIO, STATUS_ANTERIOR, STATUS_NOVO, OBSERVACAO)
    VALUES
        (p_id_ocorrencia, p_id_usuario, v_status_anterior, p_novo_status, p_observacao);

    -- 5. Monta e grava a notificacao para o dono da ocorrencia
    CASE p_novo_status
        WHEN 'EM_ANALISE' THEN
            v_titulo   := 'Ocorrencia em analise';
            v_mensagem := 'Sua solicitacao ' || v_protocolo || ' esta sendo analisada.';
        WHEN 'EM_ANDAMENTO' THEN
            v_titulo   := 'Ocorrencia em andamento';
            v_mensagem := 'A equipe iniciou o atendimento da ocorrencia ' || v_protocolo || '.';
        WHEN 'RESOLVIDA' THEN
            v_titulo   := 'Ocorrencia resolvida';
            v_mensagem := 'A ocorrencia ' || v_protocolo || ' foi resolvida.';
        WHEN 'REJEITADA' THEN
            v_titulo   := 'Ocorrencia rejeitada';
            v_mensagem := 'A ocorrencia ' || v_protocolo || ' foi rejeitada apos verificacao.';
        ELSE
            v_titulo   := 'Status atualizado';
            v_mensagem := 'A ocorrencia ' || v_protocolo || ' mudou para ' || p_novo_status || '.';
    END CASE;

    INSERT INTO NOTIFICACAO
        (ID_USUARIO, ID_OCORRENCIA, TITULO, MENSAGEM)
    VALUES
        (v_id_dono, p_id_ocorrencia, v_titulo, v_mensagem);
END PRC_ALTERAR_STATUS;
/

-- ============================================================
-- 4. PROCEDURE: PRC_REGISTRAR_OCORRENCIA
-- Abre uma nova ocorrencia em uma unica chamada:
--   1. valida usuario e categoria (existem e estao ativos)
--   2. gera o protocolo
--   3. insere a ocorrencia (status inicial ABERTA, pelo DEFAULT)
--   4. grava o primeiro registro do historico (NULL -> ABERTA)
--   5. cria a notificacao de "ocorrencia recebida"
--
-- Devolve o ID e o protocolo pelos parametros OUT.
-- p_endereco pode ser NULL. Nao faz COMMIT (ver nota acima).
-- Latitude/longitude fora da faixa sao barradas pelos CHECKs da tabela.
-- ============================================================
CREATE OR REPLACE PROCEDURE PRC_REGISTRAR_OCORRENCIA (
    p_id_usuario    IN  OCORRENCIA.ID_USUARIO%TYPE,
    p_id_categoria  IN  OCORRENCIA.ID_CATEGORIA%TYPE,
    p_titulo        IN  OCORRENCIA.TITULO%TYPE,
    p_descricao     IN  OCORRENCIA.DESCRICAO%TYPE,
    p_latitude      IN  OCORRENCIA.LATITUDE%TYPE,
    p_longitude     IN  OCORRENCIA.LONGITUDE%TYPE,
    p_endereco      IN  OCORRENCIA.ENDERECO%TYPE,
    p_id_ocorrencia OUT OCORRENCIA.ID_OCORRENCIA%TYPE,
    p_protocolo     OUT OCORRENCIA.PROTOCOLO%TYPE
)
IS
    v_qtd NUMBER;
BEGIN
    -- 1a. Usuario precisa existir e estar ativo
    SELECT COUNT(*) INTO v_qtd
      FROM USUARIO
     WHERE ID_USUARIO = p_id_usuario
       AND ATIVO = 'S';

    IF v_qtd = 0 THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Usuario inexistente ou inativo: ' || p_id_usuario);
    END IF;

    -- 1b. Categoria precisa existir e estar ativa
    SELECT COUNT(*) INTO v_qtd
      FROM CATEGORIA
     WHERE ID_CATEGORIA = p_id_categoria
       AND ATIVO = 'S';

    IF v_qtd = 0 THEN
        RAISE_APPLICATION_ERROR(-20010,
            'Categoria inexistente ou inativa: ' || p_id_categoria);
    END IF;

    -- 2. Gera o protocolo
    p_protocolo := FN_GERAR_PROTOCOLO;

    -- 3. Insere a ocorrencia e ja captura o ID gerado pelo identity
    INSERT INTO OCORRENCIA
        (ID_USUARIO, ID_CATEGORIA, TITULO, DESCRICAO,
         LATITUDE, LONGITUDE, ENDERECO, PROTOCOLO)
    VALUES
        (p_id_usuario, p_id_categoria, p_titulo, p_descricao,
         p_latitude, p_longitude, p_endereco, p_protocolo)
    RETURNING ID_OCORRENCIA INTO p_id_ocorrencia;

    -- 4. Primeiro registro do historico: quem abriu e o proprio cidadao
    INSERT INTO HISTORICO_STATUS
        (ID_OCORRENCIA, ID_USUARIO, STATUS_ANTERIOR, STATUS_NOVO, OBSERVACAO)
    VALUES
        (p_id_ocorrencia, p_id_usuario, NULL, 'ABERTA', 'Ocorrencia registrada.');

    -- 5. Notificacao de confirmacao para o cidadao
    INSERT INTO NOTIFICACAO
        (ID_USUARIO, ID_OCORRENCIA, TITULO, MENSAGEM)
    VALUES
        (p_id_usuario, p_id_ocorrencia, 'Ocorrencia recebida',
         'Sua solicitacao ' || p_protocolo || ' foi registrada com sucesso.');
END PRC_REGISTRAR_OCORRENCIA;
/

-- ============================================================
-- 5. BLOCO DE TESTE
-- Percorre o fluxo completo e testa os erros esperados.
-- No final faz ROLLBACK, entao nenhum dado de teste fica no banco.
-- (A sequence e o identity nao voltam com o ROLLBACK: o proximo
-- protocolo real sera ZEL-2026-0017, e isso e normal.)
-- Para ver as mensagens, o painel "Saida do SGBD" precisa estar aberto.
-- ============================================================
SET SERVEROUTPUT ON

DECLARE
    v_id        OCORRENCIA.ID_OCORRENCIA%TYPE;
    v_protocolo OCORRENCIA.PROTOCOLO%TYPE;
    v_qtd_notif NUMBER;
BEGIN
    -- Registra uma ocorrencia (usuario 1, categoria 1)
    PRC_REGISTRAR_OCORRENCIA(1, 1, 'Teste de buraco', 'Ocorrencia criada pelo bloco de teste.',
                             -23.5500, -46.6300, 'Rua de Teste, Centro', v_id, v_protocolo);
    DBMS_OUTPUT.PUT_LINE('Registrada: id=' || v_id || ' protocolo=' || v_protocolo);

    -- Fluxo valido (usuario 10 como responsavel)
    PRC_ALTERAR_STATUS(v_id, 10, 'EM_ANALISE',   'Teste: em analise.');
    PRC_ALTERAR_STATUS(v_id, 10, 'EM_ANDAMENTO', 'Teste: equipe acionada.');
    PRC_ALTERAR_STATUS(v_id, 10, 'RESOLVIDA',    'Teste: reparo concluido.');

    -- Erro esperado 1: a procedure barra voltar de um estado final
    BEGIN
        PRC_ALTERAR_STATUS(v_id, 10, 'ABERTA');
        DBMS_OUTPUT.PUT_LINE('FALHA: a procedure deveria ter barrado a transicao.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Erro esperado (procedure): ' || SQLERRM);
    END;

    -- Erro esperado 2: o trigger barra UPDATE direto fora do fluxo
    BEGIN
        UPDATE OCORRENCIA SET STATUS_ATUAL = 'ABERTA' WHERE ID_OCORRENCIA = v_id;
        DBMS_OUTPUT.PUT_LINE('FALHA: o trigger deveria ter barrado o UPDATE.');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Erro esperado (trigger): ' || SQLERRM);
    END;

    -- Historico gerado (esperado: 4 linhas)
    DBMS_OUTPUT.PUT_LINE('--- Historico da ocorrencia ' || v_protocolo || ' ---');
    FOR r IN (SELECT STATUS_ANTERIOR, STATUS_NOVO, ID_USUARIO
                FROM HISTORICO_STATUS
               WHERE ID_OCORRENCIA = v_id
               ORDER BY ID_HISTORICO)
    LOOP
        DBMS_OUTPUT.PUT_LINE(NVL(r.STATUS_ANTERIOR, '(nulo)') || ' -> ' || r.STATUS_NOVO
                             || ' (usuario ' || r.ID_USUARIO || ')');
    END LOOP;

    -- Notificacoes geradas (esperado: 4 = recebida + 3 mudancas)
    SELECT COUNT(*) INTO v_qtd_notif FROM NOTIFICACAO WHERE ID_OCORRENCIA = v_id;
    DBMS_OUTPUT.PUT_LINE('Notificacoes geradas: ' || v_qtd_notif);

    -- Desfaz tudo para nao deixar dado de teste no banco
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ROLLBACK executado.');
END;
/

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
