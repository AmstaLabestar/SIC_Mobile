import '../../domain/entities/float_operation.dart';

class FloatOperationModel extends FloatOperation {
  const FloatOperationModel({
    required super.id,
    required super.status,
    required super.deliveryAmount,
    required super.sicFee,
    required super.collectAmount,
  });

  factory FloatOperationModel.fromJson(Map<String, dynamic> json) {
    return FloatOperationModel(
      id: json['id']?.toString() ?? '',
      status: OperationStatus.fromApi(json['status']?.toString()),
      deliveryAmount: _toDouble(json['delivery_amount']),
      sicFee: _toDouble(json['sic_fee']),
      collectAmount: _toDouble(json['collect_amount']),
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
