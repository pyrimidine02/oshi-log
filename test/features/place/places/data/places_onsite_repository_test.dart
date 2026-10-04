import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oshi_log/platform/cache/cache_manager.dart';
import 'package:oshi_log/platform/error/failure.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/place/places/data/datasources/places_remote_data_source.dart';
import 'package:oshi_log/features/place/places/data/dto/place_dto.dart';
import 'package:oshi_log/features/place/places/data/dto/place_guide_dto.dart';
import 'package:oshi_log/features/place/places/data/repositories/places_repository_impl.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Remote remote;
  late DateTime now;
  late bool online;
  late CacheManager cache;
  late PlacesRepositoryImpl repository;
  final saved = DateTime.utc(2026, 10, 3, 18, 30);
  final cachedDto = PlaceDetailDto.fromJson({
    'id': 'p',
    'name': '保存済みの会場',
    'address': '東京都世田谷区北沢',
    'latitude': 35.6,
    'longitude': 139.6,
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = saved;
    online = true;
    remote = _Remote();
    cache = CacheManager(
      LocalStorage(await SharedPreferences.getInstance()),
      now: () => now,
      isOnline: () async => online,
    );
    repository = PlacesRepositoryImpl(
      remoteDataSource: remote,
      cacheManager: cache,
    );
    when(
      () => remote.fetchPlaceStats(projectId: 'project', placeId: 'p'),
    ).thenAnswer((_) async => const Result.failure(NetworkFailure('offline')));
  });

  test(
    'expired offline snapshot retains the original persisted time and complete address',
    () async {
      await cache.setJson(
        'place_detail:v2:project:p',
        cachedDto.toJson(),
        ttl: const Duration(minutes: 15),
      );
      now = saved.add(const Duration(days: 2));
      online = false;
      final result = await repository.getPlaceDetail(
        projectId: 'project',
        placeId: 'p',
      );
      final place = (result as Success<PlaceDetail>).data;
      expect(place.savedAt, saved);
      expect(place.address, '東京都世田谷区北沢');
      expect(place.isFromCache, isTrue);
      expect(place.isCacheStale, isTrue);
      verifyNever(
        () => remote.fetchPlaceStats(projectId: 'project', placeId: 'p'),
      );
      verifyNever(
        () => remote.fetchPlaceDetail(projectId: 'project', placeId: 'p'),
      );
    },
  );

  test(
    'background refresh must not replace the timestamp of the displayed snapshot',
    () async {
      await cache.setJson('place_detail:v2:project:p', cachedDto.toJson());
      now = saved.add(const Duration(hours: 1));
      when(
        () => remote.fetchPlaceDetail(projectId: 'project', placeId: 'p'),
      ).thenAnswer(
        (_) async => Result.success(
          PlaceDetailDto.fromJson({
            'id': 'p',
            'name': 'newer name',
            'latitude': 35.6,
            'longitude': 139.6,
          }),
        ),
      );
      final result = await repository.getPlaceDetail(
        projectId: 'project',
        placeId: 'p',
      );
      final place = (result as Success<PlaceDetail>).data;
      expect(place.name, cachedDto.name);
      expect(place.savedAt, saved);
      expect(place.isFromCache, isTrue);
    },
  );

  test(
    'fresh network response uses persisted clock, never server editorial date',
    () async {
      when(
        () => remote.fetchPlaceDetail(projectId: 'project', placeId: 'p'),
      ).thenAnswer((_) async => Result.success(cachedDto));
      final result = await repository.getPlaceDetail(
        projectId: 'project',
        placeId: 'p',
      );
      final place = (result as Success<PlaceDetail>).data;
      expect(place.savedAt, saved);
      expect(place.isFromCache, isFalse);
      expect(place.isCacheStale, isFalse);
    },
  );

  test(
    'guide reader stores full Markdown for subsequent offline reads',
    () async {
      when(
        () => remote.fetchPlaceGuide(placeId: 'p', guideId: 'guide'),
      ).thenAnswer(
        (_) async => Result.success(
          PlaceGuideDetailDto(
            id: 'guide',
            title: '入口案内',
            contentMarkdown: '## 入り口\n南口から地下へ。',
            updatedAt: DateTime.utc(2026, 9, 1),
          ),
        ),
      );
      final first = await repository.getPlaceGuide(
        placeId: 'p',
        guideId: 'guide',
      );
      online = false;
      now = saved.add(const Duration(days: 10));
      final second = await repository.getPlaceGuide(
        placeId: 'p',
        guideId: 'guide',
      );
      expect(
        first.dataOrNull?.contentMarkdown,
        second.dataOrNull?.contentMarkdown,
      );
      expect(second.dataOrNull?.contentMarkdown, contains('南口'));
      expect(second.dataOrNull?.updatedAt, DateTime.utc(2026, 9, 1));
      verify(
        () => remote.fetchPlaceGuide(placeId: 'p', guideId: 'guide'),
      ).called(1);
    },
  );
}

class _Remote extends Mock implements PlacesRemoteDataSource {}
