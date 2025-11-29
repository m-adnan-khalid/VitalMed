
import 'package:dartz/dartz.dart';
import '../../core/error_handling/exceptions.dart';
import '../repositories/ble_repository.dart';

class ConnectDeviceUseCase {
  final BLERepository _repository;

  ConnectDeviceUseCase(this._repository);

  Future<Either<Failure, void>> execute(String deviceId) async {
    try {
      await _repository.connectToDevice(deviceId);
      return const Right(null);
    } catch (e) {
      return Left(_mapExceptionToFailure(e));
    }
  }

  Future<Either<Failure, void>> disconnect(String deviceId) async {
    try {
      await _repository.disconnectFromDevice(deviceId);
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

    return const UnknownFailure('An unexpected error occurred');
  }
}
