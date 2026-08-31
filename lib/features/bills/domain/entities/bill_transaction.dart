class BillInquiryResult {
  final bool success;
  final String reference;
  final double amountDue;
  final String customerName;
  final String? billNumber;
  final String? dueDate;
  final String? errorMessage;

  BillInquiryResult({
    required this.success,
    required this.reference,
    required this.amountDue,
    required this.customerName,
    this.billNumber,
    this.dueDate,
    this.errorMessage,
  });

  factory BillInquiryResult.fromJson(Map<String, dynamic> json) {
    return BillInquiryResult(
      success: json['success'] ?? false,
      reference: json['reference'] ?? '',
      amountDue: (json['amount_due'] as num?)?.toDouble() ?? 0.0,
      customerName: json['customer_name'] ?? '',
      billNumber: json['bill_number'],
      dueDate: json['due_date'],
      errorMessage: json['error_message'],
    );
  }
}

class BillTransactionEntity {
  final String id;
  final String idempotencyKey;
  final String serviceType;
  final String serviceTypeDisplay;
  final String walletCode;
  final String walletCodeDisplay;
  final String meterReference;
  final double amount;
  final double feeAmount;
  final double totalAmount;
  final String status;
  final String statusDisplay;
  final String? walletTxId;
  final String? billerTxId;
  final String? tokenSts;
  final String? receiptNumber;
  final String? errorMessage;
  final String createdAt;

  BillTransactionEntity({
    required this.id,
    required this.idempotencyKey,
    required this.serviceType,
    required this.serviceTypeDisplay,
    required this.walletCode,
    required this.walletCodeDisplay,
    required this.meterReference,
    required this.amount,
    required this.feeAmount,
    required this.totalAmount,
    required this.status,
    required this.statusDisplay,
    this.walletTxId,
    this.billerTxId,
    this.tokenSts,
    this.receiptNumber,
    this.errorMessage,
    required this.createdAt,
  });

  factory BillTransactionEntity.fromJson(Map<String, dynamic> json) {
    return BillTransactionEntity(
      id: json['id'] ?? '',
      idempotencyKey: json['idempotency_key'] ?? '',
      serviceType: json['service_type'] ?? '',
      serviceTypeDisplay: json['service_type_display'] ?? '',
      walletCode: json['wallet_code'] ?? '',
      walletCodeDisplay: json['wallet_code_display'] ?? '',
      meterReference: json['meter_reference'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      feeAmount: (json['fee_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      walletTxId: json['wallet_tx_id'],
      billerTxId: json['biller_tx_id'],
      tokenSts: json['token_sts'],
      receiptNumber: json['receipt_number'],
      errorMessage: json['error_message'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
