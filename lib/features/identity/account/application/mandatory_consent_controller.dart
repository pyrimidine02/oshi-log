/// EN: Mandatory consent gate controller for authenticated sessions.
/// KO: 인증 세션의 필수 동의 게이트 컨트롤러입니다.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/logging/app_logger.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'settings_controller.dart';

@immutable
class RequiredConsentStatusItem {
  const RequiredConsentStatusItem({
    required this.type,
    required this.requiredVersion,
    required this.policyUrl,
    required this.agreed,
    required this.agreedVersion,
    required this.agreedAt,
    required this.needsReconsent,
  });

  final String type;
  final String requiredVersion;
  final String policyUrl;
  final bool agreed;
  final String? agreedVersion;
  final String? agreedAt;
  final bool needsReconsent;

  factory RequiredConsentStatusItem.fromJson(Map<String, dynamic> json) {
    final requiredRaw = json.containsKey('needsReconsent')
        ? json['needsReconsent']
        : (json['required'] ?? json['isRequired']);
    return RequiredConsentStatusItem(
      type: (json['type'] as String?)?.trim() ?? 'UNKNOWN',
      requiredVersion: (json['requiredVersion'] as String?)?.trim() ?? '-',
      policyUrl: (json['policyUrl'] as String?)?.trim() ?? '',
      agreed: _parseBool(json['agreed']),
      agreedVersion: (json['agreedVersion'] as String?)?.trim(),
      agreedAt: (json['agreedAt'] as String?)?.trim(),
      needsReconsent: _parseBool(requiredRaw),
    );
  }
}

@immutable
class MandatoryConsentStatusPayload {
  const MandatoryConsentStatusPayload({
    required this.canUseService,
    required this.requiredConsents,
  });

  final bool canUseService;
  final List<RequiredConsentStatusItem> requiredConsents;

  factory MandatoryConsentStatusPayload.fromJson(Map<String, dynamic> json) {
    final rawConsents = json['requiredConsents'];
    final requiredConsents = rawConsents is List
        ? rawConsents
              .whereType<Map<String, dynamic>>()
              .map(RequiredConsentStatusItem.fromJson)
              .toList(growable: false)
        : const <RequiredConsentStatusItem>[];
    return MandatoryConsentStatusPayload(
      canUseService: _parseBool(json['canUseService']),
      requiredConsents: requiredConsents,
    );
  }
}

class MandatoryConsentState {
  const MandatoryConsentState({
    required this.isLoading,
    required this.hasResolved,
    required this.isRequired,
    required this.isSubmitting,
    required this.requiredConsents,
    this.errorMessage,
    this.errorCode,
    this.requestId,
  });

  const MandatoryConsentState.idle()
    : isLoading = false,
      hasResolved = false,
      isRequired = false,
      isSubmitting = false,
      requiredConsents = const <RequiredConsentStatusItem>[],
      errorMessage = null,
      errorCode = null,
      requestId = null;

  final bool isLoading;
  final bool hasResolved;
  final bool isRequired;
  final bool isSubmitting;
  final List<RequiredConsentStatusItem> requiredConsents;
  final String? errorMessage;
  final String? errorCode;
  final String? requestId;

  MandatoryConsentState copyWith({
    bool? isLoading,
    bool? hasResolved,
    bool? isRequired,
    bool? isSubmitting,
    List<RequiredConsentStatusItem>? requiredConsents,
    String? errorMessage,
    String? errorCode,
    String? requestId,
    bool clearErrorMessage = false,
    bool clearErrorCode = false,
    bool clearRequestId = false,
  }) {
    return MandatoryConsentState(
      isLoading: isLoading ?? this.isLoading,
      hasResolved: hasResolved ?? this.hasResolved,
      isRequired: isRequired ?? this.isRequired,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      requiredConsents: requiredConsents ?? this.requiredConsents,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      errorCode: clearErrorCode ? null : (errorCode ?? this.errorCode),
      requestId: clearRequestId ? null : (requestId ?? this.requestId),
    );
  }
}

class MandatoryConsentController extends StateNotifier<MandatoryConsentState> {
  MandatoryConsentController(this._ref)
    : super(const MandatoryConsentState.idle());

  final Ref _ref;
  bool _refreshing = false;

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      if (!_ref.read(isAuthenticatedProvider)) {
        state = const MandatoryConsentState.idle();
        return;
      }

