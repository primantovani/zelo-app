# Zelo: Zeladoria Comunitária

Global Solution FIAP, Sistemas de Informação, 2º semestre de 2026.
Tema: *CitizenTech: tecnologia centrada no cidadão*.

O Zelo permite que moradores registrem problemas urbanos (buracos, iluminação, descarte
irregular, vazamentos, calçadas, sinalização, áreas abandonadas) com foto e localização,
recebam um protocolo, acompanhem o andamento e apoiem ocorrências de vizinhos.

**Grupo:** Gabriel Notari · Priscila Mantovani · Sophie Moreau

## Estrutura do repositório

| Pasta | Conteúdo | Responsável |
|---|---|---|
| [`app/`](app/) | Aplicativo mobile em Flutter (Android, iOS e web) | Priscila Mantovani |
| [`backend/`](backend/) | API REST em Java 21 + Spring Boot, integrada ao Oracle 21c | Gabriel Notari |
| [`docs/`](docs/) | Documento do projeto (MER, DER, arquitetura, PL/SQL, app) e arquivos de entrega | Grupo |

A Sophie entra com o mapa e as notificações push em `app/` e com as rotinas PL/SQL de
indicadores em `backend/`.

## Arquitetura

```
App Flutter  ──HTTP/JSON + JWT──▶  API Spring Boot  ──JDBC/JPA──▶  Oracle 21c XE
(app/)                              (backend/)                      procedures, functions, triggers
```

O app nunca acessa o banco diretamente. As regras de negócio críticas (protocolo, fluxo de
status, histórico, notificações) ficam no Oracle e são chamadas pela API.

## Como rodar

**Backend:** veja [`backend/README.md`](backend/README.md) (Java 21, Maven, Oracle XEPDB1).

**App:** veja [`app/README.md`](app/README.md).

```bash
cd app
flutter pub get
flutter run                                                    # modo demonstração
flutter run --dart-define=API_URL=http://localhost:8080/api    # com a API
```

## Entrega

- Documento: [`docs/Zelo - Global Solution 2026.docx`](docs/)
- Links: [`docs/entrega/`](docs/entrega/) (pitch de venda, vídeo técnico, GitHub)

## ODS

- ODS 11: Cidades e comunidades sustentáveis
- ODS 16: Instituições eficazes, responsáveis e transparentes
