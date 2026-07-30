import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// EN: Source contract for the Oshi@log rename — user-visible strings must be
///     rebranded while machine identifiers stay untouched for compatibility.
/// KO: Oshi@log 리네임 소스 계약 — 사용자에게 보이는 문자열은 리브랜딩하되
///     기계 식별자는 호환성을 위해 그대로 유지해야 한다.
void main() {
  const displayName = 'Oshi@log';

  /// EN: Legacy branding literals that must disappear from presentation source.
  /// KO: 프레젠테이션 소스에서 사라져야 하는 레거시 브랜딩 리터럴.
  const legacyBrandLiterals = <String>[
    'Girls Band Tabi',
    'GirlsBandTabi',
    'GIRLS BAND TABI',
    '걸즈밴드타비',
    '걸즈밴드 타비',
    'GBT Notifications',
  ];

  String read(String path) => File(path).readAsStringSync();

  group('user-visible rename', () {
    test('pubspec package name changes without changing Store version', () {
      final pubspec = read('pubspec.yaml');
      expect(
        pubspec,
        matches(RegExp(r'^name:\s*oshi_log\s*$', multiLine: true)),
      );
      expect(
        pubspec,
        matches(RegExp(r'^version:\s*0\.0\.2\+1\s*$', multiLine: true)),
      );
    });

    test('English and Korean ARB appTitle are Oshi@log', () {
      for (final arb in const ['l10n/app_en.arb', 'l10n/app_ko.arb']) {
        final decoded = jsonDecode(read(arb)) as Map<String, dynamic>;
        expect(decoded['appTitle'], displayName, reason: '$arb appTitle');
      }
    });

    test('Android android:label is Oshi@log', () {
      expect(
        read('android/app/src/main/AndroidManifest.xml'),
        matches(RegExp('android:label\\s*=\\s*"$displayName"')),
      );
    });

    test('iOS display and bundle names are Oshi@log', () {
      final plist = read('ios/Runner/Info.plist');
      for (final key in const ['CFBundleDisplayName', 'CFBundleName']) {
        expect(
          plist,
          matches(RegExp('<key>$key</key>\\s*<string>$displayName</string>')),
          reason: '$key must be $displayName',
        );
      }
    });

    test('presentation source carries no legacy branding literals', () {
      const sources = <String>[
        'lib/app.dart',
        'lib/core/notifications/local_notifications_service.dart',
        'lib/core/notifications/remote_push_service.dart',
        'lib/features/auth/presentation/pages/login_page.dart',
        'lib/features/feed/presentation/pages/board_page.dart',
        'lib/features/home/presentation/field_home/field_home_page.dart',
        'lib/features/home/presentation/pages/home_page.dart',
        'lib/features/my/presentation/travel_passport/passport_document.dart',
        'lib/features/settings/presentation/pages/settings_page.dart',
      ];
      for (final source in sources) {
        final content = read(source);
        for (final literal in legacyBrandLiterals) {
          // EN: Assert on the boolean so a failure reports the file, not its whole body.
          // KO: 실패 시 파일 전체가 아닌 파일명이 보고되도록 불리언으로 단정한다.
          expect(
            content.contains(literal),
            isFalse,
            reason: '$source still contains "$literal"',
          );
        }
      }
    });
  });

  group('compatibility preservation', () {
    test('Android applicationId and namespace are unchanged', () {
      final gradle = read('android/app/build.gradle.kts');
      expect(
        gradle,
        matches(RegExp(r'namespace\s*=\s*"cc\.noraneko\.girlsbandtabi_app"')),
      );
      expect(
        gradle,
        matches(
          RegExp(r'applicationId\s*=\s*"cc\.noraneko\.girlsbandtabi_app"'),
        ),
      );
    });

    test('iOS bundle identifier is unchanged', () {
      final project = read('ios/Runner.xcodeproj/project.pbxproj');
      expect(
        project,
        contains('PRODUCT_BUNDLE_IDENTIFIER = cc.noraneko.girlsbandtabi;'),
      );
      expect(project, contains('DEVELOPMENT_TEAM = RGX6UT6Z8N;'));
      expect(
        project,
        contains('CODE_SIGN_ENTITLEMENTS = Runner/RunnerRelease.entitlements;'),
      );
      final entitlements = read('ios/Runner/RunnerRelease.entitlements');
      expect(entitlements, contains('<string>production</string>'));
      expect(
        entitlements,
        contains('<string>applinks:api.noraneko.cc</string>'),
      );
    });

    test('custom deep-link scheme girlsbandtabi is unchanged', () {
      expect(
        read('android/app/src/main/AndroidManifest.xml'),
        matches(RegExp(r'android:scheme\s*=\s*"girlsbandtabi"')),
      );
      expect(
        read('ios/Runner/Info.plist'),
        matches(
          RegExp(
            r'<key>CFBundleURLSchemes</key>\s*<array>\s*<string>girlsbandtabi</string>',
          ),
        ),
      );
    });

    test('FCM channel id gbt_notifications_high is unchanged', () {
      expect(
        read('lib/core/notifications/remote_push_service.dart'),
        contains('gbt_notifications_high'),
      );
      expect(
        read('lib/core/notifications/local_notifications_service.dart'),
        contains('gbt_notifications_high'),
      );
      expect(
        read('android/app/src/main/AndroidManifest.xml'),
        contains('gbt_notifications_high'),
      );
    });

    test('legal policy URLs and legacy media buckets are unchanged', () {
      final policies = read('lib/core/constants/legal_policy_constants.dart');
      for (final path in const ['terms', 'privacy', 'location']) {
        expect(policies, contains('https://girlsbandtabi.app/policies/$path'));
      }
      final mediaUrl = read('lib/core/utils/media_url.dart');
      expect(mediaUrl, contains("'girlsbandtabi'"));
      expect(mediaUrl, contains("'girlsbandtabi-dev'"));
    });

    test('Firebase, OAuth, and cache identifiers are unchanged', () {
      final iosServices = read('ios/Runner/GoogleService-Info.plist');
      expect(
        iosServices,
        matches(
          RegExp(
            r'<key>BUNDLE_ID</key>\s*<string>cc\.noraneko\.girlsbandtabi</string>',
          ),
        ),
      );
      expect(iosServices, contains('<string>girlsbandtabi-5aa61</string>'));

      final infoPlist = read('ios/Runner/Info.plist');
      expect(
        infoPlist,
        contains(
          '413403814343-oajha5te1pv9h2dpe0ba7h8te3j578kc.apps.googleusercontent.com',
        ),
      );
      expect(
        infoPlist,
        contains(
          'com.googleusercontent.apps.413403814343-oajha5te1pv9h2dpe0ba7h8te3j578kc',
        ),
      );
      expect(
        read('lib/core/cache/cache_manager.dart'),
        contains("static const String _namespace = 'gbt_cache';"),
      );
    });
  });
}
