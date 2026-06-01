import 'package:equatable/equatable.dart';

class BalanceSummary extends Equatable {
  const BalanceSummary({
    required this.operatorCode,
    required this.operatorName,
    required this.phoneNumber,
    required this.balance,
    required this.isLow,
    required this.alertThreshold,
    required this.lastUpdated,
  });

  final String operatorCode;
  final String operatorName;
  final String phoneNumber;
  final double balance;
  final bool isLow;
  final double alertThreshold;
  final DateTime lastUpdated;

  bool get isEmpty => balance <= 0;

  @override
  List<Object?> get props => [
        operatorCode,
        operatorName,
        phoneNumber,
        balance,
        isLow,
        alertThreshold,
        lastUpdated,
      ];
}
