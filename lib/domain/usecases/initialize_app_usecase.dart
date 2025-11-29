
import 'package:dartz/dartz.dart';
import '../../core/error_handling/exceptions.dart';
import '../repositories/ble_repository.dart';

class InitializeAppUseCase {
  final BLERepository _repository;

  InitializeAppUseCase(this._repository);

  Future<Either<Failure, void>> execute() async {
    try {
      await _repository.initialize();
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
