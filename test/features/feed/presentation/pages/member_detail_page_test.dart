import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:girlsbandtabi_app/core/theme/gbt_theme.dart';
import 'package:girlsbandtabi_app/features/feed/presentation/pages/member_detail_page.dart';
import 'package:girlsbandtabi_app/features/projects/domain/entities/project_entities.dart';

void main() {
  testWidgets('member dossier uses indexed borderless record sections', (
    tester,
  ) async {
    VoiceActorRole? selectedActor;

    await tester.pumpWidget(
      MaterialApp(
        theme: GBTTheme.light,
        home: MemberDossierView(
          member: _member,
          unit: _unit,
          onVoiceActorTap: (actor) => selectedActor = actor,
        ),
      ),
    );

    expect(find.text('MEMBER DOSSIER'), findsOneWidget);
    expect(find.text('高松 燈'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('VOICE CAST'), findsOneWidget);
    expect(find.byType(SliverAppBar), findsNothing);

    await tester.scrollUntilVisible(
      find.text('羊宮姃那'),
      160,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('羊宮姃那'));
    expect(selectedActor?.id, 'voice-1');
  });

  testWidgets('member dossier has no overflow at 320dp and 200 percent text', (
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
          home: MemberDossierView(
            member: _member,
            unit: _unit,
            onVoiceActorTap: (_) {},
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('羊宮姃那'),
      160,
      scrollable: find.byType(Scrollable),
    );
    expect(tester.takeException(), isNull);

    final actorTapTarget = tester.getSize(find.byType(InkWell).first);
    expect(actorTapTarget.height, greaterThanOrEqualTo(48));
  });
}

const _unit = Unit(id: 'unit-1', code: 'mygo', displayName: 'MyGO!!!!!');

const _member = UnitMember(
  id: 'member-1',
  name: '高松 燈',
  characterNameKana: 'たかまつ ともり',
  role: '보컬과 작사를 담당하는 리더',
  instrument: 'Vocal',
  birthdate: '11-22',
  hometown: '도쿄도',
  description: '자신의 마음을 노래와 노트로 기록하는 멤버입니다.',
  voiceActors: [
    VoiceActorRole(id: 'voice-1', displayName: '羊宮姃那', roleType: 'MAIN'),
  ],
);
