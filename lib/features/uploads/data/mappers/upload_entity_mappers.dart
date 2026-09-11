/// EN: DTO to domain mappings for the feature.
/// KO: 기능 DTO를 도메인 모델로 변환하는 매핑입니다.

library;

import '../dto/upload_dto.dart';
import '../../domain/entities/upload_entity.dart';

extension UploadInfoResponseDomainMapper on UploadInfoResponse {
  UploadInfo toDomain() {
    final dto = this;

    return UploadInfo(
      uploadId: dto.uploadId,
      url: dto.url,
      filename: dto.filename,
      isApproved: dto.isApproved,
    );
  }
}

extension PresignedUrlResponseDomainMapper on PresignedUrlResponse {
  PresignedUpload toDomain() {
    return PresignedUpload(
      uploadId: uploadId,
      url: url,
      headers: Map.unmodifiable(headers),
    );
  }
}

extension ConfirmUploadResponseDomainMapper on ConfirmUploadResponse {
  UploadConfirmation toDomain() {
    return UploadConfirmation(uploadId: uploadId, status: status);
  }
}
