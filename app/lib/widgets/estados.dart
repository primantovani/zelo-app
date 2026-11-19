import 'package:flutter/material.dart';

/// Indicador de carregamento centralizado, com texto opcional.
class EstadoCarregando extends StatelessWidget {
  const EstadoCarregando({super.key, this.mensagem});

  final String? mensagem;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (mensagem != null) ...[
              const SizedBox(height: 16),
              Text(mensagem!),
            ],
          ],
        ),
      );
}

/// Mensagem centralizada com ícone, para listas vazias e erros.
class EstadoMensagem extends StatelessWidget {
  const EstadoMensagem({
    super.key,
    required this.icone,
    required this.titulo,
    this.texto,
    this.acao,
    this.rotuloAcao,
  });

  /// Erro com botão "Tentar de novo".
  factory EstadoMensagem.erro(Object erro, {required VoidCallback onRetry}) =>
      EstadoMensagem(
        icone: Icons.cloud_off,
        titulo: 'Algo deu errado',
        texto: '$erro',
        acao: onRetry,
        rotuloAcao: 'Tentar de novo',
      );

  final IconData icone;
  final String titulo;
  final String? texto;
  final VoidCallback? acao;
  final String? rotuloAcao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: tema.colorScheme.outline),
            const SizedBox(height: 16),
            Text(titulo,
                style: tema.textTheme.titleMedium, textAlign: TextAlign.center),
            if (texto != null) ...[
              const SizedBox(height: 8),
              Text(texto!,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium
                      ?.copyWith(color: tema.colorScheme.onSurfaceVariant)),
            ],
            if (acao != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(onPressed: acao, child: Text(rotuloAcao!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Carrega um `Future` e mostra carregando, erro (com nova tentativa)
/// ou o conteúdo. Puxar para baixo recarrega.
class CarregarDados<T> extends StatefulWidget {
  const CarregarDados({
    super.key,
    required this.carregar,
    required this.construir,
    this.vazio,
    this.estaVazio,
  });

  final Future<T> Function() carregar;
  final Widget Function(BuildContext context, T dados, Future<void> Function() recarregar)
      construir;

  /// Widget exibido quando [estaVazio] retorna `true`.
  final Widget? vazio;
  final bool Function(T dados)? estaVazio;

  @override
  State<CarregarDados<T>> createState() => _CarregarDadosState<T>();
}

class _CarregarDadosState<T> extends State<CarregarDados<T>> {
  late Future<T> _futuro = widget.carregar();

  Future<void> _recarregar() async {
    final novo = widget.carregar();
    setState(() => _futuro = novo);
    try {
      await novo;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _futuro,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const EstadoCarregando();
        }
        if (snap.hasError) {
          return EstadoMensagem.erro(snap.error!, onRetry: _recarregar);
        }
        final dados = snap.data as T;
        final conteudo = (widget.estaVazio?.call(dados) ?? false)
            ? ListView(children: [
                const SizedBox(height: 80),
                widget.vazio ?? const SizedBox()
              ])
            : widget.construir(context, dados, _recarregar);
        return RefreshIndicator(onRefresh: _recarregar, child: conteudo);
      },
    );
  }
}
