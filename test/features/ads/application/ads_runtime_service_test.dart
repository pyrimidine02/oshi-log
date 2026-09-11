import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:oshi_log/features/ads/application/ads_runtime_service.dart';

void main() {
  group('AdsRuntimeService', () {
    test('does not touch the SDK when ads are disabled', () async {
      final adapter = _FakeAdsSdkAdapter();
      final service = AdsRuntimeService(
        adapter: adapter,
        enabled: false,
        supported: true,
      );

      expect(await service.ensureReady(), AdsReadiness.disabled);
      expect(adapter.calls, isEmpty);
      expect(await service.showPrivacyOptions(), isFalse);
    });

    test('runs consent then initializes the SDK once when allowed', () async {
      final adapter = _FakeAdsSdkAdapter();
      final service = AdsRuntimeService(
        adapter: adapter,
        enabled: true,
        supported: true,
      );

      final first = service.ensureReady();
      final second = service.ensureReady();

      expect(await first, AdsReadiness.ready);
      expect(await second, AdsReadiness.ready);
      expect(adapter.calls, ['consent', 'form', 'canRequestAds', 'initialize']);
      expect(adapter.initializeCalls, 1);
    });

    test('fails closed when consent says ads are not allowed', () async {
      final adapter = _FakeAdsSdkAdapter(canRequestAds: false);
      final service = AdsRuntimeService(
        adapter: adapter,
        enabled: true,
        supported: true,
      );

      expect(await service.ensureReady(), AdsReadiness.denied);
      expect(adapter.calls, ['consent', 'form', 'canRequestAds']);
      expect(adapter.initializeCalls, 0);
    });

    test('fails closed on an unknown consent/network error', () async {
      final adapter = _FakeAdsSdkAdapter(failAt: 'consent');
      final service = AdsRuntimeService(
        adapter: adapter,
        enabled: true,
        supported: true,
      );

      expect(await service.ensureReady(), AdsReadiness.denied);
      expect(adapter.calls, ['consent']);
      expect(adapter.initializeCalls, 0);
    });

    test('does not touch the SDK on unsupported platforms', () async {
      final adapter = _FakeAdsSdkAdapter();
      final service = AdsRuntimeService(
        adapter: adapter,
        enabled: true,
        supported: false,
      );

      expect(await service.ensureReady(), AdsReadiness.disabled);
      expect(adapter.calls, isEmpty);
    });

    test('opens privacy options after readiness', () async {
      final adapter = _FakeAdsSdkAdapter();
      final service = AdsRuntimeService(
        adapter: adapter,
        enabled: true,
        supported: true,
      );

      expect(await service.showPrivacyOptions(), isTrue);
      expect(adapter.calls, [
        'consent',
        'form',
        'canRequestAds',
        'initialize',
        'privacyOptions',
        'canRequestAds',
      ]);
    });

    test(
      'withdrawal revokes readiness and allows a later re-consent',
      () async {
        final adapter = _FakeAdsSdkAdapter();
        final service = AdsRuntimeService(
          adapter: adapter,
          enabled: true,
          supported: true,
        );
        final changes = <AdsReadiness>[];
        final subscription = service.readinessChanges.listen(changes.add);
        addTearDown(subscription.cancel);

        expect(await service.ensureReady(), AdsReadiness.ready);
        await Future<void>.delayed(Duration.zero);
        adapter.canRequestAdsValue = false;
        expect(await service.showPrivacyOptions(), isTrue);
        await Future<void>.delayed(Duration.zero);
        expect(service.readiness, AdsReadiness.denied);
        expect(changes, [AdsReadiness.ready, AdsReadiness.denied]);

        adapter.canRequestAdsValue = true;
        expect(await service.showPrivacyOptions(), isTrue);
        await Future<void>.delayed(Duration.zero);
        expect(service.readiness, AdsReadiness.ready);
        expect(adapter.initializeCalls, 1);
        expect(changes, [
          AdsReadiness.ready,
          AdsReadiness.denied,
          AdsReadiness.ready,
        ]);
      },
    );

    test('returns the privacy-options requirement status', () async {
      final adapter = _FakeAdsSdkAdapter(
        privacyOptionsStatus: PrivacyOptionsRequirementStatus.required,
      );
      final service = AdsRuntimeService(
        adapter: adapter,
        enabled: true,
        supported: true,
      );

      expect(
        await service.getPrivacyOptionsRequirementStatus(),
        PrivacyOptionsRequirementStatus.required,
      );
      expect(adapter.calls, [
        'consent',
        'form',
        'canRequestAds',
        'initialize',
        'privacyRequirement',
      ]);
    });
  });
}

class _FakeAdsSdkAdapter implements AdsSdkAdapter {
  _FakeAdsSdkAdapter({
    bool canRequestAds = true,
    this.failAt,
    this.privacyOptionsStatus = PrivacyOptionsRequirementStatus.notRequired,
  }) : canRequestAdsValue = canRequestAds;

  bool canRequestAdsValue;
  final String? failAt;
  final PrivacyOptionsRequirementStatus privacyOptionsStatus;
  final List<String> calls = <String>[];
  int initializeCalls = 0;

  void _failIf(String operation) {
    if (failAt == operation) throw StateError(operation);
  }

  @override
  Future<void> requestConsentInfoUpdate() async {
    calls.add('consent');
    _failIf('consent');
  }

  @override
  Future<void> loadAndShowConsentFormIfRequired() async {
    calls.add('form');
    _failIf('form');
  }

  @override
  Future<bool> canRequestAds() async {
    calls.add('canRequestAds');
    _failIf('canRequestAds');
    return canRequestAdsValue;
  }

  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async {
    calls.add('privacyRequirement');
    _failIf('privacyRequirement');
    return privacyOptionsStatus;
  }

  @override
  Future<void> initialize() async {
    calls.add('initialize');
    initializeCalls += 1;
    _failIf('initialize');
  }

  @override
  Future<bool> showPrivacyOptionsForm() async {
    calls.add('privacyOptions');
    _failIf('privacyOptions');
    return true;
  }
}
