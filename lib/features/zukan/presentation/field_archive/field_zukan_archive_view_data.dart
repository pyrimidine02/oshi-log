/// EN: Derived view data for the field-notes specimen archive.
/// KO: 필드 노트 표본 아카이브를 위한 파생 뷰 데이터입니다.
library;

import '../../domain/entities/zukan_collection.dart';

/// EN: Immutable totals and featured selection derived from real collections.
/// KO: 실제 컬렉션에서 계산한 불변 합계와 대표 표본 선택입니다.
class FieldZukanArchiveData {
  const FieldZukanArchiveData._({
    required this.collections,
    required this.featured,
    required this.indexedCollections,
    required this.totalStampCount,
    required this.collectedStampCount,
    required this.completedCollectionCount,
  });

  factory FieldZukanArchiveData.from(List<ZukanCollectionSummary> collections) {
    final ordered = List<ZukanCollectionSummary>.unmodifiable(
      [...collections]..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : a.title.compareTo(b.title);
      }),
    );
    final featured =
        ordered
            .where(
              (collection) =>
                  !collection.isCompleted && collection.stampedCount > 0,
            )
            .firstOrNull ??
        ordered.firstOrNull;
    final indexed = List<ZukanCollectionSummary>.unmodifiable(
      ordered.where((collection) => collection.id != featured?.id),
    );

    return FieldZukanArchiveData._(
      collections: ordered,
      featured: featured,
      indexedCollections: indexed,
      totalStampCount: ordered.fold(
        0,
        (total, collection) => total + collection.totalCount,
      ),
      collectedStampCount: ordered.fold(
        0,
        (total, collection) => total + collection.stampedCount,
      ),
      completedCollectionCount: ordered
          .where((collection) => collection.isCompleted)
          .length,
    );
  }

  final List<ZukanCollectionSummary> collections;
  final ZukanCollectionSummary? featured;
  final List<ZukanCollectionSummary> indexedCollections;
  final int totalStampCount;
  final int collectedStampCount;
  final int completedCollectionCount;

  double get progressRatio => totalStampCount == 0
      ? 0
      : (collectedStampCount / totalStampCount).clamp(0, 1).toDouble();
}
