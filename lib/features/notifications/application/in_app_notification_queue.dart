/// EN: In-app notification banner queue for foreground popup alerts.
/// KO: 포그라운드 팝업 알림을 위한 인앱 알림 배너 큐입니다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// EN: A single in-app notification banner entry.
/// KO: 인앱 알림 배너 항목입니다.
class InAppNotificationEntry {
  const InAppNotificationEntry({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    this.entityId,
    this.deeplink,
    this.actionUrl,
    this.projectCode,
  });

  final String id;
  final String title;
  final String body;
  final String? type;
  final String? entityId;
  final String? deeplink;
  final String? actionUrl;
  final String? projectCode;
}

/// EN: Queue notifier for in-app notification banners.
/// KO: 인앱 알림 배너 큐 노티파이어입니다.
class InAppNotificationQueueNotifier
    extends StateNotifier<List<InAppNotificationEntry>> {
  InAppNotificationQueueNotifier() : super(const []);

  static const int _maxQueueSize = 5;

  /// EN: Push a new entry to the banner queue.
  /// KO: 배너 큐에 새 항목을 추가합니다.
  void push(InAppNotificationEntry entry) {
    if (state.any((e) => e.id == entry.id)) return;
    final next = [...state, entry];
    state = next.length > _maxQueueSize
        ? next.sublist(next.length - _maxQueueSize)
        : next;
  }

  /// EN: Remove the current (first) entry from the queue.
  /// KO: 큐에서 현재(첫 번째) 항목을 제거합니다.
  void dismissCurrent() {
    if (state.isEmpty) return;
    state = state.sublist(1);
  }

  /// EN: Clear all queued entries.
  /// KO: 큐의 모든 항목을 제거합니다.
  void clear() => state = const [];
}

/// EN: Provider for the in-app notification banner queue.
/// KO: 인앱 알림 배너 큐 프로바이더입니다.
final inAppNotificationQueueProvider =
    StateNotifierProvider<
      InAppNotificationQueueNotifier,
      List<InAppNotificationEntry>
    >((ref) => InAppNotificationQueueNotifier());
