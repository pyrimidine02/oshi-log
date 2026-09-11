/// EN: Consent-gated lifecycle for optional AdMob requests.
/// KO: 선택적 AdMob 요청을 위한 동의 기반 생명주기입니다.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/ad_config.dart';

/// EN: Result of preparing the optional ads SDK.
/// KO: 선택적 광고 SDK 준비 결과입니다.
enum AdsReadiness { disabled, denied, ready }

/// EN: Small adapter boundary that keeps platform SDK calls testable.
/// KO: 플랫폼 SDK 호출을 테스트 가능하게 만드는 작은 어댑터 경계입니다.
abstract interface class AdsSdkAdapter {
  /// EN: Refresh consent metadata from the UMP service.
  /// KO: UMP 서비스에서 동의 메타데이터를 갱신합니다.
  Future<void> requestConsentInfoUpdate();

  /// EN: Show the consent form when the SDK says it is required.
  /// KO: SDK가 필요하다고 판단할 때 동의 양식을 표시합니다.
  Future<void> loadAndShowConsentFormIfRequired();

  /// EN: Return whether an ad request is currently allowed.
  /// KO: 현재 광고 요청이 허용되는지 반환합니다.
  Future<bool> canRequestAds();

  /// EN: Return whether the privacy-options entry point is required.
  /// KO: 개인정보 옵션 진입점이 필요한지 반환합니다.
  Future<PrivacyOptionsRequirementStatus> getPrivacyOptionsRequirementStatus();

  /// EN: Initialize the Mobile Ads SDK after consent is ready.
  /// KO: 동의가 준비된 뒤 Mobile Ads SDK를 초기화합니다.
  Future<void> initialize();

  /// EN: Present the UMP privacy-options form.
  /// KO: UMP 개인정보 옵션 양식을 표시합니다.
  Future<bool> showPrivacyOptionsForm();
}

/// EN: Production adapter for Google Mobile Ads 6.x and UMP.
/// KO: Google Mobile Ads 6.x 및 UMP용 운영 어댑터입니다.
class GoogleAdsSdkAdapter implements AdsSdkAdapter {
  const GoogleAdsSdkAdapter();

  @override
  Future<void> requestConsentInfoUpdate() {
    final completer = Completer<void>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          if (!completer.isCompleted) completer.complete();
        },
        (error) {
          if (!completer.isCompleted) {
            completer.completeError(
              StateError('Consent information update failed'),
            );
          }
        },
      );
    } catch (error, stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    }
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw StateError('Consent information update timed out'),
    );
  }

  @override
  Future<void> loadAndShowConsentFormIfRequired() async {
    try {
      // EN: Await the SDK Future. In SDK 6 this call can fail asynchronously
      //     through a MethodChannel, before the dismissal callback runs.
      // KO: SDK 6에서는 MethodChannel을 통한 비동기 실패가 닫힘 콜백보다
      //     먼저 발생할 수 있으므로 SDK Future를 await합니다.
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) throw StateError('Consent form failed');
      });
    } catch (_) {
      throw StateError('Consent form failed');
    }
  }

  @override
  Future<bool> canRequestAds() {
    return ConsentInformation.instance.canRequestAds();
  }

  @override
  Future<PrivacyOptionsRequirementStatus> getPrivacyOptionsRequirementStatus() {
    return ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
  }

  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  @override
  Future<bool> showPrivacyOptionsForm() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) throw StateError('Privacy options failed');
      });
    } catch (_) {
      return false;
    }
    return true;
  }
}

/// EN: Coordinates consent and one-time SDK initialization for ad widgets.
///     Network requests remain disabled unless ADMOB_ENABLED=true is supplied.
/// KO: 광고 위젯의 동의와 SDK 1회 초기화를 조정합니다. ADMOB_ENABLED=true를
///     명시하지 않으면 네트워크 요청은 계속 비활성화됩니다.
class AdsRuntimeService {
  AdsRuntimeService({AdsSdkAdapter? adapter, bool? enabled, bool? supported})
    : _adapter = adapter ?? const GoogleAdsSdkAdapter(),
      _enabled = enabled ?? AdConfig.isEnabled,
      _supported = supported ?? _isSupportedPlatform;

  final AdsSdkAdapter _adapter;
  final bool _enabled;
  final bool _supported;
  Future<AdsReadiness>? _initialization;
  AdsReadiness _readiness = AdsReadiness.disabled;
  bool _sdkInitialized = false;
  final StreamController<AdsReadiness> _readinessChanges =
      StreamController<AdsReadiness>.broadcast();

