# Zelo API — Spring Boot + Oracle 21c

API REST do projeto Zelo (registro e acompanhamento de ocorrências urbanas).

## Requisitos
- Java 21
- Maven 3.9+
- Oracle Database 21c XE (PDB `XEPDB1`)
- As 7 tabelas e as rotinas PL/SQL do projeto já criadas no schema Oracle.

## Atenção: conferir o schema antes de executar
O pacote foi montado a partir dos nomes de tabelas/colunas presentes no material PL/SQL enviado e do modelo descrito no projeto. Algumas colunas das tabelas não aparecem no script PL/SQL e foram assumidas:
- `USUARIO.ATIVO` e `CATEGORIA.ATIVO` (`'S'` para ativo);
- `FOTO_OCORRENCIA.ID_FOTO`, `FOTO_OCORRENCIA.URL_FOTO`;
- `HISTORICO_STATUS.ID_HISTORICO`, `DATA_ALTERACAO`;
- `APOIO_OCORRENCIA.ID_APOIO`, `TIPO_APOIO`, `DATA_APOIO`;
- `NOTIFICACAO.ID_NOTIFICACAO`, `LIDA`, `DATA_ENVIO`.
A entidade `OCORRENCIA` assume `DATA_ABERTURA`. Se os nomes ou tipos no seu banco forem diferentes, ajuste os `@Column` correspondentes antes de iniciar. O Hibernate está com `ddl-auto: none`: ele não altera suas tabelas.

Confira no SQL Developer:
```sql
DESC USUARIO;
DESC CATEGORIA;
DESC OCORRENCIA;
DESC FOTO_OCORRENCIA;
DESC HISTORICO_STATUS;
DESC APOIO_OCORRENCIA;
DESC NOTIFICACAO;
```

## Configuração
Edite `src/main/resources/application.yml` ou defina variáveis de ambiente:
- `DB_URL` (padrão `jdbc:oracle:thin:@localhost:1521/XEPDB1`)
- `DB_USERNAME` (padrão `ZELO`)
- `DB_PASSWORD`
- `JWT_SECRET` (use uma chave forte com 32+ caracteres)

Exemplo Windows PowerShell:
```powershell
$env:DB_USERNAME="SEU_USUARIO"
$env:DB_PASSWORD="SUA_SENHA"
$env:JWT_SECRET="UmaChaveLocalForteComMaisDeTrintaEDoisCaracteres"
```

## Abrir no IntelliJ
1. Extraia `zelo-api.zip`.
2. IntelliJ IDEA → **Open** → selecione a pasta `zelo-api`.
3. Aguarde o Maven baixar as dependências.
4. Configure Java SDK 21 em Project Structure.
5. Confira usuário/senha Oracle no `application.yml`.
6. Execute `ZeloApiApplication`.

Base URL: `http://localhost:8080/api`

## Autenticação
`POST /api/auth/registrar`
```json
{"nome":"Maria Silva","email":"maria@email.com","senha":"SenhaForte123"}
```
`POST /api/auth/login`
```json
{"email":"maria@email.com","senha":"SenhaForte123"}
```
Copie o token retornado e envie nas rotas protegidas:
`Authorization: Bearer <token>`

As senhas são armazenadas com BCrypt. Os usuários de demonstração antigos com valores `HASH_001` etc. não poderão autenticar via BCrypt; cadastre um usuário novo pelo endpoint ou atualize as senhas com BCrypt.

## Endpoints

| Método | Rota | Descrição | Acesso |
|---|---|---|---|
| POST | `/auth/registrar` | Cadastra usuário | Público |
| POST | `/auth/login` | Login e JWT | Público |
| GET | `/categorias` | Lista categorias ativas | Público |
| GET | `/ocorrencias` | Lista ocorrências | Público |
| GET | `/ocorrencias/{id}` | Detalhe | Público |
| GET | `/ocorrencias/protocolo/{protocolo}` | Consulta por protocolo | Público |
| GET | `/ocorrencias/usuario/{idUsuario}` | Ocorrências de um usuário | Público |
| POST | `/ocorrencias` | Registra ocorrência via `PRC_REGISTRAR_OCORRENCIA` | JWT |
| PATCH | `/ocorrencias/{id}/status` | Altera status via `PRC_ALTERAR_STATUS` | JWT |
| GET | `/ocorrencias/{id}/historico` | Histórico da ocorrência | JWT |
| GET/POST | `/ocorrencias/{id}/fotos` | Consulta/adiciona URL de foto | JWT para POST |
| GET/POST | `/ocorrencias/{id}/apoios` | Consulta/registra apoio ou confirmação | JWT para POST |
| GET | `/usuarios/{idUsuario}/notificacoes` | Lista notificações | JWT |
| PATCH | `/notificacoes/{id}/lida` | Marca notificação como lida | JWT |

### Exemplo — registrar ocorrência
```json
{
  "idUsuario": 1,
  "idCategoria": 1,
  "titulo": "Buraco na via",
  "descricao": "Buraco grande próximo à faixa de pedestres.",
  "latitude": -23.5505,
  "longitude": -46.6333,
  "endereco": "Centro, São Paulo - SP"
}
```
A procedure devolve o ID e protocolo. A procedure também grava o primeiro histórico e a notificação de recebimento.

### Exemplo — alterar status
`PATCH /api/ocorrencias/1/status`
```json
{
  "idUsuario": 10,
  "novoStatus": "EM_ANALISE",
  "observacao": "Solicitação encaminhada para avaliação."
}
```
As transições permitidas no banco são:
- `ABERTA` → `EM_ANALISE` ou `REJEITADA`
- `EM_ANALISE` → `EM_ANDAMENTO` ou `REJEITADA`
- `EM_ANDAMENTO` → `RESOLVIDA`
- `RESOLVIDA` e `REJEITADA` são finais.

## Observações importantes
- O banco continua sendo a fonte da regra de negócio para protocolo e mudança de status. A API chama as procedures existentes.
- As procedures do script não fazem `COMMIT`; o Spring controla a transação.
- A rota de apoio evita duplicidade por usuário/ocorrência na aplicação. Recomenda-se também criar uma constraint UNIQUE no banco para `(ID_USUARIO, ID_OCORRENCIA)`.
- Nesta primeira versão, as rotas de leitura de ocorrências/categorias são públicas; as demais exigem JWT. Para produção, é necessário reforçar autorização por usuário/administrador, validar propriedade dos registros, limitar upload de imagens a armazenamento real e revisar CORS/rate limiting.
- Se sua sequence `SEQ_PROTOCOLO_OCORRENCIA` foi iniciada em 16 conforme o script, o protocolo é gerado no banco. Não gere protocolo no Java.
