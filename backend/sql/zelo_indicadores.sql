-- ============================================================
-- ZELO - INDICADORES POR BAIRRO E PRIORIDADE (PL/SQL)
-- Autoria: Sophie Moreau
-- Compativel com o schema Oracle 21c XE do projeto Zelo
-- (nao exige alteracao nas tabelas existentes).
--
-- COMO EXECUTAR:
--   Abra no Oracle SQL Developer conectado ao schema ZELO
--   e execute como SCRIPT (F5).
--
-- OBJETOS CRIADOS:
--   Functions:  FN_EXTRAIR_BAIRRO, FN_CALCULAR_PRIORIDADE
--   Procedures: PRC_INDICADORES_BAIRRO,
--               PRC_INDICADORES_PRIORIDADE,
--               PRC_RELATORIO_CRITICAS_BAIRRO
-- ============================================================


-- ============================================================
-- 1. FUNCTION: FN_EXTRAIR_BAIRRO
-- Extrai o nome do bairro a partir do texto de OCORRENCIA.ENDERECO
-- (padrao 'Logradouro, Bairro'). Caso nao haja virgula ou o
-- endereco seja nulo, retorna 'Nao informado' ou o texto limpo.
-- ============================================================

CREATE OR REPLACE FUNCTION FN_EXTRAIR_BAIRRO (
    p_endereco IN OCORRENCIA.ENDERECO%TYPE
)
RETURN VARCHAR2
DETERMINISTIC
IS
    v_pos NUMBER;
BEGIN
    IF p_endereco IS NULL OR TRIM(p_endereco) IS NULL THEN
        RETURN 'Nao informado';
    END IF;

    v_pos := INSTR(p_endereco, ',', -1);

    IF v_pos > 0 AND v_pos < LENGTH(p_endereco) THEN
        RETURN TRIM(SUBSTR(p_endereco, v_pos + 1));
    END IF;

    RETURN TRIM(p_endereco);
END FN_EXTRAIR_BAIRRO;
/


-- ============================================================
-- 2. FUNCTION: FN_CALCULAR_PRIORIDADE
-- Classifica a prioridade de atendimento da ocorrencia com base
-- no engajamento comunitario (apoios e confirmacoes):
--   >= 2 apoios -> 'ALTA'
--      1 apoio  -> 'MEDIA'
--      0 apoios -> 'BAIXA'
-- ============================================================

CREATE OR REPLACE FUNCTION FN_CALCULAR_PRIORIDADE (
    p_id_ocorrencia IN OCORRENCIA.ID_OCORRENCIA%TYPE
)
RETURN VARCHAR2
IS
    v_qtd_apoios NUMBER := 0;
BEGIN
    SELECT COUNT(*)
      INTO v_qtd_apoios
      FROM APOIO_OCORRENCIA
     WHERE ID_OCORRENCIA = p_id_ocorrencia;

    IF v_qtd_apoios >= 2 THEN
        RETURN 'ALTA';
    ELSIF v_qtd_apoios = 1 THEN
        RETURN 'MEDIA';
    ELSE
        RETURN 'BAIXA';
    END IF;
END FN_CALCULAR_PRIORIDADE;
/


-- ============================================================
-- 3. PROCEDURE: PRC_INDICADORES_BAIRRO
-- Retorna em cursor os indicadores consolidados por bairro,
-- com filtro opcional de periodo pela data de abertura:
--   BAIRRO, TOTAL, EM_ABERTO, RESOLVIDAS, REJEITADAS,
--   TAXA_RESOLUCAO_PCT, MEDIA_DIAS_RESOLUCAO, TOTAL_APOIOS,
--   ALTA_PRIORIDADE
-- ============================================================

