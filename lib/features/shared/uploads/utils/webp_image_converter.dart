/// EN: Convert images to WebP for upload.
/// KO: 업로드를 위해 이미지를 WebP로 변환합니다.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

class WebpImagePayload {
  const WebpImagePayload({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}

/// EN: Convert the image file to WebP. Best-effort keeps metadata.
/// GIF files are passed through as-is to preserve animation.
/// KO: 이미지 파일을 WebP로 변환합니다. 메타데이터는 최대한 유지합니다.
/// GIF 파일은 애니메이션 보존을 위해 변환 없이 원본 그대로 반환합니다.
Future<WebpImagePayload> convertToWebp({
  required String path,
  required String originalFilename,
  int maxWidth = 2048,
  int maxHeight = 2048,
  int quality = 85,
  bool forceJpeg = false,
}) async {
  // EN: Use the on-disk file extension for format detection.
  //     image_picker on iOS may convert Live Photos / animated items to a JPEG
  //     temp file while keeping the original name (e.g. "sticker.gif" → temp .jpg).
  //     Branching on originalFilename would send JPEG bytes with "image/gif"
  //     Content-Type, causing a server 400 "invalid input" error.
  // KO: 실제 파일 경로 확장자로 포맷을 감지합니다.
  //     iOS image_picker가 Live Photo나 GIF를 JPEG 임시 파일로 변환하면서도
  //     originalFilename은 원본명(예: "sticker.gif")을 유지할 수 있습니다.
  //     originalFilename 기준으로 분기하면 JPEG 바이트가 "image/gif"로
  //     서버에 전송되어 400 오류가 발생합니다.
  final pathExt = p.extension(path).toLowerCase();
  final nameExt = p.extension(originalFilename).toLowerCase();
  // EN: Path extension reflects the actual bytes on disk; fall back to name
  //     extension only when the temp path carries no extension (FilePicker raw).
  // KO: 경로 확장자가 실제 파일 내용을 반영하므로 우선 사용하고,
  //     임시 경로에 확장자가 없는 경우(FilePicker 원본 파일)에만 폴백합니다.
  final ext = pathExt.isNotEmpty ? pathExt : nameExt;

  // EN: GIF files are passed through without conversion to keep animation intact.
  // KO: GIF 파일은 애니메이션을 유지하기 위해 변환 없이 원본 바이트를 그대로 반환합니다.
  if (ext == '.gif') {
    final bytes = await File(path).readAsBytes();
    return WebpImagePayload(
      bytes: bytes,
      filename: originalFilename,
      contentType: 'image/gif',
    );
  }

  if (ext == '.webp' && !forceJpeg) {
    final bytes = await File(path).readAsBytes();
    return WebpImagePayload(
      bytes: bytes,
      filename: originalFilename,
      contentType: 'image/webp',
    );
  }

  final useWebp = !forceJpeg && !(Platform.isIOS || Platform.isMacOS);
  final targetFormat = useWebp ? CompressFormat.webp : CompressFormat.jpeg;
  final targetExtension = useWebp ? '.webp' : '.jpg';
  final contentType = useWebp ? 'image/webp' : 'image/jpeg';

  final result = await FlutterImageCompress.compressWithFile(
    path,
    minWidth: maxWidth,
    minHeight: maxHeight,
    quality: quality,
    format: targetFormat,
    keepExif: true,
  );

  if (result == null || result.isEmpty) {
    throw StateError('Failed to convert image for upload.');
  }

  final filename =
      '${p.basenameWithoutExtension(originalFilename)}$targetExtension';
  return WebpImagePayload(
    bytes: Uint8List.fromList(result),
    filename: filename,
    contentType: contentType,
  );
}
