/// EN: GBT Search Bar component
/// KO: GBT 검색바 컴포넌트
library;

import 'package:flutter/material.dart';

import '../../theme/gbt_colors.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';

/// EN: GBT Search Bar widget
/// KO: GBT 검색바 위젯
class GBTSearchBar extends StatefulWidget {
  const GBTSearchBar({
    super.key,
    this.controller,
    this.hint = '검색',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onTap,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.leading,
    this.trailing,
  });

  /// EN: Text editing controller
  /// KO: 텍스트 편집 컨트롤러
  final TextEditingController? controller;

  /// EN: Hint text
  /// KO: 힌트 텍스트
  final String hint;

  /// EN: Callback when text changes
  /// KO: 텍스트 변경 시 콜백
  final ValueChanged<String>? onChanged;

  /// EN: Callback when submitted
  /// KO: 제출 시 콜백
  final ValueChanged<String>? onSubmitted;

  /// EN: Callback when cleared
  /// KO: 지우기 시 콜백
  final VoidCallback? onClear;

  /// EN: Callback when tapped
  /// KO: 탭 시 콜백
  final VoidCallback? onTap;

  /// EN: Whether to autofocus
  /// KO: 자동 포커스 여부
  final bool autofocus;

  /// EN: Whether the search bar is enabled
  /// KO: 검색바 활성화 여부
  final bool enabled;

  /// EN: Whether the search bar is read-only
  /// KO: 검색바가 읽기 전용인지 여부
  final bool readOnly;

  /// EN: Focus node
  /// KO: 포커스 노드
  final FocusNode? focusNode;

  /// EN: Leading widget
  /// KO: 선행 위젯
  final Widget? leading;

  /// EN: Trailing widget
  /// KO: 후행 위젯
  final Widget? trailing;

  @override
  State<GBTSearchBar> createState() => _GBTSearchBarState();
}

class _GBTSearchBarState extends State<GBTSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _ownsFocusNode = widget.focusNode == null;
    _hasText = _controller.text.isNotEmpty;
    _isFocused = _focusNode.hasFocus;
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (widget.controller == null) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onFocusChanged() {
    final isFocused = _focusNode.hasFocus;
    if (_isFocused != isFocused) {
      setState(() => _isFocused = isFocused);
    }
  }

  void _onClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? GBTColors.darkPrimary : GBTColors.primary;
    // EN: Muted surface background — matches Twitter/Instagram/Naver style search bars.
    //     surfaceVariant gives clear contrast against page background without a hard border.
    // KO: 뮤트된 표면 배경 — 트위터/인스타그램/네이버 스타일 검색바에 맞춤.
    //     surfaceVariant는 딱딱한 테두리 없이 페이지 배경과 명확한 대비를 제공.
    final bgColor = isDark
        ? GBTColors.darkSurfaceVariant
        : GBTColors.surfaceVariant;
    final iconColor = _isFocused
        ? primaryColor
        : (isDark ? GBTColors.darkTextSecondary : GBTColors.textSecondary);

    // EN: Let TextField expose its localized native semantics. A wrapper label
    //     would duplicate the field and can mix languages with a localized hint.
    // KO: TextField가 지역화된 네이티브 시맨틱을 제공하게 합니다.
    //     래퍼 라벨은 필드를 중복하고 지역화 힌트와 언어를 섞을 수 있습니다.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: GBTSpacing.touchTarget,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
        // EN: Transparent border in rest state — animates smoothly to primary on focus.
        //     Using transparent (not null) enables AnimatedContainer interpolation.
        // KO: 휴지 상태는 투명 테두리 — 포커스 시 primary로 부드럽게 보간.
        //     null 대신 transparent를 사용해 AnimatedContainer 보간 가능.
        border: Border.all(
          color: _isFocused ? primaryColor : Colors.transparent,
          width: 2,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: GBTSpacing.md),
            child:
                widget.leading ??
                Icon(
                  Icons.search_rounded,
                  color: iconColor,
                  size: GBTSpacing.iconSm,
                ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              style: GBTTypography.bodyMedium.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
              ),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GBTTypography.bodyMedium.copyWith(
                  color: isDark
                      ? GBTColors.darkTextTertiary
                      : GBTColors.textSecondary,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: GBTSpacing.sm,
                ),
              ),
            ),
          ),
          if (_hasText)
            Tooltip(
              message: MaterialLocalizations.of(context).deleteButtonTooltip,
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark
                      ? GBTColors.darkTextSecondary
                      : GBTColors.textSecondary,
                  size: GBTSpacing.iconSm,
                ),
                onPressed: _onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: GBTSpacing.minTouchTarget,
                  minHeight: GBTSpacing.minTouchTarget,
                ),
              ),
            )
          else if (widget.trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: GBTSpacing.sm),
              child: widget.trailing,
            )
          else
            const SizedBox(width: GBTSpacing.md),
        ],
      ),
    );
  }
}

/// EN: Tappable search bar for navigation
/// KO: 네비게이션용 탭 가능한 검색바
class GBTSearchBarButton extends StatelessWidget {
  const GBTSearchBarButton({super.key, required this.onTap, this.hint = '검색'});

  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? GBTColors.darkSurfaceVariant : GBTColors.surface;

    return Semantics(
      button: true,
      label: '$hint 검색바',
      hint: '탭하면 검색 화면으로 이동합니다',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: GBTSpacing.touchTarget,
          padding: const EdgeInsets.symmetric(horizontal: GBTSpacing.md),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(GBTSpacing.radiusFull),
            border: Border.all(
              color: isDark
                  ? GBTColors.darkBorder
                  : GBTColors.border.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: isDark ? 10 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: isDark
                    ? GBTColors.darkTextTertiary
                    : GBTColors.textTertiary,
                size: GBTSpacing.iconSm,
              ),
              const SizedBox(width: GBTSpacing.sm),
              Text(
                hint,
                style: GBTTypography.bodyMedium.copyWith(
                  color: isDark
                      ? GBTColors.darkTextTertiary
                      : GBTColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
