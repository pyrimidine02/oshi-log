/// EN: Accessibility wrapper and utilities
/// KO: 접근성 래퍼 및 유틸리티
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// EN: Wrapper widget for enhanced accessibility support
/// KO: 향상된 접근성 지원을 위한 래퍼 위젯
class A11yWrapper extends StatelessWidget {
  const A11yWrapper({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.isButton = false,
    this.isLink = false,
    this.isHeader = false,
    this.isImage = false,
    this.isLiveRegion = false,
    this.excludeSemantics = false,
    this.onTap,
    this.onLongPress,
  });

  /// EN: Child widget
  /// KO: 자식 위젯
  final Widget child;

  /// EN: Semantic label for screen readers
  /// KO: 스크린 리더용 시맨틱 라벨
  final String label;

  /// EN: Additional hint text
  /// KO: 추가 힌트 텍스트
  final String? hint;

  /// EN: Whether this represents a button
  /// KO: 버튼을 나타내는지 여부
  final bool isButton;

  /// EN: Whether this represents a link
  /// KO: 링크를 나타내는지 여부
  final bool isLink;

  /// EN: Whether this is a header
  /// KO: 헤더인지 여부
  final bool isHeader;

  /// EN: Whether this is an image
  /// KO: 이미지인지 여부
  final bool isImage;

  /// EN: Whether this is a live region (dynamic content)
  /// KO: 라이브 영역(동적 콘텐츠)인지 여부
  final bool isLiveRegion;

  /// EN: Whether to exclude child semantics
  /// KO: 자식 시맨틱스를 제외할지 여부
  final bool excludeSemantics;

  /// EN: Tap callback for accessibility actions
  /// KO: 접근성 액션을 위한 탭 콜백
  final VoidCallback? onTap;

  /// EN: Long press callback for accessibility actions
  /// KO: 접근성 액션을 위한 길게 누르기 콜백
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      link: isLink,
      header: isHeader,
      image: isImage,
      liveRegion: isLiveRegion,
      excludeSemantics: excludeSemantics,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }
}

/// EN: Semantic heading wrapper for proper heading hierarchy
/// KO: 적절한 제목 계층을 위한 시맨틱 헤딩 래퍼
class A11yHeading extends StatelessWidget {
  const A11yHeading({super.key, required this.child, required this.level});

  final Widget child;

  /// EN: Heading level (1-6)
  /// KO: 제목 레벨 (1-6)
  final int level;

  @override
  Widget build(BuildContext context) {
    return Semantics(header: true, child: child);
  }
}

/// EN: Skip to content link for keyboard navigation
/// KO: 키보드 네비게이션을 위한 콘텐츠로 건너뛰기 링크
class A11ySkipLink extends StatelessWidget {
  const A11ySkipLink({
    super.key,
    required this.targetKey,
    this.label = '본문으로 건너뛰기',
  });

  /// EN: Global key of the target to skip to
  /// KO: 건너뛸 대상의 글로벌 키
  final GlobalKey targetKey;

  /// EN: Label for the skip link
  /// KO: 건너뛰기 링크의 라벨
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: label,
      child: Focus(
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            if (!hasFocus) return const SizedBox.shrink();

            // EN: Use Align instead of Positioned — Positioned requires a Stack parent
            // KO: Positioned 대신 Align 사용 — Positioned는 Stack 부모가 필요함
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                child: InkWell(
                  onTap: () {
                    final target = targetKey.currentContext;
                    if (target != null) {
                      Scrollable.ensureVisible(target);
                      FocusScope.of(target).requestFocus(Focus.of(target));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(label),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// EN: Announce a message to screen readers
/// KO: 스크린 리더에 메시지 알림
void announceToScreenReader(BuildContext context, String message) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    TextDirection.ltr,
  );
}

/// EN: Extension for common accessibility patterns
/// KO: 일반 접근성 패턴을 위한 확장
extension A11yExtensions on Widget {
  /// EN: Wrap with semantic label
  /// KO: 시맨틱 라벨로 래핑
  Widget withSemanticLabel(String label) {
    return Semantics(label: label, child: this);
  }

  /// EN: Mark as button for accessibility
  /// KO: 접근성을 위해 버튼으로 표시
  Widget asSemanticButton(String label, {VoidCallback? onTap}) {
    return Semantics(button: true, label: label, onTap: onTap, child: this);
  }

  /// EN: Mark as link for accessibility
  /// KO: 접근성을 위해 링크로 표시
  Widget asSemanticLink(String label) {
    return Semantics(link: true, label: label, child: this);
  }

  /// EN: Mark as image for accessibility
  /// KO: 접근성을 위해 이미지로 표시
  Widget asSemanticImage(String description) {
    return Semantics(image: true, label: description, child: this);
  }

  /// EN: Exclude from semantics tree
  /// KO: 시맨틱스 트리에서 제외
  Widget excludeFromSemantics() {
    return ExcludeSemantics(child: this);
  }

  /// EN: Merge child semantics
  /// KO: 자식 시맨틱스 병합
  Widget mergeSemantics() {
    return MergeSemantics(child: this);
  }
}

/// EN: Accessibility utilities
/// KO: 접근성 유틸리티
class A11yUtils {
  A11yUtils._();

  /// EN: Check if screen reader is enabled
  /// KO: 스크린 리더가 활성화되어 있는지 확인
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// EN: Check if reduce motion is enabled
  /// KO: 모션 감소가 활성화되어 있는지 확인
  static bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// EN: Check if bold text is enabled
  /// KO: 굵은 텍스트가 활성화되어 있는지 확인
  static bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// EN: Get current text scale factor
  /// KO: 현재 텍스트 스케일 팩터 반환
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  /// EN: Check if high contrast mode is enabled
  /// KO: 고대비 모드가 활성화되어 있는지 확인
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }
}

/// EN: Text widget with scalable font size based on user accessibility settings
/// KO: 사용자 접근성 설정에 따라 폰트 크기가 조정되는 텍스트 위젯
class A11yScalableText extends StatelessWidget {
  const A11yScalableText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticLabel,
  });

