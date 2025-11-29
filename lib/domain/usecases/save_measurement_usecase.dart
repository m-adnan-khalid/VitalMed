
import 'package:dartz/dartz.dart';
import '../../core/error_handling/exceptions.dart';
import '../entities/measurement.dart';
import '../repositories/ble_repository.dart';

class SaveMeasurementUseCase {
  final BLERepository _repository;

  SaveMeasurementUseCase(this._repository);

  Future<Either<Failure, void>> execute(Measurement measurement) async {
    try {
      await _repository.saveAndSyncMeasurement(measurement);
      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  Future<Either<Failure, List<Measurement>>> getMeasurements({
    int? limit,
    MeasurementType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final measurements = await _repository.getMeasurements(
        limit: limit,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(measurements);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  Future<Either<Failure, void>> deleteMeasurement(String measurementId) async {
    try {
      await _repository.deleteMeasurement(measurementId);
      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  Future<Either<Failure, void>> syncPendingMeasurements() async {
    try {
      await _repository.syncPendingMeasurements();
      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  Failure _mapExceptionToFailure(dynamic exception) {
    if (exception is Failure) {
      return exception;
    }

    if (exception is Exception) {
      return UnknownFailure('Unexpected error: ${exception.toString()}');
    }

    return UnknownFailure('An unexpected error occurred');
  }
}
