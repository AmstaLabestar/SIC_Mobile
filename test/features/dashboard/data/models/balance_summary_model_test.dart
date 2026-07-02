import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/features/dashboard/data/models/balance_summary_model.dart';

void main() {
  group('BalanceSummaryModel', () {
    test('parse correctement un JSON valide', () {
      final json = {
        'id': 'abc-123',
        'operator_code': 'OM',
        'operator_name': 'Orange Money',
        'phone_number': '0701234234',
        'balance': 250000.0,
        'is_low': false,
        'alert_threshold': 50000.0,
        'last_updated': '2024-01-15T10:30:00Z',
        'is_active': true,
      };

      final model = BalanceSummaryModel.fromJson(json);

      expect(model.id, 'abc-123');
      expect(model.operatorCode, 'OM');
      expect(model.operatorName, 'Orange Money');
      expect(model.phoneNumber, '0701234234');
      expect(model.balance, 250000.0);
      expect(model.isLow, isFalse);
      expect(model.alertThreshold, 50000.0);
      expect(model.isActive, isTrue);
    });

    test('is_active default a true si absent du JSON', () {
      final json = {
        'operator_code': 'OM',
        'operator_name': 'Orange Money',
        'phone_number': '0701234234',
        'balance': 0.0,
        'is_low': true,
        'alert_threshold': 50000.0,
        'last_updated': '2024-01-15T10:30:00Z',
      };

      final model = BalanceSummaryModel.fromJson(json);
      expect(model.isActive, isTrue);
    });

    test('convertit correctement en JSON via toJson', () {
      final now = DateTime(2024, 1, 15, 10, 30, 0).toLocal();
      final model = BalanceSummaryModel(
        id: 'abc-123',
        operatorCode: 'OM',
        operatorName: 'Orange Money',
        phoneNumber: '0701234234',
        balance: 250000.0,
        isLow: false,
        alertThreshold: 50000.0,
        lastUpdated: now,
        isActive: true,
      );

      final json = model.toJson();

      expect(json['id'], 'abc-123');
      expect(json['operator_code'], 'OM');
      expect(json['balance'], 250000.0);
      expect(json['last_updated'], now.toUtc().toIso8601String());
      expect(json['is_active'], isTrue);
    });

    test('mock retourne le bon operateur', () {
      final mockOm = BalanceSummaryModel.mock('OM');
      expect(mockOm.operatorCode, 'OM');
      expect(mockOm.operatorName, 'Orange Money');

      final mockMoov = BalanceSummaryModel.mock('MOOV');
      expect(mockMoov.operatorCode, 'MOOV');
      expect(mockMoov.isLow, isTrue);
    });
  });
}
