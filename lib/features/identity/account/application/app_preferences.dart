/// EN: Theme/locale user preferences.
/// KO: 테마/로케일 사용자 설정.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:oshi_log/core/providers/core_providers.dart'
    show localStorageProvider;

/// EN: Theme mode provider (light/dark/system)
/// KO: 테마 모드 프로바이더 (라이트/다크/시스템)
final themeModeProvider = StateProvider<String>((ref) {
  return 'system';
});

/// EN: Locale state notifier.
/// KO: 로케일 상태 노티파이어.
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._ref) : super(null) {
    unawaited(_loadPersistedLocale());
  }

  final Ref _ref;

  Future<void> _loadPersistedLocale() async {
    final storage = await _ref.read(localStorageProvider.future);
    final stored = storage.getLocale();
    final locale = _parseStoredLocale(stored);
    state = locale;
    Intl.defaultLocale = _intlLocaleTag(locale);
  }

  /// EN: Set locale and persist user preference.
  /// KO: 로케일을 설정하고 사용자 선호도를 저장합니다.
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    Intl.defaultLocale = _intlLocaleTag(locale);
    final storage = await _ref.read(localStorageProvider.future);
    final value = locale == null ? 'system' : locale.languageCode;
    await storage.setLocale(value);
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
