/// EN: Ad runtime configuration for hybrid sponsored slots.
/// KO: 하이브리드 스폰서 슬롯을 위한 광고 런타임 설정입니다.
library;

import 'package:flutter/foundation.dart';

import 'app_config.dart';

/// EN: Build-time configuration for optional AdMob inventory. The app ID is
///     configured by the Android manifest or iOS Info.plist; Dart build
///     defines control opt-in and unit selection only.
/// KO: 선택적 AdMob 인벤토리를 위한 빌드 시 구성입니다. 앱 ID는 Android
///     매니페스트 또는 iOS Info.plist에서 구성하며, Dart 빌드 정의는 광고
///     사용 여부와 유닛 선택만 제어합니다.
class AdConfig {
  AdConfig._();

  static const String _enabledValue = String.fromEnvironment(
    'ADMOB_ENABLED',
    defaultValue: 'false',
  );

  /// EN: AdMob remains disabled until a build explicitly opts in.
  /// KO: 빌드에서 명시적으로 활성화할 때까지 AdMob을 비활성화합니다.
  static bool get isEnabled => _enabledValue.trim().toLowerCase() == 'true';

  static const String _androidHomeNativeUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_NATIVE_HOME_UNIT_ID',
    defaultValue: '',
  );
  static const String _iosHomeNativeUnitId = String.fromEnvironment(
    'ADMOB_IOS_NATIVE_HOME_UNIT_ID',
    defaultValue: '',
  );
  static const String _androidBoardNativeUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_NATIVE_BOARD_UNIT_ID',
    defaultValue: '',
  );
  static const String _iosBoardNativeUnitId = String.fromEnvironment(
    'ADMOB_IOS_NATIVE_BOARD_UNIT_ID',
    defaultValue: '',
  );

  static const String _androidTestNativeUnitId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _iosTestNativeUnitId =
      'ca-app-pub-3940256099942544/3986624511';

  /// EN: Resolve the only supported network unit for a slot.
  ///     Staging/development always use Google's test inventory, even if the
  ///     server accidentally returns a production unit. Unknown networks and
  ///     disabled builds fail closed.
  /// KO: 슬롯에 사용할 유일하게 지원되는 네트워크 유닛을 해석합니다.
  ///     서버가 운영 유닛을 보내더라도 staging/development는 항상 Google
  ///     테스트 인벤토리를 사용합니다. 알 수 없는 네트워크와 비활성화 빌드는
  ///     안전하게 광고를 표시하지 않습니다.
  static String? resolveNativeUnitId(
    String slotKey, {
    String? serverUnitId,
    bool serverNetworkIsAdMob = true,
    bool? enabled,
    Environment? environment,
    TargetPlatform? platform,
  }) {
    final resolvedEnabled = enabled ?? isEnabled;
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    final resolvedEnvironment = environment ?? AppConfig.instance.environment;
    if (!resolvedEnabled ||
        !_isSupportedPlatform(resolvedPlatform) ||
        !serverNetworkIsAdMob) {
      return null;
    }
    if (slotKey != 'home_primary' && slotKey != 'board_feed') {
      return null;
    }

    final isIos = resolvedPlatform == TargetPlatform.iOS;
    if (resolvedEnvironment != Environment.production) {
      return isIos ? _iosTestNativeUnitId : _androidTestNativeUnitId;
    }

    final serverValue = serverUnitId?.trim();
    if (serverValue != null && serverValue.isNotEmpty) {
      return serverValue;
    }

    final configured = switch (slotKey) {
      'home_primary' => isIos ? _iosHomeNativeUnitId : _androidHomeNativeUnitId,
      'board_feed' => isIos ? _iosBoardNativeUnitId : _androidBoardNativeUnitId,
      _ => '',
    };
    if (configured.trim().isNotEmpty) {
      return configured.trim();
    }
    return null;
  }

  static bool _isSupportedPlatform(TargetPlatform platform) {
    if (kIsWeb) return false;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }
}
