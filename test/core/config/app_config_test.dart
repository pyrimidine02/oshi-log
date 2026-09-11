import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.instance;

  setUp(() {
    config.init(
      environment: Environment.development,
      baseUrl: 'https://dev.oshilog.org',
    );
  });

  group('AppConfig environment policy', () {
    test('maps supported APP_ENV values and rejects unknown values', () {
      expect(
        AppConfig.parseEnvironment('development'),
        Environment.development,
      );
      expect(AppConfig.parseEnvironment(' STAGING '), Environment.staging);
      expect(AppConfig.parseEnvironment('Production'), Environment.production);
      expect(
        () => AppConfig.parseEnvironment('prod'),
        throwsA(isA<FormatException>()),
      );
    });

    test('selects the configured origin for each environment', () {
      config.init(environment: Environment.staging);
      expect(config.baseUrl, 'https://dev.oshilog.org');
      expect(config.isProduction, isFalse);

      config.init(environment: Environment.production);
      expect(config.baseUrl, 'https://api.oshilog.org');
      expect(config.isProduction, isTrue);
    });

    test('allows loopback HTTP only for debug development', () {
      config.init(
        environment: Environment.development,
        baseUrl: 'http://10.0.2.2:8080/',
      );
      expect(config.baseUrl, 'http://10.0.2.2:8080');

      expect(
        () => config.init(
          environment: Environment.staging,
          baseUrl: 'http://10.0.2.2:8080',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects credentials without echoing the secret', () {
      const value = 'https://client:super-secret@example.com';
      expect(
        () => config.init(environment: Environment.development, baseUrl: value),
        throwsA(
          predicate<FormatException>(
            (error) => !error.message.toString().contains('super-secret'),
          ),
        ),
      );
    });
  });

  group('storage namespace', () {
    test('ignores paths and normalizes equivalent default ports', () {
      expect(
        AppConfig.storageNamespaceForOrigin('https://example.com/api/v1'),
        AppConfig.storageNamespaceForOrigin('https://EXAMPLE.com:443'),
      );
      expect(
        AppConfig.storageNamespaceForOrigin('http://example.com'),
        AppConfig.storageNamespaceForOrigin('http://example.com:80/'),
      );
      expect(
        AppConfig.storageNamespaceForOrigin('https://example.com'),
        isNot(AppConfig.storageNamespaceForOrigin('https://example.com:444')),
      );
    });

    test('keeps visually similar hostnames collision-free', () {
      final hyphenated = AppConfig.storageNamespaceForOrigin(
        'https://a-b.example',
      );
      final dotted = AppConfig.storageNamespaceForOrigin('https://a.b.example');

      expect(hyphenated, isNot(dotted));
      expect(hyphenated, isNot(contains('a-b.example')));
      expect(dotted, isNot(contains('a.b.example')));
    });
  });
}
