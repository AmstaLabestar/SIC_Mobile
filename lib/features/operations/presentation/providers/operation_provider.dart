import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../data/datasources/operation_remote_datasource.dart';
import '../../domain/entities/float_operation.dart';

final operationDatasourceProvider = Provider<OperationRemoteDatasource>(
  (ref) => OperationRemoteDatasource(ref.watch(dioProvider)),
);

/// Pilote une opération : création puis polling du statut (toutes les 2 s)
/// jusqu'à un état terminal. Le WebSocket temps réel peut compléter/accélérer,
/// le polling reste le filet de sécurité.
class OperationController
    extends StateNotifier<AsyncValue<FloatOperation?>> {
  OperationController(this._ds) : super(const AsyncValue.data(null));

  final OperationRemoteDatasource _ds;
  Timer? _timer;

  Future<void> start({
    required OperationType type,
    required String sourceOperator,
    required String destOperator,
    required String destWallet,
    required double deliveryAmount,
    String? pinToken,
  }) async {
    _timer?.cancel();
    state = const AsyncValue.loading();
    try {
      final op = await _ds.create(
        type: type,
        sourceOperator: sourceOperator,
        destOperator: destOperator,
        destWallet: destWallet,
        deliveryAmount: deliveryAmount,
        pinToken: pinToken,
      );
      state = AsyncValue.data(op);
      if (!op.isTerminal) _startPolling(op.id);
    } catch (error, st) {
      state = AsyncValue.error(error, st);
    }
  }

  void _startPolling(String id) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final op = await _ds.getStatus(id);
        state = AsyncValue.data(op);
        if (op.isTerminal) timer.cancel();
      } catch (_) {
        // Erreur réseau ponctuelle : on continue le polling.
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final operationControllerProvider = StateNotifierProvider.autoDispose<
    OperationController, AsyncValue<FloatOperation?>>(
  (ref) => OperationController(ref.watch(operationDatasourceProvider)),
);
