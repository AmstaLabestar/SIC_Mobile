import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../features/transactions/presentation/providers/transaction_providers.dart';
import '../app_globals.dart';
import '../constants/api_constants.dart';
import '../network/network_providers.dart';
import 'realtime_service.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/alerts/presentation/providers/alert_provider.dart';

/// Service temps reel de l'app (singleton). Le cycle de vie (start/stop selon
/// l'auth et le premier plan) est pilote depuis `main.dart`.
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  Timer? resyncTimer;

  // Re-synchronisation debouncee : la base via REST reste la source de verite.
  // Une rafale d'evenements (plusieurs transactions ou actions d'admin)
  // ne declenche qu'un seul re-fetch. On invalide (re-fetch paresseux) plutot
  // que de patcher l'etat depuis le payload socket.
  void scheduleResync() {
    resyncTimer?.cancel();
    resyncTimer = Timer(const Duration(milliseconds: 400), () {
      ref.invalidate(authControllerProvider);
      ref.invalidate(dashboardNotifierProvider);
      ref.invalidate(transactionsNotifierProvider);
      ref.invalidate(alertNotifierProvider);
    });
  }

  final service = RealtimeService(
    tokenReader: () => ref.read(tokenStorageProvider).readAccess(),
    baseWsUrl: () => ApiConstants.wsNotificationsUrl,
    onConnected: scheduleResync,
    onEvent: (event) {
      scheduleResync();
      _notify(event);
    },
  );

  ref.onDispose(() {
    resyncTimer?.cancel();
    service.stop();
  });
  return service;
});

void _notify(Map<String, dynamic> event) {
  final type = (event['type'] as String?) ?? '';
  final message = (event['message'] as String?) ??
      switch (event['status'] as String?) {
        'COMPLETED' => 'Transaction confirmée en Backoffice.',
        'FAILED' => 'Transaction échouée.',
        _ => 'Mise à jour reçue du serveur.',
      };

  final isDanger = type.contains('rejected') || type.contains('failed');
  final isSuccess = type.contains('approved') || type.contains('completed');

  scaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDanger
            ? const Color(0xFFDC2626)
            : (isSuccess ? const Color(0xFF059669) : const Color(0xFF1E3A8A)),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
}