  /// EN: The text to display
  /// KO: 표시할 텍스트
  final String data;

  /// EN: Text style to apply
  /// KO: 적용할 텍스트 스타일
  final TextStyle? style;

  /// EN: Text alignment
  /// KO: 텍스트 정렬
  final TextAlign? textAlign;

  /// EN: Maximum number of lines
  /// KO: 최대 줄 수
  final int? maxLines;

  /// EN: Text overflow behavior
  /// KO: 텍스트 오버플로우 동작
  final TextOverflow? overflow;

  /// EN: Semantic label for screen readers (overrides text if provided)
  /// KO: 스크린 리더용 시맨틱 라벨 (제공되면 텍스트를 대체)
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // EN: Get user's text scale factor from system settings
    // KO: 시스템 설정에서 사용자의 텍스트 스케일 팩터 가져오기
    final scaleFactor = A11yUtils.getTextScaleFactor(context);

    // EN: Clamp scale factor between 1.0 and 2.0 to prevent layout overflow
    // KO: 레이아웃 오버플로우를 방지하기 위해 스케일 팩터를 1.0 ~ 2.0으로 제한
    final clampedScale = scaleFactor.clamp(1.0, 2.0);

    // EN: Calculate scaled font size with default fallback
    // KO: 기본값 폴백으로 조정된 폰트 크기 계산
    final baseFontSize = style?.fontSize ?? 14.0;
    final scaledFontSize = baseFontSize * clampedScale;

    // EN: Apply scaled font size to text style
    // KO: 텍스트 스타일에 조정된 폰트 크기 적용
    final scaledStyle = (style ?? const TextStyle()).copyWith(
      fontSize: scaledFontSize,
    );

    return Text(
      data,
      style: scaledStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      semanticsLabel: semanticLabel,
    );
  }
}

/// EN: Utility class for announcing messages to screen readers
/// KO: 스크린 리더에 메시지를 알리기 위한 유틸리티 클래스
class A11yAnnouncer {
  A11yAnnouncer._();

  /// EN: Announce a general message to screen readers
  /// KO: 스크린 리더에 일반 메시지 공지
  static void announce(BuildContext context, String message) {
    // EN: Ignore empty messages
    // KO: 빈 메시지는 무시
    if (message.trim().isEmpty) return;

    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      TextDirection.ltr,
    );
  }

  /// EN: Announce an error message to screen readers with "Error: " prefix
  /// KO: "오류: " 접두사와 함께 스크린 리더에 에러 메시지 공지
  static void announceError(BuildContext context, String message) {
    // EN: Ignore empty messages
    // KO: 빈 메시지는 무시
    if (message.trim().isEmpty) return;

    // EN: Prefix with "Error: " for Korean locale, "Error: " for others
    // KO: 한국어 로케일의 경우 "오류: " 접두사, 그 외는 "Error: " 사용
    final locale = Localizations.localeOf(context);
    final prefix = locale.languageCode == 'ko' ? '오류: ' : 'Error: ';

    SemanticsService.sendAnnouncement(
      View.of(context),
      '$prefix$message',
      TextDirection.ltr,
    );
  }

  /// EN: Announce a success message to screen readers with "Success: " prefix
  /// KO: "성공: " 접두사와 함께 스크린 리더에 성공 메시지 공지
  static void announceSuccess(BuildContext context, String message) {
    // EN: Ignore empty messages
    // KO: 빈 메시지는 무시
    if (message.trim().isEmpty) return;

    // EN: Prefix with "Success: " for Korean locale, "Success: " for others
    // KO: 한국어 로케일의 경우 "성공: " 접두사, 그 외는 "Success: " 사용
    final locale = Localizations.localeOf(context);
    final prefix = locale.languageCode == 'ko' ? '성공: ' : 'Success: ';

    SemanticsService.sendAnnouncement(
      View.of(context),
      '$prefix$message',
      TextDirection.ltr,
    );
  }
}
