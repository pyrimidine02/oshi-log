/// EN: Media link DTOs for image/banner management.
/// KO: 이미지/배너 관리를 위한 미디어 링크 DTO.
library;

/// EN: Request to link an uploaded image to an entity.
/// KO: 업로드된 이미지를 엔티티에 연결하는 요청.
class LinkImageRequest {
  const LinkImageRequest({required this.uploadId});

  final String uploadId;

  Map<String, dynamic> toJson() {
    return {'uploadId': uploadId};
  }
}

/// EN: Request to reorder images.
/// KO: 이미지 순서 변경 요청.
class ReorderRequest {
  const ReorderRequest({required this.imageIds});

  final List<String> imageIds;

  Map<String, dynamic> toJson() {
    return {'imageIds': imageIds};
  }
}

/// EN: Response after linking an image to an entity.
/// KO: 이미지를 엔티티에 연결한 후 응답.
class ImageLinkResponse {
  const ImageLinkResponse({
    required this.imageId,
    required this.url,
    required this.filename,
    required this.contentType,
    required this.fileSize,
    required this.isPrimary,
    this.linkedAt,
  });

  final String imageId;
  final String url;
  final String filename;
  final String contentType;
  final int fileSize;
  final bool isPrimary;
  final DateTime? linkedAt;

  factory ImageLinkResponse.fromJson(Map<String, dynamic> json) {
    return ImageLinkResponse(
      imageId: json['imageId'] as String? ?? '',
      url: json['url'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      contentType: json['contentType'] as String? ?? '',
      fileSize: _int(json['fileSize']),
      isPrimary: json['isPrimary'] as bool? ?? false,
      linkedAt: json['linkedAt'] is String
          ? DateTime.tryParse(json['linkedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'url': url,
      'filename': filename,
      'contentType': contentType,
      'fileSize': fileSize,
      'isPrimary': isPrimary,
      'linkedAt': linkedAt?.toIso8601String(),
    };
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
