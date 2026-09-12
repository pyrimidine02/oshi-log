import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/widgets/common/gbt_linkified_text.dart';

void main() {
  testWidgets('linkifies HTTPS and www URLs surrounded by whitespace', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GBTLinkifiedText(
            '  Official: https://example.com/profile, and www.example.org/about.  ',
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    final linkedSpans = _textSpans(
      richText.text,
    ).where((span) => span.recognizer != null).toList();

    expect(linkedSpans, hasLength(2));
    expect(
      linkedSpans.map((span) => span.text),
      containsAll(<String>[
        'https://example.com/profile',
        'www.example.org/about',
      ]),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves trailing punctuation outside clickable URL spans', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GBTLinkifiedText('See https://example.com/profile).'),
        ),
      ),
    );

    final richText = tester.widget<RichText>(find.byType(RichText));
    final spans = _textSpans(richText.text).toList();
    final linkedSpans = spans.where((span) => span.recognizer != null).toList();
    final plainSpans = spans
        .where((span) => span.recognizer == null)
        .map((span) => span.text ?? '')
        .join();

    expect(linkedSpans.single.text, 'https://example.com/profile');
    expect(plainSpans, contains(').'));
    expect(tester.takeException(), isNull);
  });
}

Iterable<TextSpan> _textSpans(InlineSpan span) sync* {
  if (span is! TextSpan) return;
  yield span;
  for (final child in span.children ?? const <InlineSpan>[]) {
    yield* _textSpans(child);
  }
}
