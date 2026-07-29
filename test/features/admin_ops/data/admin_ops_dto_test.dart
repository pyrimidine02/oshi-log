import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/admin_ops/data/dto/admin_ops_dto.dart';

void main() {
  group('AdminDashboardDto', () {
    test('parses access-grant metrics and extra numeric metrics', () {
      final dto = AdminDashboardDto.fromJson({
        'openReportCount': 3,
        'reviewInProgressCount': 2,
        'pendingAccessGrantRequests': '5',
        'pendingAppeals': 4,
        'mediaDeletionPendingCount': 1,
        'activeSanctionCount': 7,
        'customBacklog': 9,
      });

      expect(dto.openReports, 3);
      expect(dto.inReviewReports, 2);
      expect(dto.pendingAccessGrantRequests, 5);
      expect(dto.pendingVerificationAppeals, 4);
      expect(dto.pendingMediaDeletionRequests, 1);
      expect(dto.activeSanctions, 7);
      expect(dto.extraMetrics['customBacklog'], 9);
    });
  });

  group('AdminCommunityReportDto', () {
    test('parses list from pageable content payload', () {
      final dtos = AdminCommunityReportDto.listFromAny({
        'content': [
          {
            'reportId': 'report-1',
            'targetType': 'POST',
            'targetId': 'post-1',
            'reportReason': 'SPAM',
            'reportStatus': 'OPEN',
            'reportedAt': '2026-02-19T00:00:00Z',
            'reporter': {'id': 'user-1', 'displayName': 'Reporter'},
          },
        ],
      });

      expect(dtos.length, 1);
      expect(dtos.first.id, 'report-1');
      expect(dtos.first.targetType, 'POST');
      expect(dtos.first.reason, 'SPAM');
      expect(dtos.first.reporterName, 'Reporter');
    });

    test('parses single map payload', () {
      final dtos = AdminCommunityReportDto.listFromAny({
        'id': 'single-1',
        'type': 'COMMENT',
        'contentId': 'comment-1',
        'reason': 'ABUSE',
        'status': 'IN_REVIEW',
        'createdAt': '2026-02-19T00:00:00Z',
      });

      expect(dtos.length, 1);
      expect(dtos.first.id, 'single-1');
      expect(dtos.first.targetType, 'COMMENT');
      expect(dtos.first.targetId, 'comment-1');
      expect(dtos.first.status, 'IN_REVIEW');
    });
  });

  group('AdminProjectRoleRequestDto', () {
    test('parses role request payload list', () {
      final dtos = AdminProjectRoleRequestDto.listFromAny({
        'items': [
          {
            'requestId': 'role-req-1',
            'projectId': 'project-1',
            'projectName': '걸즈 밴드 크라이',
            'requesterName': '운영지원자',
            'requestedRole': 'PLACE_EDITOR',
            'status': 'PENDING',
            'justification': '콘텐츠 정합성 개선 작업을 수행하려고 합니다.',
            'createdAt': '2026-03-09T03:00:00Z',
          },
        ],
      });

      expect(dtos, hasLength(1));
      expect(dtos.first.id, 'role-req-1');
      expect(dtos.first.projectName, '걸즈 밴드 크라이');
      expect(dtos.first.requestedRole, 'PLACE_EDITOR');
      expect(dtos.first.status, 'PENDING');
    });
  });

  group('AdminMediaDeletionRequestDto', () {
    test('parses pageable payload into media deletion requests', () {
      final dtos = AdminMediaDeletionRequestDto.listFromAny({
        'content': [
          {
            'id': '1b6cb78d-d12d-4d52-b6cf-4562f7f64740',
            'entityType': 'PLACE',
            'linkId': '34db0f86-dce0-4fc8-a3f2-c1a8a525f2af',
            'uploadId': 'f6f76461-f6f1-4812-a580-1bb3077d9dbb',
            'requestedBy': 'moderator@noraneko.cc',
            'status': 'PENDING',
            'createdAt': '2026-03-10T06:00:00Z',
          },
        ],
      });

      expect(dtos, hasLength(1));
      expect(dtos.first.id, '1b6cb78d-d12d-4d52-b6cf-4562f7f64740');
      expect(dtos.first.entityType, 'PLACE');
      expect(dtos.first.status, 'PENDING');
    });
  });

  group('AdminMediaDeletionActionResponseDto', () {
    test('parses success payload', () {
      final dto = AdminMediaDeletionActionResponseDto.fromJson({
        'success': true,
      });

      expect(dto.success, isTrue);
    });
  });
}
