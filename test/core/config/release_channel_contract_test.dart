import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('Android internal distribution embeds staging', () {
    expect(
      read('.github/workflows/android-internal-distribution.yml'),
      contains('--dart-define=APP_ENV=staging'),
    );
    expect(
      read('scripts/build_android_internal.sh'),
      contains(r'app_env="${APP_ENV:-staging}"'),
    );
  });

  test('tag release embeds production', () {
    expect(
      read('.github/workflows/android-release-from-tag.yml'),
      contains('--dart-define=APP_ENV=production'),
    );
  });

  test('Xcode Cloud defaults to staging and passes the channel to Flutter', () {
    for (final path in const [
      'ci_post_clone.sh',
      'ios/ci_scripts/ci_post_clone.sh',
    ]) {
      final script = read(path);
      expect(script, contains(r'APP_ENV="${APP_ENV:-staging}"'), reason: path);
      expect(
        script,
        contains(r'--dart-define="APP_ENV=$APP_ENV"'),
        reason: path,
      );
    }
  });
}
