import 'package:flutter/material.dart';

import '../core/formato.dart';
import '../models/models.dart';
import '../state/app_scope.dart';
import '../widgets/estados.dart';
import 'detalhe_screen.dart';

/// Avisos do Oracle sobre as ocorrências do usuário
/// (`GET /usuarios/{id}/notificacoes`). Tocar marca como lida
/// (`PATCH /notificacoes/{id}/lida`) e abre o protocolo.
class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return CarregarDados<List<Notificacao>>(
      carregar: () => scope.repo.notificacoes(scope.auth.sessao!.idUsuario),
      estaVazio: (l) => l.isEmpty,
      vazio: const EstadoMensagem(
        icone: Icons.notifications_none,
        titulo: 'Nenhum aviso',
        texto: 'Quando o status de uma ocorrência sua mudar, você vê aqui.',
      ),
      construir: (context, lista, recarregar) => ListView.separated(
        itemCount: lista.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final n = lista[i];
          final tema = Theme.of(context);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: n.lida
                  ? tema.colorScheme.surfaceContainerHighest
                  : tema.colorScheme.primaryContainer,
              child: Icon(
                  n.lida ? Icons.drafts_outlined : Icons.mark_email_unread,
                  color: n.lida ? tema.colorScheme.outline : null),
            ),
            title: Text(n.titulo,
                style: TextStyle(
                    fontWeight: n.lida ? FontWeight.normal : FontWeight.bold)),
            subtitle: Text(n.mensagem),
            trailing: n.data == null
                ? null
                : Text(Formato.relativo(n.data!),
                    style: tema.textTheme.bodySmall),
            onTap: () async {
              if (!n.lida) {
                try {
                  await scope.repo.marcarComoLida(n.id);
                } catch (_) {
                  // Não impede abrir o protocolo.
                }
              }
              if (n.idOcorrencia != null && context.mounted) {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        DetalheScreen(idOcorrencia: n.idOcorrencia!)));
              }
              recarregar();
            },
          );
        },
      ),
    );
  }
}
