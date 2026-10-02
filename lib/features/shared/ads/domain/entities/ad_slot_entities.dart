/// EN: Domain entities for hybrid sponsored slot decisions.
/// KO: 하이브리드 스폰서 슬롯 결정을 위한 도메인 엔티티입니다.
library;

/// EN: Supported in-app ad slot placements.
/// KO: 앱에서 지원하는 광고 슬롯 배치 위치입니다.
enum AdSlotPlacement { homePrimary, boardFeed }

extension AdSlotPlacementX on AdSlotPlacement {
  /// EN: API key representation for backend decision lookup.
  /// KO: 백엔드 결정 조회에 사용하는 API 키 표현입니다.
  String get apiKey {
    return switch (this) {
      AdSlotPlacement.homePrimary => 'home_primary',
      AdSlotPlacement.boardFeed => 'board_feed',
    };
  }
}

/// EN: Delivery type selected for the slot.
/// KO: 슬롯에 대해 선택된 전달 타입입니다.
enum AdDeliveryType { house, network, none }

/// EN: External ad network identifiers.
/// KO: 외부 광고 네트워크 식별자입니다.
enum AdNetworkType { admob, unknown }

/// EN: Event type to track ad analytics.
/// KO: 광고 분석 추적 이벤트 타입입니다.
enum AdEventType { impression, click }

extension AdEventTypeX on AdEventType {
  /// EN: API key representation for event payload.
  /// KO: 이벤트 페이로드에 사용하는 API 키 표현입니다.
  String get apiKey {
    return switch (this) {
      AdEventType.impression => 'impression',
      AdEventType.click => 'click',
    };
  }
}

/// EN: Slot request context.
/// KO: 슬롯 요청 컨텍스트입니다.
class AdSlotRequest {
  const AdSlotRequest({
    required this.placement,
    this.ordinal = 0,
    this.projectKey,
  });

  final AdSlotPlacement placement;
  final int ordinal;
  final String? projectKey;

  @override
  bool operator ==(Object other) {
    return other is AdSlotRequest &&
        other.placement == placement &&
        other.ordinal == ordinal &&
        other.projectKey == projectKey;
  }

  @override
  int get hashCode => Object.hash(placement, ordinal, projectKey);
}

/// EN: Optional house campaign content.
/// KO: 선택적 하우스 캠페인 콘텐츠입니다.
class HouseAdContent {
  const HouseAdContent({
    this.badgeLabel,
    this.sponsorLabel,
    this.title,
    this.description,
    this.ctaLabel,
    this.targetPath,
    this.targetUrl,
  });

  final String? badgeLabel;
  final String? sponsorLabel;
  final String? title;
  final String? description;
  final String? ctaLabel;
  final String? targetPath;
  final String? targetUrl;
}

/// EN: Optional external-network content.
/// KO: 선택적 외부 네트워크 콘텐츠입니다.
class NetworkAdContent {
  const NetworkAdContent({required this.networkType, this.adUnitId});

  final AdNetworkType networkType;
  final String? adUnitId;
}

/// EN: Backend decision for a slot.
/// KO: 슬롯에 대한 백엔드 결정입니다.
class AdSlotDecision {
  const AdSlotDecision({
    required this.placement,
    required this.deliveryType,
    this.decisionId,
    this.campaignId,
    this.house,
    this.network,
  });

  final AdSlotPlacement placement;
  final AdDeliveryType deliveryType;
  final String? decisionId;
  final String? campaignId;
  final HouseAdContent? house;
  final NetworkAdContent? network;
}
