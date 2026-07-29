import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/visits/application/visits_controller.dart';
import 'package:oshi_log/features/visits/domain/entities/visit_entities.dart';
import 'package:oshi_log/features/visits/domain/repositories/visits_repository.dart';

class _MockVisitsRepository extends Mock implements VisitsRepository {}

void main() {
  group('UserVisitsController', () {
    test('loads visits from repository', () async {
      final repository = _MockVisitsRepository();
      when(
        () => repository.getAllVisits(
          pageSize: any(named: 'pageSize'),
          forceRefresh: any(named: 'forceRefresh'),
        ),
      ).thenAnswer(
        (_) async => Result.success(const [
          VisitEvent(id: 'visit-1', placeId: 'place-1', visitedAt: null),
        ]),
      );

      final container = ProviderContainer(
        overrides: [
          visitsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(userVisitsControllerProvider.notifier);
      await notifier.load(forceRefresh: true);

      final state = container.read(userVisitsControllerProvider);
      expect(state.valueOrNull?.length, 1);
      verify(
        () => repository.getAllVisits(
          pageSize: any(named: 'pageSize'),
          forceRefresh: true,
        ),
      ).called(1);
    });
  });
}