      state = state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
        clearErrorCode: true,
        clearRequestId: true,
      );

      final repository = await _ref.read(settingsRepositoryProvider.future);
      final result = await repository.getMandatoryConsentStatus();

      if (result is Success<Map<String, dynamic>>) {
        final payload = parseMandatoryConsentStatusPayload(result.data);
        final mandatoryConsents = extractMandatoryConsentItems(
          consents: payload.requiredConsents,
        );
        final hasRequiredConsentSet = containsAllMandatoryConsentTypes(
          consents: mandatoryConsents,
        );
        final blockingConsents = resolveBlockingRequiredConsents(
          consents: mandatoryConsents,
        );
        final shouldBlock =
            !payload.canUseService ||
            blockingConsents.isNotEmpty ||
            !hasRequiredConsentSet;
        state = MandatoryConsentState(
          isLoading: false,
          hasResolved: true,
          isRequired: shouldBlock,
          isSubmitting: false,
          requiredConsents: mandatoryConsents,
          errorMessage: hasRequiredConsentSet
              ? null
              : '필수 약관 정책 정보를 다시 불러와주세요.',
        );
        return;
      }

      if (result is Err<Map<String, dynamic>>) {
        _applyRefreshFailure(result.failure);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Mandatory consent refresh failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'MandatoryConsentController',
      );
      state = state.copyWith(
        isLoading: false,
        hasResolved: true,
        isRequired: true,
        isSubmitting: false,
        requiredConsents: const <RequiredConsentStatusItem>[],
        errorMessage: '동의 상태를 확인하지 못했어요. 잠시 후 다시 시도해주세요.',
        clearErrorCode: true,
        clearRequestId: true,
      );
    } finally {
      _refreshing = false;
    }
  }

  Future<bool> submitRequiredConsents({
    required Map<String, bool> agreedByType,
  }) async {
    if (!_ref.read(isAuthenticatedProvider)) {
      state = state.copyWith(
        isRequired: true,
        errorMessage: '로그인 후 동의할 수 있어요.',
      );
      return false;
    }

    final requiredConsents = state.requiredConsents;
    if (requiredConsents.isEmpty) {
      state = state.copyWith(
        isRequired: true,
        errorMessage: '동의 상태를 다시 확인해주세요.',
      );
      return false;
    }

    final mandatoryConsents = extractMandatoryConsentItems(
      consents: requiredConsents,
    );
    if (!containsAllMandatoryConsentTypes(consents: mandatoryConsents)) {
      state = state.copyWith(
        isRequired: true,
        errorMessage: '필수 동의 정책 정보를 다시 확인해주세요.',
      );
      return false;
    }

    final blockingConsents = resolveBlockingRequiredConsents(
      consents: mandatoryConsents,
    );
    final hasUnchecked = blockingConsents.any(
      (item) => agreedByType[item.type] != true,
    );
    if (hasUnchecked) {
      state = state.copyWith(
        isRequired: true,
        errorMessage: '필수 동의 항목을 모두 체크해주세요.',
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearErrorMessage: true,
      clearErrorCode: true,
      clearRequestId: true,
    );

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final payload = mandatoryConsents
          .map(
            (item) => {
              'type': item.type,
              'version': item.requiredVersion,
              'agreed': true,
              'agreedAt': now,
            },
          )
          .toList(growable: false);

      final repository = await _ref.read(settingsRepositoryProvider.future);
      final result = await repository.submitMandatoryConsents(
        consents: payload,
      );

      if (result is Err<void>) {
        _applySubmitFailure(result.failure);
        return false;
      }

      await refresh();
      return !state.isRequired;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Mandatory consent submit failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'MandatoryConsentController',
      );
      state = state.copyWith(
        isSubmitting: false,
        hasResolved: true,
        isRequired: true,
        errorMessage: '동의 제출에 실패했습니다. 다시 시도해주세요.',
      );
      return false;
    }
  }

  void clear() {
    state = const MandatoryConsentState.idle();
  }

  void _applyRefreshFailure(Failure failure) {
    if (_isUnauthorizedFailure(failure)) {
      _ref.read(authStateProvider.notifier).setUnauthenticated();
      state = const MandatoryConsentState.idle();
      return;
    }
    state = state.copyWith(
      isLoading: false,
      hasResolved: true,
      isRequired: true,
      isSubmitting: false,
      requiredConsents: const <RequiredConsentStatusItem>[],
      errorMessage: _mapConsentFailureMessage(
        failure,
        fallback: '동의 상태를 확인하지 못했어요. 잠시 후 다시 시도해주세요.',
      ),
      errorCode: failure.code,
      requestId: _extractRequestId(failure.message),
    );
  }

  void _applySubmitFailure(Failure failure) {
    if (_isUnauthorizedFailure(failure)) {
      _ref.read(authStateProvider.notifier).setUnauthenticated();
      state = const MandatoryConsentState.idle();
      return;
    }
    state = state.copyWith(
      isLoading: false,
      hasResolved: true,
      isRequired: true,
      isSubmitting: false,
      errorMessage: _mapConsentFailureMessage(
        failure,
        fallback: '동의 제출에 실패했습니다. 다시 시도해주세요.',
      ),
      errorCode: failure.code,
      requestId: _extractRequestId(failure.message),
    );
  }

  bool _isUnauthorizedFailure(Failure failure) {
    if (failure is! AuthFailure) {
      return false;
    }
    final code = failure.code?.trim().toLowerCase();
    return code == '401' || code == 'auth_required';
  }
}

