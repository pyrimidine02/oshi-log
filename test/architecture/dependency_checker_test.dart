import 'package:flutter_test/flutter_test.dart';

import 'dependency_checker.dart';

void main() {
  test('migrated groups own <group>/<sub>; others are legacy/<feature>', () {
    expect(
      findDependencyViolations({
        'lib/features/oshikatsu/catalog/data/dto/unit_dto.dart': '',
        'lib/features/oshikatsu/music/data/song_repository.dart':
            "import '../../catalog/data/dto/unit_dto.dart';",
        'lib/features/feed/data/post_repository.dart':
            "import '../../oshikatsu/catalog/data/dto/unit_dto.dart';",
      }),
      {
        'lib/features/oshikatsu/music/data/song_repository.dart -> '
            'lib/features/oshikatsu/catalog/data/dto/unit_dto.dart : R2',
        'lib/features/feed/data/post_repository.dart -> '
            'lib/features/oshikatsu/catalog/data/dto/unit_dto.dart : R2',
      },
    );
  });

  test('a business file directly under a migrated group dir fails', () {
    expect(
      findDependencyViolations({
        'lib/features/oshikatsu/stray_controller.dart': '',
      }),
      {
        'lib/features/oshikatsu/stray_controller.dart -> '
            'lib/features/oshikatsu/stray_controller.dart : R2',
      },
    );
  });

  test('normalizes relative and package URIs to one file dependency', () {
    expect(
      findDependencyViolations({
        'lib/features/a/presentation/page.dart': '''
          import '../data/./dto.dart';
          export 'package:oshi_log/features/a/domain/../data/dto.dart';
        ''',
        'lib/features/a/data/dto.dart': '',
      }),
      {
        'lib/features/a/presentation/page.dart -> '
            'lib/features/a/data/dto.dart : R1',
      },
    );
  });

  test('R1 keeps domain and presentation layer restrictions', () {
    expect(
      findDependencyViolations({
        'lib/features/a/domain/model.dart': '''
          import '../data/dto.dart';
          import '../application/provider.dart';
          export '../presentation/page.dart';
          import 'package:flutter/widgets.dart';
          import 'package:flutter_riverpod/flutter_riverpod.dart';
          import 'dart:async';
        ''',
        'lib/features/a/presentation/page.dart': '''
          import '../application/provider.dart';
          import '../domain/entity.dart';
        ''',
      }),
      {
        for (final target in [
          'lib/features/a/data/dto.dart',
          'lib/features/a/application/provider.dart',
          'lib/features/a/presentation/page.dart',
          'package:flutter/widgets.dart',
          'package:flutter_riverpod/flutter_riverpod.dart',
        ])
          'lib/features/a/domain/model.dart -> $target : R1',
      },
    );
  });

  test('normalizes escaped and percent-encoded URI paths', () {
    for (final uri in [
      r'../\u0064ata/dto.dart',
      r'package:oshi_log/features/a/\x64ata/dto.dart',
      '../%64ata/dto.dart',
    ]) {
      expect(
        findDependencyViolations({
          'lib/features/a/presentation/page.dart': "import '$uri';",
        }),
        {
          'lib/features/a/presentation/page.dart -> '
              'lib/features/a/data/dto.dart : R1',
        },
        reason: uri,
      );
    }
  });

  test('R2 rejects another feature data and presentation libraries', () {
    expect(
      findDependencyViolations({
        'lib/features/a/application/provider.dart': '''
          import '../../b/data/dto.dart';
          export 'package:oshi_log/features/b/presentation/page.dart';
          import '../data/repository.dart';
          import '../../b/domain/model.dart';
          import '../../b/application/provider.dart';
          import '../../ab/application/provider.dart';
        ''',
      }),
      {
        'lib/features/a/application/provider.dart -> '
            'lib/features/b/data/dto.dart : R2',
        'lib/features/a/application/provider.dart -> '
            'lib/features/b/presentation/page.dart : R2',
      },
    );
  });

  test('R4 checks both core and shared but permits app composition', () {
    expect(
      findDependencyViolations({
        for (final root in ['core', 'shared', 'app'])
          'lib/$root/provider.dart': '''
            import '../features/a/application/provider.dart';
            export 'package:oshi_log/features/b/domain/model.dart';
          ''',
      }),
      {
        for (final root in ['core', 'shared'])
          for (final target in [
            'lib/features/a/application/provider.dart',
            'lib/features/b/domain/model.dart',
          ])
            'lib/$root/provider.dart -> $target : R4',
      },
    );
  });

  test('R4 treats platform like core and shared', () {
    expect(
      findDependencyViolations({
        'lib/platform/notifications/service.dart':
            "import '../../features/a/domain/model.dart';",
        'lib/features/a/domain/model.dart': '',
      }),
      {
        'lib/platform/notifications/service.dart -> '
            'lib/features/a/domain/model.dart : R4',
      },
    );
  });

  test('R4 rejects feature imports and re-exports from design_system', () {
    expect(
      findDependencyViolations({
        'lib/design_system/widgets/shared.dart':
            "export '../../features/a/domain/model.dart';",
        'lib/design_system/theme/theme.dart':
            "import '../widgets/shared.dart';",
        'lib/features/a/domain/model.dart': '',
      }),
      {
        'lib/design_system/widgets/shared.dart -> '
            'lib/features/a/domain/model.dart : R4',
        'lib/design_system/theme/theme.dart -> '
            'lib/features/a/domain/model.dart : R4',
      },
    );
  });

  test('R3 rejects a feature importing app, but permits sibling imports', () {
    expect(
      findDependencyViolations({
        'lib/features/a/application/provider.dart': '''
          import '../../../app/compositions/thing.dart';
          import '../domain/model.dart';
        ''',
        'lib/app/compositions/thing.dart': '',
        'lib/features/a/domain/model.dart': '',
      }),
      {
        'lib/features/a/application/provider.dart -> '
            'lib/app/compositions/thing.dart : R3',
      },
    );
  });

  test('follows nested exports and terminates on barrel cycles', () {
    final violations = findDependencyViolations({
      'lib/features/a/presentation/page.dart': "import '../../b/b.dart';",
      'lib/features/b/b.dart': "export 'public.dart';",
      'lib/features/b/public.dart': '''
        export 'b.dart';
        export 'data/dto.dart' show Dto;
      ''',
      'lib/features/b/data/dto.dart': '',
      'lib/core/bridge.dart': "import '../app/public.dart';",
      'lib/app/public.dart': "export '../features/b/b.dart';",
    });

    expect(violations, {
      'lib/features/a/presentation/page.dart -> '
          'lib/features/b/data/dto.dart : R1',
      'lib/features/a/presentation/page.dart -> '
          'lib/features/b/data/dto.dart : R2',
      for (final target in ['b.dart', 'public.dart', 'data/dto.dart'])
        'lib/core/bridge.dart -> lib/features/b/$target : R4',
    });
  });

  test('domain cannot import Flutter through a barrel', () {
    expect(
      findDependencyViolations({
        'lib/features/a/domain/model.dart': "import '../../../public.dart';",
        'lib/public.dart': "export 'package:flutter/foundation.dart';",
      }),
      {
        'lib/features/a/domain/model.dart -> '
            'package:flutter/foundation.dart : R1',
      },
    );
  });

  test('does not follow private imports behind public providers', () {
    expect(
      findDependencyViolations({
        'lib/features/a/presentation/page.dart':
            "import '../../b/application/provider.dart';",
        'lib/features/b/application/provider.dart':
            "import '../data/repository.dart';",
        'lib/features/b/data/repository.dart': '',
      }),
      isEmpty,
    );
  });

  test(
    'reads multiline and conditional directives, ignoring quoted values',
    () {
      expect(
        findDependencyViolations({
          'lib/core/bridge.dart': '''
          import
            '../fallback.dart'
            if (dart.library.io) '../features/a/domain/io.dart'
            if (runtime == 'not_a_uri.dart')
              'package:oshi_log/features/b/domain/web.dart';
          export r'../features/c/domain/raw.dart';
        ''',
        }),
        {
          for (final target in [
            'a/domain/io.dart',
            'b/domain/web.dart',
            'c/domain/raw.dart',
          ])
            'lib/core/bridge.dart -> lib/features/$target : R4',
        },
      );
    },
  );

  test('ignores directives inside comments and string literals', () {
    expect(
      findDependencyViolations({
        'lib/core/example.dart': '''
          // import '../features/a/data/line.dart';
          /* nested /* comment */
             export '../features/a/data/block.dart'; */
          const example = "import '../features/a/data/string.dart';";
          const multiline = """
            export '../features/a/data/multiline.dart';
          """;
          const raw = r"export '../features/a/data/raw.dart';";
        ''',
      }),
      isEmpty,
    );
  });

  test('R5 records exact file edges in a three-feature cycle', () {
    expect(
      findDependencyViolations({
        'lib/features/a/application/a.dart':
            "import '../../b/application/b.dart';",
        'lib/features/b/application/b.dart':
            "import '../../c/application/c.dart';",
        'lib/features/c/application/c.dart':
            "export '../../a/application/a.dart';",
        'lib/features/d/application/d.dart':
            "import '../../a/application/a.dart';",
      }),
      {
        'lib/features/a/application/a.dart -> '
            'lib/features/b/application/b.dart : R5',
        'lib/features/b/application/b.dart -> '
            'lib/features/c/application/c.dart : R5',
        'lib/features/b/application/b.dart -> '
            'lib/features/a/application/a.dart : R5',
        'lib/features/c/application/c.dart -> '
            'lib/features/a/application/a.dart : R5',
      },
    );
  });

  test('R5 catches a cycle hidden by a barrel outside features', () {
    expect(
      findDependencyViolations({
        'lib/features/a/application/a.dart': "import '../../../public.dart';",
        'lib/public.dart': "export 'features/b/application/b.dart';",
        'lib/features/b/application/b.dart':
            "import '../../a/application/a.dart';",
      }),
      {
        'lib/features/a/application/a.dart -> '
            'lib/features/b/application/b.dart : R5',
        'lib/features/b/application/b.dart -> '
            'lib/features/a/application/a.dart : R5',
      },
    );
  });

  test('R5 permits acyclic features and cycles within one feature', () {
    expect(
      findDependencyViolations({
        'lib/features/a/application/a.dart': '''
          import 'local.dart';
          import '../../b/application/b.dart';
        ''',
        'lib/features/a/application/local.dart': "import 'a.dart';",
        'lib/features/b/application/b.dart':
            "import '../../c/domain/model.dart';",
        'lib/features/c/domain/model.dart': '',
      }),
      isEmpty,
    );
  });

  const oldEdge = 'lib/core/a.dart -> lib/features/a/domain/a.dart : R4';
  const newEdge = 'lib/core/a.dart -> lib/features/b/domain/b.dart : R4';

  test('allowlist accepts only exact current edges', () {
    expect(
      compareDependencyAllowlist({oldEdge}, '# Existing debt\n$oldEdge\n'),
      isEmpty,
    );
  });

  test('allowlist rejects new edges even when total count is unchanged', () {
    expect(compareDependencyAllowlist({newEdge}, oldEdge), [
      'New dependency: $newEdge',
      'Remove stale allowance: $oldEdge',
    ]);
  });

  test('allowlist must shrink when violations disappear', () {
    expect(compareDependencyAllowlist({}, oldEdge), [
      'Remove stale allowance: $oldEdge',
    ]);
  });

  test('allowlist rejects malformed and duplicate entries', () {
    for (final text in [
      'lib/** -> * : R4',
      '$oldEdge\n$oldEdge',
      'lib/core/a.dart -> lib/features/a/domain/a.dart : R6',
    ]) {
      expect(() => compareDependencyAllowlist({}, text), throwsFormatException);
    }
  });
}
