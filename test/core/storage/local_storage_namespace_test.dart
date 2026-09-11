import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oshi_log/core/cache/cache_manager.dart';
import 'package:oshi_log/core/storage/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('scopes API data while preserving theme and locale globally', () async {
    final prefs = await SharedPreferences.getInstance();
    final development = LocalStorage(prefs, namespace: 'api_dev');
    final production = LocalStorage(prefs, namespace: 'api_prod');

    await development.setString(LocalStorageKeys.selectedProjectKey, 'dev');
    await production.setString(LocalStorageKeys.selectedProjectKey, 'prod');
    await development.setThemeMode('dark');
    await development.setLocale('ko');

    expect(development.getString(LocalStorageKeys.selectedProjectKey), 'dev');
    expect(production.getString(LocalStorageKeys.selectedProjectKey), 'prod');
    expect(development.getThemeMode(), 'dark');
    expect(production.getThemeMode(), 'dark');
    expect(production.getLocale(), 'ko');
    expect(
      prefs.getString('gbt:api_dev:${LocalStorageKeys.selectedProjectKey}'),
      'dev',
    );
    expect(
      prefs.getString('gbt:api_prod:${LocalStorageKeys.selectedProjectKey}'),
      'prod',
    );
  });

  test('does not read legacy unscoped API values under a new origin', () async {
    SharedPreferences.setMockInitialValues({
      LocalStorageKeys.selectedProjectId: 'legacy-project',
      LocalStorageKeys.themeMode: 'dark',
    });
    final prefs = await SharedPreferences.getInstance();
    final scoped = LocalStorage(prefs, namespace: 'api_dev');

    expect(scoped.getSelectedProjectId(), isNull);
    expect(scoped.getThemeMode(), 'dark');
  });

  test('clearAll removes only the selected origin namespace', () async {
    final prefs = await SharedPreferences.getInstance();
    final development = LocalStorage(prefs, namespace: 'api_dev');
    final production = LocalStorage(prefs, namespace: 'api_prod');

    await development.setString('cached_record', 'dev');
    await production.setString('cached_record', 'prod');
    await development.setThemeMode('dark');

    expect(await development.clearAll(), isTrue);
    expect(development.getString('cached_record'), isNull);
    expect(production.getString('cached_record'), 'prod');
    expect(development.getThemeMode(), 'dark');
  });

  test('cache prefix invalidation sees logical keys in each origin', () async {
    final prefs = await SharedPreferences.getInstance();
    final development = CacheManager(LocalStorage(prefs, namespace: 'api_dev'));
    final production = CacheManager(LocalStorage(prefs, namespace: 'api_prod'));
    const devKey = 'post_list:bang-dream:p0:s20';
    const prodKey = 'post_list:bang-dream:p0:s20';

    await development.setJson(devKey, {'origin': 'dev'});
    await production.setJson(prodKey, {'origin': 'prod'});

    expect(await development.removeByPrefix('post_list:bang-dream:'), 1);
    expect(
      development.getJsonEntry<Map<String, dynamic>>(
        devKey,
        fromJson: (json) => json,
      ),
      isNull,
    );
    expect(
      production
          .getJsonEntry<Map<String, dynamic>>(prodKey, fromJson: (json) => json)
          ?.data['origin'],
      'prod',
    );
  });
}
