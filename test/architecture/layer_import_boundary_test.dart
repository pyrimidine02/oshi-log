import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature domain files do not depend on data or Flutter layers', () {
    final violations = <String>[];
    final featureRoot = Directory('lib/features');

    for (final entity in featureRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final normalizedPath = entity.path.replaceAll('\\', '/');
      final isDomain = normalizedPath.contains('/domain/');
      final isPresentation = normalizedPath.contains('/presentation/');
      if (!isDomain && !isPresentation) {
        continue;
      }

      final source = entity.readAsStringSync();
      for (final line in source.split('\n')) {
        final import = line.trim();
        if (!import.startsWith('import ') && !import.startsWith('export ')) {
          continue;
        }
        final domainViolation =
            isDomain &&
            (import.contains('/data/') ||
                import.contains('/presentation/') ||
                import.contains('/application/') ||
                import.contains('package:flutter') ||
                import.contains('package:flutter_'));
        final presentationViolation =
            isPresentation &&
            (import.contains('/data/') ||
                import.contains('package:oshi_log/') &&
                    import.contains('/data/'));
        if (domainViolation || presentationViolation) {
          violations.add('$normalizedPath: $import');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Domain layers must stay independent of DTO and Flutter APIs:\n'
          '${violations.join('\n')}',
    );
  });
}
