import 'package:flutter/material.dart';

import 'data/zelo_repository.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'state/app_scope.dart';
import 'state/auth_controller.dart';

/// Cor da marca Zelo (verde-azulado: cuidado com a cidade).
const corZelo = Color(0xFF00796B);

/// Raiz do app: tema, injeção de dependências e decisão login × home.
class ZeloApp extends StatelessWidget {
  const ZeloApp({super.key, required this.repo, required this.auth});

  final ZeloRepository repo;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repo: repo,
      auth: auth,
      child: MaterialApp(
        title: 'Zelo',
        debugShowCheckedModeBanner: false,
        theme: _tema(Brightness.light),
        darkTheme: _tema(Brightness.dark),
        home: ListenableBuilder(
          listenable: auth,
          builder: (context, _) {
            if (auth.carregando) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            return auth.logado ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }

  ThemeData _tema(Brightness brilho) {
    final cores = ColorScheme.fromSeed(seedColor: corZelo, brightness: brilho);
    return ThemeData(
      colorScheme: cores,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}