  /// EN: Current SDK readiness.
  /// KO: 현재 SDK 준비 상태입니다.
  AdsReadiness get readiness => _readiness;

  /// EN: Emits readiness changes so mounted ad views can dispose stale ads
  ///     after a user withdraws consent.
  /// KO: 사용자가 동의를 철회한 뒤 마운트된 광고 뷰가 오래된 광고를
  ///     폐기할 수 있도록 준비 상태 변경을 발행합니다.
  Stream<AdsReadiness> get readinessChanges => _readinessChanges.stream;

  /// EN: Prepare consent and initialize Mobile Ads exactly once.
  /// KO: 동의를 준비하고 Mobile Ads를 정확히 한 번 초기화합니다.
  Future<AdsReadiness> ensureReady() {
    if (!_enabled || !_supported) {
      _setReadiness(AdsReadiness.disabled);
      return Future<AdsReadiness>.value(_readiness);
    }
    if (_readiness == AdsReadiness.ready && _sdkInitialized) {
      return Future<AdsReadiness>.value(_readiness);
    }
    return _initialization ??= _initializeOnce();
  }

  Future<AdsReadiness> _initializeOnce() async {
    try {
      await _adapter.requestConsentInfoUpdate();
      await _adapter.loadAndShowConsentFormIfRequired();
      final canRequestAds = await _adapter.canRequestAds();
      if (!canRequestAds) {
        _setReadiness(AdsReadiness.denied);
        return _readiness;
      }
      await _initializeSdkIfNeeded();
      _setReadiness(AdsReadiness.ready);
    } catch (_) {
      // EN: Unknown consent/network failures fail closed.
      // KO: 알 수 없는 동의/네트워크 실패는 안전하게 차단합니다.
      _setReadiness(AdsReadiness.denied);
    }
    return _readiness;
  }

  /// EN: Open privacy options after refreshing consent state.
  /// KO: 동의 상태를 갱신한 뒤 개인정보 옵션을 엽니다.
  Future<bool> showPrivacyOptions() async {
    if (!_enabled || !_supported) return false;
    await ensureReady();
    if (_readiness == AdsReadiness.disabled) return false;
    try {
      final opened = await _adapter.showPrivacyOptionsForm();
      if (!opened) return false;

      // EN: Re-read consent after the form closes. A previous ready result is
      //     invalid if the user withdrew consent in the form.
      // KO: 양식이 닫힌 후 동의를 다시 읽습니다. 사용자가 철회했다면
      //     이전의 ready 결과를 더 이상 사용하지 않습니다.
      final canRequestAds = await _adapter.canRequestAds();
      if (canRequestAds) {
        await _initializeSdkIfNeeded();
        _setReadiness(AdsReadiness.ready);
      } else {
        _setReadiness(AdsReadiness.denied);
      }
      // EN: Replace the completed future with the current consent decision so
      //     ensureReady cannot return a stale pre-form result.
      // KO: 완료된 Future를 현재 동의 결정으로 교체해 ensureReady가 양식
      //     이전의 오래된 결과를 반환하지 않게 합니다.
      _initialization = Future<AdsReadiness>.value(_readiness);
      return true;
    } catch (_) {
      _setReadiness(AdsReadiness.denied);
      _initialization = Future<AdsReadiness>.value(_readiness);
      return false;
    }
  }

  /// EN: Return the UMP privacy-options requirement status for settings UI.
  /// KO: 설정 UI에서 사용할 UMP 개인정보 옵션 필요 상태를 반환합니다.
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async {
    if (!_enabled || !_supported) {
      return PrivacyOptionsRequirementStatus.unknown;
    }
    await ensureReady();
    try {
      return await _adapter.getPrivacyOptionsRequirementStatus();
    } catch (_) {
      return PrivacyOptionsRequirementStatus.unknown;
    }
  }

  /// EN: Whether settings should expose the UMP privacy-options entry point.
  /// KO: 설정에서 UMP 개인정보 옵션 진입점을 노출해야 하는지 반환합니다.
  Future<bool> isPrivacyOptionsRequired() async {
    return await getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  /// EN: Release the broadcast stream when the Riverpod provider is disposed.
  /// KO: Riverpod 프로바이더가 폐기될 때 broadcast 스트림을 해제합니다.
  void dispose() {
    _readinessChanges.close();
  }

  void _setReadiness(AdsReadiness value) {
    if (_readiness == value) return;
    _readiness = value;
    if (!_readinessChanges.isClosed) _readinessChanges.add(value);
  }

  Future<void> _initializeSdkIfNeeded() async {
    if (_sdkInitialized) return;
    await _adapter.initialize();
    _sdkInitialized = true;
  }

  static bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
