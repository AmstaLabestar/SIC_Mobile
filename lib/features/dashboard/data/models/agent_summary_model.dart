import '../../domain/entities/agent_summary.dart';
import 'balance_summary_model.dart';
import 'benefit_period_model.dart';

class AgentSummaryModel extends AgentSummary {
  const AgentSummaryModel({
    required super.agentCode,
    required super.agentName,
    required super.totalBalance,
    required super.benefits,
    required super.balances,
    required super.transactionCountToday,
  });

  factory AgentSummaryModel.fromJson(Map<String, dynamic> json) {
    final balancesJson = json['balances'] as List<dynamic>;

    return AgentSummaryModel(
      agentCode: json['agent_code'] as String,
      agentName: json['agent_name'] as String,
      totalBalance: (json['total_balance'] as num).toDouble(),
      benefits: BenefitPeriodModel.fromJson(
        json['benefits'] as Map<String, dynamic>,
      ),
      balances: balancesJson
          .map(
            (balance) => BalanceSummaryModel.fromJson(
              balance as Map<String, dynamic>,
            ),
          )
          .toList(),
      transactionCountToday: json['transaction_count_today'] as int,
    );
  }

  factory AgentSummaryModel.mock() {
    final balances = [
      BalanceSummaryModel.mock('OM'),
      BalanceSummaryModel.mock('MOOV'),
      BalanceSummaryModel.mock('TELECEL'),
    ];
    final totalBalance = balances.fold<double>(
      0,
      (total, balance) => total + balance.balance,
    );

    return AgentSummaryModel(
      agentCode: 'AGT-0042',
      agentName: 'Kone Moussa',
      totalBalance: totalBalance,
      benefits: BenefitPeriodModel.mock(),
      balances: balances,
      transactionCountToday: 8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agent_code': agentCode,
      'agent_name': agentName,
      'total_balance': totalBalance,
      'benefits': (benefits as BenefitPeriodModel).toJson(),
      'balances': balances
          .map((balance) => (balance as BalanceSummaryModel).toJson())
          .toList(),
      'transaction_count_today': transactionCountToday,
    };
  }
}