CREATE OR REPLACE PROCEDURE PRC_INDICADORES_BAIRRO (
    p_resultado   OUT SYS_REFCURSOR,
    p_data_inicio IN  DATE DEFAULT NULL,
    p_data_fim    IN  DATE DEFAULT NULL
)
IS
BEGIN
    OPEN p_resultado FOR
        WITH base AS (
            SELECT o.ID_OCORRENCIA,
                   FN_EXTRAIR_BAIRRO(o.ENDERECO) AS BAIRRO,
                   o.STATUS_ATUAL,
                   o.DATA_ABERTURA,
                   FN_CALCULAR_PRIORIDADE(o.ID_OCORRENCIA) AS PRIORIDADE,
                   (SELECT COUNT(*)
                      FROM APOIO_OCORRENCIA a
                     WHERE a.ID_OCORRENCIA = o.ID_OCORRENCIA) AS QTD_APOIOS,
                   (SELECT ROUND(CAST(MAX(h.DATA_ALTERACAO) AS DATE)
                               - CAST(o.DATA_ABERTURA AS DATE), 1)
                      FROM HISTORICO_STATUS h
                     WHERE h.ID_OCORRENCIA = o.ID_OCORRENCIA
                       AND h.STATUS_NOVO = 'RESOLVIDA') AS DIAS_RESOLUCAO
              FROM OCORRENCIA o
             WHERE (p_data_inicio IS NULL OR o.DATA_ABERTURA >= p_data_inicio)
               AND (p_data_fim    IS NULL OR o.DATA_ABERTURA <  p_data_fim + 1)
        )
        SELECT BAIRRO,
               COUNT(*) AS TOTAL,
               COUNT(CASE WHEN STATUS_ATUAL IN ('ABERTA', 'EM_ANALISE', 'EM_ANDAMENTO')
                          THEN 1 END) AS EM_ABERTO,
               COUNT(CASE WHEN STATUS_ATUAL = 'RESOLVIDA' THEN 1 END) AS RESOLVIDAS,
               COUNT(CASE WHEN STATUS_ATUAL = 'REJEITADA' THEN 1 END) AS REJEITADAS,
               NVL(ROUND(100 * COUNT(CASE WHEN STATUS_ATUAL = 'RESOLVIDA' THEN 1 END)
                         / NULLIF(COUNT(*), 0), 1), 0) AS TAXA_RESOLUCAO_PCT,
               ROUND(AVG(CASE WHEN STATUS_ATUAL = 'RESOLVIDA'
                              THEN DIAS_RESOLUCAO END), 1) AS MEDIA_DIAS_RESOLUCAO,
               NVL(SUM(QTD_APOIOS), 0) AS TOTAL_APOIOS,
               COUNT(CASE WHEN PRIORIDADE = 'ALTA' THEN 1 END) AS ALTA_PRIORIDADE
          FROM base
         GROUP BY BAIRRO
         ORDER BY TOTAL DESC, TOTAL_APOIOS DESC, BAIRRO;
END PRC_INDICADORES_BAIRRO;
/


-- ============================================================
-- 4. PROCEDURE: PRC_INDICADORES_PRIORIDADE
-- Consolida o volume de ocorrencias por nivel de prioridade
-- (ALTA, MEDIA, BAIXA) e status de atendimento.
-- ============================================================

CREATE OR REPLACE PROCEDURE PRC_INDICADORES_PRIORIDADE (
    p_resultado   OUT SYS_REFCURSOR,
    p_data_inicio IN  DATE DEFAULT NULL,
    p_data_fim    IN  DATE DEFAULT NULL
)
IS
BEGIN
    OPEN p_resultado FOR
        WITH base AS (
            SELECT o.ID_OCORRENCIA,
                   o.STATUS_ATUAL,
                   FN_CALCULAR_PRIORIDADE(o.ID_OCORRENCIA) AS PRIORIDADE,
                   (SELECT COUNT(*)
                      FROM APOIO_OCORRENCIA a
                     WHERE a.ID_OCORRENCIA = o.ID_OCORRENCIA) AS QTD_APOIOS
              FROM OCORRENCIA o
             WHERE (p_data_inicio IS NULL OR o.DATA_ABERTURA >= p_data_inicio)
               AND (p_data_fim    IS NULL OR o.DATA_ABERTURA <  p_data_fim + 1)
        )
        SELECT PRIORIDADE,
               COUNT(*) AS TOTAL,
               COUNT(CASE WHEN STATUS_ATUAL IN ('ABERTA', 'EM_ANALISE', 'EM_ANDAMENTO')
                          THEN 1 END) AS EM_ABERTO,
               COUNT(CASE WHEN STATUS_ATUAL = 'RESOLVIDA' THEN 1 END) AS RESOLVIDAS,
               COUNT(CASE WHEN STATUS_ATUAL = 'REJEITADA' THEN 1 END) AS REJEITADAS,
               NVL(SUM(QTD_APOIOS), 0) AS TOTAL_APOIOS
          FROM base
         GROUP BY PRIORIDADE
         ORDER BY CASE PRIORIDADE
                      WHEN 'ALTA'  THEN 1
                      WHEN 'MEDIA' THEN 2
                      ELSE 3
                  END;
END PRC_INDICADORES_PRIORIDADE;
/


-- ============================================================
-- 5. PROCEDURE: PRC_RELATORIO_CRITICAS_BAIRRO
-- Utiliza cursor explicito para listar ocorrencias em aberto
-- de prioridade ALTA, com filtro opcional por bairro.
-- ============================================================

