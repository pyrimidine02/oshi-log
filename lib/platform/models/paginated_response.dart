/// EN: Pagination metadata and paginated response models.
/// KO: 페이지네이션 메타데이터 및 페이지네이션 응답 모델.
library;

/// EN: Pagination metadata from API response (ApiResponse.pagination).
/// KO: API 응답(ApiResponse.pagination)의 페이지네이션 메타데이터.
class PaginationMeta {
  const PaginationMeta({
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.totalItems,
    required this.isFirst,
    required this.isLast,
    required this.hasNext,
    required this.hasPrevious,
    required this.numberOfItems,
  });

  final int currentPage;
  final int pageSize;
  final int totalPages;
  final int totalItems;
  final bool isFirst;
  final bool isLast;
  final bool hasNext;
  final bool hasPrevious;
  final int numberOfItems;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: _int(json['currentPage']),
      pageSize: _int(json['pageSize']),
      totalPages: _int(json['totalPages']),
      totalItems: _int(json['totalItems']),
      isFirst: json['isFirst'] as bool? ?? true,
      isLast: json['isLast'] as bool? ?? true,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
      numberOfItems: _int(json['numberOfItems']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'pageSize': pageSize,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'isFirst': isFirst,
      'isLast': isLast,
      'hasNext': hasNext,
      'hasPrevious': hasPrevious,
      'numberOfItems': numberOfItems,
    };
  }
}

/// EN: Paginated response wrapping items with pagination metadata.
/// KO: 페이지네이션 메타데이터와 함께 아이템을 래핑하는 페이지네이션 응답.
class PaginatedResponse<T> {
  const PaginatedResponse({required this.items, this.pagination});

  final List<T> items;
  final PaginationMeta? pagination;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
