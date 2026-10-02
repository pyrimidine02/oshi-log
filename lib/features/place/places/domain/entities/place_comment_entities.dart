/// EN: Place comment domain entities.
/// KO: 장소 댓글 도메인 엔티티.
library;

import 'package:intl/intl.dart';

class PlaceComment {
  const PlaceComment({
    required this.id,
    required this.authorId,
    required this.body,
    required this.createdAt,
    required this.replyCount,
    required this.isAdminNote,
    required this.isPinnedByAdmin,
    required this.tags,
    required this.photoUploadIds,
    required this.photoUrls,
  });

  final String id;
  final String authorId;
  final String body;
  final DateTime? createdAt;
  final int replyCount;
  final bool isAdminNote;
  final bool isPinnedByAdmin;
  final List<String> tags;
  final List<String> photoUploadIds;
  final List<String> photoUrls;

  String get createdAtLabel {
    if (createdAt == null) return '';
    return DateFormat('yyyy.MM.dd').format(createdAt!.toLocal());
  }
}
