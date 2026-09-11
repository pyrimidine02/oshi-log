/// EN: Live event domain entities.
/// KO: 라이브 이벤트 도메인 엔티티.
library;

import 'package:intl/intl.dart';

class LiveEventSummary {
  const LiveEventSummary({
    required this.id,
    required this.title,
    this.placeId,
    this.venue,
    this.venueTypes = const [],
    this.address,
    this.regionCodes = const [],
    required this.showStartTime,
    required this.status,
    required this.projectIds,
    required this.unitIds,
    this.bannerUrl,
    this.doorsOpenTime,
    this.endTime,
    this.ticketUrl,
  });

  final String id;
  final String title;
  final String? placeId;
  final String? venue;
  final List<String> venueTypes;
  final String? address;
  final List<String> regionCodes;
  final DateTime showStartTime;
  final DateTime? doorsOpenTime;
  final DateTime? endTime;
  final String status;
  final List<String> projectIds;
  final List<String> unitIds;
  final String? bannerUrl;
  final String? ticketUrl;

  bool get isUpcoming {
    return showStartTime.isAfter(DateTime.now());
  }

  String get dateLabel {
    return DateFormat.MMMd(_localeTag()).format(showStartTime.toLocal());
  }

  String get dDayLabel {
    return _formatDDay(showStartTime);
  }

  String get statusLabel => status;

  String get metaLabel {
    final lang = _languageCode();
    if (lang == 'en') {
      return 'Projects ${projectIds.length} · Units ${unitIds.length}';
    }
    if (lang == 'ja') {
      return 'プロジェクト ${projectIds.length} · ユニット ${unitIds.length}';
    }
    return '프로젝트 ${projectIds.length} · 유닛 ${unitIds.length}';
  }
}

class LiveEventDetail {
  const LiveEventDetail({
    required this.id,
    required this.title,
    this.placeId,
    this.venue,
    this.venueTypes = const [],
    this.address,
    this.regionCodes = const [],
    this.description,
    required this.showStartTime,
    this.doorsOpenTime,
    this.endTime,
    required this.status,
    required this.projectIds,
    required this.unitIds,
    this.bannerUrl,
    this.ticketUrl,
  });

  final String id;
  final String title;
  final String? placeId;
  final String? venue;
  final List<String> venueTypes;
  final String? address;
  final List<String> regionCodes;
  final String? description;
  final DateTime showStartTime;
  final DateTime? doorsOpenTime;
  final DateTime? endTime;
  final String status;
  final List<String> projectIds;
  final List<String> unitIds;
  final String? bannerUrl;
  final String? ticketUrl;

  String get metaLabel {
    final lang = _languageCode();
    if (lang == 'en') {
      return 'Projects ${projectIds.length} · Units ${unitIds.length}';
    }
    if (lang == 'ja') {
      return 'プロジェクト ${projectIds.length} · ユニット ${unitIds.length}';
    }
    return '프로젝트 ${projectIds.length} · 유닛 ${unitIds.length}';
  }

  String get dateLabel {
    return DateFormat.yMMMMd(_localeTag()).format(showStartTime.toLocal());
  }

  String get dDayLabel {
    return _formatDDay(showStartTime);
  }

  String get timeLabel {
    return DateFormat('HH:mm').format(showStartTime.toLocal());
  }

  String get doorTimeLabel {
    if (doorsOpenTime == null) {
      final lang = _languageCode();
      if (lang == 'en') return 'TBD';
      if (lang == 'ja') return '未定';
      return '미정';
    }
    return DateFormat('HH:mm').format(doorsOpenTime!.toLocal());
  }
}

class LiveAttendanceStatus {
  const LiveAttendanceStatus._();

  static const String declared = 'DECLARED';
  static const String verified = 'VERIFIED';
  static const String none = 'NONE';

  static String normalize(String raw) {
    final upper = raw.toUpperCase().trim();
    if (upper == declared || upper == verified || upper == none) {
      return upper;
    }
    return none;
  }
}

