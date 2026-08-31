import 'package:dio/dio.dart';
import '../../domain/entities/bill_transaction.dart';

class BillsRemoteDatasource {
  final Dio _dio;

  BillsRemoteDatasource(this._dio);

  Future<BillInquiryResult> inquiry({
    required String serviceType,
    required String meterReference,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>('/bills/inquiry/', data: {
      'service_type': serviceType,
      'meter_reference': meterReference,
    });
    final data = res.data ?? <String, dynamic>{};
    return BillInquiryResult.fromJson(data);
  }

  Future<BillTransactionEntity> initiatePayment({
    required String serviceType,
    required String walletCode,
    required String meterReference,
    required double amount,
    required String idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>('/bills/initiate/', data: {
      'service_type': serviceType,
      'wallet_code': walletCode,
      'meter_reference': meterReference,
      'amount': amount,
      'idempotency_key': idempotencyKey,
    });
    final data = res.data ?? <String, dynamic>{};
    final txData = data['transaction'] as Map<String, dynamic>;
    return BillTransactionEntity.fromJson(txData);
  }

  Future<BillTransactionEntity> getTransactionDetail(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/bills/transaction/$id/');
    final data = res.data ?? <String, dynamic>{};
    return BillTransactionEntity.fromJson(data);
  }

  Future<List<BillTransactionEntity>> getHistory() async {
    final res = await _dio.get<Map<String, dynamic>>('/bills/history/');
    final data = res.data ?? <String, dynamic>{};
    final results = (data['results'] as List<dynamic>?) ?? [];
    return results.map((item) => BillTransactionEntity.fromJson(item as Map<String, dynamic>)).toList();
  }
}
