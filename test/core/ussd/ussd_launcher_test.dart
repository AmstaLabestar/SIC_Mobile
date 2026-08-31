import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/core/ussd/ussd_launcher.dart';

void main() {
  group('UssdLauncher.telUriString', () {
    test('encode le # en %23 et garde les *', () {
      expect(
        UssdLauncher.telUriString('*144*1*1*500#'),
        'tel:*144*1*1*500%23',
      );
    });

    test('transfert Moov', () {
      expect(
        UssdLauncher.telUriString('*555*2*1*60000000#'),
        'tel:*555*2*1*60000000%23',
      );
    });
  });
}
