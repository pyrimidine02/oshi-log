import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/widgets/feedback/gbt_loading.dart';

void main() {
  group('GBT feedback localization', () {
    testWidgets('uses English copy for default loading states', (tester) async {
      await tester.pumpWidget(
        _testApp(locale: const Locale('en'), child: const GBTLoading()),
      );

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.bySemanticsLabel('로딩 중'), findsNothing);

      await tester.pumpWidget(
        _testApp(
          locale: const Locale('en'),
          child: const GBTLoadingOverlay(
            isLoading: true,
            child: SizedBox.expand(),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Loading. Please wait.'), findsOneWidget);
    });

    testWidgets('localizes default error title, retry label, and hint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          locale: const Locale('en'),
          child: GBTErrorState(message: 'Network unavailable', onRetry: () {}),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('문제가 발생했어요'), findsNothing);
      expect(find.text('다시 시도'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.hint == 'Tap to try again',
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses Japanese copy for default feedback labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          locale: const Locale('ja'),
          child: Column(
            children: [
              const Expanded(child: GBTLoading()),
              Expanded(
                child: GBTErrorState(message: '接続できません', onRetry: () {}),
              ),
            ],
          ),
        ),
      );

      expect(find.bySemanticsLabel('読み込み中'), findsOneWidget);
      expect(find.text('問題が発生しました'), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });

    testWidgets('localizes shimmer live-region semantics', (tester) async {
      await tester.pumpWidget(
        _testApp(
          locale: const Locale('en'),
          child: const GBTShimmer(child: SizedBox(width: 40, height: 20)),
        ),
      );

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.bySemanticsLabel('로딩 중'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('keeps Korean copy for Korean locale', (tester) async {
      await tester.pumpWidget(
        _testApp(
          locale: const Locale('ko'),
          child: GBTErrorState(message: '연결할 수 없어요', onRetry: () {}),
        ),
      );

      expect(find.text('문제가 발생했어요'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.hint == '탭하면 다시 시도합니다',
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps explicit title and retryLabel API behavior', (
      tester,
    ) async {
      var retryCount = 0;

      await tester.pumpWidget(
        _testApp(
          locale: const Locale('en'),
          child: GBTErrorState(
            title: 'Connection lost',
            message: 'Check your connection.',
            retryLabel: 'Reload now',
            onRetry: () => retryCount += 1,
          ),
        ),
      );

      expect(find.text('Connection lost'), findsOneWidget);
      expect(find.text('Reload now'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Try again'), findsNothing);

      await tester.tap(find.text('Reload now'));
      expect(retryCount, 1);
    });

    testWidgets('does not overflow at 320dp with 2x text scaling', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _testApp(
          locale: const Locale('en'),
          textScaler: const TextScaler.linear(2),
          child: GBTErrorState(
            message:
                'We could not load this information. Check your connection '
                'and try again.',
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _testApp({
  required Locale locale,
  required Widget child,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    locale: locale,
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
