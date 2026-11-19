import 'package:flutter/material.dart';

import '../core/formato.dart';
import '../models/models.dart';

/// Linha do tempo do protocolo: etapas do fluxo (Aberta → Em análise →
/// Em andamento → Resolvida) com data de cada passagem, a partir do
/// histórico gravado no Oracle. Rejeitada aparece como etapa final.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.atual, required this.historico});

  final StatusOcorrencia atual;
  final List<HistoricoStatus> historico;

  @override
  Widget build(BuildContext context) {
    final etapas = atual == StatusOcorrencia.rejeitada
        ? [
            ...StatusOcorrencia.caminho.where(
                (s) => historico.any((h) => h.statusNovo == s)),
            StatusOcorrencia.rejeitada,
          ]
        : StatusOcorrencia.caminho;

    return Column(
      children: [
        for (var i = 0; i < etapas.length; i++)
          _Etapa(
            status: etapas[i],
            registro: _ultimo(etapas[i]),
            atual: etapas[i] == atual,
            ultima: i == etapas.length - 1,
          ),
      ],
    );
  }

  HistoricoStatus? _ultimo(StatusOcorrencia s) {
    final h = historico.where((h) => h.statusNovo == s);
    return h.isEmpty ? null : h.last;
  }
}

class _Etapa extends StatelessWidget {
  const _Etapa({
    required this.status,
    required this.registro,
    required this.atual,
    required this.ultima,
  });

  final StatusOcorrencia status;
  final HistoricoStatus? registro;
  final bool atual;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final feita = registro != null;
    final cor = feita ? status.cor : tema.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: feita ? cor : tema.colorScheme.surfaceContainerHighest,
                  child: Icon(status.icone,
                      size: 16, color: feita ? Colors.white : cor),
                ),
                if (!ultima)
                  Expanded(child: Container(width: 2, color: cor)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.rotulo,
                      style: tema.textTheme.titleSmall?.copyWith(
                        fontWeight: atual ? FontWeight.bold : FontWeight.w500,
                        color: feita ? null : tema.colorScheme.outline,
                      )),
                  if (registro?.data != null)
                    Text(Formato.dataHora(registro!.data!),
                        style: tema.textTheme.bodySmall),
                  if (registro?.observacao?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(registro!.observacao!,
                          style: tema.textTheme.bodyMedium),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
