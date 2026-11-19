import 'package:flutter/material.dart';

import '../core/validators.dart';
import '../state/app_scope.dart';
import '../widgets/formulario_auth.dart';

/// Cadastro do cidadão: `POST /auth/registrar`. A API devolve o token,
/// então o usuário já entra logado.
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    for (final c in [_nome, _email, _senha, _confirma]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_enviando || !_form.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await AppScope.of(context)
          .auth
          .registrar(_nome.text, _email.text, _senha.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MolduraAuth(
      subtitulo: 'Crie sua conta para reportar problemas na cidade.',
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('cadastro-nome'),
                controller: _nome,
                validator: Validators.nome,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('cadastro-email'),
                controller: _email,
                validator: Validators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                    labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
              ),
              const SizedBox(height: 16),
              CampoSenha(
                key: const Key('cadastro-senha'),
                controller: _senha,
                validator: Validators.senha,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              CampoSenha(
                key: const Key('cadastro-confirma'),
                controller: _confirma,
                rotulo: 'Confirme a senha',
                textInputAction: TextInputAction.done,
                validator: (v) =>
                    v != _senha.text ? 'As senhas não conferem.' : null,
                onSubmitted: (_) => _cadastrar(),
              ),
              const SizedBox(height: 24),
              if (_erro != null) FaixaErro(_erro!),
              BotaoEnviar(
                  rotulo: 'Criar conta',
                  enviando: _enviando,
                  onPressed: _cadastrar),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _enviando ? null : () => Navigator.of(context).pop(),
                child: const Text('Já tenho conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
