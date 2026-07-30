/// EN: Contract for the one-time location-notice consent log.
/// KO: 위치 수집 고지 1회 동의 로그 계약입니다.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oshi_log/core/location/location_notice_consent.dart';
import 'package:oshi_log/core/storage/local_storage.dart';

Future<LocationNoticeConsentStore> buildStore() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return LocationNoticeConsentStore(LocalStorage(prefs));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts out not agreed with no timestamps', () async {
    final store = await buildStore();

    final consent = store.read();

    expect(consent.isAgreed, isFalse);
    expect(consent.agreedAt, isNull);
    expect(consent.lastRevokedAt, isNull);
  });

  test('agreeing once keeps consent effective across reads', () async {
    final store = await buildStore();
    final agreedAt = DateTime.utc(2026, 7, 30, 4, 15);

    await store.agree(agreedAt);
    final consent = store.read();

    expect(consent.isAgreed, isTrue);
    expect(consent.agreedAt, agreedAt);
    expect(consent.revokedAt, isNull);
  });

  test('revoking records the withdrawal time and clears consent', () async {
    final store = await buildStore();
    final revokedAt = DateTime.utc(2026, 8, 1, 9, 30);

    await store.agree(DateTime.utc(2026, 7, 30, 4, 15));
    await store.revoke(revokedAt);
    final consent = store.read();

    expect(consent.isAgreed, isFalse);
    expect(consent.revokedAt, revokedAt);
    expect(consent.lastRevokedAt, revokedAt);
  });

  test('agreeing again after revoke keeps the past withdrawal date', () async {
    final store = await buildStore();
    final revokedAt = DateTime.utc(2026, 8, 1, 9, 30);
    final reAgreedAt = DateTime.utc(2026, 8, 2, 10, 0);

    await store.agree(DateTime.utc(2026, 7, 30, 4, 15));
    await store.revoke(revokedAt);
    await store.agree(reAgreedAt);
    final consent = store.read();

    expect(consent.isAgreed, isTrue);
    expect(consent.agreedAt, reAgreedAt);
    expect(consent.revokedAt, isNull);
    expect(consent.lastRevokedAt, revokedAt);
  });
}
