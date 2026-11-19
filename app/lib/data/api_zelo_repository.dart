import '../core/api_client.dart';
import '../models/models.dart';
import 'zelo_repository.dart';

/// Implementação que fala com a API REST do Zelo (Spring Boot + Oracle).
/// Rotas conforme o README do backend (`zelo-backend`).
class ApiZeloRepository implements ZeloRepository {
  ApiZeloRepository(this._api);

  final ApiClient _api;

  @override
  set token(String? valor) => _api.token = valor;

  List<T> _lista<T>(dynamic dados, T Function(Map<String, dynamic>) de) =>
      (dados as List? ?? const [])
          .map((e) => de(Map<String, dynamic>.from(e as Map)))
          .toList();

  Map<String, dynamic> _mapa(dynamic dados) =>
      Map<String, dynamic>.from(dados as Map);

  @override
  Future<Sessao> registrar(
          {required String nome,
          required String email,
          required String senha}) async =>
      Sessao.fromJson(_mapa(await _api.post('/auth/registrar', {
        'nome': nome.trim(),
        'email': email.trim().toLowerCase(),
        'senha': senha,
      })));

  @override
  Future<Sessao> login({required String email, required String senha}) async =>
      Sessao.fromJson(_mapa(await _api.post('/auth/login', {
        'email': email.trim().toLowerCase(),
        'senha': senha,
      })));

  @override
  Future<List<Categoria>> categorias() async =>
      _lista(await _api.get('/categorias'), Categoria.fromJson);

  @override
  Future<List<Ocorrencia>> ocorrencias() async =>
      _lista(await _api.get('/ocorrencias'), Ocorrencia.fromJson);

  @override
  Future<List<Ocorrencia>> ocorrenciasDoUsuario(int idUsuario) async {
    final lista = _lista(
        await _api.get('/ocorrencias/usuario/$idUsuario'), Ocorrencia.fromJson);
    lista.sort((a, b) => (b.dataAbertura ?? DateTime(0))
        .compareTo(a.dataAbertura ?? DateTime(0)));
    return lista;
  }

  @override
  Future<Ocorrencia> ocorrencia(int id) async =>
      Ocorrencia.fromJson(_mapa(await _api.get('/ocorrencias/$id')));

  @override
  Future<Ocorrencia> porProtocolo(String protocolo) async {
    final p = Uri.encodeComponent(protocolo.trim().toUpperCase());
    return Ocorrencia.fromJson(
        _mapa(await _api.get('/ocorrencias/protocolo/$p')));
  }

  @override
  Future<OcorrenciaCriada> registrarOcorrencia(
      NovaOcorrencia nova, int idUsuario) async {
    final criada = OcorrenciaCriada.fromJson(
        _mapa(await _api.post('/ocorrencias', nova.toJson(idUsuario))));
    final foto = nova.caminhoFoto;
    if (foto != null && foto.isNotEmpty) {
      // A API guarda só a referência da imagem (FOTO_OCORRENCIA.URL_FOTO).
      // Se falhar, a ocorrência já existe: não desfazemos o registro.
      try {
        await _api.post('/ocorrencias/${criada.id}/fotos', {'urlFoto': foto});
      } catch (_) {}
    }
    return criada;
  }

  @override
  Future<List<HistoricoStatus>> historico(int idOcorrencia) async => _lista(
      await _api.get('/ocorrencias/$idOcorrencia/historico'),
      HistoricoStatus.fromJson);

  @override
  Future<List<Foto>> fotos(int idOcorrencia) async =>
      _lista(await _api.get('/ocorrencias/$idOcorrencia/fotos'), Foto.fromJson);

  @override
  Future<List<Apoio>> apoios(int idOcorrencia) async => _lista(
      await _api.get('/ocorrencias/$idOcorrencia/apoios'), Apoio.fromJson);

  @override
  Future<void> apoiar(int idOcorrencia, int idUsuario,
          {String tipo = 'APOIO'}) =>
      _api.post('/ocorrencias/$idOcorrencia/apoios',
          {'idUsuario': idUsuario, 'tipoApoio': tipo});

  @override
  Future<List<Notificacao>> notificacoes(int idUsuario) async => _lista(
      await _api.get('/usuarios/$idUsuario/notificacoes'),
      Notificacao.fromJson);

  @override
  Future<void> marcarComoLida(int idNotificacao) =>
      _api.patch('/notificacoes/$idNotificacao/lida');
}
