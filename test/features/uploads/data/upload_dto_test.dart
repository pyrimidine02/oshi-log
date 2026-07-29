import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/features/uploads/data/dto/upload_dto.dart';

void main() {
  test('UploadInfoResponse parses alternate key variants', () {
    final json = {
      'id': 'upload-123',
      'publicUrl': '/uploads/sample.webp',
      'fileName': 'sample.webp',
      'approved': true,
    };

    final dto = UploadInfoResponse.fromJson(json);

    expect(dto.uploadId, 'upload-123');
    expect(dto.url, '/uploads/sample.webp');
    expect(dto.filename, 'sample.webp');
    expect(dto.isApproved, isTrue);
  });

  test('PresignedUrlResponse parses snake-case payload', () {
    final json = {
      'upload_id': 'upload-456',
      'presigned_url': 'https://example.com/upload',
      'headers': {'x-amz-acl': 'private'},
    };

    final dto = PresignedUrlResponse.fromJson(json);

    expect(dto.uploadId, 'upload-456');
    expect(dto.url, 'https://example.com/upload');
    expect(dto.headers['x-amz-acl'], 'private');
  });

  test('ConfirmUploadResponse parses id/state fallback keys', () {
    final json = {'id': 'upload-789', 'state': 'CONFIRMED'};

    final dto = ConfirmUploadResponse.fromJson(json);

    expect(dto.uploadId, 'upload-789');
    expect(dto.status, 'CONFIRMED');
  });
}
