import 'package:flutter/material.dart';

import '../core/validators.dart';
import '../state/app_scope.dart';
import '../widgets/formulario_auth.dart';
import 'cadastro_screen.dart';

/// Tela de entrada: e-mail e senha → `POST /auth/login` → token JWT.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_enviando || !_form.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await AppScope.of(context).auth.login(_email.text, _senha.text);
      // O AuthController notifica o app, que troca para a Home sozinho.
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MolduraAuth(
      subtitulo: 'Cuide da sua cidade. Reporte, acompanhe, apoie.',
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('login-email'),
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
                key: const Key('login-senha'),
                controller: _senha,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Senha é obrigatória.' : null,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _entrar(),
              ),
              const SizedBox(height: 24),
              if (_erro != null) FaixaErro(_erro!),
              BotaoEnviar(
                  rotulo: 'Entrar', enviando: _enviando, onPressed: _entrar),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _enviando
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CadastroScreen())),
                child: const Text('Não tem conta? Cadastre-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
