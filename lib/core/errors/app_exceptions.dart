sealed class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException($code): $message';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

class ExportException extends AppException {
  const ExportException(super.message, {super.code});
}

class SubscriptionException extends AppException {
  const SubscriptionException(super.message, {super.code});
}

class BanubaException extends AppException {
  final String platformCode;
  const BanubaException(
    super.message, {
    required this.platformCode,
    super.code,
  });
}
