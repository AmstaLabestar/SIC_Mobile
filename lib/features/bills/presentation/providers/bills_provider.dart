import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/datasources/bills_remote_datasource.dart';
import '../../domain/entities/bill_transaction.dart';

final billsDatasourceProvider = Provider<BillsRemoteDatasource>(
  (ref) => BillsRemoteDatasource(ref.watch(dioProvider)),
);

class BillsController extends StateNotifier<AsyncValue<BillTransactionEntity?>> {
  BillsController(this._ds) : super(const AsyncValue.data(null));

  final BillsRemoteDatasource _ds;
  Timer? _pollingTimer;

  Future<BillInquiryResult> inquiry({
    required String serviceType,
    required String meterReference,
  }) async {
    return await _ds.inquiry(serviceType: serviceType, meterReference: meterReference);
  }

  Future<BillTransactionEntity> initiatePayment({
    required String serviceType,
    required String walletCode,
    required String meterReference,
    required double amount,
    required String idempotencyKey,
  }) async {
    _pollingTimer?.cancel();
    state = const AsyncValue.loading();
    try {
      final tx = await _ds.initiatePayment(
        serviceType: serviceType,
        walletCode: walletCode,
        meterReference: meterReference,
        amount: amount,
        idempotencyKey: idempotencyKey,
      );
      state = AsyncValue.data(tx);
      if (tx.status != 'BILLER_SUCCESS' && tx.status != 'REFUNDED' && tx.status != 'EXPIRED' && tx.status != 'BILLER_FAILED') {
        _startPolling(tx.id);
      }
      return tx;
    } catch (error, st) {
      state = AsyncValue.error(error, st);
      rethrow;
    }
  }

  void _startPolling(String id) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final tx = await _ds.getTransactionDetail(id);
        state = AsyncValue.data(tx);
        if (tx.status == 'BILLER_SUCCESS' || tx.status == 'REFUNDED' || tx.status == 'EXPIRED' || tx.status == 'BILLER_FAILED') {
          timer.cancel();
        }
      } catch (_) {
        // Continue polling on transient network error
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final billsControllerProvider = StateNotifierProvider.autoDispose<BillsController, AsyncValue<BillTransactionEntity?>>(
  (ref) => BillsController(ref.watch(billsDatasourceProvider)),
);
