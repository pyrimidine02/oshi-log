import 'dart:io';

/// EN: Checks file dependencies, following exports but never private imports.
/// KO: export를 추적하되 내부 import는 전파하지 않고 파일 의존성을 검사합니다.
Set<String> findDependencyViolations(Map<String, String> sources) {
  final directives = {
    for (final entry in sources.entries)
      entry.key: _directives(entry.key, entry.value).toList(),
  };
  final dependencies = <String, Set<String>>{};
  final featureGraph = <String, Set<String>>{};
  final violations = <String>{};

  for (final source in sources.keys) {
    final targets = <String>{};
    final pending = [for (final edge in directives[source]!) edge.target];
    while (pending.isNotEmpty) {
      final target = pending.removeLast();
      if (!targets.add(target)) continue;
      for (final edge in directives[target] ?? <_Directive>[]) {
        if (edge.isExport) pending.add(edge.target);
      }
    }
    dependencies[source] = targets;
    final sourceFeature = _feature(source);
    for (final target in targets) {
      final targetFeature = _feature(target);
      if (sourceFeature != null) {
        final domainViolation =
            source.contains('/domain/') &&
            (target.contains('/data/') ||
                target.contains('/presentation/') ||
                target.contains('/application/') ||
                target.startsWith('package:flutter'));
        final presentationViolation =
            source.contains('/presentation/') && target.contains('/data/');
        if (domainViolation || presentationViolation) {
          violations.add('$source -> $target : R1');
        }
        if (targetFeature != null && targetFeature != sourceFeature) {
          (featureGraph[sourceFeature] ??= {}).add(targetFeature);
          if (target.contains('/data/') || target.contains('/presentation/')) {
            violations.add('$source -> $target : R2');
          }
        }
      }
      if (targetFeature != null &&
          (source.startsWith('lib/core/') ||
              source.startsWith('lib/shared/') ||
              source.startsWith('lib/platform/'))) {
        violations.add('$source -> $target : R4');
      }
      if (sourceFeature != null && target.startsWith('lib/app/')) {
        violations.add('$source -> $target : R3');
      }
    }
  }

  // EN: Record every file edge in a cycle, so new edges in old cycles fail too.
  // KO: 기존 순환에 추가된 의존성도 실패하도록 순환의 모든 파일 간선을 기록합니다.
  final reachable = {
    for (final feature in featureGraph.keys)
      feature: _reachableFeatures(feature, featureGraph),
  };
  for (final entry in dependencies.entries) {
    final sourceFeature = _feature(entry.key);
    if (sourceFeature == null) continue;
    for (final target in entry.value) {
      final targetFeature = _feature(target);
      if (targetFeature != null &&
          targetFeature != sourceFeature &&
          (reachable[targetFeature]?.contains(sourceFeature) ?? false)) {
        violations.add('${entry.key} -> $target : R5');
      }
    }
  }
  return violations;
}

String? _feature(String path) {
  final parts = path.split('/');
  return parts.length >= 4 && parts[0] == 'lib' && parts[1] == 'features'
      ? parts[2]
      : null;
}

Set<String> _reachableFeatures(String source, Map<String, Set<String>> graph) {
  final visited = <String>{};
  final pending = [...?graph[source]];
  while (pending.isNotEmpty) {
    final target = pending.removeLast();
    if (visited.add(target)) pending.addAll(graph[target] ?? {});
  }
  return visited;
}

typedef _Directive = ({String target, bool isExport});

Iterable<_Directive> _directives(String path, String source) sync* {
  String? directive;
  var parentheses = 0;
  for (final token in _tokens(source)) {
    if (token == 'import' || token == 'export') {
      directive = token;
    } else if (token == ';') {
      directive = null;
      parentheses = 0;
    } else if (directive != null) {
      if (token == '(') parentheses++;
      if (token == ')') parentheses--;
      final literal = token.startsWith('r') ? token.substring(1) : token;
      if (parentheses == 0 &&
          (literal.startsWith("'") || literal.startsWith('"'))) {
        final width = literal.startsWith(literal[0] * 3) ? 3 : 1;
        var uri = literal.substring(width, literal.length - width);
        if (!token.startsWith('r')) {
          uri = uri.replaceAllMapped(_escape, (match) {
            final hex = match[1] ?? match[2] ?? match[3];
            return hex == null
                ? match[4]!
                : String.fromCharCode(int.parse(hex, radix: 16));
          });
        }
        yield (
          target: _normalizeUri(path, uri),
          isExport: directive == 'export',
        );
      }
    }
  }
}

