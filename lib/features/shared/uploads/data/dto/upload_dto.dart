/// EN: Upload DTOs for presigned URL, confirm, and info responses.
/// KO: presigned URL, 확인, 정보 응답을 위한 업로드 DTO.
library;

/// EN: Request to create a presigned upload URL.
/// KO: presigned 업로드 URL 생성 요청.
class CreateUploadUrlRequest {
  const CreateUploadUrlRequest({
    required this.filename,
    required this.contentType,
    required this.size,
  });

  final String filename;
  final String contentType;
  final int size;

  Map<String, dynamic> toJson() {
    return {'filename': filename, 'contentType': contentType, 'size': size};
  }
}

/// EN: Response containing presigned URL for direct upload.
/// KO: 직접 업로드를 위한 presigned URL 응답.
class PresignedUrlResponse {
  const PresignedUrlResponse({
    required this.uploadId,
    required this.url,
    required this.headers,
  });

  final String uploadId;
  final String url;
  final Map<String, String> headers;

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponse(
      uploadId: _firstNonEmptyString([
        json['uploadId'],
        json['upload_id'],
        json['id'],
      ]),
      url: _firstNonEmptyString([
        json['url'],
        json['uploadUrl'],
        json['upload_url'],
        json['presignedUrl'],
        json['presigned_url'],
      ]),
      headers: _stringMap(json['headers']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'uploadId': uploadId, 'url': url, 'headers': headers};
  }
}

/// EN: Response after confirming an upload.
/// KO: 업로드 확인 후 응답.
class ConfirmUploadResponse {
  const ConfirmUploadResponse({required this.uploadId, required this.status});

  final String uploadId;
  final String status;

  factory ConfirmUploadResponse.fromJson(Map<String, dynamic> json) {
    return ConfirmUploadResponse(
      uploadId: _firstNonEmptyString([
        json['uploadId'],
        json['upload_id'],
        json['id'],
      ]),
      status: _firstNonEmptyString([json['status'], json['state']]),
    );
  }

  Map<String, dynamic> toJson() {
    return {'uploadId': uploadId, 'status': status};
  }
}

/// EN: Upload info returned from list-my-uploads API.
/// KO: 내 업로드 목록 API에서 반환되는 업로드 정보.
class UploadInfoResponse {
  const UploadInfoResponse({
    required this.uploadId,
    required this.url,
    required this.filename,
    required this.isApproved,
  });

  final String uploadId;
  final String url;
  final String filename;
  final bool isApproved;

  factory UploadInfoResponse.fromJson(Map<String, dynamic> json) {
    return UploadInfoResponse(
      uploadId: _firstNonEmptyString([
        json['uploadId'],
        json['upload_id'],
        json['id'],
        json['fileId'],
        json['file_id'],
      ]),
      url: _firstNonEmptyString([
        json['url'],
        json['fileUrl'],
        json['file_url'],
        json['publicUrl'],
        json['public_url'],
        json['cdnUrl'],
        json['cdn_url'],
        json['path'],
      ]),
      filename: _firstNonEmptyString([
        json['filename'],
        json['fileName'],
        json['name'],
        json['originalFilename'],
      ]),
      isApproved:
          _boolValue(json['isApproved']) ??
          _boolValue(json['approved']) ??
          false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uploadId': uploadId,
      'url': url,
      'filename': filename,
      'isApproved': isApproved,
    };
  }
}

Map<String, String> _stringMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), val?.toString() ?? ''),
    );
  }
  return <String, String>{};
}

String _firstNonEmptyString(List<dynamic> values) {
  for (final value in values) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'null') {
        return trimmed;
      }
    }
  }
  return '';
}

bool? _boolValue(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}
