
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String code;

  const Failure(this.message, this.code);

  @override
  List<Object> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code = 'SERVER_ERROR']);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code = 'NETWORK_ERROR']);
}

class BLEFailure extends Failure {
  const BLEFailure(super.message, [super.code = 'BLE_ERROR']);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, [super.code = 'PERMISSION_ERROR']);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.code = 'STORAGE_ERROR']);
}

class ParsingFailure extends Failure {
  const ParsingFailure(super.message, [super.code = 'PARSING_ERROR']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code = 'VALIDATION_ERROR']);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, [super.code = 'UNKNOWN_ERROR']);
}
