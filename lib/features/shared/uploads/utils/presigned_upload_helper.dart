/// EN: Helper for uploading files to presigned URLs.
/// KO: presigned URL로 파일을 업로드하는 헬퍼.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';

/// EN: Upload bytes to a presigned URL.
/// KO: presigned URL로 바이트를 업로드합니다.
Future<void> uploadToPresignedUrl({
  required String url,
  required Uint8List bytes,
  required String contentType,
  Map<String, String> headers = const {},
}) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  final response = await dio.put<void>(
    url,
    data: bytes,
    options: Options(
      contentType: contentType,
      headers: {
        'Content-Type': contentType,
        'Content-Length': bytes.length,
        ...headers,
      },
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );

  if (response.statusCode == null ||
      response.statusCode! < 200 ||
      response.statusCode! >= 300) {
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }
}
