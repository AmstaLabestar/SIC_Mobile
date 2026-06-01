import 'package:equatable/equatable.dart';

import 'balance_summary.dart';
import 'benefit_period.dart';

class AgentSummary extends Equatable {
  const AgentSummary({
    required this.agentCode,
    required this.agentName,
    required this.totalBalance,
    required this.benefits,
    required this.balances,
    required this.transactionCountToday,
  });

  final String agentCode;
  final String agentName;
  final double totalBalance;
  final BenefitPeriod benefits;
  final List<BalanceSummary> balances;
  final int transactionCountToday;

  int get activeSimCount => balances.where((balance) => !balance.isEmpty).length;

  bool get hasLowBalance {
    return balances.any((balance) => balance.isLow || balance.isEmpty);
  }

  @override
  List<Object?> get props => [
        agentCode,
        agentName,
        totalBalance,
        benefits,
        balances,
        transactionCountToday,
      ];
}
