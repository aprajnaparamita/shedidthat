abstract class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class RegistrationException extends ApiException {
  RegistrationException(String message) : super(message);
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class RateLimitException extends ApiException {
  RateLimitException(String message) : super(message);
}
