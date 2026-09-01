import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/core/ussd/ussd_codes.dart';

void main() {
  group('UssdShortcuts — Burkina', () {
    test('Orange recharge soi-meme insere le montant', () {
      expect(
        UssdShortcuts.build('ORANGE', UssdOperation.rechargeSelf, amount: 500),
        '*144*1*1*500#',
      );
    });

    test('Orange transfert insere le destinataire (sans montant)', () {
      expect(
        UssdShortcuts.build('ORANGE', UssdOperation.transfer,
            recipient: '70000000'),
        '*144*2*1*70000000#',
      );
    });

    test('Orange cash-out (retrait) insere code marchand + montant', () {
      expect(
        UssdShortcuts.build('ORANGE', UssdOperation.cashout,
            merchant: '8170275', amount: 5000),
        '*144*3*8170275*5000#',
      );
    });

    test('Moov cash-out non defini -> null (retombe sur agregateur/manuel)', () {
      expect(UssdShortcuts.supports('MOOV', UssdOperation.cashout), isFalse);
      expect(
        UssdShortcuts.build('MOOV', UssdOperation.cashout,
            merchant: '60000000', amount: 5000),
        isNull,
      );
    });

    test('Moov utilise le prefixe *555*', () {
      expect(
        UssdShortcuts.build('MOOV', UssdOperation.rechargeSelf, amount: 1000),
        '*555*1*1*1000#',
      );
      expect(
        UssdShortcuts.build('MOOV', UssdOperation.transfer, recipient: '60000000'),
        '*555*2*1*60000000#',
      );
    });

    test('operateur non couvert -> null', () {
      expect(
        UssdShortcuts.build('TELECEL', UssdOperation.transfer, recipient: 'x'),
        isNull,
      );
      expect(UssdShortcuts.supports('MTN', UssdOperation.rechargeSelf), isFalse);
    });

    test('insensible a la casse de l operateur + trim du destinataire', () {
      expect(
        UssdShortcuts.build('orange', UssdOperation.rechargeSelf, amount: 100),
        '*144*1*1*100#',
      );
      expect(
        UssdShortcuts.build('ORANGE', UssdOperation.transfer,
            recipient: '  70000000 '),
        '*144*2*1*70000000#',
      );
    });

    test('supports() vrai pour Orange/Moov', () {
      expect(UssdShortcuts.supports('ORANGE', UssdOperation.transfer), isTrue);
      expect(UssdShortcuts.supports('MOOV', UssdOperation.rechargeSelf), isTrue);
    });
  });
}
