/// EN: Durable daily list mutations, isolated by the secure account identifier.
/// KO: 보안 저장소 계정 식별자로 격리한 당일 목록 저장·변경입니다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/place/places/application/places_controller.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import '../domain/today_plan.dart';

enum TodayFailure { load, save, download, accountChanged, dateMismatch }

class TodayState {
  const TodayState({
    this.plan,
    this.isLoading = false,
    this.isSaving = false,
    this.accountRequired = false,
    this.failure,
    this.failedDownloads = const {},
  });
  final TodayPlan? plan;
  final bool isLoading;
  final bool isSaving;
  final bool accountRequired;
  final TodayFailure? failure;
  final Set<String> failedDownloads;

  TodayState copyWith({
    TodayPlan? plan,
    bool isSaving = false,
    TodayFailure? failure,
    Set<String>? failedDownloads,
  }) => TodayState(
    plan: plan ?? this.plan,
    isSaving: isSaving,
    failure: failure,
    failedDownloads: Set.unmodifiable(failedDownloads ?? this.failedDownloads),
  );
}

final todayControllerProvider =
    StateNotifierProvider<TodayController, TodayState>((ref) {
      final authenticated = ref.watch(isAuthenticatedProvider);
      ref.watch(authTokenRefreshTickProvider);
      return TodayController(
        storage: () => ref.read(localStorageProvider.future),
        readUserId: () async =>
            authenticated ? ref.read(secureStorageProvider).getUserId() : null,
        fetchDetail: (projectKey, placeId) async {
          final repository = await ref.read(placesRepositoryProvider.future);
          return (await repository.getPlaceDetail(
            projectId: projectKey,
            placeId: placeId,
            forceRefresh: true,
          )).getOrThrow();
        },
      );
    });

class TodayController extends StateNotifier<TodayState> {
  TodayController({
    required Future<LocalStorage> Function() storage,
    required Future<String?> Function() readUserId,
    required Future<PlaceDetail> Function(String, String) fetchDetail,
    DateTime Function()? now,
  }) : _storageFactory = storage,
       _readUserId = readUserId,
       _fetchDetail = fetchDetail,
       _now = now ?? DateTime.now,
       super(const TodayState(isLoading: true)) {
    ready = load();
  }
  final Future<LocalStorage> Function() _storageFactory;
  final Future<String?> Function() _readUserId;
  final Future<PlaceDetail> Function(String, String) _fetchDetail;
  final DateTime Function() _now;
  late final Future<void> ready;
  LocalStorage? _storage;
  String? _account;
  String get _storageKey => 'today_plan_v1:${Uri.encodeComponent(_account!)}';

  Future<void> load() async {
    if (!mounted) return;
    state = const TodayState(isLoading: true);
    try {
      final account = (await _readUserId())?.trim();
      if (!mounted) return;
      if (account == null || account.isEmpty) {
        state = const TodayState(accountRequired: true);
        return;
      }
      _account = account;
      _storage = await _storageFactory();
      if (!await _sameAccount()) return;
      final json = _storage!.getJson(_storageKey);
      if (json == null && _storage!.getString(_storageKey) != null) {
        throw const FormatException('Unreadable local plan');
      }
      state = TodayState(
        plan: json == null
            ? TodayPlan(date: todayDateKey(_now()))
            : TodayPlan.fromJson(json),
      );
    } catch (_) {
      if (mounted) state = const TodayState(failure: TodayFailure.load);
    }
  }

  Future<bool> _sameAccount() async {
    final account = (await _readUserId())?.trim();
    if (!mounted) return false;
    if (account == null || account.isEmpty || account != _account) {
      state = const TodayState(
        accountRequired: true,
        failure: TodayFailure.accountChanged,
      );
      return false;
    }
    return true;
  }