CREATE OR REPLACE PROCEDURE PRC_RELATORIO_CRITICAS_BAIRRO (
    p_bairro IN VARCHAR2 DEFAULT NULL
)
IS
    CURSOR c_criticas (cp_bairro VARCHAR2) IS
        SELECT o.PROTOCOLO,
               o.TITULO,
               c.NOME AS CATEGORIA,
               FN_EXTRAIR_BAIRRO(o.ENDERECO) AS BAIRRO,
               o.STATUS_ATUAL,
               (SELECT COUNT(*)
                  FROM APOIO_OCORRENCIA a
                 WHERE a.ID_OCORRENCIA = o.ID_OCORRENCIA) AS APOIOS
          FROM OCORRENCIA o
          JOIN CATEGORIA c ON c.ID_CATEGORIA = o.ID_CATEGORIA
         WHERE o.STATUS_ATUAL IN ('ABERTA', 'EM_ANALISE', 'EM_ANDAMENTO')
           AND FN_CALCULAR_PRIORIDADE(o.ID_OCORRENCIA) = 'ALTA'
           AND (cp_bairro IS NULL
                OR UPPER(FN_EXTRAIR_BAIRRO(o.ENDERECO)) = UPPER(TRIM(cp_bairro)))
         ORDER BY APOIOS DESC, o.DATA_ABERTURA;

    v_encontrou BOOLEAN := FALSE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== OCORRENCIAS CRITICAS EM ABERTO (PRIORIDADE ALTA) ===');

    FOR r IN c_criticas(p_bairro) LOOP
        v_encontrou := TRUE;
        DBMS_OUTPUT.PUT_LINE(
            r.PROTOCOLO || ' | Bairro: ' || r.BAIRRO
            || ' | ' || r.TITULO
            || ' (' || r.CATEGORIA || ')'
            || ' | Status: ' || r.STATUS_ATUAL
            || ' | Apoios: ' || r.APOIOS
        );
    END LOOP;

    IF NOT v_encontrou THEN
        DBMS_OUTPUT.PUT_LINE('Nenhuma ocorrencia critica em aberto encontrada.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20040,
            'Erro ao gerar relatorio de ocorrencias criticas: ' || SQLERRM);
END PRC_RELATORIO_CRITICAS_BAIRRO;
/


-- ============================================================
-- 6. BLOCO DE TESTE (SOMENTE LEITURA)
-- Execute com "Saida do SGBD" (DBMS Output) habilitada.
-- ============================================================

SET SERVEROUTPUT ON

DECLARE
    v_cur        SYS_REFCURSOR;
    v_bairro     VARCHAR2(120);
    v_prioridade VARCHAR2(20);
    v_total      NUMBER;
    v_aberto     NUMBER;
    v_resolv     NUMBER;
    v_rejeit     NUMBER;
    v_taxa       NUMBER;
    v_dias       NUMBER;
    v_apoios     NUMBER;
    v_alta       NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- 1. INDICADORES POR BAIRRO ---');
    PRC_INDICADORES_BAIRRO(v_cur);
    LOOP
        FETCH v_cur INTO v_bairro, v_total, v_aberto, v_resolv, v_rejeit,
                         v_taxa, v_dias, v_apoios, v_alta;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(
            v_bairro
            || ' | Total=' || v_total
            || ' | Em aberto=' || v_aberto
            || ' | Resolvidas=' || v_resolv
            || ' | Rejeitadas=' || v_rejeit
            || ' | Taxa=' || v_taxa || '%'
            || ' | Media dias=' || NVL(TO_CHAR(v_dias), '-')
            || ' | Apoios=' || v_apoios
            || ' | Alta prioridade=' || v_alta
        );
    END LOOP;
    CLOSE v_cur;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('--- 2. INDICADORES POR PRIORIDADE ---');
    PRC_INDICADORES_PRIORIDADE(v_cur);
    LOOP
        FETCH v_cur INTO v_prioridade, v_total, v_aberto, v_resolv, v_rejeit, v_apoios;
        EXIT WHEN v_cur%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(
            'Prioridade ' || v_prioridade
            || ' | Total=' || v_total
            || ' | Em aberto=' || v_aberto
            || ' | Resolvidas=' || v_resolv
            || ' | Rejeitadas=' || v_rejeit
            || ' | Apoios=' || v_apoios
        );
    END LOOP;
    CLOSE v_cur;

    DBMS_OUTPUT.PUT_LINE('');
    PRC_RELATORIO_CRITICAS_BAIRRO;
END;
/

-- ============================================================
-- FIM DO SCRIPT DE INDICADORES
-- ============================================================
