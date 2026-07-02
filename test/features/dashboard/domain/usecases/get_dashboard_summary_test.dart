import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sic_mobile/core/errors/failures.dart';
import 'package:sic_mobile/core/usecases/usecase.dart';
import 'package:sic_mobile/features/dashboard/domain/entities/agent_summary.dart';
import 'package:sic_mobile/features/dashboard/domain/entities/compensation_volume.dart';
import 'package:sic_mobile/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:sic_mobile/features/dashboard/domain/usecases/get_dashboard_summary.dart';

// Manual Mock implementation of DashboardRepository
class MockDashboardRepository implements DashboardRepository {
  Either<Failure, AgentSummary>? getDashboardSummaryResult;

  @override
  Future<Either<Failure, AgentSummary>> getDashboardSummary() async {
    if (getDashboardSummaryResult == null) {
      throw UnimplementedError('Result not configured in mock repository.');
    }
    return getDashboardSummaryResult!;
  }

  @override
  Future<Either<Failure, Unit>> refreshBalance(String operatorCode) async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> updatePuce({
    required String id,
    required String operatorCode,
    required String phoneNumber,
    required bool isActive,
  }) async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deletePuce(String id) async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> createPuce({
    required String operatorCode,
    required String phoneNumber,
  }) async {
    return const Right(unit);
  }
}

void main() {
  late GetDashboardSummary usecase;
  late MockDashboardRepository mockRepository;

  setUp(() {
    mockRepository = MockDashboardRepository();
    usecase = GetDashboardSummary(mockRepository);
  });

  final tSummary = AgentSummary(
    agentCode: 'AGT-001',
    agentName: 'Test Agent',
    totalBalance: 100000.0,
    compensation: const CompensationVolume(
      today: 10000.0,
      week: 50000.0,
      month: 120000.0,
      total: 500000.0,
    ),
    balances: const [],
    transactionCountToday: 5,
  );

  test('should return AgentSummary when repository succeeds', () async {
    // Arrange
    mockRepository.getDashboardSummaryResult = Right(tSummary);

    // Act
    final result = await usecase(const NoParams());

    // Assert
    expect(result, Right(tSummary));
  });

  test('should return ServerFailure when repository fails', () async {
    // Arrange
    const failure = ServerFailure('Erreur serveur test');
    mockRepository.getDashboardSummaryResult = const Left(failure);

    // Act
    final result = await usecase(const NoParams());

    // Assert
    expect(result, const Left(failure));
    result.fold(
      (fail) => expect(fail.message, 'Erreur serveur test'),
      (_) => fail('Expected Left but got Right'),
    );
  });
}
