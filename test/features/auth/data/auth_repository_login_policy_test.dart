import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:girlsbandtabi_app/core/error/failure.dart';
import 'package:girlsbandtabi_app/core/security/secure_storage.dart';
import 'package:girlsbandtabi_app/core/utils/result.dart';
import 'package:girlsbandtabi_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:girlsbandtabi_app/features/auth/data/dto/account_recovery_password_request.dart';
import 'package:girlsbandtabi_app/features/auth/data/dto/login_request.dart';
import 'package:girlsbandtabi_app/features/auth/data/dto/token_response.dart';
import 'package:girlsbandtabi_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:girlsbandtabi_app/features/auth/domain/entities/auth_tokens.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  setUpAll(() {
    registerFallbackValue(const LoginRequest(username: 'u', password: 'p'));
    registerFallbackValue(
      const AccountRecoveryPasswordRequest(email: 'u', password: 'p'),
    );
  });

  late _MockAuthRemoteDataSource remoteDataSource;
  late _MockSecureStorage secureStorage;

  setUp(() {
    remoteDataSource = _MockAuthRemoteDataSource();
    secureStorage = _MockSecureStorage();

    when(
      () => secureStorage.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {});
    when(() => secureStorage.saveTokenExpiry(any())).thenAnswer((_) async {});
    when(() => secureStorage.getUserId()).thenAnswer((_) async => null);
    when(() => secureStorage.saveUserId(any())).thenAnswer((_) async {});
    when(() => secureStorage.clearVerificationKeys()).thenAnswer((_) async {});
    when(() => secureStorage.hasValidTokens()).thenAnswer((_) async => true);
  });

  group('AuthRepositoryImpl.login policy', () {
    test('login request payload uses username key (not email)', () {
      final payload = const LoginRequest(
        username: 'user@example.com',
        password: 'pw',
      ).toJson();

      expect(payload['username'], 'user@example.com');
      expect(payload.containsKey('email'), isFalse);
    });

    test(
      'uses username/password payload and deduplicates in-flight same account',
      () async {
        final completer = Completer<Result<TokenResponse>>();
        LoginRequest? capturedRequest;
        when(() => remoteDataSource.login(any())).thenAnswer((invocation) {
          capturedRequest =
              invocation.positionalArguments.first as LoginRequest;
          return completer.future;
        });

        final repository = AuthRepositoryImpl(
          remoteDataSource: remoteDataSource,
          secureStorage: secureStorage,
        );

        final first = repository.login(
          username: ' User@Example.com ',
          password: 'pw1',
        );
        final second = repository.login(
          username: 'user@example.com',
          password: 'pw2',
        );

        verify(() => remoteDataSource.login(any())).called(1);
        expect(capturedRequest?.username, 'User@Example.com');
        expect(capturedRequest?.password, 'pw1');

        completer.complete(
          Result.success(
            TokenResponse(accessToken: 'token-1', refreshToken: 'refresh-1'),
          ),
        );

        final firstResult = await first;
        final secondResult = await second;
        expect(firstResult, isA<Success>());
        expect(secondResult, isA<Success>());
      },
    );

    test('retries once with short delay on 409 conflict', () async {
      final sleeps = <Duration>[];
      var callCount = 0;
      when(() => remoteDataSource.login(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return Result.failure(const ServerFailure('Conflict', code: '409'));
        }
        return Result.success(
          TokenResponse(accessToken: 'token-2', refreshToken: 'refresh-2'),
        );
      });

      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        secureStorage: secureStorage,
        sleep: (duration) async => sleeps.add(duration),
        nextInt: (_) => 60,
      );

      final result = await repository.login(
        username: 'user@example.com',
        password: 'pw',
      );

      expect(result, isA<Success>());
      verify(() => remoteDataSource.login(any())).called(2);
      expect(sleeps, [const Duration(milliseconds: 280)]);
    });

    test('waits then retries once on 429 rate limit', () async {
      final sleeps = <Duration>[];
      var callCount = 0;
      when(() => remoteDataSource.login(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return Result.failure(
            const ServerFailure('Too many requests', code: '429'),
          );
        }
        return Result.success(
          TokenResponse(accessToken: 'token-3', refreshToken: 'refresh-3'),
        );
      });

      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        secureStorage: secureStorage,
        sleep: (duration) async => sleeps.add(duration),
      );

      final result = await repository.login(
        username: 'user@example.com',
        password: 'pw',
      );

      expect(result, isA<Success>());
      verify(() => remoteDataSource.login(any())).called(2);
      expect(sleeps, [const Duration(milliseconds: 1200)]);
    });

    test('uses server retryAfter hint for 429 rate limit', () async {
      final sleeps = <Duration>[];
      var callCount = 0;
      when(() => remoteDataSource.login(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return Result.failure(
            const ServerFailure(
              'Too many requests',
              code: '429',
              retryAfterMs: 2300,
            ),
          );
        }
        return Result.success(
          TokenResponse(accessToken: 'token-3b', refreshToken: 'refresh-3b'),
        );
      });

      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        secureStorage: secureStorage,
        sleep: (duration) async => sleeps.add(duration),
      );

      final result = await repository.login(
        username: 'user@example.com',
        password: 'pw',
      );

      expect(result, isA<Success>());
      verify(() => remoteDataSource.login(any())).called(2);
      expect(sleeps, [const Duration(milliseconds: 2300)]);
    });

    test('does not retry for non 409/429 failures', () async {
      when(() => remoteDataSource.login(any())).thenAnswer(
        (_) async =>
            Result.failure(const AuthFailure('Unauthorized', code: '401')),
      );

      final repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        secureStorage: secureStorage,
      );

      final result = await repository.login(
        username: 'user@example.com',
        password: 'pw',
      );

      expect(result, isA<Err>());
      verify(() => remoteDataSource.login(any())).called(1);
    });

    test(
      'returns failure when tokens are not persisted after success',
      () async {
        when(
          () => secureStorage.hasValidTokens(),
        ).thenAnswer((_) async => false);
        when(() => remoteDataSource.login(any())).thenAnswer(
          (_) async => Result.success(
            TokenResponse(accessToken: 'token-4', refreshToken: 'refresh-4'),
          ),
        );

        final repository = AuthRepositoryImpl(
          remoteDataSource: remoteDataSource,
          secureStorage: secureStorage,
        );

        final result = await repository.login(
          username: 'user@example.com',
          password: 'pw',
        );

        expect(result, isA<Err<AuthTokens>>());
        final failure = (result as Err<AuthTokens>).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.code, 'token_persist_failed');
      },
    );
  });

  test('persists tokens after explicit password account recovery', () async {
    AccountRecoveryPasswordRequest? capturedRequest;
    when(() => remoteDataSource.recoverWithPassword(any())).thenAnswer((
      invocation,
    ) async {
      capturedRequest =
          invocation.positionalArguments.first
              as AccountRecoveryPasswordRequest;
      return Result.success(
        const TokenResponse(accessToken: 'access', refreshToken: 'refresh'),
      );
    });
    final repository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      secureStorage: secureStorage,
    );

    final result = await repository.recoverWithPassword(
      email: ' Fan@Example.com ',
      password: 'secret',
    );

    expect(result, isA<Success<AuthTokens>>());
    expect(capturedRequest?.email, 'fan@example.com');
    expect(capturedRequest?.password, 'secret');
    verify(
      () => secureStorage.saveTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      ),
    ).called(1);
  });
}
