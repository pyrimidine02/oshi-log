import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:oshi_log/platform/storage/local_storage.dart';
import '../domain/private_trip.dart';

/// EN: Account-scoped metadata and permanent local photo copies. No network I/O.
/// KO: 계정별 메타데이터와 영구 로컬 사진 복사본입니다. 네트워크 I/O는 없습니다.
class PrivateTripStore {
  PrivateTripStore({required this.storage, required this.directory});
  final LocalStorage storage;
  final Directory directory;
  static const maxPhotoBytes = 32 * 1024 * 1024;

  String _key(String userId) {
    if (userId.trim().isEmpty) throw ArgumentError('An account is required');
    return 'trips_v1:${Uri.encodeComponent(userId)}';
  }

  Directory _ownerDirectory(String userId) {
    _key(userId);
    final digest = sha256.convert(
      utf8.encode('${storage.namespace ?? ''}:$userId'),
    );
    return Directory(path.join(directory.path, 'private_trips', '$digest'));
  }

  Future<List<PrivateTrip>> load(String userId) async {
    final value = storage.getString(_key(userId));
    if (value == null) return [];
    final json = jsonDecode(value) as Map<String, dynamic>;
    if (json['version'] != 1) {
      throw const FormatException('Unknown album version');
    }
    final owner = _ownerDirectory(userId);
    final trips = (json['trips'] as List).map((value) {
      final trip = Map<String, dynamic>.from(value as Map);
      trip['photos'] = (trip['photos'] as List).map((value) {
        final photo = Map<String, dynamic>.from(value as Map);
        final storedPath = photo['path'] as String;
        if (path.isRelative(storedPath) &&
            path.basename(storedPath) == storedPath) {
          photo['path'] = path.join(owner.path, storedPath);
        }
        return photo;
      }).toList();
      return PrivateTrip.fromJson(trip);
    }).toList();
    _validate(userId, trips);
    return trips;
  }

  void _validate(String userId, List<PrivateTrip> trips) {
    final owner = _ownerDirectory(userId).path;
    for (final trip in trips) {
      if (trip.id.isEmpty ||
          trip.projectKey.isEmpty ||
          trip.entries.any((e) => e.projectKey != trip.projectKey) ||
          trip.photos.any((p) => !path.isWithin(owner, p.path)) ||
          (trip.datesConfirmed &&
              (trip.startedOn == null ||
                  trip.endedOn == null ||
                  trip.endedOn!.isBefore(trip.startedOn!)))) {
        throw const FormatException('Invalid private album');
      }
    }
  }

  Future<void> save(String userId, List<PrivateTrip> trips) async {
    _validate(userId, trips);
    final saved = await storage.setJson(_key(userId), {
      'version': 1,
      'trips': trips
          .map(
            (t) => {
              ...t.toJson(),
              // EN: App sandbox roots can change; persist only the owned filename.
              // KO: 앱 샌드박스 루트는 바뀔 수 있어 소유한 파일명만 저장합니다.
              'photos': [
                for (final photo in t.photos)
                  {'id': photo.id, 'path': path.basename(photo.path)},
              ],
            },
          )
          .toList(),
    });
    if (!saved) throw const FileSystemException('Unable to save private album');
  }

  Future<PrivateTripPhoto> copyPhoto(String userId, String sourcePath) async {
    final source = File(sourcePath);
    final size = await source.length();
    if (size <= 0 || size > maxPhotoBytes) {
      throw ArgumentError('Photo size limit');
    }
    final folder = await _ownerDirectory(userId).create(recursive: true);
    final id = const Uuid().v4();
    final destination = File(path.join(folder.path, '$id.original'));
    try {
      await source.copy(destination.path);
    } catch (_) {
      if (await destination.exists()) await destination.delete();
      rethrow;
    }
    return PrivateTripPhoto(id: id, path: destination.path);
  }

  Future<void> deleteUnreferencedPhoto(
    String userId,
    PrivateTripPhoto photo,
  ) async {
    if (!path.isWithin(_ownerDirectory(userId).path, photo.path)) {
      throw ArgumentError('Photo owner mismatch');
    }
    final trips = await load(userId);
    if (trips.any((t) => t.photos.any((p) => p.path == photo.path))) return;
    final file = File(photo.path);
    if (await file.exists()) await file.delete();
  }

  /// EN: The caller owns export lifetime; this cannot delete permanent originals.
  /// KO: 호출자가 내보내기 수명을 관리하며 영구 원본은 삭제할 수 없습니다.
  Future<void> deleteExports(String userId, List<String> paths) async {
    final exports = path.join(_ownerDirectory(userId).path, 'exports');
    for (final filePath in paths) {
      if (!path.equals(path.dirname(filePath), exports) ||
          path.extension(filePath) != '.png') {
        throw ArgumentError('Not an owned export');
      }
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    }
  }

  /// EN: Re-encode only an explicitly selected photo, removing EXIF/location data.
  /// KO: 명시적으로 선택한 사진만 재인코딩하여 EXIF/위치정보를 제거합니다.
  Future<String> exportPhoto(String userId, PrivateTripPhoto photo) async {
    final owner = _ownerDirectory(userId);
    if (!path.isWithin(owner.path, photo.path)) {
      throw ArgumentError('Photo owner mismatch');
    }
    final source = File(photo.path);
    if (!path.isWithin(
      await owner.resolveSymbolicLinks(),
      await source.resolveSymbolicLinks(),
    )) {
      throw ArgumentError('Photo owner mismatch');
    }
    if (await source.length() > maxPhotoBytes) {
      throw ArgumentError('Photo size limit');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      await source.readAsBytes(),
    );
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width * descriptor.height > 100000000) {
        throw ArgumentError('Photo dimension limit');
      }
      final scale = math.min(
        1.0,
        1600 / math.max(descriptor.width, descriptor.height),
      );
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (descriptor.width * scale).round()),
        targetHeight: math.max(1, (descriptor.height * scale).round()),
      );
      image = (await codec.getNextFrame()).image;
      final encoded = await image.toByteData(format: ui.ImageByteFormat.png);
      if (encoded == null) throw const FormatException('Cannot encode photo');
      final folder = await Directory(
        path.join(owner.path, 'exports'),
      ).create(recursive: true);
      final output = File(path.join(folder.path, '${const Uuid().v4()}.png'));
      await output.writeAsBytes(encoded.buffer.asUint8List(), flush: true);
      return output.path;
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}
