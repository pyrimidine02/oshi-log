/// EN: Upload domain entity.
/// KO: 업로드 도메인 엔티티.
library;

/// EN: Domain entity representing an uploaded file.
/// KO: 업로드된 파일을 나타내는 도메인 엔티티.
class UploadInfo {
  const UploadInfo({
    required this.uploadId,
    required this.url,
    required this.filename,
    required this.isApproved,
  });

  final String uploadId;
  final String url;
  final String filename;
  final bool isApproved;
}

/// EN: Presigned upload target returned by the upload use case.
/// KO: 업로드 유스케이스가 반환하는 presigned 업로드 대상입니다.
class PresignedUpload {
  const PresignedUpload({
    required this.uploadId,
    required this.url,
    required this.headers,
  });

  final String uploadId;
  final String url;
  final Map<String, String> headers;
}

/// EN: Confirmation result returned after an object is uploaded.
/// KO: 객체 업로드 후 반환되는 확인 결과입니다.
class UploadConfirmation {
  const UploadConfirmation({required this.uploadId, required this.status});

  final String uploadId;
  final String status;
}
