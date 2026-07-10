import 'package:equatable/equatable.dart';

/// Statut d'une opération overlay (miroir du backend `OperationStatus`).
enum OperationStatus {
  created,
  pendingDebit,
  debitSuccess,
  debitFailed,
  pendingDelivery,
  completed,
  deliveryFailed,
  pendingRefund,
  refunded,
  refundFailed,
  unknown;

  static OperationStatus fromApi(String? raw) {
    switch (raw) {
      case 'created':
        return OperationStatus.created;
      case 'pending_debit':
        return OperationStatus.pendingDebit;
      case 'debit_success':
        return OperationStatus.debitSuccess;
      case 'debit_failed':
        return OperationStatus.debitFailed;
      case 'pending_delivery':
        return OperationStatus.pendingDelivery;
      case 'completed':
        return OperationStatus.completed;
      case 'delivery_failed':
        return OperationStatus.deliveryFailed;
      case 'pending_refund':
        return OperationStatus.pendingRefund;
      case 'refunded':
        return OperationStatus.refunded;
      case 'refund_failed':
        return OperationStatus.refundFailed;
      default:
        return OperationStatus.unknown;
    }
  }

  /// États terminaux : on arrête le polling.
  bool get isTerminal =>
      this == OperationStatus.completed ||
      this == OperationStatus.debitFailed ||
      this == OperationStatus.refunded ||
      this == OperationStatus.refundFailed;
}

/// Type d'opération overlay.
enum OperationType { conversion, transfer, airtime }

extension OperationTypeApi on OperationType {
  String get api => switch (this) {
        OperationType.conversion => 'conversion',
        OperationType.transfer => 'transfer',
        OperationType.airtime => 'airtime',
      };
}

/// Une opération overlay (collect → livraison). Aucun solde : SIC collecte
/// l'argent réel de l'agent (PIN USSD) puis livre, et garde `sicFee`.
class FloatOperation extends Equatable {
  const FloatOperation({
    required this.id,
    required this.status,
    required this.deliveryAmount,
    required this.sicFee,
    required this.collectAmount,
  });

  final String id;
  final OperationStatus status;
  final double deliveryAmount; // reçu par la destination
  final double sicFee; // marge SIC
  final double collectAmount; // débité à l'agent (delivery + fee)

  bool get isTerminal => status.isTerminal;

  @override
  List<Object?> get props => [id, status, deliveryAmount, sicFee, collectAmount];
}
