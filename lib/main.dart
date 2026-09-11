/// EN: Application entry point
/// KO: 앱 진입점
library;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/logging/app_logger.dart';
import 'core/notifications/firebase_runtime_options.dart';
import 'core/notifications/remote_push_service.dart';
import 'core/providers/core_providers.dart';
import 'core/theme/gbt_font_licenses.dart';

Future<void> main() async {
  // EN: Ensure Flutter bindings are initialized
  // KO: Flutter 바인딩 초기화 확인
  WidgetsFlutterBinding.ensureInitialized();
  registerGBTFontLicenses();

  // EN: Resolve APP_ENV before any provider or telemetry can access storage or
  //     the API. Unknown values fail closed instead of silently selecting prod.
  // KO: 프로바이더나 텔레메트리가 저장소/API에 접근하기 전에 APP_ENV를
  //     해석합니다. 알 수 없는 값은 운영 환경으로 묵인하지 않고 중단합니다.
  final environment = AppConfig.environmentFromBuild();
  AppConfig.instance.init(environment: environment);

  // EN: Initialize Firebase (required before Crashlytics / Messaging).
  // KO: Crashlytics / Messaging 사용 전에 Firebase를 초기화합니다.
  final firebaseOptions = FirebaseRuntimeOptions.resolveForCurrentPlatform();
  if (firebaseOptions != null) {
    await Firebase.initializeApp(options: firebaseOptions);
  } else {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // EN: No google-services.json / GoogleService-Info.plist — skip Firebase.
      // KO: google-services.json / GoogleService-Info.plist 없음 — Firebase 초기화 건너뜁니다.
    }
  }

  // EN: Route Flutter framework errors to Crashlytics.
  // KO: Flutter 프레임워크 에러를 Crashlytics로 라우팅합니다.
  if (!kIsWeb) {
    try {
      // EN: Disable Crashlytics collection in debug/dev builds.
      // KO: 디버그/개발 빌드에서 Crashlytics 수집을 비활성화합니다.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        AppConfig.instance.environment != Environment.development,
      );
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (_) {
      // EN: Crashlytics not available (e.g. no Firebase config) — skip gracefully.
      // KO: Crashlytics 사용 불가(Firebase 설정 없음 등) — 무시합니다.
    }
  }

  AppLogger.info('App starting', tag: 'Main');
  AppLogger.info('Environment: ${AppConfig.instance.environment.name}');
  AppLogger.info('Base URL: ${AppConfig.instance.baseUrl}');

  // EN: Set preferred orientations
  // KO: 선호 방향 설정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // EN: Enable edge-to-edge mode — app renders behind system bars on Android.
  //     iOS handles this natively via SafeArea / home indicator insets.
  // KO: 엣지 투 엣지 모드 활성화 — Android에서 앱이 시스템 바 뒤까지 렌더링됩니다.
  //     iOS는 SafeArea / 홈 인디케이터 인셋으로 자동 처리됩니다.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // EN: Initial overlay style — transparent bars, icon brightness set at runtime
  //     via AnnotatedRegion in app.dart based on the active theme.
  // KO: 초기 오버레이 스타일 — 투명 바, 아이콘 밝기는 app.dart의 AnnotatedRegion에서
  //     활성 테마에 따라 런타임에 설정됩니다.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // EN: Create provider container for pre-initialization
  // KO: 사전 초기화를 위한 프로바이더 컨테이너 생성
  final container = ProviderContainer();

  // EN: Register Firebase Messaging background handler before runApp.
  // KO: runApp 이전에 Firebase Messaging 백그라운드 핸들러를 등록합니다.
  registerRemotePushBackgroundHandler();

  // EN: Initialize Sentry and run the app inside its error zone.
  //     DSN is injected at build time via --dart-define=SENTRY_DSN=<value>.
  // KO: Sentry를 초기화하고 에러 존 내에서 앱을 실행합니다.
  //     DSN은 빌드 시 --dart-define=SENTRY_DSN=<value>로 주입합니다.
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.environment = AppConfig.instance.environment.name;
      // EN: Sample 20% of transactions for performance tracing.
      // KO: 성능 트레이싱을 위해 트랜잭션의 20%를 샘플링합니다.
      options.tracesSampleRate = 0.2;
      // EN: Do not send PII (user IP, name) to Sentry.
      // KO: 개인정보(사용자 IP, 이름)를 Sentry로 전송하지 않습니다.
      options.sendDefaultPii = false;
    },
    appRunner: () {
      // EN: Run the app with Riverpod
      // KO: Riverpod과 함께 앱 실행
      runApp(
        UncontrolledProviderScope(container: container, child: const GBTApp()),
      );

      // EN: Bootstrap critical services without blocking the first frame.
      // KO: 첫 프레임을 막지 않도록 핵심 서비스를 부트스트랩합니다.
      unawaited(_bootstrap(container));
    },
  );
}

/// EN: Non-blocking bootstrap for storage + auth checks.
/// KO: 스토리지 + 인증 확인을 위한 논블로킹 부트스트랩.
Future<void> _bootstrap(ProviderContainer container) async {
  try {
    // EN: Pre-initialize local storage.
    // KO: 로컬 저장소 사전 초기화.
    await container.read(localStorageProvider.future);

    // EN: Check authentication status.
    // KO: 인증 상태 확인.
    await container.read(authStateProvider.notifier).checkAuthStatus();

    // EN: Bootstrap telemetry — restore device-banned flag from SharedPreferences.
    // KO: 텔레메트리 부트스트랩 — SharedPreferences에서 기기 차단 플래그를 복원합니다.
    container.read(telemetryBootstrapProvider);

    AppLogger.info('App initialization complete', tag: 'Main');
  } catch (error, stackTrace) {
    AppLogger.error(
      'App bootstrap failed',
      error: error,
      stackTrace: stackTrace,
      tag: 'Main',
    );
  }
}
