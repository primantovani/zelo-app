import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formato.dart';
import '../models/models.dart';
import '../state/app_scope.dart';
import '../widgets/estados.dart';
import '../widgets/status_chip.dart';
import '../widgets/status_timeline.dart';

/// Tudo de uma ocorrência carregado de uma vez.
typedef _Detalhe = ({
  Ocorrencia ocorrencia,
  String? categoria,
  List<HistoricoStatus> historico,
  List<Apoio> apoios,
  List<Foto> fotos,
});

/// Acompanhamento do protocolo: status atual, linha do tempo
/// (`/historico`), fotos e apoios da comunidade (`/apoios`).
class DetalheScreen extends StatelessWidget {
  const DetalheScreen({super.key, required this.idOcorrencia});

  final int idOcorrencia;

  Future<_Detalhe> _carregar(AppScope scope) async {
    final repo = scope.repo;
    final r = await Future.wait([
      repo.ocorrencia(idOcorrencia),
      repo.categorias(),
      repo.historico(idOcorrencia),
      repo.apoios(idOcorrencia),
      repo.fotos(idOcorrencia),
    ]);
    final o = r[0] as Ocorrencia;
    final cats = r[1] as List<Categoria>;
    return (
      ocorrencia: o,
      categoria: cats.where((c) => c.id == o.idCategoria).firstOrNull?.nome,
      historico: r[2] as List<HistoricoStatus>,
      apoios: r[3] as List<Apoio>,
      fotos: r[4] as List<Foto>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Protocolo')),
      body: CarregarDados<_Detalhe>(
        carregar: () => _carregar(scope),
        construir: (context, d, recarregar) =>
            _Conteudo(dados: d, onAtualizar: recarregar),
      ),
    );
  }
}

class _Conteudo extends StatefulWidget {
  const _Conteudo({required this.dados, required this.onAtualizar});

  final _Detalhe dados;
  final Future<void> Function() onAtualizar;

  @override
  State<_Conteudo> createState() => _ConteudoState();
}

class _ConteudoState extends State<_Conteudo> {
  bool _apoiando = false;

  Future<void> _apoiar(String tipo) async {
    final scope = AppScope.of(context);
    setState(() => _apoiando = true);
    try {
      await scope.repo.apoiar(
          widget.dados.ocorrencia.id, scope.auth.sessao!.idUsuario,
          tipo: tipo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tipo == 'CONFIRMACAO'
              ? 'Obrigado por confirmar o problema!'
              : 'Obrigado pelo apoio!')));
      await widget.onAtualizar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _apoiando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final d = widget.dados;
    final o = d.ocorrencia;
    final idUsuario = AppScope.of(context).auth.sessao!.idUsuario;
    final souAutor = o.idUsuario == idUsuario;
    final jaApoiei = d.apoios.any((a) => a.idUsuario == idUsuario);
    final confirmacoes = d.apoios.where((a) => a.tipo == 'CONFIRMACAO').length;
    final fotosVisiveis = d.fotos
        .where((f) => f.url.startsWith('http') || f.url.startsWith('blob:'))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: o.protocolo));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Protocolo copiado.')));
                },
                child: Row(children: [
                  Text(o.protocolo,
                      style: tema.textTheme.titleMedium?.copyWith(
                          color: tema.colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Icon(Icons.copy, size: 16, color: tema.colorScheme.primary),
                ]),
              ),
            ),
            StatusChip(o.status),
          ],
        ),
        const SizedBox(height: 12),
        Text(o.titulo, style: tema.textTheme.headlineSmall),
        if (d.categoria != null)
          Text(d.categoria!,
              style: tema.textTheme.bodyMedium
                  ?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        Text(o.descricao, style: tema.textTheme.bodyLarge),
        const SizedBox(height: 12),
        _Linha(Icons.place_outlined,
            o.endereco ?? '${o.latitude?.toStringAsFixed(5)}, ${o.longitude?.toStringAsFixed(5)}'),
        if (o.dataAbertura != null)
          _Linha(Icons.event_outlined,
              'Aberta em ${Formato.dataHora(o.dataAbertura!)}'),
        if (fotosVisiveis.isNotEmpty) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(fotosVisiveis.first.url,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
        ] else if (d.fotos.isNotEmpty)
          _Linha(Icons.photo_outlined, '${d.fotos.length} foto(s) anexada(s)'),
        const Divider(height: 40),
        Text('Andamento', style: tema.textTheme.titleMedium),
        const SizedBox(height: 16),
        StatusTimeline(atual: o.status, historico: d.historico),
        const Divider(height: 24),
        Text('Comunidade', style: tema.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          d.apoios.isEmpty
              ? 'Ninguém apoiou ainda.'
              : '${d.apoios.length} apoio(s), $confirmacoes confirmação(ões) '
                  'de quem também viu o problema.',
        ),
        const SizedBox(height: 12),
        if (souAutor)
          const _Linha(Icons.info_outline,
              'Esta ocorrência é sua. Compartilhe o protocolo para vizinhos apoiarem.')
        else if (o.status.encerrada)
          const _Linha(Icons.lock_outline,
              'Ocorrência encerrada: não recebe novos apoios.')
        else if (jaApoiei)
          const _Linha(Icons.favorite, 'Você já apoiou esta ocorrência.')
        else
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _apoiando ? null : () => _apoiar('APOIO'),
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Apoiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _apoiando ? null : () => _apoiar('CONFIRMACAO'),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Eu também vi'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.icone, this.texto);

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: tema.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: tema.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
