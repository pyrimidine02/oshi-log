/// EN: One-time location-notice consent state, backed by an append-only log.
/// KO: append-only 로그로 관리되는 위치 수집 고지 1회 동의 상태입니다.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import '../storage/local_storage.dart';

/// EN: Current consent state plus the timestamps shown in settings.
/// KO: 현재 동의 상태와 설정 화면에 표시할 시각 정보입니다.
@immutable
class LocationNoticeConsent {
  const LocationNoticeConsent({
    this.agreedAt,
    this.revokedAt,
    this.lastRevokedAt,
  });

  /// EN: When the still-effective consent was given; null when not agreed.
  /// KO: 현재 유효한 동의를 한 시각이며, 동의하지 않았다면 null입니다.
  final DateTime? agreedAt;

  /// EN: Set only while the latest recorded action is a revocation.
  /// KO: 가장 최근 기록된 동작이 철회인 경우에만 설정됩니다.
  final DateTime? revokedAt;

  /// EN: Most recent revocation ever recorded, kept for the history line.
  /// KO: 기록된 가장 최근 철회 시각으로, 이력 표시에 사용합니다.
  final DateTime? lastRevokedAt;

  /// EN: True when verification may start without asking for consent again.
  /// KO: 동의를 다시 묻지 않고 인증을 시작할 수 있으면 true입니다.
  bool get isAgreed => agreedAt != null && revokedAt == null;
}

/// EN: Reads and appends location-notice consent actions in local storage.
/// KO: 로컬 저장소의 위치 고지 동의 이력을 읽고 추가합니다.
class LocationNoticeConsentStore {
  const LocationNoticeConsentStore(this._storage);

  final LocalStorage _storage;

  static const String actionAgreed = 'AGREED';
  static const String actionRevoked = 'REVOKED';

  // EN: Cap the log so preferences stay small; only recent history is shown.
  // KO: 설정 저장소 용량을 위해 로그를 제한하며, 최근 이력만 표시합니다.
  static const int _maxEntries = 20;

  LocationNoticeConsent read() {
    final entries =
        _storage.getJsonList(LocalStorageKeys.locationNoticeConsentLog) ??
        const <Map<String, dynamic>>[];

    DateTime? agreedAt;
    DateTime? revokedAt;
    DateTime? lastRevokedAt;
    for (final entry in entries) {
      final at = DateTime.tryParse((entry['at'] as String?) ?? '');
      if (at == null) continue;
      switch (entry['action']) {
        case actionAgreed:
          agreedAt = at;
          revokedAt = null;
        case actionRevoked:
          revokedAt = at;
          lastRevokedAt = at;
      }
    }
    return LocationNoticeConsent(
      agreedAt: agreedAt,
      revokedAt: revokedAt,
      lastRevokedAt: lastRevokedAt,
    );
  }

  Future<bool> agree(DateTime at) => _append(actionAgreed, at);

  Future<bool> revoke(DateTime at) => _append(actionRevoked, at);

  Future<bool> _append(String action, DateTime at) {
    final entries = <Map<String, dynamic>>[
      ...?_storage.getJsonList(LocalStorageKeys.locationNoticeConsentLog),
      {'action': action, 'at': at.toUtc().toIso8601String()},
    ];
    final trimmed = entries.length > _maxEntries
        ? entries.sublist(entries.length - _maxEntries)
        : entries;
    return _storage.setJsonList(
      LocalStorageKeys.locationNoticeConsentLog,
      trimmed,
    );
  }
}

/// EN: Store bound to the app's local storage instance.
/// KO: 앱 로컬 저장소 인스턴스에 연결된 스토어입니다.
final locationNoticeConsentStoreProvider =
    FutureProvider<LocationNoticeConsentStore>((ref) async {
      final storage = await ref.read(localStorageProvider.future);
      return LocationNoticeConsentStore(storage);
    });

/// EN: Current consent state; invalidate after agreeing or revoking.
/// KO: 현재 동의 상태이며, 동의/철회 후 invalidate 해야 합니다.
final locationNoticeConsentProvider = FutureProvider<LocationNoticeConsent>((
  ref,
) async {
  final store = await ref.watch(locationNoticeConsentStoreProvider.future);
  return store.read();
});
