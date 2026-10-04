/// EN: Image metadata DTO shared across features.
/// KO: 기능 간 공유되는 이미지 메타데이터 DTO.
library;

class ImageMetaDto {
  const ImageMetaDto({
    required this.imageId,
    required this.url,
    required this.filename,
    required this.contentType,
    required this.fileSize,
    required this.uploadedAt,
    required this.isPrimary,
  });

  final String imageId;
  final String url;
  final String filename;
  final String contentType;
  final int fileSize;
  final DateTime uploadedAt;
  final bool isPrimary;

  factory ImageMetaDto.fromJson(Map<String, dynamic> json) {
    final uploadedAtRaw = json['uploadedAt'] as String? ?? '';
    final parsedUploadedAt =
        DateTime.tryParse(uploadedAtRaw) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    return ImageMetaDto(
      imageId: json['imageId'] as String? ?? '',
      url: json['url'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      contentType: json['contentType'] as String? ?? '',
      fileSize: _int(json['fileSize']),
      uploadedAt: parsedUploadedAt,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'url': url,
      'filename': filename,
      'contentType': contentType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
      'isPrimary': isPrimary,
    };
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
