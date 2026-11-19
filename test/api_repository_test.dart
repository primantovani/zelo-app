import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zelo/core/api_client.dart';
import 'package:zelo/core/api_exception.dart';
import 'package:zelo/data/api_zelo_repository.dart';
import 'package:zelo/models/models.dart';

http.Response _json(Object corpo, [int status = 200]) => http.Response(
    jsonEncode(corpo), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  late List<http.Request> chamadas;

  ApiZeloRepository repo(http.Response Function(http.Request) responder) {
    chamadas = [];
    final client = MockClient((r) async {
      chamadas.add(r);
      return responder(r);
    });
    return ApiZeloRepository(
        ApiClient(baseUrl: 'https://api.test/api', client: client));
  }

  test('login envia e-mail normalizado e devolve a sessão', () async {
    final r = repo((_) => _json(
        {'token': 'jwt', 'idUsuario': 5, 'nome': 'Maria', 'email': 'm@e.com'}));
    final s = await r.login(email: ' M@E.com ', senha: '12345678');
    expect(s.idUsuario, 5);
    expect(chamadas.single.url.toString(), 'https://api.test/api/auth/login');
    expect(jsonDecode(chamadas.single.body)['email'], 'm@e.com');
  });

  test('token vai no cabeçalho Authorization', () async {
    final r = repo((_) => _json([]));
    r.token = 'abc';
    await r.notificacoes(5);
    expect(chamadas.single.headers['Authorization'], 'Bearer abc');
    expect(chamadas.single.url.path, '/api/usuarios/5/notificacoes');
  });

  test('registrar ocorrência chama /ocorrencias e depois /fotos', () async {
    final r = repo((req) => req.url.path.endsWith('/fotos')
        ? _json({'id': 1, 'urlFoto': 'x'})
        : _json({'idOcorrencia': 9, 'protocolo': 'ZEL-2026-0020'}));
    final criada = await r.registrarOcorrencia(
      const NovaOcorrencia(
          idCategoria: 1,
          titulo: 'Buraco',
          descricao: 'Grande',
          latitude: -23.5,
          longitude: -46.6,
          caminhoFoto: 'https://img/1.jpg'),
      5,
    );
    expect(criada.protocolo, 'ZEL-2026-0020');
    expect(chamadas.map((c) => c.url.path),
        ['/api/ocorrencias', '/api/ocorrencias/9/fotos']);
  });

  test('erro da API vira ApiException com a mensagem do backend', () async {
    final r = repo((_) => _json({'erro': 'E-mail ou senha inválidos.'}, 400));
    expect(
      () => r.login(email: 'a@b.com', senha: 'x'),
      throwsA(isA<ApiException>()
          .having((e) => e.mensagem, 'mensagem', 'E-mail ou senha inválidos.')),
    );
  });

  test('401 sem corpo pede novo login', () async {
    final r = repo((_) => http.Response('', 401));
    expect(
      () => r.historico(1),
      throwsA(isA<ApiException>().having((e) => e.naoAutorizado, 'auth', true)),
    );
  });

  test('falha de rede vira mensagem amigável', () async {
    final client = MockClient((_) => throw http.ClientException('offline'));
    final r = ApiZeloRepository(
        ApiClient(baseUrl: 'https://api.test/api', client: client));
    expect(() => r.categorias(),
        throwsA(isA<ApiException>().having((e) => e.mensagem, 'm',
            contains('Não foi possível falar com o servidor'))));
  });

  test('protocolo é normalizado na URL', () async {
    final r = repo((_) => _json({
          'id': 1, 'idUsuario': 1, 'idCategoria': 1, 'titulo': 't',
          'descricao': 'd', 'protocolo': 'ZEL-2026-0016', 'statusAtual': 'ABERTA'
        }));
    await r.porProtocolo(' zel-2026-0016 ');
    expect(chamadas.single.url.path, '/api/ocorrencias/protocolo/ZEL-2026-0016');
  });
}
