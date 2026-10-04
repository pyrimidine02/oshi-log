import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/app/compositions/today/application/today_controller.dart';
import 'package:oshi_log/app/compositions/today/domain/today_plan.dart';
import 'package:oshi_log/app/compositions/today/presentation/today_page.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';

void main() {
  for (final locale in ['ko', 'ja']) {
    for (final dark in [false, true]) {
      testWidgets(
        'saved text survives failed refresh and actions fit 320dp 200% $locale $dark',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final actions = <String>[];
          final snapshot = TodayTextSnapshot(
            name: 'Saved place',
            address: 'Saved address',
            description: 'Respect residents',
            savedAt: DateTime.utc(2026, 10, 4, 1),
          );
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(locale),
              supportedLocales: const [Locale('ko'), Locale('ja')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: dark ? GBTTheme.dark : GBTTheme.light,
              home: Builder(
                builder: (context) => MediaQuery(
                  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                  child: Scaffold(
                    body: TodayPlaceList(
                      state: TodayState(
                        plan: TodayPlan(
                          date: todayDateKey(DateTime.now()),
                          entries: [
                            TodayPlace(
                              projectKey: 'p',
                              placeId: '1',
                              name: 'A very long place name 日本語 한국어',
                              address: 'A long address for the selected place',
                              text: snapshot,
                            ),
                            const TodayPlace(
                              projectKey: 'p',
                              placeId: '2',
                              name: 'Second',
                              address: 'Another address',
                            ),
                          ],
                        ),
                        failedDownloads: const {'p:1'},
                        failure: TodayFailure.download,
                      ),
                      onMove: (from, to) => actions.add('$from:$to'),
                      onToggleSkipped: actions.add,
                      onRemove: (_) {},
                      onDownload: (_) => actions.add('download'),
                      onOpenText: (text) => showTodayText(context, text),
                      onStartToday: () => actions.add('reset'),
                      onBrowsePlaces: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          for (final action in ['down', 'skip', 'download']) {
            final finder = find.byKey(ValueKey('today-$action-p:1'));
            await tester.scrollUntilVisible(finder, 200);
            await tester.pumpAndSettle();
            await tester.tap(finder);
            expect(tester.takeException(), isNull);
          }
          expect(actions, ['0:1', 'p:1', 'download']);
          expect(find.textContaining('2026-10-04 10:00 JST'), findsOneWidget);
          final read = find.byKey(const ValueKey('today-read-p:1'));
          await tester.ensureVisible(read);
          await tester.pumpAndSettle();
          await tester.tap(read);
          await tester.pumpAndSettle();
          expect(find.textContaining('Saved address'), findsOneWidget);
          expect(find.textContaining('Respect residents'), findsOneWidget);
          expect(find.textContaining('2026-10-04 10:00 JST'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
