import '../core/api_exception.dart';
import '../models/models.dart';
import 'zelo_repository.dart';

/// Implementação em memória, usada quando o app roda sem `API_URL`.
///
/// Reproduz as regras do banco Oracle para a demonstração ficar fiel:
/// protocolo ZEL-AAAA-NNNN, histórico inicial ABERTA, notificação de
/// recebimento, apoio único por usuário, autor não apoia a própria
/// ocorrência e ocorrência encerrada não recebe apoio.
class DemoZeloRepository implements ZeloRepository {
  DemoZeloRepository({this.atraso = const Duration(milliseconds: 500)}) {
    _semear();
  }

  /// Atraso artificial, para os estados de carregamento aparecerem.
  final Duration atraso;

  final _usuarios = <int, ({String nome, String email, String senha})>{};
  final _ocorrencias = <int, Ocorrencia>{};
  final _historico = <int, List<HistoricoStatus>>{};
  final _fotos = <int, List<Foto>>{};
  final _apoios = <int, List<Apoio>>{};
  final _notificacoes = <int, List<Notificacao>>{};
  int _seqUsuario = 1, _seqOcorrencia = 1, _seqProtocolo = 16, _seqNotif = 1;

  static const _categorias = [
    Categoria(id: 1, nome: 'Buraco na via', descricao: 'Buracos e asfalto danificado'),
    Categoria(id: 2, nome: 'Iluminação pública', descricao: 'Poste apagado ou piscando'),
    Categoria(id: 3, nome: 'Descarte irregular', descricao: 'Lixo e entulho em local público'),
    Categoria(id: 4, nome: 'Vazamento', descricao: 'Vazamento de água ou esgoto'),
    Categoria(id: 5, nome: 'Calçada danificada', descricao: 'Calçada quebrada ou sem acessibilidade'),
    Categoria(id: 6, nome: 'Sinalização', descricao: 'Placa ou semáforo com defeito'),
    Categoria(id: 7, nome: 'Área abandonada', descricao: 'Praça ou terreno público abandonado'),
  ];

  @override
  set token(String? valor) {}

  Future<T> _espera<T>(T Function() f) async {
    await Future<void>.delayed(atraso);
    return f();
  }

  void _semear() {
    final vizinha = _criarUsuario('Ana Vizinha', 'ana@zelo.dev', 'senha1234');
    final agora = DateTime.now();
    _abrir(vizinha, 2, 'Poste apagado na esquina',
        'O poste está apagado há uma semana e a rua fica escura à noite.',
        -23.5641, -46.6527, 'Av. Paulista, 1100 - Bela Vista',
        quando: agora.subtract(const Duration(days: 6)));
    final id = _abrir(vizinha, 1, 'Buraco em frente à escola',
        'Buraco grande na faixa da direita, carros desviam em cima da calçada.',
        -23.5874, -46.6576, 'R. Domingos de Morais, 500 - Vila Mariana',
        quando: agora.subtract(const Duration(days: 3)));
    _mudarStatus(id, StatusOcorrencia.emAnalise, 'Encaminhada para a subprefeitura.',
        agora.subtract(const Duration(days: 2)));
  }

  int _criarUsuario(String nome, String email, String senha) {
    final id = _seqUsuario++;
    _usuarios[id] = (nome: nome, email: email, senha: senha);
    _notificacoes[id] = [];
    return id;
  }

  int _abrir(int idUsuario, int idCategoria, String titulo, String descricao,
      double lat, double lng, String? endereco,
      {DateTime? quando, String? foto}) {
    final id = _seqOcorrencia++;
    final data = quando ?? DateTime.now();
    final protocolo =
        'ZEL-${data.year}-${(_seqProtocolo++).toString().padLeft(4, '0')}';
    _ocorrencias[id] = Ocorrencia(
      id: id,
      idUsuario: idUsuario,
      idCategoria: idCategoria,
      titulo: titulo,
      descricao: descricao,
      protocolo: protocolo,
      status: StatusOcorrencia.aberta,
      latitude: lat,
      longitude: lng,
      endereco: endereco,
      dataAbertura: data,
    );
    _historico[id] = [
      HistoricoStatus(
          statusNovo: StatusOcorrencia.aberta,
          observacao: 'Ocorrência registrada.',
          data: data),
    ];
    _fotos[id] = [if (foto != null) Foto(id: id, url: foto)];
    _apoios[id] = [];
    _notificar(idUsuario, id, 'Ocorrência recebida',
        'Sua ocorrência $protocolo foi registrada.', data);
    return id;
  }

