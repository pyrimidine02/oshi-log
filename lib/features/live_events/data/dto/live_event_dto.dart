/// EN: Live event DTOs aligned with Swagger schema.
/// KO: Swagger 스키마에 맞춘 라이브 이벤트 DTO.
library;

import '../../../../core/models/image_meta_dto.dart';

class LiveEventSummaryDto {
  const LiveEventSummaryDto({
    required this.id,
    required this.title,
    required this.showStartTime,
    required this.status,
    required this.projectIds,
    required this.unitIds,
    this.doorsOpenTime,
    this.bannerUrl,
    this.bannerFilename,
    this.bannerSize,
    this.ticketUrl,
  });

  final String id;
  final String title;
  final DateTime showStartTime;
  final DateTime? doorsOpenTime;
  final String status;
  final String? bannerUrl;
  final String? bannerFilename;
  final int? bannerSize;
  final String? ticketUrl;
  final List<String> projectIds;
  final List<String> unitIds;

  factory LiveEventSummaryDto.fromJson(Map<String, dynamic> json) {
    return LiveEventSummaryDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      showStartTime: _dateTime(json['showStartTime']),
      doorsOpenTime: _dateTimeOrNull(json['doorsOpenTime']),
      status: json['status'] as String? ?? 'UNKNOWN',
      bannerUrl: json['bannerUrl'] as String?,
      bannerFilename: json['bannerFilename'] as String?,
      bannerSize: _intOrNull(json['bannerSize']),
      ticketUrl: json['ticketUrl'] as String?,
      projectIds: _stringList(json['projectIds']),
      unitIds: _stringList(json['unitIds']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'showStartTime': showStartTime.toIso8601String(),
      'doorsOpenTime': doorsOpenTime?.toIso8601String(),
      'status': status,
      'bannerUrl': bannerUrl,
      'bannerFilename': bannerFilename,
      'bannerSize': bannerSize,
      'ticketUrl': ticketUrl,
      'projectIds': projectIds,
      'unitIds': unitIds,
    };
  }
}

class LiveEventDetailDto {
  const LiveEventDetailDto({
    required this.id,
    required this.title,
    required this.showStartTime,
    required this.status,
    required this.projectIds,
    required this.unitIds,
    this.description,
    this.doorsOpenTime,
    this.endTime,
    this.banner,
    this.ticketUrl,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime showStartTime;
  final DateTime? doorsOpenTime;
  final DateTime? endTime;
  final String status;
  final ImageMetaDto? banner;
  final String? ticketUrl;
  final List<String> projectIds;
  final List<String> unitIds;

  factory LiveEventDetailDto.fromJson(Map<String, dynamic> json) {
    return LiveEventDetailDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      showStartTime: _dateTime(json['showStartTime']),
      doorsOpenTime: _dateTimeOrNull(json['doorsOpenTime']),
      endTime: _dateTimeOrNull(json['endTime']),
      status: json['status'] as String? ?? 'UNKNOWN',
      banner: json['banner'] is Map<String, dynamic>
          ? ImageMetaDto.fromJson(json['banner'] as Map<String, dynamic>)
          : null,
      ticketUrl: json['ticketUrl'] as String?,
      projectIds: _stringList(json['projectIds']),
      unitIds: _stringList(json['unitIds']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'showStartTime': showStartTime.toIso8601String(),
      'doorsOpenTime': doorsOpenTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status,
      'banner': banner?.toJson(),
      'ticketUrl': ticketUrl,
      'projectIds': projectIds,
      'unitIds': unitIds,
    };
  }
}

class LiveAttendanceToggleRequestDto {
  const LiveAttendanceToggleRequestDto({required this.attended});

  final bool attended;

  Map<String, dynamic> toJson() {
    return {'attended': attended};
  }
}

class LiveAttendanceStateDto {
  const LiveAttendanceStateDto({
    required this.liveEventId,
    required this.attended,
    required this.status,
    required this.canUndo,
    this.attendanceId,
    this.verificationMethod,
    this.attendedAt,
  });

  final String? attendanceId;
  final String liveEventId;
  final bool attended;
  final String status;
  final bool canUndo;
  final String? verificationMethod;
  final DateTime? attendedAt;

  factory LiveAttendanceStateDto.fromJson(Map<String, dynamic> json) {
    final status = (json['status'] as String? ?? 'NONE').toUpperCase();
    final attendedValue = json['attended'];
    return LiveAttendanceStateDto(
      attendanceId: _nonEmptyStringOrNull(json['attendanceId'] ?? json['id']),
      liveEventId:
          json['liveEventId'] as String? ?? json['eventId'] as String? ?? '',
      attended: attendedValue == null
          ? status != 'NONE'
          : _boolOrFallback(attendedValue, false),
      status: status,
      canUndo: _boolOrFallback(json['canUndo'], false),
      verificationMethod: json['verificationMethod'] as String?,
      attendedAt: _dateTimeOrNull(json['attendedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (attendanceId != null) 'id': attendanceId,
      'liveEventId': liveEventId,
      'attended': attended,
      'status': status,
      'canUndo': canUndo,
      'verificationMethod': verificationMethod,
      'attendedAt': attendedAt?.toIso8601String(),
    };
  }
}

class LiveAttendancePageDto {
  const LiveAttendancePageDto({
    required this.items,
    required this.currentPage,
    required this.pageSize,
    required this.hasNext,
  });

  final List<LiveAttendanceStateDto> items;
  final int currentPage;
  final int pageSize;
  final bool hasNext;
}

DateTime _dateTime(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _dateTimeOrNull(dynamic value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

int? _intOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return <String>[];
}

bool _boolOrFallback(dynamic value, bool fallback) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == 'y' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == 'n' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}

String? _nonEmptyStringOrNull(dynamic value) {
  final normalized = value?.toString().trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
