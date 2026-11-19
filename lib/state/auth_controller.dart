import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/zelo_repository.dart';
import '../models/models.dart';

/// Guarda a sessão do usuário e avisa a interface quando ela muda.
///
/// A sessão (token JWT + dados básicos) fica salva no aparelho, então o
/// usuário continua logado ao reabrir o app até o token expirar (24 h).
class AuthController extends ChangeNotifier {
  AuthController(this._repo);

  static const _chave = 'zelo.sessao';

  final ZeloRepository _repo;
  Sessao? _sessao;
  bool _carregando = true;

  Sessao? get sessao => _sessao;
  bool get logado => _sessao != null;

  /// `true` enquanto a sessão salva ainda está sendo lida.
  bool get carregando => _carregando;

  /// Lê a sessão salva, se houver. Chamado uma vez na abertura do app.
  Future<void> restaurar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvo = prefs.getString(_chave);
      if (salvo != null) {
        _definir(Sessao.fromJson(jsonDecode(salvo) as Map<String, dynamic>));
      }
    } catch (_) {
      // Sessão corrompida: segue deslogado.
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String senha) async =>
      _salvar(await _repo.login(email: email, senha: senha));

  Future<void> registrar(String nome, String email, String senha) async =>
      _salvar(await _repo.registrar(nome: nome, email: email, senha: senha));

  Future<void> sair() async {
    _definir(null);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }

  Future<void> _salvar(Sessao sessao) async {
    _definir(sessao);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, jsonEncode(sessao.toJson()));
  }

  void _definir(Sessao? sessao) {
    _sessao = sessao;
    _repo.token = sessao?.token;
  }
}
