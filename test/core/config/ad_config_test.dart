import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/config/ad_config.dart';
import 'package:oshi_log/core/config/app_config.dart';

void main() {
  test('disabled builds fail closed before selecting an ad unit', () {
    expect(
      AdConfig.resolveNativeUnitId(
        'home_primary',
        enabled: false,
        platform: TargetPlatform.android,
      ),
      isNull,
    );
  });

  test('development and staging use test inventory even with server ids', () {
    final development = AdConfig.resolveNativeUnitId(
      'home_primary',
      enabled: true,
      environment: Environment.development,
      platform: TargetPlatform.android,
      serverUnitId: 'ca-app-pub-production/home',
    );
    final staging = AdConfig.resolveNativeUnitId(
      'board_feed',
      enabled: true,
      environment: Environment.staging,
      platform: TargetPlatform.iOS,
      serverUnitId: 'ca-app-pub-production/board',
    );

    expect(development, 'ca-app-pub-3940256099942544/2247696110');
    expect(staging, 'ca-app-pub-3940256099942544/3986624511');
  });

  test('production accepts only known AdMob network and supported slots', () {
    expect(
      AdConfig.resolveNativeUnitId(
        'home_primary',
        enabled: true,
        environment: Environment.production,
        platform: TargetPlatform.android,
        serverUnitId: 'ca-app-pub-production/home',
      ),
      'ca-app-pub-production/home',
    );
    expect(
      AdConfig.resolveNativeUnitId(
        'unknown_slot',
        enabled: true,
        environment: Environment.production,
        platform: TargetPlatform.android,
        serverUnitId: 'ca-app-pub-production/home',
      ),
      isNull,
    );
    expect(
      AdConfig.resolveNativeUnitId(
        'home_primary',
        enabled: true,
        environment: Environment.production,
        platform: TargetPlatform.android,
        serverUnitId: 'ad-network/unknown',
        serverNetworkIsAdMob: false,
      ),
      isNull,
    );
  });

  test('unsupported platforms fail closed even when enabled', () {
    expect(
      AdConfig.resolveNativeUnitId(
        'home_primary',
        enabled: true,
        environment: Environment.development,
        platform: TargetPlatform.linux,
      ),
      isNull,
    );
  });
}
