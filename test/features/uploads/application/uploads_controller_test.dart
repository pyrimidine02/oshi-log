import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_log/core/error/failure.dart';
import 'package:oshi_log/core/utils/result.dart';
import 'package:oshi_log/features/uploads/application/uploads_controller.dart';
import 'package:oshi_log/features/uploads/data/dto/upload_dto.dart';
import 'package:oshi_log/features/uploads/domain/entities/upload_entity.dart';
import 'package:oshi_log/features/uploads/domain/repositories/uploads_repository.dart';

class _FakeUploadsRepository implements UploadsRepository {
  int directCalls = 0;
  int presignedCalls = 0;

  @override
  Future<Result<UploadInfo>> directUpload({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    directCalls += 1;
    return Result.success(
      UploadInfo(
        uploadId: 'upload-1',
        url: 'https://example.com/upload-1',
        filename: filename,
        isApproved: true,
      ),
    );
  }

  @override
  Future<Result<PresignedUrlResponse>> requestPresignedUrl({
    required String filename,
    required String contentType,
    required int size,
  }) async {
    presignedCalls += 1;
    return const Result.failure(
      UnknownFailure('Presigned should not be called for image/*'),
    );
  }

  @override
  Future<Result<ConfirmUploadResponse>> confirmUpload(String uploadId) async {
    return Result.success(
      ConfirmUploadResponse(uploadId: uploadId, status: 'CONFIRMED'),
    );
  }

  @override
  Future<Result<void>> deleteUpload(String uploadId) async {
    return const Result.success(null);
  }

  @override
  Future<Result<List<UploadInfo>>> getMyUploads({bool forceRefresh = false}) {
    return Future.value(const Result.success(<UploadInfo>[]));
  }
}

void main() {
  group('UploadsController.uploadImageBytes', () {
    test('routes gif to direct upload endpoint', () async {
      final repository = _FakeUploadsRepository();
      final container = ProviderContainer(
        overrides: [
          uploadsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(uploadsControllerProvider.notifier);
      final result = await controller.uploadImageBytes(
        bytes: Uint8List.fromList([0x47, 0x49, 0x46]),
        filename: 'sample.gif',
        contentType: 'image/gif',
      );

      expect(result, isA<Success<UploadInfo>>());
      expect(repository.directCalls, 1);
      expect(repository.presignedCalls, 0);
    });

    test('routes jpeg to direct upload endpoint', () async {
      final repository = _FakeUploadsRepository();
      final container = ProviderContainer(
        overrides: [
          uploadsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(uploadsControllerProvider.notifier);
      final result = await controller.uploadImageBytes(
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        filename: 'sample.jpg',
        contentType: 'image/jpeg',
      );

      expect(result, isA<Success<UploadInfo>>());
      expect(repository.directCalls, 1);
      expect(repository.presignedCalls, 0);
    });

    test(
      'normalizes uppercase image content type and still routes to direct upload',
      () async {
        final repository = _FakeUploadsRepository();
        final container = ProviderContainer(
          overrides: [
            uploadsRepositoryProvider.overrideWith((ref) async => repository),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(uploadsControllerProvider.notifier);
        final result = await controller.uploadImageBytes(
          bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
          filename: 'sample.jpg',
          contentType: 'Image/JPEG',
        );

        expect(result, isA<Success<UploadInfo>>());
        expect(repository.directCalls, 1);
        expect(repository.presignedCalls, 0);
      },
    );

    test('rejects empty payload before sending any upload request', () async {
      final repository = _FakeUploadsRepository();
      final container = ProviderContainer(
        overrides: [
          uploadsRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(uploadsControllerProvider.notifier);
      final result = await controller.uploadImageBytes(
        bytes: Uint8List(0),
        filename: 'sample.jpg',
        contentType: 'image/jpeg',
      );

      expect(result, isA<Err<UploadInfo>>());
      final failure = (result as Err<UploadInfo>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.code, 'upload_payload_empty');
      expect(repository.directCalls, 0);
      expect(repository.presignedCalls, 0);
    });
  });
}
