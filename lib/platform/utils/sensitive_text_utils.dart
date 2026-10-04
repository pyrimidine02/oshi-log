/// EN: Helpers for masking sensitive text in UI surfaces.
/// KO: UI 노출 시 민감정보 마스킹을 위한 유틸리티입니다.
library;

String maskEmail(String? email) {
  final value = email?.trim() ?? '';
  if (value.isEmpty) return '';
  final atIndex = value.indexOf('@');
  if (atIndex <= 1 || atIndex == value.length - 1) {
    return '***';
  }

  final localPart = value.substring(0, atIndex);
  final domainPart = value.substring(atIndex + 1);
  final maskedLocal = localPart.length <= 2
      ? '${localPart[0]}*'
      : '${localPart.substring(0, 2)}${'*' * (localPart.length - 2)}';
  return '$maskedLocal@$domainPart';
}
