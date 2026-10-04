import 'package:oshi_log/features/place/places/domain/entities/place_entities.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/entities/live_event_entities.dart';

enum TripEntryKind { place, live }

/// EN: A local source reference; a verification timestamp is never a trip date.
/// KO: 로컬 원본 참조이며 인증 시각은 여행 날짜로 사용하지 않습니다.
class PrivateTripEntry {
  const PrivateTripEntry({
    required this.id,
    required this.resourceId,
    required this.title,
    required this.kind,
    required this.projectKey,
    this.verified = false,
    this.place,
    this.eventStart,
  });

  final String id;
  final String resourceId;
  final String title;
  final TripEntryKind kind;
  final String projectKey;
  final bool verified;
  final PlaceSummary? place;
  final DateTime? eventStart;

  LiveEventSummary? get event =>
      kind == TripEntryKind.live && eventStart != null
      ? LiveEventSummary(
          id: resourceId,
          title: title,
          showStartTime: eventStart!,
          status: '',
          projectIds: [projectKey],
          unitIds: const [],
        )
      : null;

  PrivateTripEntry copyWith({String? id}) => PrivateTripEntry(
    id: id ?? this.id,
    resourceId: resourceId,
    title: title,
    kind: kind,
    projectKey: projectKey,
    verified: verified,
    place: place,
    eventStart: eventStart,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'resourceId': resourceId,
    'title': title,
    'kind': kind.name,
    'projectKey': projectKey,
    'verified': verified,
    'eventStart': eventStart?.toIso8601String(),
    if (place case final p?)
      'place': {
        'id': p.id,
        'name': p.name,
        'address': p.address,
        'latitude': p.latitude,
        'longitude': p.longitude,
      },
  };

  factory PrivateTripEntry.fromJson(Map<String, dynamic> json) {
    final p = json['place'] as Map<String, dynamic>?;
    return PrivateTripEntry(
      id: json['id'] as String,
      resourceId: json['resourceId'] as String,
      title: json['title'] as String,
      kind: TripEntryKind.values.byName(json['kind'] as String),
      projectKey: json['projectKey'] as String,
      verified: json['verified'] == true,
      eventStart: DateTime.tryParse(json['eventStart'] as String? ?? ''),
      place: p == null
          ? null
          : PlaceSummary(
              id: p['id'] as String,
              name: p['name'] as String,
              address: p['address'] as String,
              latitude: (p['latitude'] as num).toDouble(),
              longitude: (p['longitude'] as num).toDouble(),
            ),
    );
  }
}

class PrivateTripPhoto {
  const PrivateTripPhoto({required this.id, required this.path});
  final String id;
  final String path;
  Map<String, dynamic> toJson() => {'id': id, 'path': path};
  factory PrivateTripPhoto.fromJson(Map<String, dynamic> json) =>
      PrivateTripPhoto(id: json['id'] as String, path: json['path'] as String);
}

class PrivateTrip {
  const PrivateTrip({
    required this.id,
    required this.projectKey,
    required this.title,
    this.memo = '',
    this.entries = const [],
    this.photos = const [],
    this.startedOn,
    this.endedOn,
    this.datesConfirmed = false,
  });
  final String id;
  final String projectKey;
  final String title;
  final String memo;
  final List<PrivateTripEntry> entries;
  final List<PrivateTripPhoto> photos;
  final DateTime? startedOn;
  final DateTime? endedOn;
  final bool datesConfirmed;

  PrivateTrip copyWith({
    String? title,
    String? memo,
    List<PrivateTripEntry>? entries,
    List<PrivateTripPhoto>? photos,
    DateTime? startedOn,
    DateTime? endedOn,
    bool? datesConfirmed,
  }) => PrivateTrip(
    id: id,
    projectKey: projectKey,
    title: title ?? this.title,
    memo: memo ?? this.memo,
    entries: entries ?? this.entries,
    photos: photos ?? this.photos,
    startedOn: startedOn ?? this.startedOn,
    endedOn: endedOn ?? this.endedOn,
    datesConfirmed: datesConfirmed ?? this.datesConfirmed,
  );

  PrivateTrip merge(PrivateTrip other) {
    if (projectKey != other.projectKey) throw ArgumentError('Project mismatch');
    return PrivateTrip(
      id: id,
      projectKey: projectKey,
      title: title,
      memo: [memo, other.memo].where((m) => m.isNotEmpty).join('\n\n'),
      entries: {
        for (final e in [...entries, ...other.entries]) e.id: e,
      }.values.toList(),
      photos: {
        for (final p in [...photos, ...other.photos]) p.id: p,
      }.values.toList(),
    );
  }

  (PrivateTrip, PrivateTrip) split(
    Set<String> entryIds, {
    required String newId,
  }) {
    final moved = entries.where((e) => entryIds.contains(e.id)).toList();
    final kept = entries.where((e) => !entryIds.contains(e.id)).toList();
    if (moved.isEmpty || kept.isEmpty) throw ArgumentError('Select a subset');
    return (
      copyWith(entries: kept),
      PrivateTrip(
        id: newId,
        projectKey: projectKey,
        title: title,
        entries: moved,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectKey': projectKey,
    'title': title,
    'memo': memo,
    'entries': entries.map((e) => e.toJson()).toList(),
    'photos': photos.map((p) => p.toJson()).toList(),
    'startedOn': startedOn?.toIso8601String(),
    'endedOn': endedOn?.toIso8601String(),
    'datesConfirmed': datesConfirmed,
  };
  factory PrivateTrip.fromJson(Map<String, dynamic> json) => PrivateTrip(
    id: json['id'] as String,
    projectKey: json['projectKey'] as String,
    title: json['title'] as String,
    memo: json['memo'] as String? ?? '',
    entries: (json['entries'] as List)
        .map((e) => PrivateTripEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    photos: (json['photos'] as List)
        .map((e) => PrivateTripPhoto.fromJson(e as Map<String, dynamic>))
        .toList(),
    startedOn: DateTime.tryParse(json['startedOn'] as String? ?? ''),
    endedOn: DateTime.tryParse(json['endedOn'] as String? ?? ''),
    datesConfirmed: json['datesConfirmed'] == true,
  );
}