class LiveAttendanceState {
  const LiveAttendanceState({
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

  bool get isDeclared => status == LiveAttendanceStatus.declared;
  bool get isVerified => status == LiveAttendanceStatus.verified;
  bool get isNone => status == LiveAttendanceStatus.none;

  LiveAttendanceState copyWith({
    String? attendanceId,
    String? liveEventId,
    bool? attended,
    String? status,
    bool? canUndo,
    String? verificationMethod,
    DateTime? attendedAt,
  }) {
    return LiveAttendanceState(
      attendanceId: attendanceId ?? this.attendanceId,
      liveEventId: liveEventId ?? this.liveEventId,
      attended: attended ?? this.attended,
      status: status ?? this.status,
      canUndo: canUndo ?? this.canUndo,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      attendedAt: attendedAt ?? this.attendedAt,
    );
  }

  factory LiveAttendanceState.none(String liveEventId) {
    return LiveAttendanceState(
      attendanceId: null,
      liveEventId: liveEventId,
      attended: false,
      status: LiveAttendanceStatus.none,
      canUndo: false,
      verificationMethod: null,
      attendedAt: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (attendanceId != null) 'attendanceId': attendanceId,
      'liveEventId': liveEventId,
      'attended': attended,
      'status': status,
      'canUndo': canUndo,
      'verificationMethod': verificationMethod,
      'attendedAt': attendedAt?.toIso8601String(),
    };
  }
}

class LiveAttendanceHistoryRecord {
  const LiveAttendanceHistoryRecord({
    required this.projectKey,
    required this.eventId,
    required this.attended,
    required this.status,
    required this.canUndo,
    this.attendanceId,
    this.verificationMethod,
    this.attendedAt,
    this.eventTitle,
    this.bannerUrl,
    this.showStartTime,
  });

  final String projectKey;
  final String? attendanceId;
  final String eventId;
  final bool attended;
  final String status;
  final bool canUndo;
  final String? verificationMethod;
  final DateTime? attendedAt;
  final String? eventTitle;
  final String? bannerUrl;
  final DateTime? showStartTime;

  bool get isDeclared => status == LiveAttendanceStatus.declared;
  bool get isVerified => status == LiveAttendanceStatus.verified;
  bool get isNone => status == LiveAttendanceStatus.none;

  String get titleFallback =>
      eventTitle?.trim().isNotEmpty == true ? eventTitle!.trim() : eventId;

  LiveAttendanceHistoryRecord copyWith({
    String? projectKey,
    String? attendanceId,
    String? eventId,
    bool? attended,
    String? status,
    bool? canUndo,
    String? verificationMethod,
    DateTime? attendedAt,
    String? eventTitle,
    String? bannerUrl,
    DateTime? showStartTime,
  }) {
    return LiveAttendanceHistoryRecord(
      projectKey: projectKey ?? this.projectKey,
      attendanceId: attendanceId ?? this.attendanceId,
      eventId: eventId ?? this.eventId,
      attended: attended ?? this.attended,
      status: status ?? this.status,
      canUndo: canUndo ?? this.canUndo,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      attendedAt: attendedAt ?? this.attendedAt,
      eventTitle: eventTitle ?? this.eventTitle,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      showStartTime: showStartTime ?? this.showStartTime,
    );
  }

  LiveAttendanceHistoryRecord withDetail(LiveEventDetail detail) {
    return copyWith(
      eventTitle: detail.title,
      bannerUrl: detail.bannerUrl,
      showStartTime: detail.showStartTime,
    );
  }

  factory LiveAttendanceHistoryRecord.fromState({
    required String projectKey,
    required LiveAttendanceState state,
  }) {
    return LiveAttendanceHistoryRecord(
      projectKey: projectKey,
      attendanceId: state.attendanceId,
      eventId: state.liveEventId,
      attended: state.attended,
      status: state.status,
      canUndo: state.canUndo,
      verificationMethod: state.verificationMethod,
      attendedAt: state.attendedAt,
      eventTitle: null,
      bannerUrl: null,
      showStartTime: null,
    );
  }
}

class LiveAttendanceHistoryPageData {
  const LiveAttendanceHistoryPageData({
    required this.items,
    required this.currentPage,
    required this.pageSize,
    required this.hasNext,
  });

  final List<LiveAttendanceHistoryRecord> items;
  final int currentPage;
  final int pageSize;
  final bool hasNext;
}

String _formatDDay(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final localDateTime = dateTime.toLocal();
  final eventDate = DateTime(
    localDateTime.year,
    localDateTime.month,
    localDateTime.day,
  );
  final diff = eventDate.difference(today).inDays;
  if (diff == 0) {
    return 'D-day';
  }
  if (diff > 0) {
    return 'D-$diff';
  }
  return 'D+${diff.abs()}';
}

String _localeTag() {
  final locale = Intl.getCurrentLocale();
  if (locale.isEmpty) return 'ko_KR';
  return locale;
}

String _languageCode() {
  return _localeTag().split(RegExp(r'[_-]')).first;
}
