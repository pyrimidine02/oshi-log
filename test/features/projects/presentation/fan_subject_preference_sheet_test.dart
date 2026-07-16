import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/providers/core_providers.dart';
import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/core/utils/result.dart';
import 'package:girlsbandtabi_app/features/projects/application/fan_subjects_controller.dart';
import 'package:girlsbandtabi_app/features/projects/domain/entities/fan_subject.dart';
import 'package:girlsbandtabi_app/features/projects/domain/repositories/fan_subjects_repository.dart';
import 'package:girlsbandtabi_app/features/projects/presentation/widgets/fan_subject_preference_sheet.dart';

void main() {
  testWidgets('keeps mobile filters scoped to current girls-band subjects', (
    tester,
  ) async {
    final repository = _FakeFanSubjectsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAuthenticatedProvider.overrideWithValue(false),
          fanSubjectsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          theme: GBTTheme.light,
          home: const Scaffold(
            body: FanSubjectPreferenceSheet(projectId: 'bang-dream'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Voice actors'), findsOneWidget);
    expect(find.text('Artists'), findsNothing);
    expect(find.text('Anime'), findsNothing);
    expect(find.byIcon(Icons.record_voice_over_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('fan-subject-kind-ARTIST')), findsNothing);
    expect(find.byKey(const ValueKey('fan-subject-kind-ANIME')), findsNothing);
  });
}

class _FakeFanSubjectsRepository implements FanSubjectsRepository {
  final queries = <FanSubjectQuery>[];

  @override
  Future<Result<FanSubject>> getSubject(String identifier) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<FanSubject>>> getSubjects(FanSubjectQuery query) async {
    queries.add(query);
    return const Result.success(<FanSubject>[]);
  }

  @override
  Future<Result<List<FanSubjectSubscription>>> getMySubjects() async {
    return const Result.success(<FanSubjectSubscription>[]);
  }

  @override
  Future<Result<FanSubjectSubscription>> subscribe(String subjectId) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> unsubscribe(String subjectId) {
    throw UnimplementedError();
  }
}