  Future<bool> _begin() async {
    await ready;
    if (!mounted || state.isSaving || state.plan == null) return false;
    state = state.copyWith(isSaving: true);
    try {
      return await _sameAccount();
    } catch (_) {
      if (mounted) {
        state = const TodayState(
          accountRequired: true,
          failure: TodayFailure.accountChanged,
        );
      }
      return false;
    }
  }

  Future<bool> _commit(TodayPlan plan, {Set<String>? failedDownloads}) async {
    try {
      if (!await _sameAccount()) return false;
      final saved = await _storage!.setJson(_storageKey, plan.toJson());
      if (!await _sameAccount()) return false;
      if (!saved) throw StateError('Local save failed');
      state = state.copyWith(plan: plan, failedDownloads: failedDownloads);
      return true;
    } catch (_) {
      if (mounted && state.plan != null) {
        state = state.copyWith(failure: TodayFailure.save);
      }
      return false;
    }
  }

  Future<bool> addDetail({
    required String projectKey,
    required PlaceDetail detail,
  }) async {
    if (projectKey.trim().isEmpty ||
        detail.id.trim().isEmpty ||
        !await _begin()) {
      return false;
    }
    if (state.plan!.date != todayDateKey(_now())) {
      state = state.copyWith(failure: TodayFailure.dateMismatch);
      return false;
    }
    final item = TodayPlace(
      projectKey: projectKey,
      placeId: detail.id,
      name: detail.name,
      address: detail.address,
    );
    final plan = state.plan!;
    if (plan.entries.any((entry) => entry.key == item.key)) {
      state = state.copyWith();
      return true;
    }
    return _commit(
      TodayPlan(date: plan.date, entries: [...plan.entries, item]),
    );
  }

  Future<bool> move(int from, int to) async {
    if (!await _begin()) return false;
    final plan = state.plan!;
    final entries = plan.entries.toList();
    if (from < 0 || to < 0 || from >= entries.length || to >= entries.length) {
      state = state.copyWith();
      return false;
    }
    entries.insert(to, entries.removeAt(from));
    return _commit(TodayPlan(date: plan.date, entries: entries));
  }

  Future<bool> toggleSkipped(String key) async {
    if (!await _begin()) return false;
    final plan = state.plan!;
    return _commit(
      TodayPlan(
        date: plan.date,
        entries: [
          for (final entry in plan.entries)
            entry.key == key ? entry.copyWith(skipped: !entry.skipped) : entry,
        ],
      ),
    );
  }

  Future<bool> remove(String key) async {
    if (!await _begin()) return false;
    return _commit(
      TodayPlan(
        date: state.plan!.date,
        entries: state.plan!.entries
            .where((entry) => entry.key != key)
            .toList(),
      ),
    );
  }

  Future<bool> startToday() async {
    if (!await _begin()) return false;
    return _commit(TodayPlan(date: todayDateKey(_now())), failedDownloads: {});
  }

  Future<bool> downloadText(String key) async {
    if (!await _begin()) return false;
    final plan = state.plan!;
    final matches = plan.entries.where((entry) => entry.key == key);
    if (matches.isEmpty) {
      state = state.copyWith();
      return false;
    }
    final entry = matches.first;
    try {
      final detail = await _fetchDetail(entry.projectKey, entry.placeId);
      if (!await _sameAccount()) return false;
      if (detail.id != entry.placeId || detail.isFromCache) {
        throw StateError('No fresh detail');
      }
      final snapshot = TodayTextSnapshot(
        name: detail.name,
        address: detail.address,
        description: detail.description,
        savedAt: _now(),
      );
      return await _commit(
        TodayPlan(
          date: plan.date,
          entries: [
            for (final item in plan.entries)
              item.key == key ? item.copyWith(text: snapshot) : item,
          ],
        ),
        failedDownloads: {...state.failedDownloads}..remove(key),
      );
    } catch (_) {
      if (mounted && state.plan != null) {
        state = state.copyWith(
          failure: TodayFailure.download,
          failedDownloads: {...state.failedDownloads, key},
        );
      }
      return false;
    }
  }
}
