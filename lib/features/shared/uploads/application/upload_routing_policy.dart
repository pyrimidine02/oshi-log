/// EN: Returns whether the upload must use the direct multipart endpoint.
/// KO: direct multipart 엔드포인트를 사용해야 하는지 여부를 반환합니다.
bool shouldUseDirectUploadForContentType(String contentType) {
  return contentType.startsWith('image/');
}
