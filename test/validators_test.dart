import 'package:flutter_test/flutter_test.dart';
import 'package:zelo/core/validators.dart';

void main() {
  group('Validators', () {
    test('e-mail', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('maria'), 'E-mail inválido.');
      expect(Validators.email('maria@email.com'), isNull);
    });

    test('senha exige 8 caracteres, como a API', () {
      expect(Validators.senha('1234567'), isNotNull);
      expect(Validators.senha('12345678'), isNull);
    });

    test('limites de tamanho do Oracle', () {
      expect(Validators.titulo('a' * 121), isNotNull);
      expect(Validators.titulo('Buraco'), isNull);
      expect(Validators.descricao('a' * 1001), isNotNull);
      expect(Validators.nome('a' * 101), isNotNull);
    });

    test('protocolo no formato ZEL-AAAA-NNNN', () {
      expect(Validators.protocolo('ZEL-2026-0016'), isNull);
      expect(Validators.protocolo('zel-2026-0016'), isNull);
      expect(Validators.protocolo('ZEL-26-1'), isNotNull);
      expect(Validators.protocolo(''), isNotNull);
    });

    test('coordenadas', () {
      expect(Validators.latitudeValida(-23.5), isTrue);
      expect(Validators.latitudeValida(91), isFalse);
      expect(Validators.longitudeValida(-181), isFalse);
    });
  });
}
