import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/features/place/places/application/places_controller.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_comment_entities.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/place/places/presentation/widgets/place_onsite_sections.dart';

void main() {
  const name = '下北沢 LIVE HAUS 長い会場名・시모키타자와 라이브하우스';
  const address = '〒155-0031 東京都世田谷区北沢二丁目六番五号 地下一階';
  final place = PlaceDetail(
    id: 'p',
    name: name,
    address: address,
    types: const [],
    savedAt: DateTime(2026, 10, 3, 18, 30),
    isFromCache: true,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    String locale = 'ja',
    bool dark = false,
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: const [Locale('ja'), Locale('ko')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: dark ? GBTTheme.darkFor(locale) : GBTTheme.lightFor(locale),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final locale in ['ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$locale dark=$dark on-site presentation preserves full copy at 320dp/200%',
        (tester) async {
          String? copied;
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async {
              if (call.method == 'Clipboard.setData') {
                copied = (call.arguments as Map)['text'] as String;
              }
              return null;
            },
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(SystemChannels.platform, null),
          );
          await pump(
            tester,
            PlaceAccessSection(place: place),
            locale: locale,
            dark: dark,
          );
          expect(tester.takeException(), isNull);
          final show = find.byKey(const ValueKey('place-show-onsite'));
          await tester.ensureVisible(show);
          await tester.tap(show);
          await tester.pumpAndSettle();
          expect(find.byType(PlacePresentationSheet), findsOneWidget);
          expect(find.text(name), findsWidgets);
          expect(find.text(address), findsWidgets);
          expect(
            find.textContaining(locale == 'ja' ? '原文未確認' : '원문 미확인'),
            findsWidgets,
          );
          expect(find.textContaining('2026.10.03 18:30'), findsWidgets);
          final copy = find.byKey(const ValueKey('place-copy-name-address'));
          await tester.ensureVisible(copy);
          expect(tester.getSize(copy).height, greaterThanOrEqualTo(48));
          await tester.tap(copy);
          await tester.pump();
          expect(copied, '$name\n$address');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('no visit rules never implies access or photography permission', (
    tester,
  ) async {
    await pump(tester, const PlaceVisitNotice(), locale: 'ko');
    expect(find.textContaining('정보 없음은 출입·촬영 허가가 아닙니다'), findsOneWidget);
    expect(find.textContaining('사유지'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Tips use server categories, keep pinned notes, and cap regular list at three',
    (tester) async {
      final requests = <PlaceTipCategory>[];
      await pump(
        tester,
        const PlaceTipsSection(placeId: 'p'),
        overrides: [
          placeTipsProvider.overrideWith((ref, key) async {
            requests.add(key.category);
            if (key.category == PlaceTipCategory.pinned) {
              return [_comment('pinned', pinned: true)];
            }
            return List.generate(4, (i) => _comment('${key.category.name}-$i'));
          }),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('pinned'), findsOneWidget);
      expect(find.text('access-2'), findsOneWidget);
      expect(find.text('access-3'), findsNothing);
      final routes = find.byKey(const ValueKey('place-tips-routes'));
      await tester.ensureVisible(routes);
      await tester.tap(routes);
      await tester.pumpAndSettle();
      expect(
        requests,
        containsAll([
          PlaceTipCategory.access,
          PlaceTipCategory.pinned,
          PlaceTipCategory.routes,
        ]),
      );
      expect(find.text('routes-0'), findsOneWidget);
      expect(find.text('access-0'), findsNothing);
      expect(find.text('pinned'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

PlaceComment _comment(String body, {bool pinned = false}) => PlaceComment(
  id: body,
  authorId: 'fan',
  body: body,
  createdAt: DateTime(2026, 10, 1),
  replyCount: 0,
  isAdminNote: false,
  isPinnedByAdmin: pinned,
  tags: const [],
  photoUploadIds: const [],
  photoUrls: const [],
);
