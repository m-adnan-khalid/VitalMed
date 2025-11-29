
import 'package:dartz/dartz.dart';
import '../../core/error_handling/exceptions.dart';
import '../repositories/ble_repository.dart';

class ScanDevicesUseCase {
  final BLERepository _repository;

  ScanDevicesUseCase(this._repository);

  Future<Either<Failure, void>> execute() async {
    try {
      await _repository.startScanning();
      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  Future<Either<Failure, void>> stop() async {
    try {
      await _repository.stopScanning();
      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  bool get isScanning => _repository.isScanning;

  Failure _mapExceptionToFailure(dynamic exception) {
    if (exception is Failure) {
      return exception;
    }

    if (exception is Exception) {
      return UnknownFailure('Unexpected error: ${exception.toString()}');
    }

    return const UnknownFailure('An unexpected error occurred');
  }
}
