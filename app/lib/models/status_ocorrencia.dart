import 'package:flutter/material.dart';

/// Status possíveis de uma ocorrência, iguais ao domínio do Oracle
/// (STATUS_ATUAL). O fluxo é validado no banco por FN_TRANSICAO_VALIDA.
enum StatusOcorrencia {
  aberta('ABERTA', 'Aberta', Icons.inbox_outlined, Color(0xFF1565C0)),
  emAnalise('EM_ANALISE', 'Em análise', Icons.search, Color(0xFF6A1B9A)),
  emAndamento(
      'EM_ANDAMENTO', 'Em andamento', Icons.construction, Color(0xFFE65100)),
  resolvida('RESOLVIDA', 'Resolvida', Icons.check_circle, Color(0xFF2E7D32)),
  rejeitada('REJEITADA', 'Rejeitada', Icons.block, Color(0xFFC62828));

  const StatusOcorrencia(this.codigo, this.rotulo, this.icone, this.cor);

  /// Valor gravado no banco e trafegado pela API.
  final String codigo;
  final String rotulo;
  final IconData icone;
  final Color cor;

  /// Converte o texto da API; valores desconhecidos viram [aberta].
  static StatusOcorrencia fromCodigo(String? codigo) => values.firstWhere(
        (s) => s.codigo == codigo?.toUpperCase(),
        orElse: () => aberta,
      );

  /// RESOLVIDA e REJEITADA são finais: não mudam mais e não recebem apoio.
  bool get encerrada => this == resolvida || this == rejeitada;

  /// Ordem das etapas no caminho feliz, usada na linha do tempo.
  static const caminho = [aberta, emAnalise, emAndamento, resolvida];
}
