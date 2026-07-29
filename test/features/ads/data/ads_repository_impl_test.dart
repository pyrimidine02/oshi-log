import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/core/config/app_config.dart';
import 'package:oshi_log/core/constants/api_constants.dart';
import 'package:oshi_log/core/network/api_client.dart';
import 'package:oshi_log/core/security/secure_storage.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/ads/data/datasources/ads_remote_data_source.dart';
import 'package:oshi_log/features/ads/data/repositories/ads_repository_impl.dart';
import 'package:oshi_log/features/ads/domain/entities/ad_slot_entities.dart';

void main() {
  setUpAll(() {
    AppConfig.instance.init(
      environment: Environment.development,
      baseUrl: 'http://localhost:8080',
    );
  });

  group('AdsRepositoryImpl.trackEvent', () {
    test('skips remote call when decisionId is missing', () async {
      final fakeApiClient = _FakeApiClient();
      final repository = AdsRepositoryImpl(
        remoteDataSource: AdsRemoteDataSource(fakeApiClient),
      );
      const request = AdSlotRequest(placement: AdSlotPlacement.homePrimary);

      final result = await repository.trackEvent(
        eventType: AdEventType.impression,
        request: request,
        decisionId: null,
      );

      expect(result, isA<Success<void>>());
      expect(fakeApiClient.postCalls, 0);
    });

    test('sends decisionId in payload when present', () async {
      final fakeApiClient = _FakeApiClient();
      final repository = AdsRepositoryImpl(
        remoteDataSource: AdsRemoteDataSource(fakeApiClient),
      );
      const request = AdSlotRequest(
        placement: AdSlotPlacement.boardFeed,
        ordinal: 3,
        projectKey: 'bang-dream',
      );

      final result = await repository.trackEvent(
        eventType: AdEventType.click,
        request: request,
        decisionId: 'dec_123',
        campaignId: 'cmp_123',
      );

      expect(result, isA<Success<void>>());
      expect(fakeApiClient.postCalls, 1);
      expect(fakeApiClient.lastPostPath, ApiEndpoints.adsEvents);
      expect(fakeApiClient.lastPostBody?['eventType'], 'click');
      expect(fakeApiClient.lastPostBody?['slot'], 'board_feed');
      expect(fakeApiClient.lastPostBody?['ordinal'], 3);
      expect(fakeApiClient.lastPostBody?['projectKey'], 'bang-dream');
      expect(fakeApiClient.lastPostBody?['projectCode'], 'bang-dream');
      expect(fakeApiClient.lastPostBody?['decisionId'], 'dec_123');
      expect(fakeApiClient.lastPostBody?['campaignId'], 'cmp_123');
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(secureStorage: SecureStorage());

  int postCalls = 0;
  String? lastPostPath;
  Map<String, dynamic>? lastPostBody;

  @override
  Future<Result<T>> post<T>(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
    options,
  }) async {
    postCalls += 1;
    lastPostPath = path;
    if (data is Map<String, dynamic>) {
      lastPostBody = Map<String, dynamic>.from(data);
    } else {
      lastPostBody = null;
    }
    return Result.success(null as T);
  }
}
