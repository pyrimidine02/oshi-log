/// EN: Tests for accessibility wrapper components
/// KO: 접근성 래퍼 컴포넌트 테스트
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/accessibility/a11y_wrapper.dart';

void main() {
  group('A11yScalableText', () {
    testWidgets('renders text with default scale factor',
        (WidgetTester tester) async {
      // EN: Build widget with default text scale
      // KO: 기본 텍스트 스케일로 위젯 빌드
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: A11yScalableText(
              'Test Text',
              style: TextStyle(fontSize: 16.0),
            ),
          ),
        ),
      );

      // EN: Verify text is displayed
      // KO: 텍스트가 표시되는지 확인
      expect(find.text('Test Text'), findsOneWidget);
    });

    testWidgets('applies text scale factor from MediaQuery',
        (WidgetTester tester) async {
      // EN: Build widget with custom text scale factor
      // KO: 사용자 정의 텍스트 스케일 팩터로 위젯 빌드
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.5),
            ),
            child: const Scaffold(
              body: A11yScalableText(
                'Scaled Text',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ),
      );

      // EN: Find the Text widget
      // KO: Text 위젯 찾기
      final textWidget = tester.widget<Text>(find.text('Scaled Text'));

      // EN: Verify font size is scaled (16.0 * 1.5 = 24.0)
      // KO: 폰트 크기가 조정되었는지 확인 (16.0 * 1.5 = 24.0)
      expect(textWidget.style?.fontSize, 24.0);
    });

    testWidgets('clamps text scale factor to maximum 2.0',
        (WidgetTester tester) async {
      // EN: Build widget with excessive text scale factor
      // KO: 과도한 텍스트 스케일 팩터로 위젯 빌드
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(3.0),
            ),
            child: const Scaffold(
              body: A11yScalableText(
                'Clamped Text',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ),
      );

      // EN: Find the Text widget
      // KO: Text 위젯 찾기
      final textWidget = tester.widget<Text>(find.text('Clamped Text'));

      // EN: Verify font size is clamped (16.0 * 2.0 = 32.0, not 48.0)
      // KO: 폰트 크기가 제한되었는지 확인 (16.0 * 2.0 = 32.0, 48.0이 아님)
      expect(textWidget.style?.fontSize, 32.0);
    });

    testWidgets('respects minimum scale factor of 1.0',
        (WidgetTester tester) async {
      // EN: Build widget with text scale factor below minimum
      // KO: 최소값 이하의 텍스트 스케일 팩터로 위젯 빌드
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(0.5),
            ),
            child: const Scaffold(
              body: A11yScalableText(
                'Min Scale Text',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ),
      );

      // EN: Find the Text widget
      // KO: Text 위젯 찾기
      final textWidget = tester.widget<Text>(find.text('Min Scale Text'));

      // EN: Verify font size respects minimum (16.0 * 1.0 = 16.0, not 8.0)
      // KO: 폰트 크기가 최소값을 준수하는지 확인 (16.0 * 1.0 = 16.0, 8.0이 아님)
      expect(textWidget.style?.fontSize, 16.0);
    });

    testWidgets('uses default font size when style is null',
        (WidgetTester tester) async {
      // EN: Build widget without style
      // KO: 스타일 없이 위젯 빌드
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.5),
            ),
            child: const Scaffold(
              body: A11yScalableText('Default Size Text'),
            ),
          ),
        ),
      );

      // EN: Find the Text widget
      // KO: Text 위젯 찾기
      final textWidget = tester.widget<Text>(find.text('Default Size Text'));

      // EN: Verify default font size is applied and scaled (14.0 * 1.5 = 21.0)
      // KO: 기본 폰트 크기가 적용되고 조정되었는지 확인 (14.0 * 1.5 = 21.0)
      expect(textWidget.style?.fontSize, 21.0);
    });

    testWidgets('applies text alignment correctly',
        (WidgetTester tester) async {
      // EN: Build widget with text alignment
      // KO: 텍스트 정렬이 있는 위젯 빌드
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: A11yScalableText(
              'Aligned Text',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

      // EN: Verify text alignment is applied
      // KO: 텍스트 정렬이 적용되었는지 확인
      final textWidget = tester.widget<Text>(find.text('Aligned Text'));
      expect(textWidget.textAlign, TextAlign.center);
    });

    testWidgets('respects maxLines property', (WidgetTester tester) async {
      // EN: Build widget with maxLines constraint
      // KO: maxLines 제약이 있는 위젯 빌드
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: A11yScalableText(
              'Multi-line text that should be limited',
              maxLines: 2,
            ),
          ),
        ),
      );

      // EN: Verify maxLines is applied
      // KO: maxLines가 적용되었는지 확인
      final textWidget = tester.widget<Text>(
        find.text('Multi-line text that should be limited'),
      );
      expect(textWidget.maxLines, 2);
    });

    testWidgets('respects overflow property', (WidgetTester tester) async {
      // EN: Build widget with overflow behavior
      // KO: 오버플로우 동작이 있는 위젯 빌드
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: A11yScalableText(
              'Overflow text',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      // EN: Verify overflow behavior is applied
      // KO: 오버플로우 동작이 적용되었는지 확인
      final textWidget = tester.widget<Text>(find.text('Overflow text'));
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('applies semantic label correctly',
        (WidgetTester tester) async {
      // EN: Build widget with semantic label
      // KO: 시맨틱 라벨이 있는 위젯 빌드
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: A11yScalableText(
              'Visual Text',
              semanticLabel: 'Screen reader text',
            ),
          ),
        ),
      );

      // EN: Verify semantic label is applied
      // KO: 시맨틱 라벨이 적용되었는지 확인
      final textWidget = tester.widget<Text>(find.text('Visual Text'));
      expect(textWidget.semanticsLabel, 'Screen reader text');
    });
  });

  group('A11yAnnouncer', () {
    testWidgets('announce works with valid context and message',
        (WidgetTester tester) async {
      // EN: Build a simple widget to get context
      // KO: 컨텍스트를 얻기 위한 간단한 위젯 빌드
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      // EN: Call announce - should not throw
      // KO: announce 호출 - 예외가 발생하지 않아야 함
      expect(
        () => A11yAnnouncer.announce(capturedContext, 'Test message'),
        returnsNormally,
      );
    });

    testWidgets('announce ignores empty messages',
        (WidgetTester tester) async {
      // EN: Build a simple widget to get context
      // KO: 컨텍스트를 얻기 위한 간단한 위젯 빌드
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      // EN: Call announce with empty string - should not throw
      // KO: 빈 문자열로 announce 호출 - 예외가 발생하지 않아야 함
      expect(
        () => A11yAnnouncer.announce(capturedContext, '   '),
        returnsNormally,
      );
    });

    testWidgets('announceError works with Korean locale',
        (WidgetTester tester) async {
      // EN: Build widget with Korean locale
      // KO: 한국어 로케일로 위젯 빌드
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      // EN: Call announceError - should not throw
      // KO: announceError 호출 - 예외가 발생하지 않아야 함
      expect(
        () => A11yAnnouncer.announceError(capturedContext, '네트워크 오류'),
        returnsNormally,
      );
    });

    testWidgets('announceError works with English locale',
        (WidgetTester tester) async {
      // EN: Build widget with English locale
      // KO: 영어 로케일로 위젯 빌드
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      // EN: Call announceError - should not throw
      // KO: announceError 호출 - 예외가 발생하지 않아야 함
      expect(
        () => A11yAnnouncer.announceError(capturedContext, 'Network error'),
        returnsNormally,
      );
    });

    testWidgets('announceSuccess works with Korean locale',
        (WidgetTester tester) async {
      // EN: Build widget with Korean locale
      // KO: 한국어 로케일로 위젯 빌드
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko', 'KR'),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      // EN: Call announceSuccess - should not throw
      // KO: announceSuccess 호출 - 예외가 발생하지 않아야 함
      expect(
        () => A11yAnnouncer.announceSuccess(capturedContext, '저장 완료'),
        returnsNormally,
      );
    });

    testWidgets('announceSuccess works with English locale',
        (WidgetTester tester) async {
      // EN: Build widget with English locale
      // KO: 영어 로케일로 위젯 빌드
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      // EN: Call announceSuccess - should not throw
      // KO: announceSuccess 호출 - 예외가 발생하지 않아야 함
      expect(
        () => A11yAnnouncer.announceSuccess(capturedContext, 'Save completed'),
        returnsNormally,
      );
    });

    testWidgets('announceError ignores empty messages',
        (WidgetTester tester) async {
      // EN: Build a simple widget to get context
      // KO: 컨텍스트를 얻기 위한 간단한 위젯 빌드
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      // EN: Call announceError with empty string - should not throw
      // KO: 빈 문자열로 announceError 호출 - 예외가 발생하지 않아야 함
      expect(
        () => A11yAnnouncer.announceError(capturedContext, ''),
        returnsNormally,
      );
    });

    testWidgets('announceSuccess ignores empty messages',
        (WidgetTester tester) async {
      // EN: Build a simple widget to get context
      // KO: 컨텍스트를 얻기 위한 간단한 위젯 빌드
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      // EN: Call announceSuccess with empty string - should not throw
      // KO: 빈 문자열로 announceSuccess 호출 - 예외가 발생하지 않아야 함
      expect(
        () => A11yAnnouncer.announceSuccess(capturedContext, ''),
        returnsNormally,
      );
    });
  });

  group('A11yUtils', () {
    testWidgets('getTextScaleFactor returns correct value',
        (WidgetTester tester) async {
      // EN: Build widget with custom text scale factor
      // KO: 사용자 정의 텍스트 스케일 팩터로 위젯 빌드
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const Text('Test');
                },
              ),
            ),
          ),
        ),
      );

      // EN: Verify text scale factor
      // KO: 텍스트 스케일 팩터 확인
      final scaleFactor = A11yUtils.getTextScaleFactor(capturedContext);
      expect(scaleFactor, 1.5);
    });

    testWidgets('isScreenReaderEnabled returns correct value',
        (WidgetTester tester) async {
      // EN: Build widget with accessibleNavigation enabled
      // KO: accessibleNavigation이 활성화된 위젯 빌드
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              accessibleNavigation: true,
            ),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const Text('Test');
                },
              ),
            ),
          ),
        ),
      );

      // EN: Verify screen reader status
      // KO: 스크린 리더 상태 확인
      final isEnabled = A11yUtils.isScreenReaderEnabled(capturedContext);
      expect(isEnabled, true);
    });
  });
}
