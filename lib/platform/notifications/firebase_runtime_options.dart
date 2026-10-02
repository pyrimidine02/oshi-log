/// EN: Runtime Firebase options resolver for platforms without bundled config files.
/// KO: 번들 설정 파일 없이 실행할 때 사용할 런타임 Firebase 옵션 해석기입니다.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
const String _messagingSenderId = String.fromEnvironment(
  'FIREBASE_MESSAGING_SENDER_ID',
);
const String _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const String _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
const String _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
const String _measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

const String _androidApiKey = String.fromEnvironment(
  'FIREBASE_ANDROID_API_KEY',
);
const String _androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
const String _androidMessagingSenderId = String.fromEnvironment(
  'FIREBASE_ANDROID_MESSAGING_SENDER_ID',
);
const String _androidProjectId = String.fromEnvironment(
  'FIREBASE_ANDROID_PROJECT_ID',
);
const String _androidStorageBucket = String.fromEnvironment(
  'FIREBASE_ANDROID_STORAGE_BUCKET',
);

const String _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
const String _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
const String _iosMessagingSenderId = String.fromEnvironment(
  'FIREBASE_IOS_MESSAGING_SENDER_ID',
);
const String _iosProjectId = String.fromEnvironment('FIREBASE_IOS_PROJECT_ID');
const String _iosStorageBucket = String.fromEnvironment(
  'FIREBASE_IOS_STORAGE_BUCKET',
);
const String _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

class FirebaseRuntimeOptions {
  const FirebaseRuntimeOptions._();

  /// EN: Returns platform Firebase options when enough dart-defines are present.
  /// KO: 필요한 dart-define 값이 있으면 플랫폼용 Firebase 옵션을 반환합니다.
  static FirebaseOptions? resolveForCurrentPlatform() {
    if (kIsWeb) {
      return null;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidOptions();
      case TargetPlatform.iOS:
        return _iosOptions();
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  static FirebaseOptions? _androidOptions() {
    final apiKey = _pick(_androidApiKey, _apiKey);
    final appId = _pick(_androidAppId, _appId);
    final messagingSenderId = _pick(
      _androidMessagingSenderId,
      _messagingSenderId,
    );
    final projectId = _pick(_androidProjectId, _projectId);
    if (!_hasRequired(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
    )) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: _pick(_androidStorageBucket, _storageBucket),
    );
  }

  static FirebaseOptions? _iosOptions() {
    final apiKey = _pick(_iosApiKey, _apiKey);
    final appId = _pick(_iosAppId, _appId);
    final messagingSenderId = _pick(_iosMessagingSenderId, _messagingSenderId);
    final projectId = _pick(_iosProjectId, _projectId);
    final bundleId = _iosBundleId.trim();
    if (!_hasRequired(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
        ) ||
        bundleId.isEmpty) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: _pick(_iosStorageBucket, _storageBucket),
      iosBundleId: bundleId,
      authDomain: _authDomain.trim().isEmpty ? null : _authDomain.trim(),
      measurementId: _measurementId.trim().isEmpty
          ? null
          : _measurementId.trim(),
    );
  }

  static String _pick(String primary, String fallback) {
    final normalizedPrimary = primary.trim();
    if (normalizedPrimary.isNotEmpty) {
      return normalizedPrimary;
    }
    return fallback.trim();
  }

  static bool _hasRequired({
    required String apiKey,
    required String appId,
    required String messagingSenderId,
    required String projectId,
  }) {
    return apiKey.isNotEmpty &&
        appId.isNotEmpty &&
        messagingSenderId.isNotEmpty &&
        projectId.isNotEmpty;
  }
}
