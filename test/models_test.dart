import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/core/formato.dart';
import 'package:zelo/models/models.dart';

void main() {
  test('Ocorrencia.fromJson lê o formato da API', () {
    final o = Ocorrencia.fromJson({
      'id': 3,
      'idUsuario': 1,
      'idCategoria': 2,
      'titulo': 'Poste apagado',
      'descricao': 'Escuro',
      'latitude': -23.55,
      'longitude': -46.63,
      'endereco': 'Centro',
      'protocolo': 'ZEL-2026-0016',
      'statusAtual': 'EM_ANALISE',
      'dataAbertura': '2026-11-15T10:30:00',
    });
    expect(o.status, StatusOcorrencia.emAnalise);
    expect(o.latitude, -23.55);
    expect(o.dataAbertura, DateTime(2026, 11, 15, 10, 30));
  });

  test('status desconhecido vira ABERTA; encerrados', () {
    expect(StatusOcorrencia.fromCodigo('XYZ'), StatusOcorrencia.aberta);
    expect(StatusOcorrencia.resolvida.encerrada, isTrue);
    expect(StatusOcorrencia.rejeitada.encerrada, isTrue);
    expect(StatusOcorrencia.emAndamento.encerrada, isFalse);
  });

  test('NovaOcorrencia.toJson segue o CriarOcorrenciaRequest', () {
    const nova = NovaOcorrencia(
        idCategoria: 1,
        titulo: ' Buraco ',
        descricao: 'Grande',
        latitude: -23.5,
        longitude: -46.6,
        endereco: '  ');
    expect(nova.toJson(7), {
      'idUsuario': 7,
      'idCategoria': 1,
      'titulo': 'Buraco',
      'descricao': 'Grande',
      'latitude': -23.5,
      'longitude': -46.6,
    });
  });

  test('Notificacao: LIDA S/N vira bool', () {
    final n = Notificacao.fromJson(
        {'id': 1, 'titulo': 't', 'mensagem': 'm', 'lida': 'N'});
    expect(n.lida, isFalse);
    expect(n.marcadaComoLida().lida, isTrue);
  });

  test('Formato', () {
    final d = DateTime(2026, 11, 9, 8, 5);
    expect(Formato.dataHora(d), '09/11/2026 às 08:05');
    expect(Formato.relativo(d, agora: d.add(const Duration(minutes: 5))),
        'há 5 min');
    expect(Formato.relativo(d, agora: d.add(const Duration(days: 10))),
        '09/11/2026');
  });
}
