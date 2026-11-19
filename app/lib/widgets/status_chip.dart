import 'package:flutter/material.dart';

import '../models/models.dart';

/// Selo colorido com o status da ocorrência.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final StatusOcorrencia status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icone, size: 14, color: status.cor),
          const SizedBox(width: 4),
          Text(status.rotulo,
              style: TextStyle(
                  color: status.cor, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
