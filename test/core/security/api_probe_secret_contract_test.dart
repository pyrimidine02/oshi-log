import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('api probe requires credentials outside source control', () {
    final script = File('scripts/api_probe.sh').readAsStringSync();

    expect(script, isNot(contains('DEFAULT_ACCESS_TOKEN')));
    expect(script, isNot(contains('DEFAULT_LOGIN_PASSWORD')));
    expect(script, isNot(matches(RegExp(r'eyJ[a-zA-Z0-9_-]+\.eyJ'))));
    expect(script, contains('ACCESS_TOKEN="\${ACCESS_TOKEN:-}"'));
    expect(script, contains('LOGIN_PASSWORD="\${LOGIN_PASSWORD:-}"'));
  });
}
