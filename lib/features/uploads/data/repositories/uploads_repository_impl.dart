/// EN: Uploads repository implementation with caching.
/// KO: 캐싱을 포함한 업로드 리포지토리 구현.
library;

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/cache/cache_profiles.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/upload_entity.dart';
import '../../domain/repositories/uploads_repository.dart';
import '../datasources/uploads_remote_data_source.dart';
import '../dto/upload_dto.dart';
import '../mappers/upload_entity_mappers.dart';

class UploadsRepositoryImpl implements UploadsRepository {
  UploadsRepositoryImpl({
    required UploadsRemoteDataSource remoteDataSource,
    required CacheManager cacheManager,
  }) : _remoteDataSource = remoteDataSource,
       _cacheManager = cacheManager;

  final UploadsRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  static const String _myUploadsCacheKey = 'uploads_my';

  @override
  Future<Result<UploadInfo>> directUpload({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    final result = await _remoteDataSource.directUpload(
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );

    if (result is Success<UploadInfoResponse>) {
      await _cacheManager.remove(_myUploadsCacheKey);
      return Result.success(result.data.toDomain());
    }
    if (result is Err<UploadInfoResponse>) {
      return Result.failure(result.failure);
    }

    return const Result.failure(UnknownFailure('Unknown direct upload result'));
  }

  @override
  Future<Result<PresignedUpload>> requestPresignedUrl({
    required String filename,
    required String contentType,
    required int size,
  }) async {
    final result = await _remoteDataSource.requestPresignedUrl(
      CreateUploadUrlRequest(
        filename: filename,
        contentType: contentType,
        size: size,
      ),
    );
    if (result is Success<PresignedUrlResponse>) {
      return Result.success(result.data.toDomain());
    }
    if (result is Err<PresignedUrlResponse>) {
      return Result.failure(result.failure);
    }
    return const Result.failure(
      UnknownFailure('Unknown presigned upload result'),
    );
  }

  @override
  Future<Result<UploadConfirmation>> confirmUpload(String uploadId) async {
    final result = await _remoteDataSource.confirmUpload(uploadId);
    // EN: Invalidate my-uploads cache on confirm.
    // KO: 확인 시 내 업로드 캐시를 무효화합니다.
    if (result is Success<ConfirmUploadResponse>) {
      await _cacheManager.remove(_myUploadsCacheKey);
      return Result.success(result.data.toDomain());
    }
    if (result is Err<ConfirmUploadResponse>) {
      return Result.failure(result.failure);
    }
    return const Result.failure(
      UnknownFailure('Unknown upload confirmation result'),
    );
  }

  @override
  Future<Result<List<UploadInfo>>> getMyUploads({
    bool forceRefresh = false,
  }) async {
    final profile = CacheProfiles.uploadsMy;
    final policy = profile.policyFor(forceRefresh: forceRefresh);

    try {
      final cacheResult = await _cacheManager.resolve<List<UploadInfoResponse>>(
        key: _myUploadsCacheKey,
        policy: policy,
        ttl: profile.ttl,
        revalidateAfter: profile.revalidateAfter,
        fetcher: () => _fetchMyUploads(),
        toJson: (dtos) => {'items': dtos.map((e) => e.toJson()).toList()},
        fromJson: (json) {
          final items = json['items'];
          if (items is List) {
            return items
                .whereType<Map<String, dynamic>>()
                .map(UploadInfoResponse.fromJson)
                .toList();
          }
          return <UploadInfoResponse>[];
        },
      );

      final entities = cacheResult.data.map((dto) => dto.toDomain()).toList();
      return Result.success(entities);
    } catch (e, stackTrace) {
      return Result.failure(ErrorHandler.mapException(e, stackTrace));
    }
  }

  @override
  Future<Result<void>> deleteUpload(String uploadId) async {
    final result = await _remoteDataSource.deleteUpload(uploadId);
    // EN: Invalidate my-uploads cache on delete.
    // KO: 삭제 시 내 업로드 캐시를 무효화합니다.
    if (result is Success<void>) {
      await _cacheManager.remove(_myUploadsCacheKey);
    }
    return result;
  }

  Future<List<UploadInfoResponse>> _fetchMyUploads() async {
    final result = await _remoteDataSource.fetchMyUploads();

    if (result is Success<List<UploadInfoResponse>>) {
      return result.data;
    }
    if (result is Err<List<UploadInfoResponse>>) {
      throw result.failure;
    }

    throw const UnknownFailure(
      'Unknown uploads list result',
      code: 'unknown_uploads_list',
    );
  }
}
