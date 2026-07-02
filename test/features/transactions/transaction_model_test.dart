import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/features/transactions/data/models/agent_transaction_model.dart';
import 'package:sic_mobile/features/transactions/data/models/operation_result_model.dart';
import 'package:sic_mobile/features/transactions/domain/entities/agent_transaction.dart';

void main() {
  group('AgentTransactionModel.fromJson', () {
    test('mappe le type DEPOT et l\'operateur ORANGE -> OM', () {
      final t = AgentTransactionModel.fromJson({
        'id': 'tx-1',
        'type': 'DEPOT',
        'status': 'PENDING',
        'target_operator': 'ORANGE',
        'target_phone_number': '07000001',
        'amount': '5000.00',
        'commission_sic': '50.00',
        'agent_benefit': '120.00',
        'is_compensated': false,
        'created_at': '2026-06-12T10:00:00Z',
      });

      expect(t.kind, TransactionKind.deposit);
      expect(t.status, 'PENDING');
      expect(t.amount, 5000);
      expect(t.commissionSic, 50);
      expect(t.operatorCode, 'OM');
      expect(t.operatorName, 'Orange Money');
      expect(t.isPending, isTrue);
    });

    test('mappe RETRAIT et SWAP', () {
      expect(
        AgentTransactionModel.fromJson({'type': 'RETRAIT'}).kind,
        TransactionKind.withdrawal,
      );
      expect(
        AgentTransactionModel.fromJson({'type': 'SWAP'}).kind,
        TransactionKind.transfer,
      );
    });

    test('type inconnu -> other, valeurs par defaut robustes', () {
      final t = AgentTransactionModel.fromJson({'type': 'XYZ'});
      expect(t.kind, TransactionKind.other);
      expect(t.amount, 0);
      expect(t.operatorCode, isNull);
    });

    test('mappe correctement la liste de details de compensation', () {
      final t = AgentTransactionModel.fromJson({
        'id': 'tx-2',
        'type': 'DEPOT',
        'status': 'SUCCESS',
        'amount': '10000.00',
        'commission_sic': '100.00',
        'is_compensated': true,
        'created_at': '2026-06-12T10:00:00Z',
        'compensation_details': [
          {
            'id': 'detail-1',
            'puce_operator': 'ORANGE',
            'puce_phone': '+22670123456',
            'amount_deducted': '4000.00',
            'status': 'SUCCESS',
          },
          {
            'id': 'detail-2',
            'puce_operator': 'MOOV',
            'puce_phone': '+22675123456',
            'amount_deducted': '6000.00',
            'status': 'SUCCESS',
          }
        ]
      });

      expect(t.isCompensated, isTrue);
      expect(t.compensationDetails, hasLength(2));
      
      final d1 = t.compensationDetails[0];
      expect(d1.id, 'detail-1');
      expect(d1.puceOperator, 'Orange Money');
      expect(d1.pucePhone, '+22670123456');
      expect(d1.amountDeducted, 4000);
      expect(d1.isSuccess, isTrue);

      final d2 = t.compensationDetails[1];
      expect(d2.id, 'detail-2');
      expect(d2.puceOperator, 'Moov Money');
      expect(d2.pucePhone, '+22675123456');
      expect(d2.amountDeducted, 6000);
      expect(d2.isSuccess, isTrue);
    });
  });

  group('OperationResultModel.fromJson', () {
    test('depot : commission/benefice presents', () {
      final r = OperationResultModel.fromJson({
        'transaction_id': 'tx-9',
        'amount': '5000',
        'commission_sic': '50',
        'status': 'PENDING',
        'created_at': '2026-06-12T10:00:00Z',
      });
      expect(r.transactionId, 'tx-9');
      expect(r.amount, 5000);
      expect(r.commissionSic, 50);
      expect(r.status, 'PENDING');
    });

    test('transfert : commission absente -> null', () {
      final r = OperationResultModel.fromJson({
        'transaction_id': 'tx-10',
        'amount': '2000',
        'status': 'PENDING',
        'created_at': '2026-06-12T10:00:00Z',
      });
      expect(r.commissionSic, isNull);
    });
  });
}
