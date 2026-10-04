/// EN: Account-local daily ordering and explicitly downloaded text snapshots.
/// KO: 계정별 당일 순서와 명시적으로 내려받은 텍스트 스냅샷입니다.
library;

import 'package:flutter/foundation.dart';
import 'package:oshi_log/features/oshikatsu/live/domain/event_time_policy.dart';

String todayDateKey(DateTime now) =>
    EventTimePolicy.dateInJst(now).toIso8601String().substring(0, 10);

@immutable
class TodayPlan {
  TodayPlan({required this.date, List<TodayPlace> entries = const []})
    : entries = List.unmodifiable(entries);
  final String date;
  final List<TodayPlace> entries;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'date': date,
    'entries': entries.map((entry) => entry.toJson()).toList(),
  };

  factory TodayPlan.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 ||
        DateTime.tryParse(json['date'] as String? ?? '') == null) {
      throw const FormatException('Invalid today plan');
    }
    final entries = (json['entries'] as List).map(
      (item) => TodayPlace.fromJson(Map<String, dynamic>.from(item as Map)),
    );
    return TodayPlan(
      date: json['date'] as String,
      entries: {for (final entry in entries) entry.key: entry}.values.toList(),
    );
  }
}

@immutable
class TodayPlace {
  const TodayPlace({
    required this.projectKey,
    required this.placeId,
    required this.name,
    required this.address,
    this.skipped = false,
    this.text,
  });
  final String projectKey;
  final String placeId;
  final String name;
  final String address;
  final bool skipped;
  final TodayTextSnapshot? text;
  String get key =>
      '${Uri.encodeComponent(projectKey)}:${Uri.encodeComponent(placeId)}';

  TodayPlace copyWith({bool? skipped, TodayTextSnapshot? text}) => TodayPlace(
    projectKey: projectKey,
    placeId: placeId,
    name: name,
    address: address,
    skipped: skipped ?? this.skipped,
    text: text ?? this.text,
  );

  Map<String, dynamic> toJson() => {
    'projectKey': projectKey,
    'placeId': placeId,
    'name': name,
    'address': address,
    'skipped': skipped,
    if (text != null) 'text': text!.toJson(),
  };

  factory TodayPlace.fromJson(Map<String, dynamic> json) => TodayPlace(
    projectKey: json['projectKey'] as String,
    placeId: json['placeId'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    skipped: json['skipped'] as bool? ?? false,
    text: json['text'] == null
        ? null
        : TodayTextSnapshot.fromJson(
            Map<String, dynamic>.from(json['text'] as Map),
          ),
  );
}

@immutable
class TodayTextSnapshot {
  const TodayTextSnapshot({
    required this.name,
    required this.address,
    required this.description,
    required this.savedAt,
  });
  final String name;
  final String address;
  final String? description;
  final DateTime savedAt;
  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'description': description,
    'savedAt': savedAt.toUtc().toIso8601String(),
  };
  factory TodayTextSnapshot.fromJson(Map<String, dynamic> json) =>
      TodayTextSnapshot(
        name: json['name'] as String,
        address: json['address'] as String,
        description: json['description'] as String?,
        savedAt: DateTime.parse(json['savedAt'] as String),
      );
}
