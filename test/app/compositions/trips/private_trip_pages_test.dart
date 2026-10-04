import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oshi_log/app/compositions/trips/application/private_trips_controller.dart';
import 'package:oshi_log/app/compositions/trips/data/private_trip_store.dart';
import 'package:oshi_log/app/compositions/trips/domain/private_trip.dart';
import 'package:oshi_log/app/compositions/trips/presentation/private_trip_editor.dart';
import 'package:oshi_log/app/compositions/trips/presentation/private_trips_page.dart';
import 'package:oshi_log/app/compositions/trips/presentation/publish_selection_sheet.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import 'package:oshi_log/design_system/theme/gbt_theme.dart';
import 'package:oshi_log/features/community/reviews/domain/entities/travel_review_selection_seed.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';

const _place = PlaceSummary(
  id: 'place',
  name: 'Selected place',
  address: 'Tokyo',
  latitude: 35,
  longitude: 139,
);
const _entry = PrivateTripEntry(
  id: 'visit:place',
  resourceId: 'place',
  title: 'Selected place',
  kind: TripEntryKind.place,
  projectKey: 'project',
  place: _place,
  verified: true,
);
final _trip = PrivateTrip(
  id: 'trip',
  projectKey: 'project',
  title: 'Private title',
  memo: 'Private lodging details',
  entries: [_entry],
  startedOn: DateTime(2026, 10, 1),
  endedOn: DateTime(2026, 10, 2),
  datesConfirmed: true,
);

void main() {
  late Directory directory;
  late _RecordingStore store;
  late PrivateTripsController controller;
  String? currentUser;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('private-trip-pages-');
    store = _RecordingStore(
      storage: await LocalStorage.create(),
      directory: directory,
    );
    currentUser = 'user';
    controller = PrivateTripsController(
      store: Future.value(store),
      currentUserId: () async => currentUser,
    );
    await controller.ready;
    await controller.upsert(_trip);
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    Locale locale = const Locale('en'),
    double scale = 1,
    bool dark = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          privateTripsControllerProvider.overrideWith((ref) => controller),
          selectedProjectKeyProvider.overrideWith((ref) => 'project'),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            ref.watch(privateTripsControllerProvider);
            return MaterialApp(
              theme: GBTTheme.light,
              darkTheme: GBTTheme.dark,
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              locale: locale,
              supportedLocales: const [
                Locale('en'),
                Locale('ko'),
                Locale('ja'),
              ],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: page,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'declining publication leaves album private and performs no exports',
    (tester) async {
      TravelReviewSelectionSeed? returned;
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                returned = await Navigator.of(context)
                    .push<TravelReviewSelectionSeed>(
                      MaterialPageRoute(
                        builder: (_) => PublishSelectionSheet(trip: _trip),
                      ),
                    );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Private title'), findsNothing);
      expect(find.text('Private lodging details'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('publish-continue')),
            )
            .onPressed,
        isNull,
      );
      for (final tile in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        expect(tile.value, isFalse);
      }
      await tester.ensureVisible(find.byKey(const ValueKey('publish-decline')));
      await tester.tap(find.byKey(const ValueKey('publish-decline')));
      await tester.pumpAndSettle();
      expect(returned, isNull);
      expect(store.exports, 0);
      expect((await store.load('user')).single.memo, 'Private lodging details');
    },
  );

  testWidgets(
    'selection forwards only checked place and separately checked dates',
    (tester) async {
      TravelReviewSelectionSeed? returned;
      await pump(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                returned = await Navigator.of(context)
                    .push<TravelReviewSelectionSeed>(
                      MaterialPageRoute(
                        builder: (_) => PublishSelectionSheet(trip: _trip),
                      ),
                    );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('publish-entry-visit:place')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('publish-continue')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('publish-continue')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('publish-continue')));
      });
      await tester.pumpAndSettle();
      expect(returned, isNotNull);
      expect(returned!.places.map((p) => p.id), ['place']);
      expect(returned!.tripStartedOn, isNull);
      expect(returned!.photoPaths, isEmpty);
      expect(store.exports, 0);
    },
  );

  testWidgets(
    'editor saves memo and manual date changes survive store recreation',
    (tester) async {
      await pump(tester, PrivateTripEditor(trip: _trip));
      await tester.enterText(
        find.byKey(const ValueKey('private-trip-memo')),
        'Updated private memo',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('private-trip-dates')),
      );
      await tester.tap(find.byKey(const ValueKey('private-trip-dates')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      final dateFields = find.descendant(
        of: find.byType(DateRangePickerDialog),
        matching: find.byType(TextField),
      );
      expect(dateFields, findsNWidgets(2));
      await tester.enterText(dateFields.at(0), '10/03/2026');
      await tester.enterText(dateFields.at(1), '10/05/2026');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(DateRangePickerDialog), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('private-trip-memo')))
            .controller!
            .text,
        'Updated private memo',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('private-trip-save')),
      );
      await tester.pumpAndSettle();
      final save = tester
          .widget<FilledButton>(find.byKey(const ValueKey('private-trip-save')))
          .onPressed!;
      await tester.runAsync(() async {
        await Function.apply(save, []);
      });
      await tester.pumpAndSettle();
      final reopened = PrivateTripStore(
        storage: store.storage,
        directory: directory,
      );
      final restored = (await reopened.load('user')).single;
      expect(restored.memo, 'Updated private memo');
      expect(restored.datesConfirmed, isTrue);
      expect(restored.startedOn, DateTime(2026, 10, 3));
      expect(restored.endedOn, DateTime(2026, 10, 5));
    },
  );

  testWidgets(
    'logout during selection hides private content and blocks handoff',
    (tester) async {
      await pump(tester, PublishSelectionSheet(trip: _trip));
      currentUser = null;
      await expectLater(controller.assertSession(), throwsStateError);
      await tester.pumpAndSettle();
      expect(find.text('Selected place'), findsNothing);
      expect(find.byKey(const ValueKey('publish-continue')), findsNothing);
      expect(store.exports, 0);
    },
  );

  for (final locale in ['ko', 'ja']) {
    for (final dark in [false, true]) {
      for (final page in ['list', 'editor', 'selection']) {
        testWidgets('$locale $page fits 320dp 200 percent dark=$dark', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(const Size(320, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await pump(
            tester,
            switch (page) {
              'list' => const PrivateTripsPage(),
              'editor' => PrivateTripEditor(trip: _trip),
              _ => PublishSelectionSheet(trip: _trip),
            },
            locale: Locale(locale),
            scale: 2,
            dark: dark,
          );
          expect(tester.takeException(), isNull);
          for (var i = 0; i < 8; i++) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -400),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  }
}

class _RecordingStore extends PrivateTripStore {
  _RecordingStore({required super.storage, required super.directory});
  int exports = 0;
  @override
  Future<String> exportPhoto(String userId, PrivateTripPhoto photo) {
    exports++;
    return super.exportPhoto(userId, photo);
  }
}
