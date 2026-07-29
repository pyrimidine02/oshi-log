import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/settings/data/dto/account_tools_dto.dart';

void main() {
  group('account tools dto', () {
    test('UserBlockDto parses blocked user payload', () {
      final dto = UserBlockDto.fromJson({
        'id': 'block-1',
        'blockedUser': {
          'id': 'user-1',
          'displayName': '테스트유저',
          'avatarUrl': 'https://cdn.example.com/a.png',
        },
        'reason': '스팸',
        'createdAt': '2026-03-01T05:00:00Z',
      });

      expect(dto.id, 'block-1');
      expect(dto.blockedUser.id, 'user-1');
      expect(dto.blockedUser.displayName, '테스트유저');
      expect(dto.reason, '스팸');
      expect(dto.createdAt.toUtc().year, 2026);
    });

    test('VerificationAppealDto parses optional resolution fields', () {
      final dto = VerificationAppealDto.fromJson({
        'id': 'appeal-1',
        'targetType': 'PLACE_VISIT',
        'targetId': 'target-1',
        'reason': 'GPS_INACCURACY',
        'status': 'IN_REVIEW',
        'reviewerMemo': '재검토 중',
        'createdAt': '2026-03-01T05:00:00Z',
        'resolvedAt': '2026-03-01T06:00:00Z',
      });

      expect(dto.id, 'appeal-1');
      expect(dto.targetType, 'PLACE_VISIT');
      expect(dto.status, 'IN_REVIEW');
      expect(dto.reviewerMemo, '재검토 중');
      expect(dto.resolvedAt, isNotNull);
    });

    test('ProjectRoleRequestDto parses pageable payload', () {
      final dtos = ProjectRoleRequestDto.listFromAny({
        'content': [
          {
            'id': 'request-1',
            'projectId': 'project-1',
            'projectCode': 'girls-band-cry',
            'projectName': '걸즈 밴드 크라이',
            'requestedRole': 'COMMUNITY_MODERATOR',
            'status': 'PENDING',
            'justification': '커뮤니티 운영을 위해 권한이 필요합니다.',
            'createdAt': '2026-03-09T03:00:00Z',
          },
        ],
      });

      expect(dtos, hasLength(1));
      expect(dtos.first.id, 'request-1');
      expect(dtos.first.projectCode, 'girls-band-cry');
      expect(dtos.first.requestedRole, 'COMMUNITY_MODERATOR');
      expect(dtos.first.status, 'PENDING');
    });
  });
}
