/// EN: DTOs for slot decision and event payload.
/// KO: 슬롯 결정 및 이벤트 페이로드 DTO입니다.
library;

import 'package:oshi_log/features/shared/ads/domain/entities/ad_slot_entities.dart';

class AdSlotDecisionDto {
  const AdSlotDecisionDto({
    required this.deliveryType,
    this.slot,
    this.decisionId,
    this.campaignId,
    this.network,
    this.adUnitId,
    this.badgeLabel,
    this.sponsorLabel,
    this.title,
    this.description,
    this.ctaLabel,
    this.targetPath,
    this.targetUrl,
  });

  final String deliveryType;
  final String? slot;
  final String? decisionId;
  final String? campaignId;
  final String? network;
  final String? adUnitId;
  final String? badgeLabel;
  final String? sponsorLabel;
  final String? title;
  final String? description;
  final String? ctaLabel;
  final String? targetPath;
  final String? targetUrl;

  factory AdSlotDecisionDto.fromJson(Map<String, dynamic> json) {
    return AdSlotDecisionDto(
      deliveryType:
          _string(json, ['deliveryType', 'type', 'delivery_type']) ?? 'house',
      slot: _string(json, ['slot', 'placement']),
      decisionId: _string(json, ['decisionId', 'decision_id']),
      campaignId: _string(json, ['campaignId', 'campaign_id']),
      network: _string(json, ['network']),
      adUnitId: _string(json, ['adUnitId', 'ad_unit_id', 'nativeAdUnitId']),
      badgeLabel: _string(json, ['badgeLabel', 'badge_label']),
      sponsorLabel: _string(json, ['sponsorLabel', 'sponsor_label']),
      title: _string(json, ['title']),
      description: _string(json, ['description', 'body']),
      ctaLabel: _string(json, ['ctaLabel', 'cta_label', 'cta']),
      targetPath: _string(json, ['targetPath', 'target_path', 'targetRoute']),
      targetUrl: _string(json, ['targetUrl', 'target_url']),
    );
  }

  AdSlotDecision toDomain(AdSlotPlacement placement) {
    final delivery = switch (deliveryType.trim().toLowerCase()) {
      'house' => AdDeliveryType.house,
      'network' => AdDeliveryType.network,
      'none' => AdDeliveryType.none,
      _ => AdDeliveryType.house,
    };

    final networkType = switch (network?.trim().toLowerCase()) {
      'admob' => AdNetworkType.admob,
      null => AdNetworkType.unknown,
      _ => AdNetworkType.unknown,
    };

    return AdSlotDecision(
      placement: placement,
      deliveryType: delivery,
      decisionId: decisionId,
      campaignId: campaignId,
      house: HouseAdContent(
        badgeLabel: badgeLabel,
        sponsorLabel: sponsorLabel,
        title: title,
        description: description,
        ctaLabel: ctaLabel,
        targetPath: targetPath,
        targetUrl: targetUrl,
      ),
      network: NetworkAdContent(networkType: networkType, adUnitId: adUnitId),
    );
  }
}

class AdEventRequestDto {
  const AdEventRequestDto({
    required this.eventType,
    required this.slot,
    required this.ordinal,
    this.projectKey,
    this.decisionId,
    this.campaignId,
  });

  final String eventType;
  final String slot;
  final int ordinal;
  final String? projectKey;
  final String? decisionId;
  final String? campaignId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eventType': eventType,
      'slot': slot,
      'ordinal': ordinal,
      if (projectKey != null && projectKey!.isNotEmpty) ...{
        'projectKey': projectKey,
        // EN: Compatibility key for backends using projectCode naming.
        // KO: projectCode 명명을 사용하는 백엔드 호환 키입니다.
        'projectCode': projectKey,
      },
      if (decisionId != null && decisionId!.isNotEmpty)
        'decisionId': decisionId,
      if (campaignId != null && campaignId!.isNotEmpty)
        'campaignId': campaignId,
    };
  }
}

String? _string(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}
