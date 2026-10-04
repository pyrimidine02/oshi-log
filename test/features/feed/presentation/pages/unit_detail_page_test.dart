import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/features/oshikatsu/catalog/presentation/pages/unit_detail_page.dart';
import 'package:oshi_log/features/oshikatsu/catalog/domain/entities/project_entities.dart';

void main() {
  testWidgets('unit dossier uses the field-notes document hierarchy', (
    tester,
  ) async {
    UnitMember? selectedMember;

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: UnitDossierView(
          unit: _unit,
          membersState: const AsyncData(_members),
          onMemberTap: (member) => selectedMember = member,
        ),
      ),
    );

    expect(find.text('밴드 · 유닛'), findsOneWidget);
    expect(find.text('MyGO!!!!!'), findsOneWidget);
    expect(find.text('멤버 · 성우'), findsOneWidget);
    expect(find.byType(SliverAppBar), findsNothing);

    await tester.tap(find.text('高松 燈'));
    expect(selectedMember?.id, 'member-1');
  });

  testWidgets('unit dossier has no overflow at 320dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(2),
        ),
        child: MaterialApp(
          theme: GBTTheme.light,
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: UnitDossierView(
            unit: _unit,
            membersState: const AsyncData(_members),
            onMemberTap: (_) {},
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('高松 燈'),
      160,
      scrollable: find.byType(Scrollable),
    );
    expect(tester.takeException(), isNull);

    final firstTapTarget = tester.getSize(find.byType(InkWell).first);
    expect(firstTapTarget.height, greaterThanOrEqualTo(48));
  });
}

const _unit = Unit(
  id: 'unit-1',
  code: 'mygo',
  displayName: 'MyGO!!!!!',
  status: 'ACTIVE',
  debutDate: '2022-07-03',
  description: '길을 잃어도 앞으로 나아가는 다섯 멤버의 밴드입니다.',
);

const _members = <UnitMember>[
  UnitMember(
    id: 'member-1',
    name: '高松 燈',
    characterNameKana: 'たかまつ ともり',
    instrument: 'Vocal',
    role: '보컬과 작사를 담당하는 리더',
    voiceActorName: '羊宮姃那',
    order: 1,
  ),
  UnitMember(
    id: 'member-2',
    name: '千早 愛音',
    instrument: 'Guitar',
    voiceActorName: '立石凛',
    order: 2,
  ),
];
