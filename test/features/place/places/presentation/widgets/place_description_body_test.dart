import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/theme/gbt_theme.dart';
import 'package:oshi_log/features/place/places/presentation/widgets/place_description_body.dart';

const description = '''클럽 치타는 가와사키의 라이브홀입니다. 공연마다 입장 시간을 확인하세요.

[시설 공식 안내](https://clubcitta.co.jp/institution/)

## 연관 공연
2024-09-13 · トゲナシトゲアリ 2nd ONE-MAN LIVE “凛音の理”

## 방문 정보
〒210-0023 神奈川県川崎市川崎区小川町5-7
입장 시각과 관람 구역은 각 공연의 공식 안내를 기준으로 확인하세요.
''';

void main() {
  Future<void> pumpDescription(
    WidgetTester tester, {
    String? text = description,
    double scale = 1,
    bool dark = false,
  }) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? GBTTheme.dark : GBTTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PlaceDescriptionBody(description: text),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders headings and named links instead of Markdown source', (
    tester,
  ) async {
    await pumpDescription(tester);
    expect(find.text('연관 공연', findRichText: true), findsOneWidget);
    expect(find.text('방문 정보', findRichText: true), findsOneWidget);
    expect(find.text('시설 공식 안내', findRichText: true), findsOneWidget);
    expect(find.textContaining('https://', findRichText: true), findsNothing);
    expect(find.textContaining('##', findRichText: true), findsNothing);
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    testWidgets('long introduction scrolls at 200% text, dark=$dark', (
      tester,
    ) async {
      await pumpDescription(tester, scale: 2, dark: dark);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('방문 정보', findRichText: true),
        220,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('opens named HTTPS source and reports launch failure', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (call) async {
            calls.add(call);
            return false;
          },
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/url_launcher'),
            null,
          ),
    );
    await pumpDescription(
      tester,
      text: '[시설 공식 안내](https://clubcitta.co.jp/institution/)',
    );
    await tester.tap(find.text('시설 공식 안내', findRichText: true));
    await tester.pumpAndSettle();
    expect(calls, hasLength(1));
    expect(
      (calls.single.arguments as Map)['url'],
      'https://clubcitta.co.jp/institution/',
    );
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('blank description uses the normal empty state', (tester) async {
    await pumpDescription(tester, text: '  \n ');
    expect(find.text('No description available.'), findsOneWidget);
  });
}
