/// EN: Result type for Railway-Oriented Programming pattern
/// KO: Railway-Oriented Programming 패턴을 위한 Result 타입
library;

import '../error/failure.dart';

/// EN: Result type representing either success or failure
/// KO: 성공 또는 실패를 나타내는 Result 타입
sealed class Result<T> {
  const Result();

  /// EN: Creates a successful result with data
  /// KO: 데이터와 함께 성공 결과 생성
  const factory Result.success(T data) = Success<T>;

  /// EN: Creates a failure result with error
  /// KO: 에러와 함께 실패 결과 생성
  const factory Result.failure(Failure failure) = Err<T>;

  /// EN: Check if result is successful
  /// KO: 결과가 성공인지 확인
  bool get isSuccess => this is Success<T>;

  /// EN: Check if result is failure
  /// KO: 결과가 실패인지 확인
  bool get isFailure => this is Err<T>;

  /// EN: Get data if success, null otherwise
  /// KO: 성공 시 데이터 반환, 아니면 null
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Err() => null,
  };

  /// EN: Get failure if error, null otherwise
  /// KO: 실패 시 Failure 반환, 아니면 null
  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Err(:final failure) => failure,
  };

  /// EN: Pattern matching for Result
  /// KO: Result에 대한 패턴 매칭
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Err(failure: final f) => failure(f),
    };
  }

  /// EN: Pattern matching with async callbacks
  /// KO: 비동기 콜백을 사용한 패턴 매칭
  Future<R> whenAsync<R>({
    required Future<R> Function(T data) success,
    required Future<R> Function(Failure failure) failure,
  }) async {
    return switch (this) {
      Success(:final data) => await success(data),
      Err(failure: final f) => await failure(f),
    };
  }

  /// EN: Map success value to new type
  /// KO: 성공 값을 새 타입으로 매핑
  Result<R> map<R>(R Function(T data) mapper) {
    return switch (this) {
      Success(:final data) => Result.success(mapper(data)),
      Err(:final failure) => Result.failure(failure),
    };
  }

  /// EN: FlatMap success value to new Result
  /// KO: 성공 값을 새 Result로 플랫맵
  Result<R> flatMap<R>(Result<R> Function(T data) mapper) {
    return switch (this) {
      Success(:final data) => mapper(data),
      Err(:final failure) => Result.failure(failure),
    };
  }

  /// EN: Get data or throw exception
  /// KO: 데이터를 반환하거나 예외 발생
  T getOrThrow() {
    return switch (this) {
      Success(:final data) => data,
      Err(:final failure) => throw failure,
    };
  }

  /// EN: Get data or default value
  /// KO: 데이터를 반환하거나 기본값 반환
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success(:final data) => data,
      Err() => defaultValue,
    };
  }

  /// EN: Get data or compute default value
  /// KO: 데이터를 반환하거나 기본값 계산
  T getOrElseCompute(T Function(Failure failure) compute) {
    return switch (this) {
      Success(:final data) => data,
      Err(:final failure) => compute(failure),
    };
  }
}

/// EN: Success result containing data
/// KO: 데이터를 포함하는 성공 결과
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// EN: Failure result containing error
/// KO: 에러를 포함하는 실패 결과
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Err<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Err($failure)';
}

/// EN: Extension for converting Future to Result
/// KO: Future를 Result로 변환하는 확장
extension FutureResultExtension<T> on Future<T> {
  /// EN: Converts Future to Result, catching any errors
  /// KO: 에러를 캐치하며 Future를 Result로 변환
  Future<Result<T>> toResult({
    Failure Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      final data = await this;
      return Result.success(data);
    } catch (e, stackTrace) {
      if (onError != null) {
        return Result.failure(onError(e, stackTrace));
      }
      if (e is Failure) {
        return Result.failure(e);
      }
      return Result.failure(
        UnknownFailure(e.toString(), stackTrace: stackTrace),
      );
    }
  }
}
