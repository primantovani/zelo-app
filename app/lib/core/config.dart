/// Configuração do app, lida das variáveis passadas no build.
///
/// Exemplo:
/// `flutter run --dart-define=API_URL=https://zelo-api.onrender.com/api`
///
/// Sem `API_URL`, o app roda em **modo demonstração**, com dados locais,
/// para que a interface possa ser apresentada mesmo sem a API no ar.
class AppConfig {
  AppConfig._();

  /// URL base da API Spring Boot (inclui o context-path `/api`).
  static const String apiUrl = String.fromEnvironment('API_URL');

  /// Tempo máximo de espera de uma requisição antes de mostrar erro.
  static const Duration timeout = Duration(seconds: 20);

  /// Esconde o aviso de modo demonstração (gravação de vídeo).
  /// `--dart-define=APRESENTACAO=true`
  static const bool apresentacao = bool.fromEnvironment('APRESENTACAO');

  /// `true` quando nenhuma API foi configurada.
  static bool get modoDemonstracao => apiUrl.isEmpty;
}
