import '../models/models.dart';

/// Contrato de acesso aos dados do Zelo.
///
/// As telas dependem só desta interface. Há duas implementações:
/// [ApiZeloRepository] (API Spring Boot + Oracle) e [DemoZeloRepository]
/// (memória local, para apresentação e testes).
abstract class ZeloRepository {
  /// Token JWT usado nas rotas protegidas.
  set token(String? valor);

  Future<Sessao> registrar(
      {required String nome, required String email, required String senha});
  Future<Sessao> login({required String email, required String senha});

  Future<List<Categoria>> categorias();

  /// Todas as ocorrências (base para o mapa).
  Future<List<Ocorrencia>> ocorrencias();
  Future<List<Ocorrencia>> ocorrenciasDoUsuario(int idUsuario);
  Future<Ocorrencia> ocorrencia(int id);
  Future<Ocorrencia> porProtocolo(String protocolo);

  /// Registra a ocorrência (PRC_REGISTRAR_OCORRENCIA) e anexa a foto, se houver.
  Future<OcorrenciaCriada> registrarOcorrencia(
      NovaOcorrencia nova, int idUsuario);

  Future<List<HistoricoStatus>> historico(int idOcorrencia);
  Future<List<Foto>> fotos(int idOcorrencia);
  Future<List<Apoio>> apoios(int idOcorrencia);
  Future<void> apoiar(int idOcorrencia, int idUsuario,
      {String tipo = 'APOIO'});

  Future<List<Notificacao>> notificacoes(int idUsuario);
  Future<void> marcarComoLida(int idNotificacao);
}
