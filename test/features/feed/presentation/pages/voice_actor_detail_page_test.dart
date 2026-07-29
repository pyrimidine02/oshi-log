import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/feed/presentation/pages/voice_actor_detail_page.dart';
import 'package:oshi_log/features/projects/domain/entities/project_entities.dart';

void main() {
  testWidgets('voice actor header follows the document profile hierarchy', (
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
          home: const Scaffold(
            body: SingleChildScrollView(
              child: VoiceActorProfileHeader(detail: _detail),
            ),
          ),
        ),
      ),
    );

    expect(find.text('VOICE CAST'), findsOneWidget);
    expect(find.text('양자리 리오'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _detail = VoiceActorDetail(
  id: 'voice-1',
  displayName: '양자리 리오',
  stageName: 'Rio Yozari',
  agency: 'Example Agency',
  bio: '작품의 라이브와 캐릭터 연기를 담당합니다.',
);
