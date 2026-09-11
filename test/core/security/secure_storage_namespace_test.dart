import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/security/secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('isolates token material between API origins', () async {
    final development = SecureStorage(namespace: 'api_dev');
    final production = SecureStorage(namespace: 'api_prod');

    await development.saveAccessToken('dev-token');
    await production.saveAccessToken('prod-token');

    expect(await development.getAccessToken(), 'dev-token');
    expect(await production.getAccessToken(), 'prod-token');
  });

  test('does not read legacy unscoped tokens under a new origin', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      SecureStorageKeys.accessToken: 'legacy-token',
    });

    final scoped = SecureStorage(namespace: 'api_dev');
    expect(await scoped.getAccessToken(), isNull);
    expect(await SecureStorage().getAccessToken(), 'legacy-token');
  });

  test('clearAll removes only the selected origin namespace', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      SecureStorageKeys.accessToken: 'legacy-token',
      'gbt:api_dev:${SecureStorageKeys.accessToken}': 'dev-token',
      'gbt:api_prod:${SecureStorageKeys.accessToken}': 'prod-token',
    });

    final development = SecureStorage(namespace: 'api_dev');
    final production = SecureStorage(namespace: 'api_prod');
    await development.clearAll();

    expect(await development.getAccessToken(), isNull);
    expect(await production.getAccessToken(), 'prod-token');
    expect(await SecureStorage().getAccessToken(), 'legacy-token');
  });
}
