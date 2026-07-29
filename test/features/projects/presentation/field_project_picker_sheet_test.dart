import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/theme/gbt_colors.dart';
import 'package:oshi_log/features/projects/domain/entities/project_entities.dart';
import 'package:oshi_log/features/projects/presentation/widgets/field_project_picker_sheet.dart';

import '../../../testing/tolerant_local_file_comparator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Pretendard');
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    for (final asset in [
      'assets/fonts/Pretendard-Regular.otf',
      'assets/fonts/Pretendard-Medium.otf',
      'assets/fonts/Pretendard-SemiBold.otf',
      'assets/fonts/Pretendard-Bold.otf',
      'assets/fonts/Pretendard-ExtraBold.otf',
    ]) {
      loader.addFont(rootBundle.load(asset));
    }
    await Future.wait([loader.load(), iconLoader.load()]);
  });

  const projects = [
    Project(
      id: 'project-1',
      code: 'bandori',
      name: 'BanG Dream!',
      status: 'active',
      defaultTimezone: 'Asia/Tokyo',
    ),
    Project(
      id: 'project-2',
      code: 'girls-band-cry',
      name: 'Girls Band Cry',
      status: 'active',
      defaultTimezone: 'Asia/Tokyo',
    ),
  ];

  testWidgets(
    'presents a direct project switcher without duplicated metadata',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
          theme: GBTTheme.light,
          home: Scaffold(
            body: FieldProjectPickerSheet(
              projects: projects,
              selectedId: projects.first.id,
              onConfirm: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('어느 세계로 여행할까요?'), findsOneWidget);
      expect(find.text('성지·일정·도감이 선택한 프로젝트 기준으로 바뀝니다'), findsOneWidget);
      expect(find.text('현재 여행'), findsNothing);
      expect(find.text('BanG Dream!'), findsOneWidget);
      expect(find.text('CURRENT'), findsNothing);
      expect(find.text('현재'), findsOneWidget);
      expect(find.text('BANDORI · 도쿄 시간'), findsNothing);
      expect(find.text('GIRLS-BAND-CRY · 도쿄 시간'), findsNothing);
      expect(find.byType(RadioListTile<String>), findsNothing);
      expect(find.byKey(const ValueKey('field-project-confirm')), findsNothing);
      expect(
        find.byKey(const ValueKey('field-project-row-project-1')),
        findsOne,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('field-project-row-project-1')))
            .height,
        greaterThanOrEqualTo(56),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('switches project immediately with a single row tap', (
    tester,
  ) async {
    Project? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
        theme: GBTTheme.light,
        home: Scaffold(
          body: FieldProjectPickerSheet(
            projects: projects,
            selectedId: projects.first.id,
            onConfirm: (project) => confirmed = project,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('field-project-row-project-2')));
    await tester.pump();

    expect(confirmed?.id, 'project-2');
    expect(find.byKey(const ValueKey('field-project-confirm')), findsNothing);
  });

  testWidgets('opens generalized interests without changing project context', (
    tester,
  ) async {
    var manageCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        theme: GBTTheme.light,
        home: Scaffold(
          body: FieldProjectPickerSheet(
            projects: projects,
            selectedId: projects.first.id,
            onConfirm: (_) {},
            onManageSubjects: () => manageCount += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('manage-fan-subjects')));
    await tester.pump();

    expect(manageCount, 1);
  });

  testWidgets('remains usable at 320dp with 200 percent text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: GBTTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 720),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: FieldProjectPickerSheet(
              projects: projects,
              selectedId: projects.first.id,
              onConfirm: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Where do you want to travel?'), findsOneWidget);
    expect(
      find.text(
        'Places, schedules, and collections follow the selected project.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('field-project-confirm')), findsNothing);
    expect(find.byKey(const ValueKey('field-project-row-project-1')), findsOne);
    expect(find.byKey(const ValueKey('field-project-row-project-2')), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the original light blue accent in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: GBTTheme.dark,
        home: Scaffold(
          body: FieldProjectPickerSheet(
            projects: projects,
            selectedId: projects.first.id,
            onConfirm: (_) {},
          ),
        ),
      ),
    );

    final selectedIcon = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
    expect(selectedIcon.color, GBTColors.darkPrimary);
    expect(find.text('CURRENT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('matches the narrow-screen field-notes visual contract', (
    tester,
  ) async {
    final previousComparator = goldenFileComparator;
    goldenFileComparator = TolerantLocalFileComparator(
      Uri.file(
        '${Directory.current.path}/test/features/projects/presentation/'
        'field_project_picker_sheet_test.dart',
      ),
      precisionTolerance: 0.015,
    );
    addTearDown(() => goldenFileComparator = previousComparator);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
        theme: GBTTheme.light,
        home: Scaffold(
          backgroundColor: const Color(0x73000000),
          body: RepaintBoundary(
            key: const ValueKey('field-project-golden'),
            child: FieldProjectPickerSheet(
              projects: projects,
              selectedId: projects.first.id,
              onConfirm: (_) {},
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('field-project-golden')),
      matchesGoldenFile('goldens/field_project_picker.png'),
    );
  });
}
