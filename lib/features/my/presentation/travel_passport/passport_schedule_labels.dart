/// EN: Locale-aware labels shared by passport schedule rows.
/// KO: 여권 일정 행에서 공유하는 로케일 인식 라벨입니다.
library;

import 'package:flutter/widgets.dart';

/// EN: Returns a compact month label without requiring Intl date-symbol data.
/// KO: Intl 날짜 심볼 데이터 없이 간결한 월 라벨을 반환합니다.
String passportMonthLabel(BuildContext context, int month) {
  final languageCode = Localizations.localeOf(context).languageCode;
  if (languageCode == 'ko') return '$month월';
  if (languageCode == 'ja') return '$month月';
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return months[month.clamp(1, 12) - 1];
}
