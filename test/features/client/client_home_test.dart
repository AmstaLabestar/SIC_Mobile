import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/core/network/network_providers.dart';
import 'package:sic_mobile/core/storage/token_storage.dart';
import 'package:sic_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:sic_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:sic_mobile/features/client/presentation/screens/client_home_screen.dart';
import 'package:sic_mobile/features/dashboard/domain/entities/agent_summary.dart';
import 'package:sic_mobile/features/dashboard/domain/entities/compensation_volume.dart';
import 'package:sic_mobile/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:sic_mobile/features/transactions/domain/entities/agent_transaction.dart';
import 'package:sic_mobile/features/transactions/presentation/providers/transaction_providers.dart';

class _EmptyTokenStorage extends TokenStorage {
  _EmptyTokenStorage() : super(const FlutterSecureStorage());
  @override
  Future<bool> hasSession() async => false;
  @override
  Future<String?> readAccess() async => null;
  @override
  Future<String?> readRefresh() async => null;
}

class _FakeAuthNotifier extends AuthController {
  @override
  Future<AuthUser?> build() async => const AuthUser(
        id: '1',
        firstName: 'Test',
        lastName: 'User',
        phoneNumber: '70000000',
        email: 'test@example.com',
        kycStatus: 'APPROVED',
        isSuspended: false,
        accountType: 'CLIENT',
        hasPin: true,
      );
}

class _FakeDashboard extends DashboardNotifier {
  @override
  Future<AgentSummary> build() async => const AgentSummary(
        agentName: 'Test User',
        agentCode: 'TEST01',
        balances: [],
        totalBalance: 100000,
        compensation: CompensationVolume(
          today: 0,
          week: 0,
          month: 0,
          total: 0,
        ),
        transactionCountToday: 0,
        hasUnreadNotifications: false,
      );
}

class _FakeTransactions extends TransactionsNotifier {
  @override
  Future<List<AgentTransaction>> build() async => const [];
}

Widget _harness() => ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(_EmptyTokenStorage()),
        authControllerProvider.overrideWith(_FakeAuthNotifier.new),
        dashboardNotifierProvider.overrideWith(_FakeDashboard.new),
        transactionsNotifierProvider.overrideWith(_FakeTransactions.new),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ClientHomeScreen()),
      ),
    );

void main() {
  testWidgets('l\'accueil client affiche les actions rapides (Envoyer, Cashpower, Facture ONEA, Retrait) et la carte du solde',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Solde total'), findsOneWidget);
    expect(find.text('Envoyer'), findsOneWidget);
    expect(find.text('Retrait'), findsOneWidget);
    expect(find.text('Cashpower'), findsOneWidget);
    expect(find.text('Facture ONEA'), findsOneWidget);
  });
}
