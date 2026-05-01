class RateLimitException implements Exception {
  final String message;
  RateLimitException([this.message = 'Rate limit exceeded']);
  @override
  String toString() => 'RateLimitException: $message';
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Authentication failed']);
  @override
  String toString() => 'AuthException: $message';
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, [this.message = 'API error']);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
