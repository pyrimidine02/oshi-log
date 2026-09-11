/// EN: Uploads repository interface.
/// KO: 업로드 리포지토리 인터페이스.
library;

import '../../../../core/utils/result.dart';
import '../entities/upload_entity.dart';

/// EN: Abstract repository for upload operations.
/// KO: 업로드 작업을 위한 추상 리포지토리.
abstract class UploadsRepository {
  /// EN: Upload a file directly via multipart.
  /// KO: multipart로 파일을 직접 업로드합니다.
  Future<Result<UploadInfo>> directUpload({
    required List<int> bytes,
    required String filename,
    required String contentType,
  });

  /// EN: Request a presigned URL for file upload.
  /// KO: 파일 업로드를 위한 presigned URL을 요청합니다.
  Future<Result<PresignedUpload>> requestPresignedUrl({
    required String filename,
    required String contentType,
    required int size,
  });

  /// EN: Confirm that a file was uploaded.
  /// KO: 파일이 업로드되었음을 확인합니다.
  Future<Result<UploadConfirmation>> confirmUpload(String uploadId);

  /// EN: Get the current user's uploads.
  /// KO: 현재 사용자의 업로드 목록을 가져옵니다.
  Future<Result<List<UploadInfo>>> getMyUploads({bool forceRefresh = false});

  /// EN: Delete an upload.
  /// KO: 업로드를 삭제합니다.
  Future<Result<void>> deleteUpload(String uploadId);
}
