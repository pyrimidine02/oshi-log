/// EN: Theme/locale user preferences.
/// KO: 테마/로케일 사용자 설정.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:oshi_log/platform/providers/core_providers.dart'
    show localStorageProvider;

/// EN: Theme mode provider (light/dark/system)
/// KO: 테마 모드 프로바이더 (라이트/다크/시스템)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, String>((
  ref,
) {
  return ThemeModeNotifier(ref);
});

/// EN: Restores and persists theme without overriding a newer user choice.
/// KO: 새로운 사용자 선택을 덮지 않으면서 테마를 복원하고 저장합니다.
class ThemeModeNotifier extends StateNotifier<String> {
  ThemeModeNotifier(this._ref) : super('system') {
    unawaited(_load());
  }

  final Ref _ref;
  int _revision = 0;

  Future<void> _load() async {
    try {
      final storage = await _ref.read(localStorageProvider.future);
      if (!mounted || _revision != 0) return;
      final saved = storage.getThemeMode();
      state = saved == 'light' || saved == 'dark' ? saved! : 'system';
    } on Object {
      // EN: Storage failure keeps the usable system default.
      // KO: 저장소 오류 시 사용 가능한 시스템 기본값을 유지합니다.
    }
  }

  Future<void> setMode(String mode) async {
    final value = mode == 'light' || mode == 'dark' ? mode : 'system';
    final revision = ++_revision;
    state = value;
    final storage = await _ref.read(localStorageProvider.future);
    if (revision != _revision) return;
    if (!await storage.setThemeMode(value)) {
      throw StateError('Theme preference could not be saved');
    }
  }
}

/// EN: Local first-run completion, independent of authentication.
/// KO: 로그인 여부와 독립적인 로컬 첫 실행 완료 상태입니다.
final firstRunCompletedProvider = FutureProvider<bool>((ref) async {
  final storage = await ref.watch(localStorageProvider.future);
  return storage.isOnboardingCompleted();
});

/// EN: Locale state notifier.
/// KO: 로케일 상태 노티파이어.
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._ref) : super(null) {
    unawaited(_loadPersistedLocale());
  }

  final Ref _ref;
  int _revision = 0;

  Future<void> _loadPersistedLocale() async {
    try {
      final storage = await _ref.read(localStorageProvider.future);
      if (!mounted || _revision != 0) return;
      final locale = _parseStoredLocale(storage.getLocale());
      state = locale;
      Intl.defaultLocale = _intlLocaleTag(locale);
    } on Object {
      // EN: Storage failure keeps the usable system default.
      // KO: 저장소 오류 시 사용 가능한 시스템 기본값을 유지합니다.
    }
  }

  /// EN: Set locale and persist user preference.
  /// KO: 로케일을 설정하고 사용자 선호도를 저장합니다.
  Future<void> setLocale(Locale? locale) async {
    final revision = ++_revision;
    state = locale;
    Intl.defaultLocale = _intlLocaleTag(locale);
    final storage = await _ref.read(localStorageProvider.future);
    if (revision != _revision) return;
    final value = locale == null ? 'system' : locale.languageCode;
    if (!await storage.setLocale(value)) {
      throw StateError('Language preference could not be saved');
    }
  }

  /// EN: Set locale by language code (`ko`, `en`, `ja`), or `system`.
  /// KO: 언어 코드(`ko`, `en`, `ja`) 또는 `system`으로 로케일을 설정합니다.
  Future<void> setLocaleByCode(String code) async {
    final normalized = code.trim().toLowerCase();
    final locale = _parseStoredLocale(normalized);
    await setLocale(locale);
  }

  Locale? _parseStoredLocale(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'ko':
        return const Locale('ko', 'KR');
      case 'en':
        return const Locale('en', 'US');
      case 'ja':
        return const Locale('ja', 'JP');
      default:
        return null;
    }
  }

  String _intlLocaleTag(Locale? locale) {
    if (locale == null) {
      return Intl.systemLocale;
    }
    final effective = locale;
    final country = effective.countryCode;
    if (country == null || country.isEmpty) {
      return effective.languageCode;
    }
    return '${effective.languageCode}_$country';
  }
}

/// EN: App locale provider (null means follow system locale).
/// KO: 앱 로케일 프로바이더 (null이면 시스템 로케일을 따릅니다).
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref);
});
