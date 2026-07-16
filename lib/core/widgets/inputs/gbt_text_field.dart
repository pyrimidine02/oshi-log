/// EN: GBT Text Field component with validation support
/// KO: 유효성 검사를 지원하는 GBT 텍스트 필드 컴포넌트
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../accessibility/a11y_wrapper.dart';
import '../../theme/gbt_colors.dart';
import '../../theme/gbt_spacing.dart';
import '../../theme/gbt_typography.dart';

/// EN: GBT Text Field widget
/// KO: GBT 텍스트 필드 위젯
class GBTTextField extends StatefulWidget {
  const GBTTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.suffixTooltip,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.semanticLabel,
  });

  /// EN: Text editing controller
  /// KO: 텍스트 편집 컨트롤러
  final TextEditingController? controller;

  /// EN: Label text displayed above input
  /// KO: 입력 위에 표시되는 라벨 텍스트
  final String? label;

  /// EN: Hint text displayed when empty
  /// KO: 빈 상태일 때 표시되는 힌트 텍스트
  final String? hint;

  /// EN: Helper text displayed below input
  /// KO: 입력 아래에 표시되는 도움 텍스트
  final String? helperText;

  /// EN: Error text for validation
  /// KO: 유효성 검사용 오류 텍스트
  final String? errorText;

  /// EN: Icon displayed at start of input
  /// KO: 입력 시작에 표시되는 아이콘
  final IconData? prefixIcon;

  /// EN: Icon displayed at end of input
  /// KO: 입력 끝에 표시되는 아이콘
  final IconData? suffixIcon;

  /// EN: Callback when suffix icon is tapped
  /// KO: 접미 아이콘이 탭되었을 때 콜백
  final VoidCallback? onSuffixTap;

  /// EN: Tooltip for suffix icon button
  /// KO: 접미 아이콘 버튼의 툴팁
  final String? suffixTooltip;

  /// EN: Whether to obscure text (for passwords)
  /// KO: 텍스트를 숨길지 여부 (비밀번호용)
  final bool obscureText;

  /// EN: Whether the field is enabled
  /// KO: 필드 활성화 여부
  final bool enabled;

  /// EN: Whether the field is read-only
  /// KO: 필드가 읽기 전용인지 여부
  final bool readOnly;

  /// EN: Whether to autofocus
  /// KO: 자동 포커스 여부
  final bool autofocus;

  /// EN: Maximum lines for multiline input
  /// KO: 여러 줄 입력을 위한 최대 줄 수
  final int maxLines;

  /// EN: Minimum lines for multiline input
  /// KO: 여러 줄 입력을 위한 최소 줄 수
  final int? minLines;

  /// EN: Maximum character length
  /// KO: 최대 문자 길이
  final int? maxLength;

  /// EN: Keyboard type
  /// KO: 키보드 타입
  final TextInputType? keyboardType;

  /// EN: Text input action
  /// KO: 텍스트 입력 액션
  final TextInputAction? textInputAction;

  /// EN: Input formatters
  /// KO: 입력 포매터
  final List<TextInputFormatter>? inputFormatters;

  /// EN: Validator function
  /// KO: 유효성 검사 함수
  final String? Function(String?)? validator;

  /// EN: Callback when text changes
  /// KO: 텍스트 변경 시 콜백
  final ValueChanged<String>? onChanged;

  /// EN: Callback when submitted
  /// KO: 제출 시 콜백
  final ValueChanged<String>? onSubmitted;

  /// EN: Callback when tapped
  /// KO: 탭 시 콜백
  final VoidCallback? onTap;

  /// EN: Focus node
  /// KO: 포커스 노드
  final FocusNode? focusNode;

  /// EN: Semantic label for accessibility
  /// KO: 접근성을 위한 시맨틱 라벨
  final String? semanticLabel;

  @override
  State<GBTTextField> createState() => _GBTTextFieldState();
}

class _GBTTextFieldState extends State<GBTTextField> {
  bool _isObscured = true;
  String? _previousErrorText;

