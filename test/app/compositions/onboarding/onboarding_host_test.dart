import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/project_entities.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/repositories/projects_repository.dart';
import 'package:oshi_log/features/oshikatsu/catalog/presentation/widgets/field_project_picker_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oshi_log/app/compositions/onboarding/onboarding_host.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/features/identity/account/application/app_preferences.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/projects_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('guest language and theme persist without authentication', (
    tester,
  ) async {
    final storage = await LocalStorage.create();
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWith((_) async => storage),
        isAuthenticatedProvider.overrideWith((_) => false),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _app(const Locale('en'), false, firstRun: false),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日本語'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dark mode'));
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(container.read(isAuthenticatedProvider), isFalse);
    expect(container.read(localeProvider)?.languageCode, 'ja');
    expect(storage.getLocale(), 'ja');
    expect(container.read(themeModeProvider), 'dark');
    expect(storage.getThemeMode(), 'dark');
  });

  testWidgets(
    'project choice uses shared picker and persists existing selection',
    (tester) async {
      final storage = await LocalStorage.create();
      final repository = _ProjectsRepository();
      when(() => repository.getProjects()).thenAnswer(
        (_) async => const Result.success([
          Project(
            id: 'project-a',
            code: 'a',
            name: 'Project A',
            status: 'ACTIVE',
            defaultTimezone: 'Asia/Tokyo',
          ),
          Project(
            id: 'project-b',
            code: 'b',
            name: 'Project B',
            status: 'ACTIVE',
            defaultTimezone: 'Asia/Tokyo',
          ),
        ]),
      );
      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWith((_) async => storage),
          projectsRepositoryProvider.overrideWith((_) async => repository),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _app(const Locale('en'), false, firstRun: true),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Choose a project'), 250);
      await tester.tap(find.text('Choose a project'));
      await tester.pumpAndSettle();
      expect(find.byType(FieldProjectPickerSheet), findsOneWidget);
      await tester.tap(find.text('Project B'));
      await tester.pumpAndSettle();
      expect(storage.getSelectedProjectKey(), 'b');
      expect(storage.getSelectedProjectId(), 'project-b');
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      expect(storage.isOnboardingCompleted(), isTrue);
    },
  );

  for (final language in ['ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets(
        'skip all persists despite project failure $language dark=$dark at 320dp 200%',
        (tester) async {
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({
            LocalStorageKeys.locale: language,
          });
          final storage = await LocalStorage.create();
          final container = ProviderContainer(
            overrides: [
              localStorageProvider.overrideWith((_) async => storage),
              projectsControllerProvider.overrideWith(
                (ref) => _FailedProjects(ref),
              ),
            ],
          );
          addTearDown(container.dispose);
          expect(
            await container.read(firstRunCompletedProvider.future),
            isFalse,
          );
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: _app(Locale(language), dark, firstRun: true),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(find.byType(FirstRunPreferencesSheet), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byKey(const ValueKey('first-run-skip-all')));
          await tester.pumpAndSettle();
          expect(find.byType(FirstRunPreferencesSheet), findsNothing);
          expect(storage.isOnboardingCompleted(), isTrue);
          expect(
            await container.read(firstRunCompletedProvider.future),
            isTrue,
          );
          expect(storage.getLocale(), language);
          expect(storage.getSelectedProjectKey(), isNull);
        },
      );
    }
  }
}

Widget _app(Locale locale, bool dark, {required bool firstRun}) => MaterialApp(
  locale: locale,
  supportedLocales: const [Locale('en'), Locale('ja'), Locale('ko')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: dark
      ? GBTTheme.darkFor(locale.languageCode)
      : GBTTheme.lightFor(locale.languageCode),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => firstRun
            ? showFirstRunPreferencesSheet(context)
            : showLocaleThemeSheet(context),
        child: const Text('Open'),
      ),
    ),
  ),
);

class _FailedProjects extends ProjectsController {
  _FailedProjects(super.ref) {
    state = AsyncError(StateError('offline'), StackTrace.empty);
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {}
}

class _ProjectsRepository extends Mock implements ProjectsRepository {}
