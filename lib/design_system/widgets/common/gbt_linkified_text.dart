/// EN: Text widget that detects URLs and opens them externally.
/// KO: URL을 감지해 외부 브라우저로 여는 텍스트 위젯입니다.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GBTLinkifiedText extends StatefulWidget {
  const GBTLinkifiedText(
    this.text, {
    super.key,
    this.style,
    this.linkStyle,
    this.leadingText,
    this.leadingStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.textAlign = TextAlign.start,
    this.selectable = false,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final String? leadingText;
  final TextStyle? leadingStyle;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign textAlign;
  final bool selectable;

  @override
  State<GBTLinkifiedText> createState() => _GBTLinkifiedTextState();
}

class _GBTLinkifiedTextState extends State<GBTLinkifiedText> {
  static final RegExp _urlPattern = RegExp(
    r'(https?:\/\/[^\s<>"\]\)}]+|www\.[^\s<>"\]\)}]+)',
    caseSensitive: false,
  );
  static const String _trailingPunctuation = '.,!?;:)]}>"\'';
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans(context);
    if (widget.selectable) {
      return SelectableText.rich(
        TextSpan(children: spans),
        textAlign: widget.textAlign,
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }

  List<InlineSpan> _buildSpans(BuildContext context) {
    _disposeRecognizers();
    final text = widget.text;
    final spans = <InlineSpan>[];
    var cursor = 0;

    if (widget.leadingText != null && widget.leadingText!.isNotEmpty) {
      spans.add(
        TextSpan(
          text: widget.leadingText,
          style: widget.leadingStyle ?? widget.style,
        ),
      );
    }

    final matches = _urlPattern.allMatches(text);
    if (matches.isEmpty) {
      spans.add(TextSpan(text: text, style: widget.style));
      return spans;
    }

    final linkStyle =
        widget.linkStyle ??
        widget.style?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ) ??
        TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        );

    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, match.start),
            style: widget.style,
          ),
        );
      }

      final rawMatch = match.group(0) ?? '';
      final split = _splitUrlAndTrailing(rawMatch);
      if (split.url.isNotEmpty) {
        final uri = _buildLaunchUri(split.url);
        if (uri == null) {
          spans.add(TextSpan(text: split.url, style: widget.style));
        } else {
          final recognizer = TapGestureRecognizer()
            ..onTap = () => _openUri(uri);
          _recognizers.add(recognizer);
          spans.add(
            TextSpan(text: split.url, style: linkStyle, recognizer: recognizer),
          );
        }
      }

      if (split.trailing.isNotEmpty) {
        spans.add(TextSpan(text: split.trailing, style: widget.style));
      }

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: widget.style));
    }
    return spans;
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  _UrlMatchSplit _splitUrlAndTrailing(String raw) {
    var end = raw.length;
    while (end > 0 && _trailingPunctuation.contains(raw[end - 1])) {
      end -= 1;
    }
    return _UrlMatchSplit(
      url: raw.substring(0, end),
      trailing: raw.substring(end),
    );
  }

  Uri? _buildLaunchUri(String rawUrl) {
    final normalized =
        rawUrl.startsWith(RegExp(r'https?:\/\/', caseSensitive: false))
        ? rawUrl
        : 'https://$rawUrl';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return uri;
  }

  Future<void> _openUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _UrlMatchSplit {
  const _UrlMatchSplit({required this.url, required this.trailing});

  final String url;
  final String trailing;
}
