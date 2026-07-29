import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/features/ads/data/dto/ad_slot_decision_dto.dart';
import 'package:oshi_log/features/ads/domain/entities/ad_slot_entities.dart';

void main() {
  group('AdSlotDecisionDto', () {
    test('maps house payload to domain decision', () {
      final dto = AdSlotDecisionDto.fromJson({
        'deliveryType': 'house',
        'decisionId': 'dec_1',
        'campaignId': 'cmp_1',
        'title': 'Title',
        'description': 'Desc',
        'ctaLabel': 'CTA',
      });

      final decision = dto.toDomain(AdSlotPlacement.homePrimary);

      expect(decision.deliveryType, AdDeliveryType.house);
      expect(decision.decisionId, 'dec_1');
      expect(decision.campaignId, 'cmp_1');
      expect(decision.house?.title, 'Title');
      expect(decision.house?.description, 'Desc');
      expect(decision.house?.ctaLabel, 'CTA');
    });

    test('maps network payload to admob decision', () {
      final dto = AdSlotDecisionDto.fromJson({
        'type': 'network',
        'network': 'admob',
        'adUnitId': 'ca-app-pub-xxx/yyy',
      });

      final decision = dto.toDomain(AdSlotPlacement.boardFeed);

      expect(decision.deliveryType, AdDeliveryType.network);
      expect(decision.network?.networkType, AdNetworkType.admob);
      expect(decision.network?.adUnitId, 'ca-app-pub-xxx/yyy');
    });
  });
}
