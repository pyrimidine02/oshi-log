import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// EN: Replace the installed map plugin at its test boundary.
// KO: 설치된 지도 플러그인의 테스트 경계를 대체합니다.
// ignore: depend_on_referenced_packages
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/providers/core_providers.dart';
import 'package:oshi_log/platform/security/secure_storage.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/community/reviews/application/travel_reviews_controller.dart';
import 'package:oshi_log/features/community/reviews/domain/entities/travel_review.dart';
import 'package:oshi_log/features/community/reviews/domain/entities/travel_review_selection_seed.dart';
import 'package:oshi_log/features/community/reviews/domain/repositories/travel_reviews_repository.dart';
import 'package:oshi_log/features/community/reviews/presentation/pages/travel_review_create_page.dart';
import 'package:oshi_log/features/identity/auth/application/session_state.dart';
import 'package:oshi_log/features/oshikatsu/catalog/application/project_context.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/place/visits/application/visits_controller.dart';
import 'package:oshi_log/features/shared/uploads/application/uploads_controller.dart';
import 'package:oshi_log/features/shared/uploads/domain/entities/upload_entity.dart';

const _place = PlaceSummary(
  id: 'place-1',
  name: 'Selected place',
  address: 'Tokyo',
  latitude: 35,
  longitude: 139,
);

final _testAuthenticatedProvider = StateProvider<bool>((ref) => true);

