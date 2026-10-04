/// EN: Service and providers for locally persisted failed verification attempts.
/// KO: 로컬 저장 인증 실패 기록 서비스 및 프로바이더.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import 'package:oshi_log/features/place/verification/domain/entities/failed_verification_attempt.dart';

/// EN: Retention window for failed verification attempts (30 days).
/// KO: 인증 실패 기록 보관 기간 (30일).
const Duration _kRetention = Duration(days: 30);

/// EN: Service that persists failed verification attempts to SharedPreferences.
/// KO: 인증 실패 기록을 SharedPreferences에 저장하는 서비스.
class FailedAttemptService {
  const FailedAttemptService(this._storage);

  final LocalStorage _storage;

  static const String _key = LocalStorageKeys.failedVerificationAttempts;

  /// EN: Record a new failed attempt and prune expired entries.
  /// KO: 새 실패 기록을 저장하고 만료된 항목을 정리합니다.
  Future<void> record(FailedVerificationAttempt attempt) async {
    final items = await getAll();
    items.add(attempt);
    await _persist(items);
  }

  /// EN: Return all attempts within the retention window, newest first.
  /// KO: 보관 기간 내의 모든 기록을 최신순으로 반환합니다.
  Future<List<FailedVerificationAttempt>> getAll() async {
    final raw = _storage.getJsonList(_key);
    if (raw == null) return [];

    final cutoff = DateTime.now().subtract(_kRetention);
    return raw
        .map(FailedVerificationAttempt.fromJson)
        .where((a) => a.attemptedAt.isAfter(cutoff))
        .toList(growable: true)
      ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
  }

  /// EN: Delete all stored attempts (e.g. on logout).
  /// KO: 저장된 모든 기록 삭제 (로그아웃 시 등).
  Future<void> clear() => _storage.remove(_key);

  Future<void> _persist(List<FailedVerificationAttempt> items) async {
    // EN: Keep only entries within retention window to cap storage size.
    // KO: 저장 크기 제한을 위해 보관 기간 내 항목만 유지합니다.
    final cutoff = DateTime.now().subtract(_kRetention);
    final pruned = items
        .where((a) => a.attemptedAt.isAfter(cutoff))
        .toList(growable: false);
    await _storage.setJsonList(
      _key,
      pruned.map((a) => a.toJson()).toList(growable: false),
    );
  }
}

// ============================================================
// EN: Riverpod providers
// KO: Riverpod 프로바이더
// ============================================================

/// EN: Provider for [FailedAttemptService] (async — requires LocalStorage).
/// KO: [FailedAttemptService] 프로바이더 (비동기 — LocalStorage 필요).
final failedAttemptServiceProvider = FutureProvider<FailedAttemptService>((
  ref,
) async {
  final storage = await ref.read(localStorageProvider.future);
  return FailedAttemptService(storage);
});

/// EN: FutureProvider that exposes the 30-day failed attempt list.
/// KO: 30일 이내 실패 기록 목록을 노출하는 FutureProvider.
final failedVerificationAttemptsProvider =
    FutureProvider<List<FailedVerificationAttempt>>((ref) async {
      final service = await ref.read(failedAttemptServiceProvider.future);
      return service.getAll();
    });