  void _mudarStatus(int id, StatusOcorrencia novo, String obs, DateTime data) {
    final o = _ocorrencias[id]!;
    _ocorrencias[id] = Ocorrencia(
      id: o.id,
      idUsuario: o.idUsuario,
      idCategoria: o.idCategoria,
      titulo: o.titulo,
      descricao: o.descricao,
      protocolo: o.protocolo,
      status: novo,
      latitude: o.latitude,
      longitude: o.longitude,
      endereco: o.endereco,
      dataAbertura: o.dataAbertura,
    );
    _historico[id]!.add(HistoricoStatus(
        statusAnterior: o.status, statusNovo: novo, observacao: obs, data: data));
    _notificar(o.idUsuario, id, 'Status atualizado',
        '${o.protocolo} agora está: ${novo.rotulo}.', data);
  }

  void _notificar(int idUsuario, int idOcorrencia, String titulo, String msg,
      DateTime data) {
    _notificacoes[idUsuario]!.insert(
        0,
        Notificacao(
            id: _seqNotif++,
            idOcorrencia: idOcorrencia,
            titulo: titulo,
            mensagem: msg,
            lida: false,
            data: data));
  }

  Sessao _sessao(int id) {
    final u = _usuarios[id]!;
    return Sessao(token: 'demo-$id', idUsuario: id, nome: u.nome, email: u.email);
  }

  Ocorrencia _get(int id) =>
      _ocorrencias[id] ?? (throw ApiException('Ocorrência não encontrada.'));

  @override
  Future<Sessao> registrar(
          {required String nome,
          required String email,
          required String senha}) =>
      _espera(() {
        final e = email.trim().toLowerCase();
        if (_usuarios.values.any((u) => u.email == e)) {
          throw ApiException('Este e-mail já está cadastrado.');
        }
        return _sessao(_criarUsuario(nome.trim(), e, senha));
      });

  @override
  Future<Sessao> login({required String email, required String senha}) =>
      _espera(() {
        final e = email.trim().toLowerCase();
        final entrada = _usuarios.entries
            .where((u) => u.value.email == e && u.value.senha == senha);
        if (entrada.isEmpty) throw ApiException('E-mail ou senha inválidos.');
        return _sessao(entrada.first.key);
      });

  @override
  Future<List<Categoria>> categorias() => _espera(() => _categorias);

  @override
  Future<List<Ocorrencia>> ocorrencias() =>
      _espera(() => _ocorrencias.values.toList());

  @override
  Future<List<Ocorrencia>> ocorrenciasDoUsuario(int idUsuario) =>
      _espera(() => _ocorrencias.values
          .where((o) => o.idUsuario == idUsuario)
          .toList()
          .reversed
          .toList());

  @override
  Future<Ocorrencia> ocorrencia(int id) => _espera(() => _get(id));

  @override
  Future<Ocorrencia> porProtocolo(String protocolo) => _espera(() {
        final p = protocolo.trim().toUpperCase();
        return _ocorrencias.values.firstWhere((o) => o.protocolo == p,
            orElse: () => throw ApiException('Protocolo não encontrado.'));
      });

  @override
  Future<OcorrenciaCriada> registrarOcorrencia(
          NovaOcorrencia nova, int idUsuario) =>
      _espera(() {
        final id = _abrir(idUsuario, nova.idCategoria, nova.titulo.trim(),
            nova.descricao.trim(), nova.latitude, nova.longitude, nova.endereco,
            foto: nova.caminhoFoto);
        return OcorrenciaCriada(id: id, protocolo: _ocorrencias[id]!.protocolo);
      });

  @override
  Future<List<HistoricoStatus>> historico(int idOcorrencia) =>
      _espera(() => List.of(_historico[idOcorrencia] ?? const []));

  @override
  Future<List<Foto>> fotos(int idOcorrencia) =>
      _espera(() => List.of(_fotos[idOcorrencia] ?? const []));

  @override
  Future<List<Apoio>> apoios(int idOcorrencia) =>
      _espera(() => List.of(_apoios[idOcorrencia] ?? const []));

  @override
  Future<void> apoiar(int idOcorrencia, int idUsuario,
          {String tipo = 'APOIO'}) =>
      _espera(() {
        final o = _get(idOcorrencia);
        if (o.idUsuario == idUsuario) {
          throw ApiException('Você não pode apoiar a sua própria ocorrência.');
        }
        if (o.status.encerrada) {
          throw ApiException('Esta ocorrência já foi encerrada.');
        }
        final lista = _apoios[idOcorrencia]!;
        if (lista.any((a) => a.idUsuario == idUsuario)) {
          throw ApiException('Este usuário já apoiou esta ocorrência.');
        }
        lista.add(Apoio(idUsuario: idUsuario, tipo: tipo));
      });

  @override
  Future<List<Notificacao>> notificacoes(int idUsuario) =>
      _espera(() => List.of(_notificacoes[idUsuario] ?? const []));

  @override
  Future<void> marcarComoLida(int idNotificacao) => _espera(() {
        for (final lista in _notificacoes.values) {
          final i = lista.indexWhere((n) => n.id == idNotificacao);
          if (i >= 0) lista[i] = lista[i].marcadaComoLida();
        }
      });
}
