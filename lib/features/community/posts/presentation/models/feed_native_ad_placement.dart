/// EN: Helpers for deterministic native-ad insertion into post lists.
/// KO: 게시글 리스트에 네이티브 광고를 안정적으로 삽입하기 위한 헬퍼입니다.
library;

/// EN: Deterministic layout calculator for inline sponsored slots.
/// KO: 인라인 스폰서 슬롯의 배치 인덱스를 계산하는 레이아웃 계산기입니다.
class FeedNativeAdPlacement {
  FeedNativeAdPlacement._();

  /// EN: Number of top posts shown before first sponsored slot.
  /// KO: 첫 스폰서 슬롯 전까지 먼저 노출하는 게시글 수입니다.
  static const int leadingPostCount = 10;

  /// EN: Number of posts shown between sponsored slots.
  /// KO: 스폰서 슬롯 사이에 노출하는 게시글 수입니다.
  static const int postsPerSegment = 18;

  /// EN: Hard cap to keep ad exposure psychologically light.
  /// KO: 심리적 거부감을 줄이기 위한 광고 노출 상한입니다.
  static const int maxSponsoredSlots = 1;

  static int get _segmentSpan => postsPerSegment + 1;

  static int _adListIndexForOrdinal(int ordinal) {
    return leadingPostCount + (ordinal * _segmentSpan);
  }

  /// EN: Returns number of sponsored slots for a given post count.
  /// KO: 게시글 수에 따른 스폰서 슬롯 개수를 반환합니다.
  static int adCountForPostCount(int postCount) {
    if (postCount <= leadingPostCount) {
      return 0;
    }
    final remaining = postCount - leadingPostCount;
    final computed = (remaining + postsPerSegment - 1) ~/ postsPerSegment;
    if (computed > maxSponsoredSlots) {
      return maxSponsoredSlots;
    }
    return computed;
  }

  /// EN: Returns total list item count (posts + sponsored slots).
  /// KO: 전체 리스트 아이템 수(게시글 + 스폰서 슬롯)를 반환합니다.
  static int totalItemCount(int postCount) {
    return postCount + adCountForPostCount(postCount);
  }

  /// EN: Returns true when the given list index should render a sponsored slot.
  /// KO: 주어진 리스트 인덱스가 스폰서 슬롯인지 여부를 반환합니다.
  static bool isAdIndex({required int listIndex, required int postCount}) {
    if (listIndex < leadingPostCount) {
      return false;
    }
    final adCount = adCountForPostCount(postCount);
    for (var ordinal = 0; ordinal < adCount; ordinal++) {
      if (listIndex == _adListIndexForOrdinal(ordinal)) {
        return true;
      }
    }
    return false;
  }

  /// EN: Converts a mixed-list index to its original post index.
  /// KO: 혼합 리스트 인덱스를 원본 게시글 인덱스로 변환합니다.
  static int postIndexForListIndex({
    required int listIndex,
    required int postCount,
  }) {
    if (isAdIndex(listIndex: listIndex, postCount: postCount)) {
      throw ArgumentError.value(
        listIndex,
        'listIndex',
        'Sponsored slot index cannot be mapped to a post index.',
      );
    }
    var adsBefore = 0;
    final adCount = adCountForPostCount(postCount);
    for (var ordinal = 0; ordinal < adCount; ordinal++) {
      if (_adListIndexForOrdinal(ordinal) < listIndex) {
        adsBefore++;
      }
    }
    return listIndex - adsBefore;
  }

  /// EN: Zero-based ordinal of sponsored slots for campaign rotation.
  /// KO: 캠페인 순환에 사용하는 스폰서 슬롯의 0기반 순번입니다.
  static int adOrdinalForIndex({
    required int listIndex,
    required int postCount,
  }) {
    if (!isAdIndex(listIndex: listIndex, postCount: postCount)) {
      throw ArgumentError.value(
        listIndex,
        'listIndex',
        'Only sponsored slot indices have ad ordinals.',
      );
    }
    final adCount = adCountForPostCount(postCount);
    for (var ordinal = 0; ordinal < adCount; ordinal++) {
      if (listIndex == _adListIndexForOrdinal(ordinal)) {
        return ordinal;
      }
    }
    throw ArgumentError.value(
      listIndex,
      'listIndex',
      'Ad ordinal could not be resolved for this index.',
    );
  }
}
