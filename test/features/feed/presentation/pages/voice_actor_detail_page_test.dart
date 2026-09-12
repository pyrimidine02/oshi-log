import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/core/widgets/common/gbt_linkified_text.dart';
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

  testWidgets(
    'activity tab keeps long biographies scrollable and shows HTTPS site',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const bio = '''소개 시작
대표작과 라이브 활동을 기록한 긴 소개입니다.
대표작과 라이브 활동을 기록한 긴 소개입니다.
대표작과 라이브 활동을 기록한 긴 소개입니다.
대표작과 라이브 활동을 기록한 긴 소개입니다.
소개 끝 MARKER''';
      await tester.pumpWidget(
        _testApp(
          child: const VoiceActorActivityTab(
            detail: VoiceActorDetail(
              id: 'voice-activity',
              displayName: '양자리 리오',
              bio: bio,
              officialWebsite: 'https://example.com/rio',
            ),
          ),
        ),
      );

      expect(find.byType(GBTLinkifiedText), findsNWidgets(2));
      expect(find.textContaining('소개 시작'), findsOneWidget);

      await tester.drag(
        find.byKey(const ValueKey('voice-actor-activity-scroll')),
        const Offset(0, -1200),
      );
      await tester.pump();

      expect(find.textContaining('MARKER'), findsOneWidget);
      expect(find.textContaining('https://example.com/rio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('activity tab accepts an HTTPS URL with an anchor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        child: const VoiceActorActivityTab(
          detail: VoiceActorDetail(
            id: 'voice-anchor',
            displayName: '양자리 리오',
            officialWebsite: 'https://example.com/profile#bio',
          ),
        ),
      ),
    );

    expect(find.text('공식 사이트'), findsOneWidget);
    expect(
      find.textContaining('https://example.com/profile#bio'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity tab rejects insecure, malformed, or credential URLs', (
    tester,
  ) async {
    for (final website in <String>[
      'http://example.com/insecure',
      'https://',
      'https://user:pass@example.com/profile',
    ]) {
      await tester.pumpWidget(
        _testApp(
          child: VoiceActorActivityTab(
            detail: VoiceActorDetail(
              id: 'voice-empty-${website.hashCode}',
              displayName: '양자리 리오',
              officialWebsite: website,
            ),
          ),
        ),
      );

      expect(find.text('소개 정보가 없습니다'), findsOneWidget);
      expect(find.byType(GBTLinkifiedText), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'activity tab remains usable at 2x text scale on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _testApp(
          textScaler: const TextScaler.linear(2),
          child: const VoiceActorActivityTab(
            detail: VoiceActorDetail(
              id: 'voice-scale',
              displayName: '양자리 리오',
              bio: '소개 정보가 작은 화면에서도 읽혀야 합니다.',
              officialWebsite: 'https://example.com/profile',
            ),
          ),
        ),
      );

      expect(find.text('소개'), findsOneWidget);
      expect(find.text('공식 사이트'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _testApp({
  required Widget child,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: GBTTheme.light,
    locale: const Locale('ko'),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
    builder: (context, appChild) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: appChild!,
      );
    },
    home: Scaffold(body: child),
  );
}

const _detail = VoiceActorDetail(
  id: 'voice-1',
  displayName: '양자리 리오',
  stageName: 'Rio Yozari',
  agency: 'Example Agency',
  bio: '작품의 라이브와 캐릭터 연기를 담당합니다.',
);
