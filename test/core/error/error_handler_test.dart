import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/error/error_handler.dart';
import 'package:oshi_log/core/error/failure.dart';

void main() {
  group('ErrorHandler.mapDioError', () {
    test('extracts retryAfterMs from Retry-After header for 429', () {
      final requestOptions = RequestOptions(path: '/api/v1/auth/login');
      final response = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 429,
        data: {'error': 'too_many_requests'},
        headers: Headers.fromMap({
          'retry-after': ['3'],
        }),
      );

      final exception = DioException.badResponse(
        statusCode: 429,
        requestOptions: requestOptions,
        response: response,
      );

      final failure = ErrorHandler.mapDioError(exception);
      expect(failure, isA<ServerFailure>());
      final serverFailure = failure as ServerFailure;
      expect(serverFailure.code, '429');
      expect(serverFailure.retryAfterMs, 3000);
    });

    test('extracts retryAfterMs from X-RateLimit-Reset header for 429', () {
      final requestOptions = RequestOptions(path: '/api/v1/auth/login');
      final response = Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 429,
        data: {'error': 'too_many_requests'},
        headers: Headers.fromMap({
          'x-ratelimit-reset': ['2'],
        }),
      );

      final exception = DioException.badResponse(
        statusCode: 429,
        requestOptions: requestOptions,
        response: response,
      );

      final failure = ErrorHandler.mapDioError(exception);
      expect(failure, isA<ServerFailure>());
      final serverFailure = failure as ServerFailure;
      expect(serverFailure.code, '429');
      expect(serverFailure.retryAfterMs, 2000);
    });
  });
}
