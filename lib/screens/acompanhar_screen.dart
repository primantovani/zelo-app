import 'package:flutter/material.dart';

import '../core/validators.dart';
import '../state/app_scope.dart';
import '../widgets/formulario_auth.dart';
import 'detalhe_screen.dart';

/// Busca qualquer ocorrência pelo protocolo
/// (`GET /ocorrencias/protocolo/{protocolo}`), inclusive de outra pessoa,
/// para o cidadão acompanhar ou apoiar.
class AcompanharScreen extends StatefulWidget {
  const AcompanharScreen({super.key});

  @override
  State<AcompanharScreen> createState() => _AcompanharScreenState();
}

class _AcompanharScreenState extends State<AcompanharScreen> {
  final _form = GlobalKey<FormState>();
  final _protocolo = TextEditingController();
  bool _buscando = false;
  String? _erro;

  @override
  void dispose() {
    _protocolo.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    if (_buscando || !_form.currentState!.validate()) return;
    setState(() {
      _buscando = true;
      _erro = null;
    });
    try {
      final o = await AppScope.of(context).repo.porProtocolo(_protocolo.text);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DetalheScreen(idOcorrencia: o.id)));
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.confirmation_number_outlined,
                size: 56, color: tema.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Digite o protocolo recebido ao reportar.',
                textAlign: TextAlign.center, style: tema.textTheme.bodyLarge),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('protocolo'),
              controller: _protocolo,
              validator: Validators.protocolo,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (_) => _buscar(),
              decoration: const InputDecoration(
                labelText: 'Protocolo',
                hintText: 'ZEL-2026-0016',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 16),
            if (_erro != null) FaixaErro(_erro!),
            BotaoEnviar(
                rotulo: 'Acompanhar', enviando: _buscando, onPressed: _buscar),
          ],
        ),
      ),
    );
  }
}
