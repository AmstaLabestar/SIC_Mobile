import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/dashboard_local_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/agent_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_dashboard_summary.dart';
import '../../domain/usecases/refresh_balance.dart';

enum DashboardBenefitPeriod { today, week, month }

final dashboardLocalDatasourceProvider = Provider<DashboardLocalDatasource>(
  (ref) => const DashboardLocalDatasource(),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardLocalDatasourceProvider));
});

final getDashboardSummaryProvider = Provider<GetDashboardSummary>((ref) {
  return GetDashboardSummary(ref.watch(dashboardRepositoryProvider));
});

final refreshBalanceProvider = Provider<RefreshBalance>((ref) {
  return RefreshBalance(ref.watch(dashboardRepositoryProvider));
});

final selectedBenefitPeriodProvider = StateProvider<DashboardBenefitPeriod>(
  (ref) => DashboardBenefitPeriod.today,
);

final dashboardNotifierProvider =
    AsyncNotifierProvider<DashboardNotifier, AgentSummary>(
  DashboardNotifier.new,
);

class DashboardNotifier extends AsyncNotifier<AgentSummary> {
  @override
  Future<AgentSummary> build() {
    return _loadDashboard();
  }

  Future<void> refresh() async {
    state = const AsyncLoading<AgentSummary>();
    state = await AsyncValue.guard(_loadDashboard);
  }

  Future<void> refreshOperatorBalance(String operatorCode) async {
    final usecase = ref.read(refreshBalanceProvider);
    final result = await usecase(
      RefreshBalanceParams(operatorCode: operatorCode),
    );

    await result.fold(
      (failure) {
        state = AsyncError<AgentSummary>(failure, StackTrace.current);
        return Future<void>.value();
      },
      (_) => refresh(),
    );
  }

  void applyBalanceUpdate({
    required String operatorCode,
    required double newBalance,
    required DateTime updatedAt,
  }) {
    final currentSummary = state.valueOrNull;
    if (currentSummary == null) {
      return;
    }

    final updatedBalances = currentSummary.balances.map((balance) {
      if (balance.operatorCode != operatorCode) {
        return balance;
      }

      return balance.copyWith(balance: newBalance, lastUpdated: updatedAt);
    }).toList();

    state = AsyncData(currentSummary.copyWith(balances: updatedBalances));
  }

  Future<AgentSummary> _loadDashboard() async {
    final usecase = ref.read(getDashboardSummaryProvider);
    final result = await usecase(const NoParams());

    return result.fold((failure) => throw failure, (summary) => summary);
  }
}
