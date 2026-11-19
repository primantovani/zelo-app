# Zelo: app Flutter

App mobile do **Zelo (Zeladoria Comunitária)**, Global Solution FIAP, 2º semestre de 2026
(tema *CitizenTech: tecnologia centrada no cidadão*).

O cidadão **reporta** um problema urbano (buraco, poste apagado, lixo, vazamento, calçada,
sinalização, área abandonada) com **foto, categoria e localização**, recebe um **protocolo**
(`ZEL-AAAA-NNNN`, gerado no Oracle) e **acompanha** o andamento numa linha do tempo. Vizinhos
podem **apoiar** ou **confirmar** ocorrências, e o autor recebe **avisos** a cada mudança de status.

| Parte | Responsável | Repositório |
|---|---|---|
| App Flutter (este repositório) | Priscila Mantovani | `zelo-app` |
| API Spring Boot + Oracle + PL/SQL | Gabriel Notari | [Gabrielnotari/zelo-backend](https://github.com/Gabrielnotari/zelo-backend) |
| Mapa, notificações push, PL/SQL de indicadores, documentação | Sophie Moreau | (a integrar) |

## Funcionalidades

- **Login e cadastro** com validação (e-mail, senha com no mínimo 8 caracteres, como na API).
  A sessão (JWT) fica salva no aparelho.
- **Reportar ocorrência**: foto pela câmera ou galeria, categoria vinda do banco, título,
  descrição, GPS automático e endereço opcional. Ao enviar, mostra o protocolo, com botão para copiar.
- **Minhas ocorrências**: lista com protocolo, status colorido, categoria e há quanto tempo foi aberta.
- **Acompanhar protocolo**: busca qualquer ocorrência pelo protocolo.
- **Detalhe**: linha do tempo do fluxo (Aberta, Em análise, Em andamento, Resolvida ou
  Rejeitada) com data e observação de cada passagem, a partir do `HISTORICO_STATUS`.
- **Apoiar / "Eu também vi"**, seguindo as regras do banco: o autor não apoia a própria
  ocorrência, cada usuário apoia uma vez e ocorrência encerrada não recebe apoio.
- **Avisos**: notificações geradas pelas procedures; tocar no aviso marca como lido e abre o protocolo.
- **Estados de carregamento, erro (com "Tentar de novo") e lista vazia** em todas as telas,
  além de "puxar para atualizar".
- Tema claro e escuro (Material 3).

## Arquitetura

```
lib/
├── main.dart                 # escolhe API real ou modo demonstração
├── app.dart                  # MaterialApp, tema, decide login × home
├── core/
│   ├── config.dart           # API_URL via --dart-define
│   ├── api_client.dart       # HTTP + JWT + timeout + erros → ApiException
│   ├── api_exception.dart
│   ├── validators.dart       # mesmas regras da API e do Oracle
│   ├── localizacao.dart      # GPS com pedido de permissão
│   └── formato.dart          # datas em pt-BR
├── models/                   # Sessao, Categoria, Ocorrencia, HistoricoStatus,
│                             # Apoio, Foto, Notificacao, StatusOcorrencia
├── data/
│   ├── zelo_repository.dart       # contrato (interface) usado pelas telas
│   ├── api_zelo_repository.dart   # implementação REST (zelo-backend)
│   └── demo_zelo_repository.dart  # implementação em memória
├── state/
│   ├── auth_controller.dart  # sessão (ChangeNotifier) + persistência
│   └── app_scope.dart        # injeção de dependências (InheritedWidget)
├── screens/                  # login, cadastro, home, minhas ocorrências,
│                             # reportar, detalhe, acompanhar, notificações
└── widgets/                  # estados (carregando/erro/vazio), StatusChip,
                              # StatusTimeline, componentes de formulário
```

Separação em camadas: **telas → repositório (interface) → cliente HTTP → API → Oracle**.
As telas não conhecem HTTP nem JSON; dependem só de `ZeloRepository`. Por isso existem duas
implementações intercambiáveis:

- `ApiZeloRepository`: fala com a API Spring Boot.
- `DemoZeloRepository`: dados em memória que reproduzem as regras do Oracle (protocolo,
  histórico inicial, notificação, regras de apoio). Serve para apresentar o app sem a API no
  ar e para os testes.

O estado usa só o Flutter (`ChangeNotifier` + `ListenableBuilder` + `InheritedWidget`), sem
pacote de gerenciamento de estado.

**Gerenciamento de memória:** todo `TextEditingController` é liberado em `dispose()`; toda
atualização de tela depois de uma operação assíncrona confere `mounted` antes do `setState`;
as abas ficam num `IndexedStack`, o que evita refazer as requisições a cada troca; as fotos
são reduzidas na escolha (`maxWidth: 1600`, qualidade 80) antes de ir para a memória.

## Contrato da API usado

Base: `.../api` (context-path do Spring). JWT no cabeçalho `Authorization: Bearer <token>`.

| Tela | Método e rota |
|---|---|
| Cadastro | `POST /auth/registrar` `{nome, email, senha}` → `{token, idUsuario, nome, email}` |
| Login | `POST /auth/login` `{email, senha}` → idem |
| Reportar | `GET /categorias` · `POST /ocorrencias` `{idUsuario, idCategoria, titulo, descricao, latitude, longitude, endereco}` → `{idOcorrencia, protocolo}` · `POST /ocorrencias/{id}/fotos` `{urlFoto}` |
| Minhas | `GET /ocorrencias/usuario/{idUsuario}` |
| Acompanhar | `GET /ocorrencias/protocolo/{protocolo}` |
| Detalhe | `GET /ocorrencias/{id}` · `/historico` · `/fotos` · `/apoios` |
| Apoiar | `POST /ocorrencias/{id}/apoios` `{idUsuario, tipoApoio: APOIO \| CONFIRMACAO}` |
| Avisos | `GET /usuarios/{idUsuario}/notificacoes` · `PATCH /notificacoes/{id}/lida` |

Os erros da API (`{"erro": "..."}`) aparecem para o usuário com o texto do backend.

## Como rodar

Requisitos: Flutter 3.44+ (Dart 3.12+).

```bash
flutter pub get

# Modo demonstração (sem API): entre com ana@zelo.dev / senha1234
flutter run

# Com a API (local ou no Render)
flutter run --dart-define=API_URL=http://localhost:8080/api
flutter run --dart-define=API_URL=https://SEU-APP.onrender.com/api
```

No emulador Android, `localhost` do computador é `10.0.2.2`
(`--dart-define=API_URL=http://10.0.2.2:8080/api`).

## Testes

```bash
flutter analyze   # sem avisos
flutter test      # 26 testes
```

- `validators_test.dart`: regras de formulário (e-mail, senha, limites do Oracle, protocolo, coordenadas).
- `models_test.dart`: leitura do JSON da API, status, datas.
- `api_repository_test.dart`: rotas, JWT, corpo das requisições e tratamento de erro com `MockClient`.
- `demo_repository_test.dart`: regras de negócio (protocolo, histórico, apoio único, autor não apoia).
- `telas_test.dart`: login, cadastro e lista (testes de widget).

## Integração com o grupo

- **Mapa (Sophie):** `ZeloRepository.ocorrencias()` já devolve todas as ocorrências com
  latitude e longitude. Basta criar a tela do mapa e adicionar uma aba em `screens/home_screen.dart`.
  O "Apoiar" do mapa pode reaproveitar `repo.apoiar(...)` ou abrir `DetalheScreen(idOcorrencia: id)`.
- **API (Gabriel):** para rodar o app no navegador (Flutter web), a API precisa liberar **CORS**.
  No celular não há essa restrição.
- **Fotos:** a API guarda só a referência da imagem (`URL_FOTO`), como previsto no documento.
  O app envia o caminho do arquivo; o upload para um storage fica como evolução.

## ODS relacionados

- **ODS 11**: Cidades e comunidades sustentáveis.
- **ODS 16**: Instituições eficazes, responsáveis e transparentes (protocolo e histórico públicos).
