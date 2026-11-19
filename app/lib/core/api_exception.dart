/// Erro de comunicação com a API, já com uma mensagem pronta para o usuário.
class ApiException implements Exception {
  ApiException(this.mensagem, {this.statusCode});

  /// Texto exibido na tela.
  final String mensagem;

  /// Código HTTP, quando houve resposta do servidor.
  final int? statusCode;

  /// `true` quando o token expirou ou não foi aceito.
  bool get naoAutorizado => statusCode == 401 || statusCode == 403;

  @override
  String toString() => mensagem;
}