String _normalizeUri(String source, String value) {
  const packagePrefix = 'package:oshi_log/';
  if (value.startsWith(packagePrefix)) {
    return Uri(
      path: '/lib/',
    ).resolve(value.substring(packagePrefix.length)).path.substring(1);
  }
  final uri = Uri.parse(value);
  if (uri.hasScheme) return uri.toString();
  return Uri(path: '/$source').resolveUri(uri).path.substring(1);
}

// EN: A small lexer skips comments/strings and keeps all conditional URI arms.
// KO: 작은 렉서로 주석/문자열을 건너뛰고 조건부 URI의 모든 분기를 검사합니다.
final _word = RegExp(r'[a-zA-Z_$][\w$]*');
final _space = RegExp(r'\s+');
final _commentBoundary = RegExp(r'/\*|\*/');
final _escape = RegExp(
  r'\\(?:x([0-9a-fA-F]{2})|u\{([0-9a-fA-F]{1,6})\}|u([0-9a-fA-F]{4})|(.))',
);

Iterable<String> _tokens(String source) sync* {
  var offset = 0;
  while (offset < source.length) {
    final start = offset;
    final whitespace = _space.matchAsPrefix(source, offset);
    if (whitespace != null) {
      offset = whitespace.end;
      continue;
    }
    if (source.startsWith('//', offset)) {
      final end = source.indexOf('\n', offset);
      offset = end < 0 ? source.length : end + 1;
      continue;
    }
    if (source.startsWith('/*', offset)) {
      var depth = 1;
      for (final match in _commentBoundary.allMatches(source, offset + 2)) {
        depth += match[0] == '/*' ? 1 : -1;
        if (depth == 0) {
          offset = match.end;
          break;
        }
      }
      if (depth != 0) throw FormatException('Unterminated comment at $start');
      continue;
    }
    final raw =
        source.startsWith("r'", offset) || source.startsWith('r"', offset);
    if (raw) offset++;
    final quote = source[offset];
    if (quote == "'" || quote == '"') {
      final delimiter = source.startsWith(quote * 3, offset)
          ? quote * 3
          : quote;
      offset += delimiter.length;
      while (offset < source.length && !source.startsWith(delimiter, offset)) {
        offset += !raw && source[offset] == '\\' ? 2 : 1;
      }
      if (offset >= source.length) {
        throw FormatException('Unterminated string at $start');
      }
      offset += delimiter.length;
    } else {
      offset = _word.matchAsPrefix(source, offset)?.end ?? offset + 1;
    }
    yield source.substring(start, offset);
  }
}

List<String> compareDependencyAllowlist(Set<String> actual, String allowlist) {
  final expected = <String>{};
  final entryPattern = RegExp(
    r'^lib/[\w./-]+\.dart -> (lib/[\w./-]+\.dart|package:[\w./-]+) : R[12345]$',
  );
  for (final line in allowlist.split('\n')) {
    final entry = line.trim();
    if (entry.isEmpty || entry.startsWith('#')) continue;
    if (!entryPattern.hasMatch(entry) || !expected.add(entry)) {
      throw FormatException(
        'Invalid or duplicate dependency allowance: $entry',
      );
    }
  }
  return [
    for (final entry in actual.difference(expected).toList()..sort())
      'New dependency: $entry',
    for (final entry in expected.difference(actual).toList()..sort())
      'Remove stale allowance: $entry',
  ];
}

Map<String, String> readLibrarySources() => {
  for (final file in Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>())
    if (file.path.endsWith('.dart'))
      file.path.replaceAll('\\', '/'): file.readAsStringSync(),
};

/// EN: Explicit snapshot command; tests never rewrite the allowlist.
/// KO: 명시적인 스냅샷 명령이며 테스트는 허용 목록을 자동 수정하지 않습니다.
/// dart test/architecture/dependency_checker.dart >
///   test/architecture/dependency_allowlist.txt
void main() {
  final violations = findDependencyViolations(readLibrarySources()).toList()
    ..sort();
  stdout.writeAll(violations, '\n');
  stdout.writeln();
}
