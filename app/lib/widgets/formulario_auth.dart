import 'package:flutter/material.dart';

import '../app.dart';
import '../core/config.dart';

/// Moldura comum das telas de login e cadastro: logo, título e
/// conteúdo centralizado com largura máxima (fica bom no celular e na web).
class MolduraAuth extends StatelessWidget {
  const MolduraAuth({super.key, required this.subtitulo, required this.child});

  final String subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.location_city, size: 56, color: corZelo),
                  const SizedBox(height: 8),
                  Text('Zelo',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold, color: corZelo)),
                  Text(subtitulo,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyLarge?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant)),
                  if (AppConfig.modoDemonstracao) ...[
                    const SizedBox(height: 12),
                    const _AvisoDemonstracao(),
                  ],
                  const SizedBox(height: 32),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvisoDemonstracao extends StatelessWidget {
  const _AvisoDemonstracao();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tema.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Modo demonstração: dados locais, sem API. '
        'Entre com ana@zelo.dev / senha1234 ou crie uma conta.',
        style: TextStyle(color: tema.colorScheme.onTertiaryContainer),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Campo de senha com botão de mostrar/ocultar.
class CampoSenha extends StatefulWidget {
  const CampoSenha({
    super.key,
    required this.controller,
    this.validator,
    this.rotulo = 'Senha',
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String rotulo;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  State<CampoSenha> createState() => _CampoSenhaState();
}

class _CampoSenhaState extends State<CampoSenha> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        obscureText: _oculta,
        validator: widget.validator,
        onFieldSubmitted: widget.onSubmitted,
        textInputAction: widget.textInputAction,
        autofillHints: const [AutofillHints.password],
        decoration: InputDecoration(
          labelText: widget.rotulo,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            tooltip: _oculta ? 'Mostrar senha' : 'Ocultar senha',
            icon: Icon(_oculta ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _oculta = !_oculta),
          ),
        ),
      );
}

/// Faixa de erro exibida acima do botão de envio.
class FaixaErro extends StatelessWidget {
  const FaixaErro(this.mensagem, {super.key});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: cores.errorContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cores.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
              child: Text(mensagem,
                  style: TextStyle(color: cores.onErrorContainer))),
        ],
      ),
    );
  }
}

/// Botão principal que vira um indicador de progresso enquanto envia.
class BotaoEnviar extends StatelessWidget {
  const BotaoEnviar(
      {super.key, required this.rotulo, required this.enviando, this.onPressed});

  final String rotulo;
  final bool enviando;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: enviando ? null : onPressed,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        child: enviando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5))
            : Text(rotulo),
      );
}
