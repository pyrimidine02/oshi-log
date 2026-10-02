/// EN: DTOs for admin operations endpoints.
/// KO: 운영/관리자 엔드포인트 DTO.
library;

class AdminDashboardDto {
  const AdminDashboardDto({
    required this.openReports,
    required this.inReviewReports,
    required this.pendingAccessGrantRequests,
    required this.pendingVerificationAppeals,
    required this.pendingMediaDeletionRequests,
    required this.activeSanctions,
    this.extraMetrics = const <String, int>{},
  });

  final int openReports;
  final int inReviewReports;
  final int pendingAccessGrantRequests;
  final int pendingVerificationAppeals;
  final int pendingMediaDeletionRequests;
  final int activeSanctions;
  final Map<String, int> extraMetrics;

  factory AdminDashboardDto.fromJson(Map<String, dynamic> json) {
    final openReports = _intFromAny(json, const [
      'openReports',
      'openReportCount',
      'reportsOpen',
      'pendingReports',
    ]);
    final inReviewReports = _intFromAny(json, const [
      'inReviewReports',
      'reviewInProgressCount',
      'reportsInReview',
      'processingReports',
    ]);
    final pendingAccessGrantRequests = _intFromAny(json, const [
      'pendingAccessGrantRequests',
      'pendingAccessLevelRequests',
    ]);
    final pendingVerificationAppeals = _intFromAny(json, const [
      'pendingVerificationAppeals',
      'pendingAppeals',
      'verificationAppealsPending',
    ]);
    final pendingMediaDeletionRequests = _intFromAny(json, const [
      'pendingMediaDeletionRequests',
      'mediaDeletionPendingCount',
      'mediaDeletionsPending',
    ]);
    final activeSanctions = _intFromAny(json, const [
      'activeSanctions',
      'activeSanctionCount',
      'sanctionsActive',
    ]);

    final extraMetrics = <String, int>{};
    final consumedKeys = <String>{
      'openReports',
      'openReportCount',
      'reportsOpen',
      'pendingReports',
      'inReviewReports',
      'reviewInProgressCount',
      'reportsInReview',
      'processingReports',
      'pendingAccessGrantRequests',
      'pendingAccessLevelRequests',
      'pendingVerificationAppeals',
      'pendingAppeals',
      'verificationAppealsPending',
      'pendingMediaDeletionRequests',
      'mediaDeletionPendingCount',
      'mediaDeletionsPending',
      'activeSanctions',
      'activeSanctionCount',
      'sanctionsActive',
    };

    for (final entry in json.entries) {
      if (consumedKeys.contains(entry.key)) {
        continue;
      }
      final value = _intOrNull(entry.value);
      if (value != null) {
        extraMetrics[entry.key] = value;
      }
    }

    return AdminDashboardDto(
      openReports: openReports,
      inReviewReports: inReviewReports,
      pendingAccessGrantRequests: pendingAccessGrantRequests,
      pendingVerificationAppeals: pendingVerificationAppeals,
      pendingMediaDeletionRequests: pendingMediaDeletionRequests,
      activeSanctions: activeSanctions,
      extraMetrics: extraMetrics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'openReports': openReports,
      'inReviewReports': inReviewReports,
      'pendingAccessGrantRequests': pendingAccessGrantRequests,
      'pendingVerificationAppeals': pendingVerificationAppeals,
      'pendingMediaDeletionRequests': pendingMediaDeletionRequests,
      'activeSanctions': activeSanctions,
      if (extraMetrics.isNotEmpty) 'extraMetrics': extraMetrics,
    };
  }
}

