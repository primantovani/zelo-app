/// Formatação de datas em português, sem depender do pacote intl.
class Formato {
  Formato._();

  static String _dois(int n) => n.toString().padLeft(2, '0');

  /// 19/11/2026
  static String data(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

  /// 19/11/2026 às 14:05
  static String dataHora(DateTime d) =>
      '${data(d)} às ${_dois(d.hour)}:${_dois(d.minute)}';

  /// "agora", "há 5 min", "há 3 h", "há 2 dias" ou a data.
  static String relativo(DateTime d, {DateTime? agora}) {
    final dif = (agora ?? DateTime.now()).difference(d);
    if (dif.inMinutes < 1) return 'agora';
    if (dif.inHours < 1) return 'há ${dif.inMinutes} min';
    if (dif.inDays < 1) return 'há ${dif.inHours} h';
    if (dif.inDays == 1) return 'ontem';
    if (dif.inDays < 7) return 'há ${dif.inDays} dias';
    return data(d);
  }
}
