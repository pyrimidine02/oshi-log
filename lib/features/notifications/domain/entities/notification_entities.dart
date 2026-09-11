/// EN: Notification domain entities.
/// KO: 알림 도메인 엔티티.
library;

import 'package:intl/intl.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.type,
    this.actionUrl,
    this.deeplink,
    this.entityId,
    this.projectCode,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? type;
  final String? actionUrl;
  final String? deeplink;
  final String? entityId;
  final String? projectCode;

  String get dateLabel {
    return DateFormat('yyyy.MM.dd').format(createdAt.toLocal());
  }
}
