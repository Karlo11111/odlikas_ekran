import 'package:flutter_test/flutter_test.dart';
import 'package:odlikas_ekran/exceptions/app_exceptions.dart';

void main() {
  group('RateLimitException', () {
    test('uses default message', () {
      final e = RateLimitException();
      expect(e.message, 'Rate limit exceeded');
      expect(e.toString(), 'RateLimitException: Rate limit exceeded');
    });

    test('uses custom message', () {
      final e = RateLimitException('Too many requests');
      expect(e.message, 'Too many requests');
      expect(e.toString(), 'RateLimitException: Too many requests');
    });

    test('is an Exception', () {
      expect(RateLimitException(), isA<Exception>());
    });
  });

  group('AuthException', () {
    test('uses default message', () {
      final e = AuthException();
      expect(e.message, 'Authentication failed');
      expect(e.toString(), 'AuthException: Authentication failed');
    });

    test('uses custom message', () {
      final e = AuthException('Token expired');
      expect(e.message, 'Token expired');
      expect(e.toString(), 'AuthException: Token expired');
    });

    test('is an Exception', () {
      expect(AuthException(), isA<Exception>());
    });
  });

  group('ApiException', () {
    test('stores status code and default message', () {
      final e = ApiException(404);
      expect(e.statusCode, 404);
      expect(e.message, 'API error');
      expect(e.toString(), 'ApiException(404): API error');
    });

    test('stores custom message', () {
      final e = ApiException(500, 'Internal server error');
      expect(e.statusCode, 500);
      expect(e.message, 'Internal server error');
      expect(e.toString(), 'ApiException(500): Internal server error');
    });

    test('is an Exception', () {
      expect(ApiException(400), isA<Exception>());
    });
  });
}
