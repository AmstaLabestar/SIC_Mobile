import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/features/dashboard/domain/entities/balance_summary.dart';

void main() {
  group('BalanceSummary', () {
    test('maskedPhone retourne le format masque (07•••234)', () {
      final balance = BalanceSummary(
        operatorCode: 'OM',
        operatorName: 'Orange Money',
        phoneNumber: '0701234234',
        balance: 250000,
        isLow: false,
        alertThreshold: 50000,
        lastUpdated: DateTime(2024, 1, 15),
      );
      expect(balance.maskedPhone, '07•••234');
    });

    test('maskedPhone retourne le format masque (06•••891)', () {
      final balance = BalanceSummary(
        operatorCode: 'MOOV',
        operatorName: 'Moov Money',
        phoneNumber: '0601238891',
        balance: 35000,
        isLow: true,
        alertThreshold: 50000,
        lastUpdated: DateTime(2024, 1, 15),
      );
      expect(balance.maskedPhone, '06•••891');
    });

    test('isEmpty est true quand balance <= 0', () {
      final balance = BalanceSummary(
        operatorCode: 'OM',
        operatorName: 'Orange Money',
        phoneNumber: '0700000000',
        balance: 0,
        isLow: true,
        alertThreshold: 50000,
        lastUpdated: DateTime.now(),
      );
      expect(balance.isEmpty, isTrue);
    });

    test('isEmpty est false quand balance > 0', () {
      final balance = BalanceSummary(
        operatorCode: 'OM',
        operatorName: 'Orange Money',
        phoneNumber: '0701234234',
        balance: 1000,
        isLow: false,
        alertThreshold: 50000,
        lastUpdated: DateTime.now(),
      );
      expect(balance.isEmpty, isFalse);
    });

    test('copyWith met a jour le champ balance et recalcule isLow', () {
      final balance = BalanceSummary(
        operatorCode: 'OM',
        operatorName: 'Orange Money',
        phoneNumber: '0701234234',
        balance: 50000,
        isLow: false,
        alertThreshold: 50000,
        lastUpdated: DateTime.now(),
      );
      final updated = balance.copyWith(balance: 20000);
      expect(updated.balance, 20000);
      // isLow est recalculé car 20000 < 50000
      expect(updated.isLow, isTrue);
    });
  });
}
