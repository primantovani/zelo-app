import 'package:geolocator/geolocator.dart';

/// Coordenadas obtidas do GPS.
typedef Coordenadas = ({double latitude, double longitude});

/// Obtém a posição atual do aparelho, pedindo permissão quando preciso.
/// Lança [LocalizacaoException] com mensagem pronta para a tela.
class Localizacao {
  Localizacao._();

  static Future<Coordenadas> atual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw LocalizacaoException('Ative a localização do aparelho.');
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      throw LocalizacaoException(
          'Sem permissão de localização. Libere nas configurações.');
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
    );
    return (latitude: p.latitude, longitude: p.longitude);
  }
}

class LocalizacaoException implements Exception {
  LocalizacaoException(this.mensagem);
  final String mensagem;
  @override
  String toString() => mensagem;
}
