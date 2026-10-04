/// EN: Keeps spoiler content out of rendering and accessibility until requested.
/// KO: 사용자가 요청하기 전 스포일러 콘텐츠의 렌더링과 접근성을 차단합니다.
library;

import 'package:flutter/material.dart';
import 'package:oshi_log/design_system/localization/locale_text.dart';
import 'package:oshi_log/design_system/theme/theme.dart';

class SpoilerGuard extends StatefulWidget {
  const SpoilerGuard({
    super.key,
    required this.child,
    this.contentId,
    this.title,
  });

  final Widget child;
  final Object? contentId;
  final String? title;

  @override
  State<SpoilerGuard> createState() => _SpoilerGuardState();
}

class _SpoilerGuardState extends State<SpoilerGuard> {
  bool _revealed = false;

  @override
  void didUpdateWidget(covariant SpoilerGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contentId != widget.contentId) _revealed = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null)
          Text(widget.title!, style: Theme.of(context).textTheme.titleMedium),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: () => setState(() => _revealed = !_revealed),
          icon: Icon(
            _revealed
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          label: Text(
            _revealed
                ? context.l10n(
                    ko: '스포일러 숨기기',
                    en: 'Hide spoilers',
                    ja: 'ネタバレを隠す',
                  )
                : context.l10n(
                    ko: '스포일러 보기',
                    en: 'Show spoilers',
                    ja: 'ネタバレを表示',
                  ),
          ),
        ),
        if (_revealed) ...[const SizedBox(height: GBTSpacing.sm), widget.child],
      ],
    );
  }
}
