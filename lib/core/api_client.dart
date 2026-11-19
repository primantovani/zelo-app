import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'config.dart';

/// Cliente HTTP da API Zelo.
///
/// Centraliza a URL base, o cabeçalho `Authorization: Bearer <token>`,
/// o timeout e a conversão de erros em [ApiException], para que as telas
/// nunca precisem lidar com detalhes de rede.
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
      : _http = client ?? http.Client();

  final String baseUrl;
  final http.Client _http;

  /// Token JWT da sessão atual; enviado em toda requisição quando presente.
  String? token;

  Future<dynamic> get(String path) => _enviar('GET', path);

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _enviar('POST', path, body);

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _enviar('PATCH', path, body);

  Future<dynamic> _enviar(String metodo, String path,
      [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request(metodo, uri)
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    final http.Response resposta;
    try {
      final streamed = await _http.send(request).timeout(AppConfig.timeout);
      resposta = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException(
          'O servidor demorou para responder. Tente de novo em instantes.');
    } on http.ClientException {
      // Sem internet, servidor fora do ar ou CORS bloqueado (web).
      throw ApiException(
          'Não foi possível falar com o servidor. Confira sua conexão.');
    }

    final texto = utf8.decode(resposta.bodyBytes);
    final dados = texto.isEmpty ? null : _tentarJson(texto);

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return dados;
    throw ApiException(_mensagemDeErro(resposta.statusCode, dados),
        statusCode: resposta.statusCode);
  }

  static dynamic _tentarJson(String texto) {
    try {
      return jsonDecode(texto);
    } on FormatException {
      return texto;
    }
  }

  /// A API devolve `{"erro": "..."}` nos erros tratados (ApiExceptionHandler).
  static String _mensagemDeErro(int status, dynamic dados) {
    if (dados is Map && dados['erro'] is String) return dados['erro'] as String;
    return switch (status) {
      401 || 403 => 'Sua sessão expirou. Entre novamente.',
      404 => 'Não encontrado.',
      >= 500 => 'O servidor teve um problema. Tente de novo mais tarde.',
      _ => 'Não foi possível concluir a operação (erro $status).',
    };
  }
}