void main() {
  test('seed snapshots only the selected collections', () {
    final places = [_place];
    final photos = ['selected.png'];
    final seed = TravelReviewSelectionSeed(
      ownerUserId: 'owner',
      projectCode: 'project',
      places: places,
      photoPaths: photos,
    );
    places.clear();
    photos.clear();
    expect(seed.places, [_place]);
    expect(seed.photoPaths, ['selected.png']);
    expect(() => seed.photoPaths.clear(), throwsUnsupportedError);
  });

  testWidgets('opening selection never uploads or publishes at 320dp 200%', (
    tester,
  ) async {
    final harness = await _open(tester, largeText: true);
    expect(harness.uploadCalls, 0);
    expect(harness.repository.drafts, isEmpty);
    expect(find.textContaining('선택한 사진 1장'), findsOneWidget);
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.every((field) => field.controller!.text.isEmpty), isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final mismatch in ['owner', 'project', 'guest']) {
    testWidgets('rejects $mismatch mismatch before applying selection', (
      tester,
    ) async {
      final harness = await _open(tester, mismatch: mismatch);
      expect(find.textContaining('계정과 프로젝트'), findsOneWidget);
      expect(find.textContaining('선택한 사진 1장'), findsNothing);
      expect(harness.uploadCalls, 0);
      expect(harness.repository.drafts, isEmpty);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('travel-review-submit')),
            )
            .onPressed,
        isNull,
      );
    });
  }

  testWidgets(
    'failed publish preserves text and reuses uploaded photo on retry',
    (tester) async {
      final harness = await _open(tester);
      await _fillAndSubmit(tester);
      expect(harness.uploadCalls, 1);
      expect(harness.repository.drafts.single.imageUploadIds, ['uploaded-1']);
      expect(harness.repository.drafts.single.stops.single.placeId, 'place-1');
      expect(
        harness.repository.drafts.single.tripStartedOn,
        DateTime(2026, 10, 1),
      );
      expect(
        harness.repository.drafts.single.tripEndedOn,
        DateTime(2026, 10, 2),
      );
      expect(find.text('Public title'), findsOneWidget);
      await _submit(tester);
      expect(harness.uploadCalls, 1);
      expect(harness.repository.drafts, hasLength(2));
    },
  );

  for (final change in ['owner', 'project', 'session', 'logout']) {
    testWidgets('rejects $change change before upload and publish', (
      tester,
    ) async {
      final harness = await _open(tester);
      if (change == 'owner') harness.storage.userId = 'other';
      if (change == 'project') {
        harness.container.read(selectedProjectKeyProvider.notifier).state =
            'other';
      }
      if (change == 'session') harness.generation++;
      if (change == 'logout') {
        harness.container.read(_testAuthenticatedProvider.notifier).state =
            false;
      }
      if (change == 'project' || change == 'logout') {
        await tester.pump();
        expect(find.textContaining('선택한 사진'), findsNothing);
      } else {
        await _fillAndSubmit(tester);
      }
      expect(harness.uploadCalls, 0);
      expect(harness.repository.drafts, isEmpty);
      expect(find.textContaining('계정과 프로젝트'), findsOneWidget);
    });
  }

  testWidgets('account change during upload prevents public POST', (
    tester,
  ) async {
    final harness = await _open(tester);
    harness.onUpload = () => harness.storage.userId = 'other';
    await _fillAndSubmit(tester);
    expect(harness.uploadCalls, 1);
    expect(harness.repository.drafts, isEmpty);
  });

  testWidgets(
    'switching away and back during upload still cancels publishing',
    (tester) async {
      final harness = await _open(tester);
      harness.onUpload = () {
        final project = harness.container.read(
          selectedProjectKeyProvider.notifier,
        );
        project.state = 'other';
        project.state = 'project';
      };
      await _fillAndSubmit(tester);
      expect(harness.uploadCalls, 1);
      expect(harness.repository.drafts, isEmpty);
      expect(find.textContaining('계정과 프로젝트'), findsOneWidget);
    },
  );

  testWidgets('upload failure retains selections and never posts', (
    tester,
  ) async {
    final harness = await _open(tester);
    harness.failUpload = true;
    await _fillAndSubmit(tester);
    expect(harness.repository.drafts, isEmpty);
    expect(find.text('Public title'), findsOneWidget);
    harness.failUpload = false;
    await _submit(tester);
    expect(harness.uploadCalls, 2);
    expect(harness.repository.drafts, hasLength(1));
  });

  testWidgets('removing a selected photo keeps it out of the public draft', (
    tester,
  ) async {
    final harness = await _open(tester);
    await tester.tap(
      find.byKey(const ValueKey('travel-review-remove-photo-0')),
    );
    await tester.pumpAndSettle();
    await _fillAndSubmit(tester);
    expect(harness.uploadCalls, 0);
    expect(harness.repository.drafts.single.imageUploadIds, isEmpty);
  });

  testWidgets('leaving during upload never publishes the review', (
    tester,
  ) async {
    final harness = await _open(tester);
    await tester.runAsync(() async {
      harness.pendingUpload = Completer<Result<UploadInfo>>();
      harness.uploadStarted = Completer<void>();
    });
    await tester.enterText(find.byType(TextField).at(0), 'Public title');
    await tester.enterText(find.byType(TextField).at(1), 'Public content');
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('travel-review-submit')),
    );
    late Future<void> submission;
    await tester.runAsync(() async {
      submission = (button.onPressed! as Future<void> Function())();
      await harness.uploadStarted.future;
    });
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      harness.pendingUpload!.complete(
        const Result.success(
          UploadInfo(
            uploadId: 'cancelled-upload',
            url: '',
            filename: '',
            isApproved: true,
          ),
        ),
      );
      await submission;
    });
    expect(harness.repository.drafts, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Public title');
  await tester.enterText(fields.at(1), 'Only my public review.');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await _submit(tester);
}

Future<void> _submit(WidgetTester tester) async {
  final button = tester.widget<FilledButton>(
    find.byKey(const ValueKey('travel-review-submit')),
  );
  await tester.runAsync(button.onPressed! as Future<void> Function());
  await tester.pumpAndSettle();
}

