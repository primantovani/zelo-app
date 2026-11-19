import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/config.dart';
import 'data/api_zelo_repository.dart';
import 'data/demo_zelo_repository.dart';
import 'data/zelo_repository.dart';
import 'state/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final ZeloRepository repo = AppConfig.modoDemonstracao
      ? DemoZeloRepository()
      : ApiZeloRepository(ApiClient(baseUrl: AppConfig.apiUrl));
  final auth = AuthController(repo)..restaurar();
  runApp(ZeloApp(repo: repo, auth: auth));
}