MandatoryConsentStatusPayload parseMandatoryConsentStatusPayload(dynamic json) {
  if (json is Map<String, dynamic>) {
    return MandatoryConsentStatusPayload.fromJson(json);
  }
  return const MandatoryConsentStatusPayload(
    canUseService: false,
    requiredConsents: <RequiredConsentStatusItem>[],
  );
}

const Set<String> _mandatoryConsentTypes = <String>{
  'TERMS_OF_SERVICE',
  'PRIVACY_POLICY',
  'LOCATION_TERMS',
};

List<RequiredConsentStatusItem> extractMandatoryConsentItems({
  required List<RequiredConsentStatusItem> consents,
}) {
  final byType = <String, RequiredConsentStatusItem>{};
  for (final consent in consents) {
    final normalizedType = consent.type.toUpperCase();
    if (_mandatoryConsentTypes.contains(normalizedType)) {
      byType[normalizedType] = consent;
    }
  }
  return _mandatoryConsentTypes
      .where(byType.containsKey)
      .map((type) => byType[type]!)
      .toList(growable: false);
}

bool containsAllMandatoryConsentTypes({
  required List<RequiredConsentStatusItem> consents,
}) {
  final types = consents
      .map((item) => item.type.toUpperCase())
      .where(_mandatoryConsentTypes.contains)
      .toSet();
  return types.length == _mandatoryConsentTypes.length;
}

List<RequiredConsentStatusItem> resolveBlockingRequiredConsents({
  required List<RequiredConsentStatusItem> consents,
}) {
  return consents.where(isBlockingRequiredConsent).toList(growable: false);
}

bool isBlockingRequiredConsent(RequiredConsentStatusItem item) {
  return item.needsReconsent || !item.agreed;
}

bool _parseBool(dynamic value) {
  return switch (value) {
    bool v => v,
    String v => v.toLowerCase() == 'true',
    num v => v != 0,
    _ => false,
  };
}

String _mapConsentFailureMessage(Failure failure, {required String fallback}) {
  switch (failure.code?.toUpperCase()) {
    case 'CONSENT_INVALID_TYPE':
      return '동의 항목 타입이 올바르지 않습니다.';
    case 'CONSENT_VERSION_INVALID':
      return '동의 버전 정보가 올바르지 않습니다.';
    case 'CONSENT_REQUIRED_FIELDS_MISSING':
      return '필수 동의 정보가 누락되었습니다.';
    case 'CONSENT_SUBMISSION_CONFLICT':
      return '동의 제출이 충돌했습니다. 다시 시도해주세요.';
    case 'CONSENT_STATUS_UNAVAILABLE':
      return '동의 상태를 불러올 수 없습니다. 다시 시도해주세요.';
    case 'CONSENT_POLICY_UNAVAILABLE':
      return '정책 문서 정보를 불러올 수 없습니다. 다시 시도해주세요.';
    default:
      return failure.message.trim().isEmpty ? fallback : failure.message;
  }
}

String? _extractRequestId(String message) {
  final match = RegExp(r'(req_[A-Za-z0-9_]+)').firstMatch(message);
  return match?.group(1);
}

final mandatoryConsentControllerProvider =
    StateNotifierProvider<MandatoryConsentController, MandatoryConsentState>((
      ref,
    ) {
      final controller = MandatoryConsentController(ref);

      ref.listen<AuthState>(authStateProvider, (_, next) {
        switch (next) {
          case AuthState.authenticated:
            _scheduleMandatoryConsentRefresh(controller);
            break;
          case AuthState.unauthenticated:
          case AuthState.initial:
            _scheduleMandatoryConsentClear(controller);
            break;
        }
      });

      ref.listen<int>(authTokenRefreshTickProvider, (previous, next) {
        if (previous == null || previous == next) {
          return;
        }
        if (!ref.read(isAuthenticatedProvider)) {
          return;
        }
        _scheduleMandatoryConsentRefresh(controller);
      });

      if (ref.read(isAuthenticatedProvider)) {
        _scheduleMandatoryConsentRefresh(controller);
      }

      return controller;
    });

void _scheduleMandatoryConsentRefresh(MandatoryConsentController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(controller.refresh());
  });
}

void _scheduleMandatoryConsentClear(MandatoryConsentController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    controller.clear();
  });
}
