/// EN: Repository interface for zukan collections.
/// KO: 도감 컬렉션 리포지토리 인터페이스.
library;

import 'package:oshi_log/platform/utils/result.dart';
import 'package:oshi_log/features/place/collections/domain/entities/zukan_collection.dart';

/// EN: Defines the contract for reading zukan collection data.
/// KO: 도감 컬렉션 데이터 읽기를 위한 계약을 정의합니다.
abstract class ZukanRepository {
  /// EN: Fetches the summary list of collections, optionally filtered by project.
  /// KO: 컬렉션 요약 목록을 가져옵니다 (프로젝트 필터 선택적).
  Future<Result<List<ZukanCollectionSummary>>> fetchCollections({
    String? projectId,
  });

  /// EN: Fetches the full detail of a single collection including its stamps.
  /// KO: 스탬프를 포함한 단일 컬렉션의 전체 상세 정보를 가져옵니다.
  Future<Result<ZukanCollection>> fetchCollectionDetail(String collectionId);
}
