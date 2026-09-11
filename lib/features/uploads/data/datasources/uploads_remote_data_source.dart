/// EN: Remote data source for upload APIs.
/// KO: 업로드 API 원격 데이터 소스.
library;

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/result.dart';
import '../dto/upload_dto.dart';

/// EN: Handles upload-related API requests.
/// KO: 업로드 관련 API 요청을 처리합니다.
class UploadsRemoteDataSource {
  UploadsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// EN: Upload a file directly via multipart/form-data.
  /// KO: multipart/form-data로 파일을 직접 업로드합니다.
  Future<Result<UploadInfoResponse>> directUpload({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      ),
    });

    // EN: Use formData.contentType so the boundary is included in the
    //     Content-Type header (e.g. "multipart/form-data; boundary=<id>").
    //     Passing a bare "multipart/form-data" string strips the boundary,
    //     which causes the server to return 400.
    // KO: formData.contentType를 사용해야 Content-Type 헤더에 boundary가
    //     포함됩니다(예: "multipart/form-data; boundary=<id>").
    //     "multipart/form-data" 문자열만 넘기면 boundary가 빠져
    //     서버에서 400 오류가 발생합니다.
    return _apiClient.post<UploadInfoResponse>(
      ApiEndpoints.uploadsDirect,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data; boundary=${formData.boundary}',
      ),
      fromJson: (json) =>
          UploadInfoResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Request a presigned URL for direct file upload.
  /// KO: 직접 파일 업로드를 위한 presigned URL을 요청합니다.
  Future<Result<PresignedUrlResponse>> requestPresignedUrl(
    CreateUploadUrlRequest request,
  ) {
    // EN: Use a shorter timeout for presigned URL requests so that
    // we can quickly fall back to direct upload when the server
    // does not support or respond to presigned URL requests.
    // KO: presigned URL 요청에 짧은 타임아웃을 사용하여 서버가
    // presigned URL을 지원하지 않거나 응답하지 않을 때 빠르게
    // 직접 업로드로 폴백할 수 있도록 합니다.
    return _apiClient.post<PresignedUrlResponse>(
      ApiEndpoints.uploadsPresignedUrl,
      data: request.toJson(),
      options: Options(
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ),
      fromJson: (json) =>
          PresignedUrlResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Confirm that a file has been uploaded successfully.
  /// KO: 파일이 성공적으로 업로드되었음을 확인합니다.
  Future<Result<ConfirmUploadResponse>> confirmUpload(String uploadId) {
    return _apiClient.post<ConfirmUploadResponse>(
      ApiEndpoints.uploadsConfirm(uploadId),
      fromJson: (json) =>
          ConfirmUploadResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// EN: Fetch the current user's uploads.
  /// KO: 현재 사용자의 업로드 목록을 조회합니다.
  Future<Result<List<UploadInfoResponse>>> fetchMyUploads({
    int page = ApiPagination.defaultPage,
    int size = ApiPagination.defaultSize,
  }) {
    return _apiClient.get<List<UploadInfoResponse>>(
      ApiEndpoints.uploadsMy,
      queryParameters: {'page': page, 'size': size},
      fromJson: (json) => _decodeList(json, UploadInfoResponse.fromJson),
    );
  }

  /// EN: Delete an upload.
  /// KO: 업로드를 삭제합니다.
  Future<Result<void>> deleteUpload(String uploadId) {
    return _apiClient.delete<void>(
      ApiEndpoints.uploadsDelete(uploadId),
      fromJson: (_) {},
    );
  }
}

List<T> _decodeList<T>(dynamic json, T Function(Map<String, dynamic>) mapper) {
  if (json is List) {
    return json.whereType<Map<String, dynamic>>().map(mapper).toList();
  }
  if (json is Map<String, dynamic>) {
    const listKeys = ['items', 'content', 'data', 'results'];
    for (final key in listKeys) {
      final value = json[key];
      if (value is List) {
        return value.whereType<Map<String, dynamic>>().map(mapper).toList();
      }
    }
  }
  return <T>[];
}
