import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/projects/application/fan_subjects_controller.dart';
import 'package:oshi_log/features/projects/data/dto/fan_subject_dto.dart';
import 'package:oshi_log/features/projects/domain/entities/fan_subject.dart';
import 'package:oshi_log/features/projects/domain/repositories/fan_subjects_repository.dart';
import 'package:oshi_log/features/projects/presentation/pages/fan_subject_detail_page.dart';

void main() {
  const subject = FanSubject(
    id: 'subject-artist',
    kind: FanSubjectKind.artist,
    entityId: 'artist-source',
    key: 'artist:ado',
    name: 'Ado',
    description: '일본 아티스트',
  );

  testWidgets('shows generic subject metadata and current subscription', (
    tester,
  ) async {
    final repository = _FakeFanSubjectsRepository(
      subject: subject,
      subscribed: true,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fanSubjectsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          home: FanSubjectDetailPage(subjectId: 'subject-artist'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ado'), findsWidgets);
    expect(find.text('Artist'), findsWidgets);
    expect(find.text('일본 아티스트'), findsOneWidget);
    expect(find.bySemanticsLabel('Ado Unfollow'), findsOneWidget);

    await tester.tap(find.text('Unfollow'));
    await tester.pumpAndSettle();

    expect(repository.unsubscribedSubjectIds, ['subject-artist']);
    expect(find.text('Follow'), findsOneWidget);
  });
}

class _FakeFanSubjectsRepository implements FanSubjectsRepository {
  _FakeFanSubjectsRepository({required this.subject, required this.subscribed});

  final FanSubject subject;
  bool subscribed;
  final List<String> unsubscribedSubjectIds = [];

  @override
  Future<Result<FanSubject>> getSubject(String identifier) async {
    return Result.success(subject);
  }

  @override
  Future<Result<List<FanSubject>>> getSubjects(FanSubjectQuery query) async {
    return Result.success([subject]);
  }

  @override
  Future<Result<List<FanSubjectSubscription>>> getMySubjects() async {
    return Result.success(
      subscribed
          ? [FanSubjectSubscription(subject: subject, subscribed: true)]
          : const [],
    );
  }

  @override
  Future<Result<FanSubjectSubscription>> subscribe(String subjectId) async {
    subscribed = true;
    return Result.success(
      FanSubjectSubscription(subject: subject, subscribed: true),
    );
  }

  @override
  Future<Result<void>> unsubscribe(String subjectId) async {
    unsubscribedSubjectIds.add(subjectId);
    subscribed = false;
    return const Result.success(null);
  }
}
