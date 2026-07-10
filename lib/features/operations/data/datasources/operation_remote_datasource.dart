import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/float_operation.dart';
import '../models/float_operation_model.dart';

/// Appels réseau du moteur d'opérations overlay (peut lever [DioException]).
class OperationRemoteDatasource {
  const OperationRemoteDatasource(this._dio);

  final Dio _dio;

  /// Crée + lance une opération. `pinToken` transmis en `X-PIN-TOKEN` (exigé
  /// dès qu'un PIN app est configuré).
  Future<FloatOperationModel> create({
    required OperationType type,
    required String sourceOperator,
    required String destOperator,
    required String destWallet,
    required double deliveryAmount,
    String? pinToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.operations,
      data: {
        'type': type.api,
        'source_operator': sourceOperator,
        'dest_operator': destOperator,
        'dest_wallet': destWallet,
        'delivery_amount': deliveryAmount,
      },
      options: pinToken == null
          ? null
          : Options(headers: {'X-PIN-TOKEN': pinToken}),
    );
    return FloatOperationModel.fromJson(response.data!);
  }

  /// État courant d'une opération (polling de secours ; le canal principal
  /// reste le WebSocket temps réel).
  Future<FloatOperationModel> getStatus(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>(ApiConstants.operation(id));
    return FloatOperationModel.fromJson(response.data!);
  }
}
