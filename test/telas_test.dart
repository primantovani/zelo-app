import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelo/app.dart';
import 'package:zelo/data/demo_zelo_repository.dart';
import 'package:zelo/state/auth_controller.dart';

Future<void> _abrirApp(WidgetTester tester) async {
  // Tela de celular (1080×2400 a 3x), para o formulário caber inteiro.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final repo = DemoZeloRepository(atraso: Duration.zero);
  final auth = AuthController(repo);
  await auth.restaurar();
  await tester.pumpWidget(ZeloApp(repo: repo, auth: auth));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('login valida campos antes de enviar', (tester) async {
    await _abrirApp(tester);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('E-mail é obrigatório.'), findsOneWidget);
    expect(find.text('Senha é obrigatória.'), findsOneWidget);
  });

  testWidgets('login com senha errada mostra o erro', (tester) async {
    await _abrirApp(tester);
    await tester.enterText(find.byKey(const Key('login-email')), 'ana@zelo.dev');
    await tester.enterText(find.byKey(const Key('login-senha')), 'errada123');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
  });

  testWidgets('login correto abre a lista com as ocorrências', (tester) async {
    await _abrirApp(tester);
    await tester.enterText(find.byKey(const Key('login-email')), 'ana@zelo.dev');
    await tester.enterText(find.byKey(const Key('login-senha')), 'senha1234');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Ana'), findsOneWidget);
    expect(find.text('Buraco em frente à escola'), findsOneWidget);
    expect(find.text('Em análise'), findsOneWidget);
  });

  testWidgets('cadastro com senhas diferentes não envia', (tester) async {
    await _abrirApp(tester);
    await tester.tap(find.text('Não tem conta? Cadastre-se'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cadastro-nome')), 'Maria');
    await tester.enterText(find.byKey(const Key('cadastro-email')), 'm@e.com');
    await tester.enterText(find.byKey(const Key('cadastro-senha')), '12345678');
    await tester.enterText(
        find.byKey(const Key('cadastro-confirma')), '87654321');
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('As senhas não conferem.'), findsOneWidget);
  });

  testWidgets('cadastro novo entra com lista vazia', (tester) async {
    await _abrirApp(tester);
    await tester.tap(find.text('Não tem conta? Cadastre-se'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('cadastro-nome')), 'Maria Silva');
    await tester.enterText(find.byKey(const Key('cadastro-email')), 'm@e.com');
    await tester.enterText(find.byKey(const Key('cadastro-senha')), '12345678');
    await tester.enterText(
        find.byKey(const Key('cadastro-confirma')), '12345678');
    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Maria'), findsOneWidget);
    expect(find.text('Nenhuma ocorrência ainda'), findsOneWidget);
  });
}
