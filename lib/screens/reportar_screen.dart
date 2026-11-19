import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/localizacao.dart';
import '../core/validators.dart';
import '../models/models.dart';
import '../state/app_scope.dart';
import '../widgets/estados.dart';
import '../widgets/formulario_auth.dart';

/// Registro de um problema urbano: foto, categoria, descrição e local.
/// Envia para `POST /ocorrencias`, que chama PRC_REGISTRAR_OCORRENCIA no
/// Oracle; o protocolo devolvido é mostrado ao final.
class ReportarScreen extends StatefulWidget {
  const ReportarScreen({super.key});

  @override
  State<ReportarScreen> createState() => _ReportarScreenState();
}

class _ReportarScreenState extends State<ReportarScreen> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _endereco = TextEditingController();

  late final Future<List<Categoria>> _categorias =
      AppScope.of(context).repo.categorias();

  int? _idCategoria;
  XFile? _foto;
  Uint8List? _fotoBytes;
  Coordenadas? _local;
  bool _buscandoLocal = false;
  String? _erroLocal;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pegarLocal());
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _endereco.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    try {
      final f = await ImagePicker()
          .pickImage(source: origem, maxWidth: 1600, imageQuality: 80);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      setState(() {
        _foto = f;
        _fotoBytes = bytes;
      });
    } catch (_) {
      _aviso('Não foi possível abrir a câmera ou a galeria.');
    }
  }

  Future<void> _pegarLocal() async {
    setState(() {
      _buscandoLocal = true;
      _erroLocal = null;
    });
    try {
      final c = await Localizacao.atual();
      if (mounted) setState(() => _local = c);
    } catch (e) {
      if (mounted) {
        setState(() => _erroLocal = e is LocalizacaoException
            ? e.mensagem
            : 'Não foi possível obter sua localização.');
      }
    } finally {
      if (mounted) setState(() => _buscandoLocal = false);
    }
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _enviar() async {
    final formOk = _form.currentState!.validate();
    if (_idCategoria == null) {
      _aviso('Escolha a categoria do problema.');
      return;
    }
    if (_local == null) {
      _aviso('Precisamos da localização do problema.');
      return;
    }
    if (!formOk || _enviando) return;

    setState(() {
      _enviando = true;
      _erro = null;
    });
    final scope = AppScope.of(context);
    try {
      final criada = await scope.repo.registrarOcorrencia(
        NovaOcorrencia(
          idCategoria: _idCategoria!,
          titulo: _titulo.text,
          descricao: _descricao.text,
          latitude: _local!.latitude,
          longitude: _local!.longitude,
          endereco: _endereco.text,
          caminhoFoto: _foto?.path,
        ),
        scope.auth.sessao!.idUsuario,
      );
      if (!mounted) return;
      await _mostrarProtocolo(criada.protocolo);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _mostrarProtocolo(String protocolo) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Ocorrência registrada!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Guarde seu protocolo para acompanhar:'),
              const SizedBox(height: 12),
              SelectableText(protocolo,
                  key: const Key('protocolo-gerado'),
                  style: Theme.of(c)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copiar'),
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: protocolo)),
            ),
            FilledButton(
                onPressed: () => Navigator.pop(c), child: const Text('OK')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar problema')),
      body: FutureBuilder<List<Categoria>>(
        future: _categorias,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const EstadoCarregando(mensagem: 'Carregando categorias…');
          }
          if (snap.hasError) {
            return EstadoMensagem.erro(snap.error!,
                onRetry: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ReportarScreen())));
          }
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _secao('Foto'),
                _CampoFoto(
                  bytes: _fotoBytes,
                  onCamera: () => _escolherFoto(ImageSource.camera),
                  onGaleria: () => _escolherFoto(ImageSource.gallery),
                  onRemover: () => setState(() {
                    _foto = null;
                    _fotoBytes = null;
                  }),
                ),
                const SizedBox(height: 24),
                _secao('Categoria'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in snap.data!)
                      ChoiceChip(
                        label: Text(c.nome),
                        tooltip: c.descricao,
                        selected: _idCategoria == c.id,
                        onSelected: (_) => setState(() => _idCategoria = c.id),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _secao('O que está acontecendo?'),
                TextFormField(
                  key: const Key('titulo'),
                  controller: _titulo,
                  validator: Validators.titulo,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ex.: Buraco em frente à escola'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('descricao'),
                  controller: _descricao,
                  validator: Validators.descricao,
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Descrição',
                      alignLabelWithHint: true,
                      hintText: 'Tamanho, há quanto tempo, se oferece risco…'),
                ),
                const SizedBox(height: 16),
                _secao('Onde?'),
                _CampoLocal(
                  local: _local,
                  buscando: _buscandoLocal,
                  erro: _erroLocal,
                  onAtualizar: _pegarLocal,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('endereco'),
                  controller: _endereco,
                  maxLength: 255,
                  decoration: const InputDecoration(
                      labelText: 'Endereço ou ponto de referência (opcional)',
                      prefixIcon: Icon(Icons.signpost_outlined)),
                ),
                const SizedBox(height: 16),
                if (_erro != null) FaixaErro(_erro!),
                BotaoEnviar(
                    rotulo: 'Enviar ocorrência',
                    enviando: _enviando,
                    onPressed: _enviar),
                SizedBox(height: tema.platform == TargetPlatform.iOS ? 32 : 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _secao(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto, style: Theme.of(context).textTheme.titleSmall),
      );
}

class _CampoFoto extends StatelessWidget {
  const _CampoFoto({
    required this.bytes,
    required this.onCamera,
    required this.onGaleria,
    required this.onRemover,
  });

  final Uint8List? bytes;
  final VoidCallback onCamera, onGaleria, onRemover;

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes!,
                height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filledTonal(
                tooltip: 'Remover foto',
                icon: const Icon(Icons.close),
                onPressed: onRemover),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Câmera'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(64))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
              onPressed: onGaleria,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Galeria'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(64))),
        ),
      ],
    );
  }
}

class _CampoLocal extends StatelessWidget {
  const _CampoLocal({
    required this.local,
    required this.buscando,
    required this.erro,
    required this.onAtualizar,
  });

  final Coordenadas? local;
  final bool buscando;
  final String? erro;
  final VoidCallback onAtualizar;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final (icone, texto, cor) = buscando
        ? (Icons.gps_not_fixed, 'Buscando sua localização…', cores.outline)
        : local != null
            ? (
                Icons.gps_fixed,
                'Localização capturada: ${local!.latitude.toStringAsFixed(5)}, '
                    '${local!.longitude.toStringAsFixed(5)}',
                Colors.green.shade700
              )
            : (Icons.gps_off, erro ?? 'Localização não capturada.', cores.error);

    return Card(
      child: ListTile(
        leading: buscando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icone, color: cor),
        title: Text(texto, style: TextStyle(color: cor)),
        trailing: buscando
            ? null
            : IconButton(
                tooltip: 'Atualizar localização',
                icon: const Icon(Icons.my_location),
                onPressed: onAtualizar),
      ),
    );
  }
}
