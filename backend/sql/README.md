# Scripts do banco Oracle

Autor: Gabriel Notari. Rode no SQL Developer, como script (F5), no mesmo usuário das tabelas.

Ordem de execução:

1. **Criação das tabelas** (as 7 tabelas do modelo: USUARIO, CATEGORIA, OCORRENCIA, FOTO_OCORRENCIA, HISTORICO_STATUS, APOIO_OCORRENCIA, NOTIFICACAO).
2. `zelo_carga_completa.sql`: dados de exemplo (10 usuários, 7 categorias, 15 ocorrências em São Paulo, fotos, histórico, apoios e notificações).
3. `zelo_plsql.sql`: sequence do protocolo, `FN_GERAR_PROTOCOLO`, `FN_TRANSICAO_VALIDA`, triggers de protocolo e de fluxo de status, `PRC_REGISTRAR_OCORRENCIA` e `PRC_ALTERAR_STATUS`, com bloco de teste.
4. `zelo_plsql_parte2.sql`: `FN_DISTANCIA_KM`, `FN_TOTAL_APOIOS`, `FN_DIAS_PARA_RESOLUCAO`, triggers de autoapoio e histórico imutável, procedures de apoio, notificações lidas, busca por proximidade (mapa) e indicadores, com bloco de teste.
5. `zelo_consultas.sql`: consultas de conferência.

Os blocos de teste terminam em `ROLLBACK` e não deixam dados no banco.

Para recarregar os dados depois da parte 2, desative antes o trigger do histórico:

```sql
ALTER TRIGGER TRG_HISTORICO_IMUTAVEL DISABLE;
-- rode zelo_carga_completa.sql
ALTER TRIGGER TRG_HISTORICO_IMUTAVEL ENABLE;
```
