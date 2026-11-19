import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import 'acompanhar_screen.dart';
import 'minhas_ocorrencias_screen.dart';
import 'notificacoes_screen.dart';
import 'reportar_screen.dart';

/// Tela principal depois do login, com navegação inferior.
///
/// Para adicionar o mapa (parte da Sophie), inclua uma entrada em
/// [_abas] apontando para a tela do mapa.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _aba = 0;

  /// Muda a cada novo registro para forçar a lista a recarregar.
  int _versaoLista = 0;

  Future<void> _reportar() async {
    final criou = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const ReportarScreen()));
    if (criou == true) setState(() => _versaoLista++);
  }

  Future<void> _sair() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sair da conta?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Sair')),
        ],
      ),
    );
    if (confirma == true && mounted) await AppScope.of(context).auth.sair();
  }

  @override
  Widget build(BuildContext context) {
    final sessao = AppScope.of(context).auth.sessao!;
    final abas = [
      (
        titulo: 'Olá, ${sessao.primeiroNome}',
        icone: Icons.list_alt_outlined,
        iconeSel: Icons.list_alt,
        rotulo: 'Minhas',
        tela: MinhasOcorrenciasScreen(key: ValueKey(_versaoLista)),
      ),
      (
        titulo: 'Acompanhar protocolo',
        icone: Icons.manage_search_outlined,
        iconeSel: Icons.manage_search,
        rotulo: 'Protocolo',
        tela: const AcompanharScreen(),
      ),
      (
        titulo: 'Avisos',
        icone: Icons.notifications_outlined,
        iconeSel: Icons.notifications,
        rotulo: 'Avisos',
        tela: NotificacoesScreen(key: ValueKey('n$_versaoLista')),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(abas[_aba].titulo),
        actions: [
          IconButton(
              tooltip: 'Sair',
              icon: const Icon(Icons.logout),
              onPressed: _sair),
        ],
      ),
      body: IndexedStack(
          index: _aba, children: [for (final a in abas) a.tela]),
      floatingActionButton: _aba == 0
          ? FloatingActionButton.extended(
              onPressed: _reportar,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Reportar'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        // Recarrega as listas ao trocar de aba: o status pode ter mudado
        // no servidor (equipe de zeladoria) desde o último carregamento.
        onDestinationSelected: (i) => setState(() {
          _aba = i;
          _versaoLista++;
        }),
        destinations: [
          for (final a in abas)
            NavigationDestination(
                icon: Icon(a.icone),
                selectedIcon: Icon(a.iconeSel),
                label: a.rotulo),
        ],
      ),
    );
  }
}
