import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'dependency_checker.dart';

void main() {
  test('R1/R2/R4/R5 dependencies exactly match the shrinking allowlist', () {
    final violations = findDependencyViolations(readLibrarySources());
    final allowlist = File(
      'test/architecture/dependency_allowlist.txt',
    ).readAsStringSync();

    expect(
      compareDependencyAllowlist(violations, allowlist),
      isEmpty,
      reason:
          'Fix new dependencies and remove resolved allowances. '
          'Do not replace an old allowance with a new violation.',
    );
  });
}
