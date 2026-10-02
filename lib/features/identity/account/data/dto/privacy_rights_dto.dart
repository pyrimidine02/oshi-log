/// EN: DTOs for privacy settings and rights request records.
/// KO: 개인정보 설정 및 권리행사 요청 DTO입니다.
library;

class PrivacySettingsDto {
  const PrivacySettingsDto({
    required this.allowAutoTranslation,
    this.version,
    this.updatedAt,
  });

  final bool allowAutoTranslation;
  final int? version;
  final DateTime? updatedAt;

  factory PrivacySettingsDto.fromJson(Map<String, dynamic> json) {
    final updatedAtRaw = json['updatedAt'] ?? json['lastUpdatedAt'];
    return PrivacySettingsDto(
      allowAutoTranslation: _bool(json, const [
        'allowAutoTranslation',
        'autoTranslationEnabled',
      ], true),
      version: _parseInt(json['version']),
      updatedAt: updatedAtRaw is String
          ? DateTime.tryParse(updatedAtRaw)
          : null,
    );
  }

  Map<String, dynamic> toPatchJson() {
    return <String, dynamic>{
      'allowAutoTranslation': allowAutoTranslation,
      if (version != null) 'version': version,
    };
  }
}

class PrivacyRequestRecordDto {
  const PrivacyRequestRecordDto({
    required this.requestType,
    required this.status,
    required this.requestedAt,
    this.reason,
  });

  final String requestType;
  final String status;
  final DateTime requestedAt;
  final String? reason;

  factory PrivacyRequestRecordDto.fromJson(Map<String, dynamic> json) {
    final requestedAt =
        DateTime.tryParse(json['requestedAt'] as String? ?? '') ??
        DateTime.now().toUtc();
    return PrivacyRequestRecordDto(
      requestType:
          json['requestType'] as String? ??
          json['type'] as String? ??
          'RESTRICTION',
      status: json['status'] as String? ?? 'RECEIVED',
      requestedAt: requestedAt,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestType': requestType,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      if (reason != null) 'reason': reason,
    };
  }
}

bool _bool(Map<String, dynamic> json, List<String> keys, bool fallback) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == 'y' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == 'n' || normalized == 'no') {
        return false;
      }
    }
  }
  return fallback;
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
