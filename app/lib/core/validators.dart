/// Validações de formulário, iguais às regras da API (Bean Validation)
/// e do banco Oracle, para o usuário saber do erro antes de enviar.
class Validators {
  Validators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _protocolo = RegExp(r'^ZEL-\d{4}-\d{4,}$');

  static String? obrigatorio(String? v, {String campo = 'Campo'}) =>
      (v == null || v.trim().isEmpty) ? '$campo é obrigatório.' : null;

  static String? nome(String? v) {
    final erro = obrigatorio(v, campo: 'Nome');
    if (erro != null) return erro;
    if (v!.trim().length > 100) return 'Use no máximo 100 caracteres.';
    return null;
  }

  static String? email(String? v) {
    final erro = obrigatorio(v, campo: 'E-mail');
    if (erro != null) return erro;
    return _email.hasMatch(v!.trim()) ? null : 'E-mail inválido.';
  }

  /// A API exige no mínimo 8 caracteres (`@Size(min=8)`).
  static String? senha(String? v) {
    if (v == null || v.isEmpty) return 'Senha é obrigatória.';
    return v.length < 8 ? 'A senha precisa de pelo menos 8 caracteres.' : null;
  }

  static String? titulo(String? v) {
    final erro = obrigatorio(v, campo: 'Título');
    if (erro != null) return erro;
    return v!.trim().length > 120 ? 'Use no máximo 120 caracteres.' : null;
  }

  static String? descricao(String? v) {
    final erro = obrigatorio(v, campo: 'Descrição');
    if (erro != null) return erro;
    return v!.trim().length > 1000 ? 'Use no máximo 1000 caracteres.' : null;
  }

  static bool latitudeValida(double v) => v >= -90 && v <= 90;
  static bool longitudeValida(double v) => v >= -180 && v <= 180;

  /// Formato gerado pelo Oracle (FN_GERAR_PROTOCOLO): ZEL-AAAA-NNNN.
  static String? protocolo(String? v) {
    final erro = obrigatorio(v, campo: 'Protocolo');
    if (erro != null) return erro;
    return _protocolo.hasMatch(v!.trim().toUpperCase())
        ? null
        : 'Use o formato ZEL-AAAA-NNNN.';
  }
}
