/// EN: Lightweight locale text helper for app-level copy.
/// KO: 앱 레벨 문구용 경량 로케일 텍스트 헬퍼.
library;

import 'package:flutter/widgets.dart';

/// EN: BuildContext extension for simple localized copy selection.
/// KO: 단순 다국어 문구 선택을 위한 BuildContext 확장입니다.
extension LocaleTextX on BuildContext {
  /// EN: Returns localized text by current language code (`ko`, `en`, `ja`).
  /// A missing (null) or empty string is treated as not provided, and the
  /// selected language falls back ja -> en -> ko until a non-empty value
  /// is found.
  /// KO: 현재 언어 코드(`ko`, `en`, `ja`)에 맞는 문구를 반환합니다. null과
  /// 빈 문자열은 동일하게 "제공되지 않음"으로 취급하며, 선택한 언어부터
  /// ja -> en -> ko 순서로 비어있지 않은 값을 찾을 때까지 대체합니다.
  String l10n({required String ko, String? en, String? ja}) {
    final languageCode = Localizations.localeOf(this).languageCode;
    String? present(String? value) =>
        (value != null && value.isNotEmpty) ? value : null;
    final jaValue = present(ja);
    final enValue = present(en);
    final koValue = present(ko);
    switch (languageCode) {
      case 'ja':
        return jaValue ?? enValue ?? koValue ?? ko;
      case 'en':
        return enValue ?? koValue ?? ko;
      default:
        return koValue ?? ko;
    }
  }
}
