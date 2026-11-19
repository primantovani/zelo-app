import 'package:flutter/widgets.dart';

import '../data/zelo_repository.dart';
import 'auth_controller.dart';

/// Disponibiliza o repositório e a sessão para toda a árvore de widgets,
/// sem pacote externo de injeção de dependência.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repo,
    required this.auth,
    required super.child,
  });

  final ZeloRepository repo;
  final AuthController auth;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado na árvore.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      repo != oldWidget.repo || auth != oldWidget.auth;
}