Future<_Harness> _open(
  WidgetTester tester, {
  bool largeText = false,
  String? mismatch,
}) async {
  final harness = _Harness();
  final directory = Directory.systemTemp.createTempSync('review-seed-test-');
  addTearDown(() => directory.deleteSync(recursive: true));
  final file = File('${directory.path}/selected.png');
  file.writeAsBytesSync(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
    ),
  );
  final originalMaps = GoogleMapsFlutterPlatform.instance;
  GoogleMapsFlutterPlatform.instance = _FakeMaps();
  addTearDown(() => GoogleMapsFlutterPlatform.instance = originalMaps);
  await tester.binding.setSurfaceSize(Size(largeText ? 320 : 800, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  if (mismatch == 'owner') harness.storage.userId = 'other';
  harness.overrides = [
    secureStorageProvider.overrideWithValue(harness.storage),
    isAuthenticatedProvider.overrideWith(
      (ref) => mismatch != 'guest' && ref.watch(_testAuthenticatedProvider),
    ),
    apiSessionGenerationProvider.overrideWithValue(() => harness.generation),
    userVisitsControllerProvider.overrideWith(_FakeVisits.new),
    travelReviewsRepositoryProvider.overrideWithValue(harness.repository),
    uploadsControllerProvider.overrideWith((ref) => _FakeUploads(ref, harness)),
  ];
  harness.container = ProviderContainer(
    overrides: [
      ...harness.overrides,
      selectedProjectKeyProvider.overrideWith(
        (ref) => mismatch == 'project' ? 'other' : 'project',
      ),
    ],
  );
  addTearDown(harness.container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: harness.container,
      child: MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(largeText ? 2 : 1),
          ),
          child: TravelReviewCreatePage(
            selectionSeed: TravelReviewSelectionSeed(
              ownerUserId: 'owner',
              projectCode: 'project',
              places: [_place],
              tripStartedOn: DateTime(2026, 10, 1),
              tripEndedOn: DateTime(2026, 10, 2),
              photoPaths: [file.path],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

class _Harness {
  final storage = _FakeStorage();
  final repository = _FakeReviews();
  late ProviderContainer container;
  late List<Override> overrides;
  int generation = 1;
  int uploadCalls = 0;
  bool failUpload = false;
  void Function()? onUpload;
  var uploadStarted = Completer<void>();
  Completer<Result<UploadInfo>>? pendingUpload;
}

class _FakeStorage extends SecureStorage {
  String userId = 'owner';
  @override
  Future<String?> getUserId() async => userId;
}

class _FakeVisits extends UserVisitsController {
  _FakeVisits(super.ref) {
    state = const AsyncData([]);
  }
}

class _FakeUploads extends UploadsController {
  _FakeUploads(super.ref, this.harness);
  final _Harness harness;
  @override
  Future<Result<UploadInfo>> uploadImageBytes({
    required Uint8List bytes,
    required String filename,
    required String contentType,
    bool Function()? isCurrentOperation,
  }) async {
    harness.uploadCalls++;
    expect(contentType, 'image/png');
    expect(filename, isNot(contains('selected')));
    harness.onUpload?.call();
    if (!harness.uploadStarted.isCompleted) harness.uploadStarted.complete();
    if (harness.pendingUpload != null) return harness.pendingUpload!.future;
    return harness.failUpload
        ? const Result.failure(NetworkFailure('offline'))
        : const Result.success(
            UploadInfo(
              uploadId: 'uploaded-1',
              url: 'https://example.invalid/photo.png',
              filename: 'photo.png',
              isApproved: true,
            ),
          );
  }
}

class _FakeReviews implements TravelReviewsRepository {
  final drafts = <TravelReviewDraft>[];
  @override
  Future<Result<TravelReviewDetail>> create({
    required String projectCode,
    required TravelReviewDraft draft,
  }) async {
    drafts.add(draft);
    return const Result.failure(NetworkFailure('offline'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMaps extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapConfiguration mapConfiguration = const MapConfiguration(),
    MapObjects mapObjects = const MapObjects(),
  }) => const SizedBox();
}
