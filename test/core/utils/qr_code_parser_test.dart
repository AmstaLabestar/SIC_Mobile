import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/core/utils/qr_code_parser.dart';

void main() {
  group('QrCodeParser', () {
    test('extrait un numéro brut à 8 chiffres', () {
      final res = QrCodeParser.parse('70123456');
      expect(res.phoneNumber, equals('70123456'));
      expect(res.operatorCode, equals('MOOV'));
    });

    test('extrait un numéro avec indicatif international +226', () {
      final res = QrCodeParser.parse('+22677123456');
      expect(res.phoneNumber, equals('77123456'));
      expect(res.operatorCode, equals('OM'));
    });

    test('extrait les coordonnées du texte partagé par l\'app', () {
      final res = QrCodeParser.parse(
        'Voici mes coordonnées SIC pour recevoir un transfert :\nNom : Jean\nTéléphone : 75123456',
      );
      expect(res.phoneNumber, equals('75123456'));
      expect(res.operatorCode, equals('TELECEL'));
    });

    test('détecte l\'opérateur explicitement mentionné Moov', () {
      final res = QrCodeParser.parse('Moov Money: 70001122');
      expect(res.phoneNumber, equals('70001122'));
      expect(res.operatorCode, equals('MOOV'));
    });
  });
}
