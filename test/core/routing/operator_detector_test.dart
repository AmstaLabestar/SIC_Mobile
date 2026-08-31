import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/core/routing/operator_detector.dart';

void main() {
  group('OperatorDetector — Burkina', () {
    test('Orange', () {
      expect(OperatorDetector.fromNumber('07123456'), 'ORANGE');
      expect(OperatorDetector.fromNumber('55123456'), 'ORANGE');
      expect(OperatorDetector.fromNumber('76123456'), 'ORANGE');
    });

    test('Moov', () {
      expect(OperatorDetector.fromNumber('01123456'), 'MOOV');
      expect(OperatorDetector.fromNumber('70123456'), 'MOOV');
      expect(OperatorDetector.fromNumber('51123456'), 'MOOV');
    });

    test('Telecel', () {
      expect(OperatorDetector.fromNumber('58123456'), 'TELECEL');
      expect(OperatorDetector.fromNumber('78123456'), 'TELECEL');
    });

    test('normalise indicatif +226/226 et ponctuation', () {
      expect(OperatorDetector.fromNumber('+226 07 12 34 56'), 'ORANGE');
      expect(OperatorDetector.fromNumber('226-70-12-34-56'), 'MOOV');
    });

    test('mauvaise longueur -> null', () {
      expect(OperatorDetector.fromNumber('0712345'), isNull); // 7 chiffres
      expect(OperatorDetector.fromNumber('071234567'), isNull); // 9 chiffres
    });

    test('prefixe inconnu -> null', () {
      expect(OperatorDetector.fromNumber('99123456'), isNull);
    });
  });
}