  FocusNode? _internalFocusNode;
  bool _isFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
    _previousErrorText = widget.errorText;
    _internalFocusNode = widget.focusNode == null ? FocusNode() : null;
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _effectiveFocusNode.hasFocus;
    });
  }

  @override
  void didUpdateWidget(GBTTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // EN: Announce error to screen reader when errorText changes
    // KO: errorText가 변경될 때 스크린 리더에 에러 공지
    if (widget.errorText != _previousErrorText &&
        widget.errorText != null &&
        widget.errorText!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          A11yAnnouncer.announceError(context, widget.errorText!);
        }
      });
    }
    _previousErrorText = widget.errorText;
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // EN: Build complete semantic label with error/helper state
    // KO: 오류/도움 상태를 포함한 완전한 시맨틱 라벨 빌드
    final baseLabel = widget.semanticLabel ?? widget.label ?? '';
    final errorSuffix = hasError ? ', 오류: ${widget.errorText}' : '';
    final fullLabel = '$baseLabel$errorSuffix';

    return Semantics(
      label: fullLabel,
      textField: true,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // EN: Label with dark mode color awareness
          // KO: 다크 모드 색상 인식 라벨
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: GBTTypography.labelMedium.copyWith(
                color: hasError
                    ? GBTColors.error
                    : (isDark
                          ? GBTColors.darkTextSecondary
                          : GBTColors.textSecondary),
              ),
            ),
            const SizedBox(height: GBTSpacing.xs),
          ],

          // EN: Text field with dark mode text style and glow animation
          // KO: 다크 모드 텍스트 스타일과 발광 애니메이션이 적용된 텍스트 필드
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCirc,
            decoration: BoxDecoration(
              // EN: Radius matches the themed input border (GBTSpacing.radiusLg)
              // so the focus glow traces the field's actual rounded corners.
              // KO: 테마 입력 테두리 반지름(GBTSpacing.radiusLg)과 일치시켜
              // 포커스 글로우가 필드의 실제 둥근 모서리를 따라가도록 합니다.
              borderRadius: BorderRadius.circular(GBTSpacing.radiusLg),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color:
                            (isDark ? GBTColors.darkPrimary : GBTColors.primary)
                                .withValues(alpha: 0.25),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _effectiveFocusNode,
              obscureText: widget.obscureText && _isObscured,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              validator: widget.validator,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              style: GBTTypography.bodyMedium.copyWith(
                color: isDark
                    ? GBTColors.darkTextPrimary
                    : GBTColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: GBTTypography.bodyMedium.copyWith(
                  color: isDark
                      ? GBTColors.darkTextTertiary
                      : GBTColors.textTertiary,
                ),
                errorText: widget.errorText,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, size: GBTSpacing.iconSm)
                    : null,
                suffixIcon: _buildSuffixIcon(),
              ),
            ),
          ),

          // EN: Helper text with dark mode color awareness
          // KO: 다크 모드 색상 인식 도움 텍스트
          if (widget.helperText != null && !hasError) ...[
            const SizedBox(height: GBTSpacing.xs),
            Text(
              widget.helperText!,
              style: GBTTypography.bodySmall.copyWith(
                color: isDark
                    ? GBTColors.darkTextTertiary
                    : GBTColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// EN: Build suffix icon widget with tooltip for accessibility
  /// KO: 접근성을 위한 툴팁이 포함된 접미 아이콘 위젯 빌드
  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      // EN: Visibility toggle with tooltip
      // KO: 툴팁이 포함된 가시성 토글
      return Tooltip(
        message: _isObscured ? '비밀번호 표시' : '비밀번호 숨기기',
        child: IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility_off : Icons.visibility,
            size: GBTSpacing.iconSm,
          ),
          onPressed: () {
            setState(() => _isObscured = !_isObscured);
          },
        ),
      );
    }

    if (widget.suffixIcon != null) {
      final iconButton = IconButton(
        icon: Icon(widget.suffixIcon, size: GBTSpacing.iconSm),
        onPressed: widget.onSuffixTap,
      );
      // EN: Wrap with tooltip if provided
      // KO: 제공된 경우 툴팁으로 감싸기
      if (widget.suffixTooltip != null) {
        return Tooltip(message: widget.suffixTooltip!, child: iconButton);
      }
      return iconButton;
    }

    return null;
  }
}

/// EN: Password text field with visibility toggle
/// KO: 가시성 토글이 있는 비밀번호 텍스트 필드
class GBTPasswordField extends StatelessWidget {
  const GBTPasswordField({
    super.key,
    this.controller,
    this.label = '비밀번호',
    this.hint = '비밀번호를 입력하세요',
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String label;
  final String hint;
  final String? errorText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return GBTTextField(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      obscureText: true,
      prefixIcon: Icons.lock_outline,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      semanticLabel: label,
    );
  }
}

/// EN: Email text field with validation
/// KO: 유효성 검사가 있는 이메일 텍스트 필드
class GBTEmailField extends StatelessWidget {
  const GBTEmailField({
    super.key,
    this.controller,
    this.label = '이메일',
    this.hint = '이메일을 입력하세요',
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final String label;
  final String hint;
  final String? errorText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return GBTTextField(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: validator,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      semanticLabel: label,
    );
  }
}
