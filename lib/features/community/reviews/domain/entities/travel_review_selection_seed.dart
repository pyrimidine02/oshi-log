import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';
import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';

/// EN: Explicit selections copied from a private trip into a public draft.
/// KO: 비공개 여행에서 공개 초안으로 명시적으로 선택한 항목만 복사합니다.
class TravelReviewSelectionSeed {
  TravelReviewSelectionSeed({
    required this.ownerUserId,
    required this.projectCode,
    required List<PlaceSummary> places,
    List<LiveEventSummary> events = const [],
    this.tripStartedOn,
    this.tripEndedOn,
    List<String> photoPaths = const [],
  }) : places = List.unmodifiable(places),
       events = List.unmodifiable(events),
       photoPaths = List.unmodifiable(photoPaths);

  final String ownerUserId;
  final String projectCode;
  final List<PlaceSummary> places;
  final List<LiveEventSummary> events;
  final DateTime? tripStartedOn;
  final DateTime? tripEndedOn;

  /// EN: User-selected local PNG exports with metadata removed before handoff.
  /// KO: 전달 전에 메타데이터를 제거한, 사용자가 선택한 로컬 PNG 경로입니다.
  final List<String> photoPaths;
}
