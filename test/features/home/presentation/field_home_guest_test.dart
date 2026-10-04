import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oshi_log/app/compositions/home/presentation/field_home/field_home_page.dart';
import 'package:oshi_log/app/compositions/home/presentation/field_home/widgets/home_entry_sections.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/identity/account/application/settings_controller.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/projects_controller.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/fan_subjects_controller.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/project_entities.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/repositories/projects_repository.dart';
import 'package:oshi_log/features/shared/home/application/home_controller.dart';

void main() {
  for (final locale in ['ko', 'ja']) {
    for (final dark in [false, true]) {
      testWidgets(
        'guest avoids private providers at 320dp 200% $locale $dark',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final storage = _MockLocalStorage();
          final repository = _MockProjectsRepository();
          when(storage.getSelectedProjectKey).thenReturn(null);
          when(storage.getSelectedProjectId).thenReturn(null);
          when(storage.getSelectedUnitIds).thenReturn(const []);
          when(
            () => repository.getProjects(
              forceRefresh: any(named: 'forceRefresh'),
            ),
          ).thenAnswer((_) async => const Success(<Project>[]));
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                isAuthenticatedProvider.overrideWithValue(false),
                localStorageProvider.overrideWith((ref) async => storage),
                projectsRepositoryProvider.overrideWith(
                  (ref) async => repository,
                ),
                projectsControllerProvider.overrideWith(_EmptyProjects.new),
                homeControllerProvider.overrideWith(
                  (ref) => throw StateError('Guest read home'),
                ),
                userProfileControllerProvider.overrideWith(
                  (ref) => throw StateError('Guest read profile'),
                ),
                myFanSubjectsControllerProvider.overrideWith(
                  (ref) => throw StateError('Guest read subscriptions'),
                ),
              ],
              child: MaterialApp(
                locale: Locale(locale),
                supportedLocales: const [Locale('ko'), Locale('ja')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                theme: dark ? GBTTheme.dark : GBTTheme.light,
                home: const MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: FieldHomePage(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(HomeGuestSections), findsOneWidget);
          await tester.scrollUntilVisible(find.byType(HomeMusicShortcut), 200);
          expect(
            find.text(locale == 'ko' ? '곡·아티스트' : '楽曲・アーティスト'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _EmptyProjects extends ProjectsController {
  _EmptyProjects(super.ref) {
    state = const AsyncData([]);
  }
  @override
  Future<void> load({bool forceRefresh = false}) async {}
}

class _MockLocalStorage extends Mock implements LocalStorage {}

class _MockProjectsRepository extends Mock implements ProjectsRepository {}
