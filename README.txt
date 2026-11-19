ZELO - ZELADORIA COMUNITÁRIA
Global Solution FIAP - Sistemas de Informação - 2º semestre de 2026
Tema: CitizenTech: tecnologia centrada no cidadão
Grupo: Gabriel Notari, Priscila Mantovani, Sophie Moreau

1. O QUE É
O Zelo é um aplicativo para o cidadão registrar problemas urbanos (buracos, iluminação,
descarte irregular, vazamentos, calçadas, sinalização, áreas abandonadas) com foto,
categoria e localização, receber um protocolo, acompanhar o andamento e apoiar
ocorrências registradas por vizinhos.

Funcionalidades principais (além de login e cadastro):
  - Reportar ocorrência: foto, categoria, descrição e localização por GPS; gera protocolo.
  - Acompanhar protocolo: linha do tempo do status (Aberta, Em análise, Em andamento,
    Resolvida ou Rejeitada) e avisos a cada mudança.
  - Apoio comunitário: apoiar ou confirmar ocorrências de outras pessoas.

ODS: 11 (Cidades e comunidades sustentáveis) e 16 (Instituições eficazes e transparentes).

2. ESTRUTURA DO REPOSITÓRIO
  app/      Aplicativo Flutter (Android, iOS e web)
  backend/  API REST Java 21 + Spring Boot, integrada ao Oracle 21c
  docs/     Documento do projeto (MER, DER, arquitetura, PL/SQL, app) e arquivos .TXT de entrega

3. COMO EXECUTAR

3.1 Backend (detalhes em backend/README.md)
  Requisitos: Java 21, Maven 3.9+, Oracle Database 21c XE (PDB XEPDB1) com as tabelas e
  rotinas PL/SQL do projeto criadas.
  Variáveis de ambiente: DB_URL, DB_USERNAME, DB_PASSWORD, JWT_SECRET.
  Executar: cd backend && mvn spring-boot:run
  Base URL: http://localhost:8080/api

3.2 App (detalhes em app/README.md)
  Requisitos: Flutter 3.44+ (Dart 3.12+).
  cd app
  flutter pub get
  flutter run                                                   (modo demonstração, sem API)
  flutter run --dart-define=API_URL=http://localhost:8080/api   (com a API)
  No modo demonstração, entre com ana@zelo.dev / senha1234 ou crie uma conta.

3.3 Testes do app
  cd app
  flutter analyze
  flutter test        (26 testes)

4. TECNOLOGIAS E JUSTIFICATIVAS
  Flutter: um único código para Android, iOS e web, com interface Material 3.
  Spring Boot: API REST com validação, autenticação JWT e senhas com BCrypt.
  Oracle 21c + PL/SQL: regras críticas no banco (geração de protocolo, fluxo de status,
    histórico e notificações), protegidas mesmo fora da API, por procedures e triggers.
  Separação em camadas (app -> API -> banco): o app nunca acessa o banco diretamente.

5. GERENCIAMENTO DE MEMÓRIA (app)
  - Controladores de texto liberados em dispose() em todas as telas.
  - Nenhuma tela é atualizada depois de fechada (verificação de mounted).
  - Abas mantidas em IndexedStack, sem repetir requisições a cada troca.
  - Fotos reduzidas na escolha (largura máxima 1600 px, qualidade 80).
  - Estado com recursos nativos do Flutter, sem bibliotecas extras.

6. DOCUMENTAÇÃO
  docs/Zelo - Global Solution 2026.docx: documento completo (MER, DER, PL/SQL, API e app).
  Classes e funções do app estão documentadas no próprio código (comentários ///).
