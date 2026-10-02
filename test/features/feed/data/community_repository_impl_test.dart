import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/community/moderation/data/datasources/community_remote_data_source.dart';
import 'package:oshi_log/features/community/moderation/data/dto/community_moderation_dto.dart';
import 'package:oshi_log/features/community/moderation/data/repositories/community_repository_impl.dart';
import 'package:oshi_log/features/community/moderation/domain/entities/community_moderation.dart';

class MockCommunityRemoteDataSource extends Mock
    implements CommunityRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const ReportCreateRequestDto(
        targetType: 'POST',
        targetId: 'post-1',
        reason: 'SPAM',
      ),
    );
    registerFallbackValue(
      const AppealCreateRequestDto(
        targetType: 'POST',
        targetId: 'post-1',
        reason: '사유',
      ),
    );
    registerFallbackValue(
      const ProjectCommunityBanRequestDto(reason: 'rule violation'),
    );
  });

  test('createReport encodes extended reason with OTHER fallback', () async {
    final remoteDataSource = MockCommunityRemoteDataSource();
    final repository = CommunityRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    when(
      () => remoteDataSource.createReport(request: any(named: 'request')),
    ).thenAnswer((_) async => const Result.success(null));

    final result = await repository.createReport(
      targetType: CommunityReportTargetType.post,
      targetId: 'post-1',
      reason: CommunityReportReason.tradeInducement,
      description: '중고 티켓 판매 유도',
    );

    expect(result, isA<Success<void>>());

    final captured =
        verify(
              () => remoteDataSource.createReport(
                request: captureAny(named: 'request'),
              ),
            ).captured.single
            as ReportCreateRequestDto;
    expect(captured.targetType, 'POST');
    expect(captured.targetId, 'post-1');
    expect(captured.reason, 'OTHER');
    expect(captured.description, '[TRADE_INDUCEMENT] 중고 티켓 판매 유도');
  });

  test('getMySanctionStatus returns none when endpoint is not found', () async {
    final remoteDataSource = MockCommunityRemoteDataSource();
    final repository = CommunityRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    when(() => remoteDataSource.getMySanctionStatus()).thenAnswer(
      (_) async => const Result.failure(NotFoundFailure('Not found')),
    );

    final result = await repository.getMySanctionStatus();

    expect(result, isA<Success<UserSanctionStatus>>());
    final data = switch (result) {
      Success(:final data) => data,
      Err() => throw StateError('Expected success'),
    };
    expect(data.level, UserSanctionLevel.none);
    expect(data.isRestricted, false);
  });

  test('submitAppeal forwards target payload and returns success', () async {
    final remoteDataSource = MockCommunityRemoteDataSource();
    final repository = CommunityRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    when(
      () => remoteDataSource.submitAppeal(request: any(named: 'request')),
    ).thenAnswer((_) async => const Result.success(null));

    final result = await repository.submitAppeal(
      targetType: CommunityReportTargetType.post,
      targetId: 'post-1',
      reason: '검토 요청',
    );

    expect(result, isA<Success<void>>());

    final captured =
        verify(
              () => remoteDataSource.submitAppeal(
                request: captureAny(named: 'request'),
              ),
            ).captured.single
            as AppealCreateRequestDto;
    expect(captured.targetType, 'POST');
    expect(captured.targetId, 'post-1');
    expect(captured.reason, '검토 요청');
  });

  test('getMyReports maps report summary enums', () async {
    final remoteDataSource = MockCommunityRemoteDataSource();
    final repository = CommunityRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    when(
      () => remoteDataSource.getMyReports(
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => Result.success([
        ReportSummaryDto(
          id: 'report-1',
          targetType: 'COMMENT',
          targetId: 'comment-1',
          reason: 'SPAM',
          status: 'IN_REVIEW',
          priority: 'HIGH',
          createdAt: DateTime.parse('2026-02-01T00:00:00Z'),
        ),
      ]),
    );

    final result = await repository.getMyReports();

    expect(result, isA<Success<List<CommunityReportSummary>>>());
    final reports = switch (result) {
      Success(:final data) => data,
      Err() => throw StateError('Expected success'),
    };
    expect(reports.single.targetType, CommunityReportTargetType.comment);
    expect(reports.single.reason, CommunityReportReason.spam);
    expect(reports.single.status, CommunityReportStatus.inReview);
    expect(reports.single.priority, CommunityReportPriority.high);
  });

  test('banProjectUser forwards reason/expiresAt payload', () async {
    final remoteDataSource = MockCommunityRemoteDataSource();
    final repository = CommunityRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    final expiresAt = DateTime.parse('2026-03-01T00:00:00Z');

    when(
      () => remoteDataSource.banProjectUser(
        projectCode: any(named: 'projectCode'),
        userId: any(named: 'userId'),
        request: any(named: 'request'),
      ),
    ).thenAnswer(
      (_) async => Result.success(
        ProjectCommunityBanDto(
          id: 'ban-1',
          projectId: 'project-1',
          bannedUserId: 'user-1',
          moderatorUserId: 'admin-1',
          createdAt: DateTime.parse('2026-02-01T00:00:00Z'),
          reason: 'rule violation',
          expiresAt: expiresAt,
        ),
      ),
    );

    final result = await repository.banProjectUser(
      projectCode: 'project-code',
      userId: 'user-1',
      reason: 'rule violation',
      expiresAt: expiresAt,
    );

    expect(result, isA<Success<ProjectCommunityBan>>());

    final captured = verify(
      () => remoteDataSource.banProjectUser(
        projectCode: captureAny(named: 'projectCode'),
        userId: captureAny(named: 'userId'),
        request: captureAny(named: 'request'),
      ),
    ).captured;
    expect(captured[0], 'project-code');
    expect(captured[1], 'user-1');
    final request = captured[2] as ProjectCommunityBanRequestDto;
    expect(request.reason, 'rule violation');
    expect(request.expiresAt, expiresAt);
  });

  test('moderateDeletePost delegates to moderation endpoint', () async {
    final remoteDataSource = MockCommunityRemoteDataSource();
    final repository = CommunityRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    when(
      () => remoteDataSource.moderateDeletePost(
        projectCode: any(named: 'projectCode'),
        postId: any(named: 'postId'),
      ),
    ).thenAnswer((_) async => const Result.success(null));

    final result = await repository.moderateDeletePost(
      projectCode: 'project-code',
      postId: 'post-1',
    );

    expect(result, isA<Success<void>>());
    verify(
      () => remoteDataSource.moderateDeletePost(
        projectCode: 'project-code',
        postId: 'post-1',
      ),
    ).called(1);
  });

  test('moderateDeletePostComment delegates to moderation endpoint', () async {
    final remoteDataSource = MockCommunityRemoteDataSource();
    final repository = CommunityRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    when(
      () => remoteDataSource.moderateDeletePostComment(
        projectCode: any(named: 'projectCode'),
        postId: any(named: 'postId'),
        commentId: any(named: 'commentId'),
      ),
    ).thenAnswer((_) async => const Result.success(null));

    final result = await repository.moderateDeletePostComment(
      projectCode: 'project-code',
      postId: 'post-1',
      commentId: 'comment-1',
    );

    expect(result, isA<Success<void>>());
    verify(
      () => remoteDataSource.moderateDeletePostComment(
        projectCode: 'project-code',
        postId: 'post-1',
        commentId: 'comment-1',
      ),
    ).called(1);
  });
}
