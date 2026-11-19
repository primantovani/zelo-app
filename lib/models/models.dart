import 'status_ocorrencia.dart';

export 'status_ocorrencia.dart';

/// Lê datas da API (LocalDateTime em ISO-8601, sem fuso).
DateTime? _data(dynamic v) => v is String ? DateTime.tryParse(v) : null;

double? _double(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');

int _int(dynamic v) => v is num ? v.toInt() : int.parse('$v');

/// Sessão do usuário logado (AuthResponse da API).
class Sessao {
  const Sessao({
    required this.token,
    required this.idUsuario,
    required this.nome,
    required this.email,
  });

  final String token;
  final int idUsuario;
  final String nome;
  final String email;

  String get primeiroNome => nome.trim().split(' ').first;

  factory Sessao.fromJson(Map<String, dynamic> j) => Sessao(
        token: j['token'] as String,
        idUsuario: _int(j['idUsuario']),
        nome: j['nome'] as String? ?? '',
        email: j['email'] as String? ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'token': token, 'idUsuario': idUsuario, 'nome': nome, 'email': email};
}

/// Tipo de problema urbano (tabela CATEGORIA).
class Categoria {
  const Categoria({required this.id, required this.nome, this.descricao});

  final int id;
  final String nome;
  final String? descricao;

  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
        id: _int(j['id']),
        nome: j['nome'] as String? ?? '',
        descricao: j['descricao'] as String?,
      );
}

/// Problema reportado (tabela OCORRENCIA), entidade central do app.
class Ocorrencia {
  const Ocorrencia({
    required this.id,
    required this.idUsuario,
    required this.idCategoria,
    required this.titulo,
    required this.descricao,
    required this.protocolo,
    required this.status,
    this.latitude,
    this.longitude,
    this.endereco,
    this.dataAbertura,
  });

  final int id;
  final int idUsuario;
  final int idCategoria;
  final String titulo;
  final String descricao;
  final String protocolo;
  final StatusOcorrencia status;
  final double? latitude;
  final double? longitude;
  final String? endereco;
  final DateTime? dataAbertura;

  factory Ocorrencia.fromJson(Map<String, dynamic> j) => Ocorrencia(
        id: _int(j['id']),
        idUsuario: _int(j['idUsuario']),
        idCategoria: _int(j['idCategoria']),
        titulo: j['titulo'] as String? ?? '',
        descricao: j['descricao'] as String? ?? '',
        protocolo: j['protocolo'] as String? ?? '',
        status: StatusOcorrencia.fromCodigo(j['statusAtual'] as String?),
        latitude: _double(j['latitude']),
        longitude: _double(j['longitude']),
        endereco: j['endereco'] as String?,
        dataAbertura: _data(j['dataAbertura']),
      );
}

/// Dados enviados para registrar uma ocorrência (CriarOcorrenciaRequest).
class NovaOcorrencia {
  const NovaOcorrencia({
    required this.idCategoria,
    required this.titulo,
    required this.descricao,
    required this.latitude,
    required this.longitude,
    this.endereco,
    this.caminhoFoto,
  });

  final int idCategoria;
  final String titulo;
  final String descricao;
  final double latitude;
  final double longitude;
  final String? endereco;

  /// Referência da foto escolhida; a API guarda apenas a URL/caminho.
  final String? caminhoFoto;

  Map<String, dynamic> toJson(int idUsuario) => {
        'idUsuario': idUsuario,
        'idCategoria': idCategoria,
        'titulo': titulo.trim(),
        'descricao': descricao.trim(),
        'latitude': latitude,
        'longitude': longitude,
        if (endereco != null && endereco!.trim().isNotEmpty)
          'endereco': endereco!.trim(),
      };
}

/// Resposta do registro: o Oracle gera o protocolo (PRC_REGISTRAR_OCORRENCIA).
class OcorrenciaCriada {
  const OcorrenciaCriada({required this.id, required this.protocolo});

  final int id;
  final String protocolo;

  factory OcorrenciaCriada.fromJson(Map<String, dynamic> j) => OcorrenciaCriada(
        id: _int(j['idOcorrencia']),
        protocolo: j['protocolo'] as String? ?? '',
      );
}

/// Uma mudança de status (tabela HISTORICO_STATUS).
class HistoricoStatus {
  const HistoricoStatus({
    required this.statusNovo,
    this.statusAnterior,
    this.observacao,
    this.data,
  });

  final StatusOcorrencia? statusAnterior;
  final StatusOcorrencia statusNovo;
  final String? observacao;
  final DateTime? data;

  factory HistoricoStatus.fromJson(Map<String, dynamic> j) => HistoricoStatus(
        statusAnterior: j['statusAnterior'] == null
            ? null
            : StatusOcorrencia.fromCodigo(j['statusAnterior'] as String),
        statusNovo: StatusOcorrencia.fromCodigo(j['statusNovo'] as String?),
        observacao: j['observacao'] as String?,
        data: _data(j['dataAlteracao']),
      );
}

/// Apoio ou confirmação de outro cidadão (tabela APOIO_OCORRENCIA).
class Apoio {
  const Apoio({required this.idUsuario, required this.tipo});

  final int idUsuario;

  /// `APOIO` ou `CONFIRMACAO`.
  final String tipo;

  factory Apoio.fromJson(Map<String, dynamic> j) => Apoio(
        idUsuario: _int(j['idUsuario']),
        tipo: j['tipoApoio'] as String? ?? 'APOIO',
      );
}

/// Foto anexada (tabela FOTO_OCORRENCIA).
class Foto {
  const Foto({required this.id, required this.url});

  final int id;
  final String url;

  factory Foto.fromJson(Map<String, dynamic> j) =>
      Foto(id: _int(j['id']), url: j['urlFoto'] as String? ?? '');
}

/// Aviso ao cidadão sobre uma ocorrência (tabela NOTIFICACAO).
class Notificacao {
  const Notificacao({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.lida,
    this.idOcorrencia,
    this.data,
  });

  final int id;
  final int? idOcorrencia;
  final String titulo;
  final String mensagem;
  final bool lida;
  final DateTime? data;

  factory Notificacao.fromJson(Map<String, dynamic> j) => Notificacao(
        id: _int(j['id']),
        idOcorrencia: j['idOcorrencia'] == null ? null : _int(j['idOcorrencia']),
        titulo: j['titulo'] as String? ?? '',
        mensagem: j['mensagem'] as String? ?? '',
        lida: j['lida'] == 'S',
        data: _data(j['dataEnvio']),
      );

  Notificacao marcadaComoLida() => Notificacao(
      id: id,
      idOcorrencia: idOcorrencia,
      titulo: titulo,
      mensagem: mensagem,
      lida: true,
      data: data);
}
