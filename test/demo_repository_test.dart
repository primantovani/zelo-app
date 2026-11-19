import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/core/api_exception.dart';
import 'package:zelo/data/demo_zelo_repository.dart';
import 'package:zelo/models/models.dart';

void main() {
  late DemoZeloRepository repo;
  setUp(() => repo = DemoZeloRepository(atraso: Duration.zero));

  const nova = NovaOcorrencia(
      idCategoria: 1,
      titulo: 'Buraco',
      descricao: 'Grande',
      latitude: -23.5,
      longitude: -46.6);

  test('registro gera protocolo, histórico ABERTA e notificação', () async {
    final s = await repo.registrar(
        nome: 'Maria', email: 'maria@e.com', senha: '12345678');
    final criada = await repo.registrarOcorrencia(nova, s.idUsuario);
    expect(criada.protocolo, matches(RegExp(r'^ZEL-\d{4}-\d{4}$')));
    final h = await repo.historico(criada.id);
    expect(h.single.statusNovo, StatusOcorrencia.aberta);
    expect(h.single.statusAnterior, isNull);
    expect((await repo.notificacoes(s.idUsuario)).first.lida, isFalse);
  });

  test('e-mail duplicado e senha errada', () async {
    await repo.registrar(nome: 'A', email: 'a@e.com', senha: '12345678');
    expect(() => repo.registrar(nome: 'B', email: 'A@e.com', senha: '12345678'),
        throwsA(isA<ApiException>()));
    expect(() => repo.login(email: 'a@e.com', senha: 'errada00'),
        throwsA(isA<ApiException>()));
  });

  test('regras de apoio: autor não apoia; apoio único', () async {
    final autor =
        await repo.registrar(nome: 'A', email: 'a@e.com', senha: '12345678');
    final vizinho =
        await repo.registrar(nome: 'B', email: 'b@e.com', senha: '12345678');
    final o = await repo.registrarOcorrencia(nova, autor.idUsuario);

    expect(() => repo.apoiar(o.id, autor.idUsuario),
        throwsA(isA<ApiException>()));
    await repo.apoiar(o.id, vizinho.idUsuario, tipo: 'CONFIRMACAO');
    expect(() => repo.apoiar(o.id, vizinho.idUsuario),
        throwsA(isA<ApiException>()));
    expect((await repo.apoios(o.id)).single.tipo, 'CONFIRMACAO');
  });

  test('marcar notificação como lida', () async {
    final s = await repo.login(email: 'ana@zelo.dev', senha: 'senha1234');
    final n = (await repo.notificacoes(s.idUsuario)).first;
    await repo.marcarComoLida(n.id);
    expect((await repo.notificacoes(s.idUsuario)).first.lida, isTrue);
  });
}
