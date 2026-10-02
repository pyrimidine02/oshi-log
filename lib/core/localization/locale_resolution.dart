/// EN: Device locale -> supported app locale resolution. Japan is the
/// primary market, so an unsupported or missing device locale falls back to
/// `ja` (not `ko`).
/// KO: 기기 로케일 → 지원 로케일 결정 로직입니다. 일본이 주 시장이므로
/// 지원하지 않거나 알 수 없는 기기 로케일은 `ko`가 아닌 `ja`로 대체됩니다.
library;

import 'package:flutter/widgets.dart';

/// EN: Fallback locale when the device locale is missing or unsupported.
/// KO: 기기 로케일이 없거나 지원하지 않을 때 사용할 기본 로케일입니다.
const Locale fallbackAppLocale = Locale('ja', 'JP');

/// EN: Resolves [deviceLocale] against [supportedLocales] by language code
/// only; falls back to [fallbackAppLocale] when there is no match.
/// KO: 언어 코드 기준으로 [deviceLocale]을 [supportedLocales]와 매칭하며,
/// 일치하는 항목이 없으면 [fallbackAppLocale]로 대체합니다.
Locale resolveAppLocale(
  Locale? deviceLocale,
  Iterable<Locale> supportedLocales,
) {
  if (deviceLocale != null) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == deviceLocale.languageCode) {
        return supported;
      }
    }
  }
  return fallbackAppLocale;
}
