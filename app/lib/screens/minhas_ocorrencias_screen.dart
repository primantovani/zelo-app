import 'package:flutter/material.dart';

import '../core/formato.dart';
import '../models/models.dart';
import '../state/app_scope.dart';
import '../widgets/estados.dart';
import '../widgets/status_chip.dart';
import 'detalhe_screen.dart';

/// Lista das ocorrências do usuário logado
/// (`GET /ocorrencias/usuario/{id}` + `GET /categorias`).
class MinhasOcorrenciasScreen extends StatelessWidget {
  const MinhasOcorrenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final idUsuario = scope.auth.sessao!.idUsuario;

    return CarregarDados<(List<Ocorrencia>, Map<int, String>)>(
      carregar: () async {
        final r = await Future.wait([
          scope.repo.ocorrenciasDoUsuario(idUsuario),
          scope.repo.categorias(),
        ]);
        final cats = {for (final c in r[1] as List<Categoria>) c.id: c.nome};
        return (r[0] as List<Ocorrencia>, cats);
      },
      estaVazio: (d) => d.$1.isEmpty,
      vazio: const EstadoMensagem(
        icone: Icons.location_city,
        titulo: 'Nenhuma ocorrência ainda',
        texto: 'Viu um buraco, poste apagado ou lixo na rua? '
            'Toque em Reportar e acompanhe pelo protocolo.',
      ),
      construir: (context, dados, recarregar) {
        final (lista, categorias) = dados;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: lista.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) => CartaoOcorrencia(
            ocorrencia: lista[i],
            categoria: categorias[lista[i].idCategoria],
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => DetalheScreen(idOcorrencia: lista[i].id)));
              recarregar();
            },
          ),
        );
      },
    );
  }
}

/// Cartão resumido de uma ocorrência.
class CartaoOcorrencia extends StatelessWidget {
  const CartaoOcorrencia(
      {super.key, required this.ocorrencia, this.categoria, this.onTap});

  final Ocorrencia ocorrencia;
  final String? categoria;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final o = ocorrencia;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(o.protocolo,
                        style: tema.textTheme.labelMedium?.copyWith(
                            color: tema.colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                  StatusChip(o.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(o.titulo, style: tema.textTheme.titleMedium),
              if (categoria != null)
                Text(categoria!, style: tema.textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.place_outlined,
                      size: 16, color: tema.colorScheme.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(o.endereco ?? 'Local marcado no mapa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.bodySmall),
                  ),
                  if (o.dataAbertura != null)
                    Text(Formato.relativo(o.dataAbertura!),
                        style: tema.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
