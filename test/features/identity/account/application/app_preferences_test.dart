import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import 'package:oshi_log/features/identity/account/application/app_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'late saved locale cannot overwrite an explicit language selection',
    () async {
      final previousIntl = Intl.defaultLocale;
      addTearDown(() => Intl.defaultLocale = previousIntl);
      SharedPreferences.setMockInitialValues({LocalStorageKeys.locale: 'ko'});
      final storageReady = Completer<LocalStorage>();
      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWith((ref) => storageReady.future),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(localeProvider.notifier);
      final save = notifier.setLocaleByCode('ja');
      expect(container.read(localeProvider)?.languageCode, 'ja');
      final observed = <String?>[];
      container.listen(
        localeProvider,
        (_, next) => observed.add(next?.languageCode),
      );
      storageReady.complete(await LocalStorage.create());
      await save;
      await Future<void>.delayed(Duration.zero);
      expect(observed, isNot(contains('ko')));
      expect(container.read(localeProvider)?.languageCode, 'ja');
      expect((await storageReady.future).getLocale(), 'ja');
      expect(Intl.defaultLocale, 'ja_JP');
    },
  );

  test(
    'saved theme restores and explicit setting survives delayed restore',
    () async {
      SharedPreferences.setMockInitialValues({
        LocalStorageKeys.themeMode: 'light',
      });
      final storageReady = Completer<LocalStorage>();
      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWith((ref) => storageReady.future),
        ],
      );
      addTearDown(container.dispose);
      final save = container.read(themeModeProvider.notifier).setMode('dark');
      storageReady.complete(await LocalStorage.create());
      await save;
      await Future<void>.delayed(Duration.zero);
      expect(container.read(themeModeProvider), 'dark');
      expect((await storageReady.future).getThemeMode(), 'dark');
      final restored = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWith((ref) => storageReady.future),
        ],
      );
      addTearDown(restored.dispose);
      restored.read(themeModeProvider);
      await Future<void>.delayed(Duration.zero);
      expect(restored.read(themeModeProvider), 'dark');
    },
  );

  test('system locale remains explicit while stored value arrives', () async {
    final previousIntl = Intl.defaultLocale;
    addTearDown(() => Intl.defaultLocale = previousIntl);
    SharedPreferences.setMockInitialValues({LocalStorageKeys.locale: 'ja'});
    final ready = Completer<LocalStorage>();
    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWith((ref) => ready.future)],
    );
    addTearDown(container.dispose);
    final save = container.read(localeProvider.notifier).setLocale(null);
    ready.complete(await LocalStorage.create());
    await save;
    expect(container.read(localeProvider), isNull);
    expect((await ready.future).getLocale(), 'system');
  });

  test(
    'disposing before storage readiness does not write notifier state',
    () async {
      final ready = Completer<LocalStorage>();
      final container = ProviderContainer(
        overrides: [localStorageProvider.overrideWith((ref) => ready.future)],
      );
      container.read(localeProvider);
      container.read(themeModeProvider);
      container.dispose();
      ready.complete(await LocalStorage.create());
      await Future<void>.delayed(Duration.zero);
    },
  );
}