class AdminCommunityReportDto {
  const AdminCommunityReportDto({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.reporterId,
    this.reporterName,
    this.assigneeId,
    this.assigneeName,
    this.description,
    this.previewText,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String reason;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? reporterId;
  final String? reporterName;
  final String? assigneeId;
  final String? assigneeName;
  final String? description;
  final String? previewText;

  factory AdminCommunityReportDto.fromJson(Map<String, dynamic> json) {
    final target = _mapOrNull(json['target']);
    final reporter = _mapOrNull(json['reporter']);
    final assignee = _mapOrNull(json['assignee']);

    return AdminCommunityReportDto(
      id: _stringOrEmpty(
        json['id'] ?? json['reportId'] ?? json['communityReportId'],
      ).trim(),
      targetType: _stringOrEmpty(
        json['targetType'] ?? json['type'] ?? target?['type'] ?? 'UNKNOWN',
      ),
      targetId: _stringOrEmpty(
        json['targetId'] ?? json['contentId'] ?? target?['id'] ?? '',
      ),
      reason: _stringOrEmpty(json['reason'] ?? json['reportReason'] ?? 'OTHER'),
      status: _stringOrEmpty(json['status'] ?? json['reportStatus'] ?? 'OPEN'),
      createdAt:
          _dateTimeOrNull(
            json['createdAt'] ?? json['reportedAt'] ?? json['submittedAt'],
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: _dateTimeOrNull(
        json['updatedAt'] ?? json['reviewedAt'] ?? json['modifiedAt'],
      ),
      reporterId: _stringOrNull(
        json['reporterId'] ?? json['reportedById'] ?? reporter?['id'],
      ),
      reporterName: _stringOrNull(
        json['reporterName'] ??
            json['reportedByName'] ??
            reporter?['displayName'],
      ),
      assigneeId: _stringOrNull(
        json['assigneeId'] ?? json['assignedToId'] ?? assignee?['id'],
      ),
      assigneeName: _stringOrNull(
        json['assigneeName'] ??
            json['assignedToName'] ??
            assignee?['displayName'],
      ),
      description: _stringOrNull(
        json['description'] ?? json['details'] ?? json['note'],
      ),
      previewText: _stringOrNull(
        json['previewText'] ??
            json['contentPreview'] ??
            json['targetPreview'] ??
            json['snippet'],
      ),
    );
  }

  static List<AdminCommunityReportDto> listFromAny(dynamic raw) {
    final list = _extractList(raw);
    return list
        .whereType<Map<String, dynamic>>()
        .map(AdminCommunityReportDto.fromJson)
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (reporterId != null) 'reporterId': reporterId,
      if (reporterName != null) 'reporterName': reporterName,
      if (assigneeId != null) 'assigneeId': assigneeId,
      if (assigneeName != null) 'assigneeName': assigneeName,
      if (description != null) 'description': description,
      if (previewText != null) 'previewText': previewText,
    };
  }
}

class AdminProjectRoleRequestDto {
  const AdminProjectRoleRequestDto({
    required this.id,
    required this.projectId,
    required this.requestedRole,
    required this.status,
    required this.justification,
    required this.createdAt,
    this.projectCode,
    this.projectName,
    this.requesterId,
    this.requesterName,
    this.adminMemo,
    this.reviewedAt,
  });

  final String id;
  final String projectId;
  final String? projectCode;
  final String? projectName;
  final String? requesterId;
  final String? requesterName;
  final String requestedRole;
  final String status;
  final String justification;
  final DateTime createdAt;
  final String? adminMemo;
  final DateTime? reviewedAt;

  factory AdminProjectRoleRequestDto.fromJson(Map<String, dynamic> json) {
    final project = _mapOrNull(json['project']);
    final requester = _mapOrNull(json['requester'] ?? json['user']);

    return AdminProjectRoleRequestDto(
      id: _stringOrEmpty(json['id'] ?? json['requestId']).trim(),
      projectId:
          _stringOrNull(
            json['projectId'] ?? project?['id'] ?? json['project'],
          ) ??
          '',
      projectCode: _stringOrNull(
        json['projectCode'] ?? json['projectSlug'] ?? project?['code'],
      ),
      projectName: _stringOrNull(json['projectName'] ?? project?['name']),
      requesterId: _stringOrNull(
        json['requesterId'] ?? json['userId'] ?? requester?['id'],
      ),
      requesterName: _stringOrNull(
        json['requesterName'] ??
            json['userDisplayName'] ??
            requester?['displayName'] ??
            requester?['name'],
      ),
      requestedRole: _stringOrEmpty(
        json['requestedRole'] ?? json['role'] ?? 'PLACE_EDITOR',
      ),
      status: _stringOrEmpty(json['status'] ?? 'PENDING'),
      justification: _stringOrEmpty(
        json['justification'] ?? json['reason'] ?? '(No reason)',
      ),
      createdAt:
          _dateTimeOrNull(
            json['createdAt'] ?? json['requestedAt'] ?? json['updatedAt'],
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      adminMemo: _stringOrNull(json['adminMemo'] ?? json['reviewMemo']),
      reviewedAt: _dateTimeOrNull(json['reviewedAt'] ?? json['resolvedAt']),
    );
  }

  static List<AdminProjectRoleRequestDto> listFromAny(dynamic raw) {
    final list = _extractList(raw);
    return list
        .whereType<Map<String, dynamic>>()
        .map(AdminProjectRoleRequestDto.fromJson)
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      if (projectCode != null) 'projectCode': projectCode,
      if (projectName != null) 'projectName': projectName,
      if (requesterId != null) 'requesterId': requesterId,
      if (requesterName != null) 'requesterName': requesterName,
      'requestedRole': requestedRole,
      'status': status,
      'justification': justification,
      'createdAt': createdAt.toIso8601String(),
      if (adminMemo != null) 'adminMemo': adminMemo,
      if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
    };
  }
}

class AdminMediaDeletionRequestDto {
  const AdminMediaDeletionRequestDto({
    required this.id,
    required this.entityType,
    required this.linkId,
    required this.uploadId,
    required this.requestedBy,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String entityType;
  final String linkId;
  final String uploadId;
  final String requestedBy;
  final String status;
  final DateTime createdAt;

  factory AdminMediaDeletionRequestDto.fromJson(Map<String, dynamic> json) {
    return AdminMediaDeletionRequestDto(
      id: _stringOrEmpty(json['id'] ?? json['requestId']).trim(),
      entityType: _stringOrEmpty(json['entityType'] ?? json['type']).trim(),
      linkId: _stringOrEmpty(json['linkId']).trim(),
      uploadId: _stringOrEmpty(json['uploadId']).trim(),
      requestedBy: _stringOrEmpty(json['requestedBy']).trim(),
      status: _stringOrEmpty(json['status']).trim(),
      createdAt:
          _dateTimeOrNull(json['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static List<AdminMediaDeletionRequestDto> listFromAny(dynamic raw) {
    final list = _extractList(raw);
    return list
        .whereType<Map<String, dynamic>>()
        .map(AdminMediaDeletionRequestDto.fromJson)
        .toList(growable: false);
  }
}

class AdminMediaDeletionApproveRequestDto {
  const AdminMediaDeletionApproveRequestDto({
    required this.deleteLinkedContents,
  });

  final bool deleteLinkedContents;

  Map<String, dynamic> toJson() {
    return {'deleteLinkedContents': deleteLinkedContents};
  }
}

class AdminMediaDeletionActionResponseDto {
  const AdminMediaDeletionActionResponseDto({required this.success});

  final bool success;

  factory AdminMediaDeletionActionResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminMediaDeletionActionResponseDto(
      success: json['success'] as bool? ?? false,
    );
  }
}

List<dynamic> _extractList(dynamic raw) {
  if (raw is List<dynamic>) {
    return raw;
  }
  if (raw is Map<String, dynamic>) {
    final nestedCandidates = <dynamic>[
      raw['content'],
      raw['items'],
      raw['reports'],
      raw['results'],
      raw['data'],
      raw['list'],
    ];

    for (final candidate in nestedCandidates) {
      if (candidate is List<dynamic>) {
        return candidate;
      }
    }

    if (raw.containsKey('id') || raw.containsKey('reportId')) {
      return <dynamic>[raw];
    }
  }
  return const <dynamic>[];
}

Map<String, dynamic>? _mapOrNull(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return null;
}

int _intFromAny(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _intOrNull(json[key]);
    if (value != null) {
      return value;
    }
  }
  return 0;
}

int? _intOrNull(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

DateTime? _dateTimeOrNull(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String _stringOrEmpty(dynamic value) {
  if (value is String) {
    return value;
  }
  if (value == null) {
    return '';
  }
  return value.toString();
}

String? _stringOrNull(dynamic value) {
  final text = _stringOrEmpty(value).trim();
  if (text.isEmpty) {
    return null;
  }
  return text;
}
