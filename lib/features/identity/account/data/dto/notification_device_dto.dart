/// EN: Notification device DTOs for push registration/deactivation APIs.
/// KO: 푸시 등록/해제 API용 알림 디바이스 DTO입니다.
library;

class NotificationDeviceDeactivationDto {
  const NotificationDeviceDeactivationDto({
    required this.deviceId,
    required this.deactivated,
  });

  final String deviceId;
  final bool deactivated;

  factory NotificationDeviceDeactivationDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return NotificationDeviceDeactivationDto(
      deviceId: _firstString(json, const ['deviceId', 'id']) ?? '',
      deactivated:
          _firstBool(json, const [
            'deactivated',
            'inactive',
            'disabled',
            'deleted',
          ]) ??
          true,
    );
  }
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

bool? _firstBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == 'y' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == 'n' || normalized == 'no') {
        return false;
      }
    }
  }
  return null;
}
