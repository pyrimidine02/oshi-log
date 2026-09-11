/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/place_comment_dto.dart';
import '../../domain/entities/place_comment_entities.dart';

extension PlaceCommentDetailDtoDomainMapper on PlaceCommentDetailDto {
  PlaceComment toDomain() {
    final dto = this;

    final rawBody = dto.bodyMarkdown.isNotEmpty
        ? dto.bodyMarkdown
        : _stripHtml(dto.bodyHtml ?? '');
    return PlaceComment(
      id: dto.id,
      authorId: dto.authorSubjectId,
      body: rawBody.trim(),
      createdAt: dto.createdAt,
      replyCount: dto.replyCount,
      isAdminNote: dto.isAdminNote,
      isPinnedByAdmin: dto.isPinnedByAdmin,
      tags: List.unmodifiable(dto.tags),
      photoUploadIds: List.unmodifiable(dto.photoUploadIds),
      photoUrls: List.unmodifiable(
        dto.photos.map((photo) => photo.url).toList(),
      ),
    );
  }
}

String _stripHtml(String input) {
  return input.replaceAll(RegExp(r'<[^>]*>'), '');
}
