/// EN: Lifecycle lease for a native map platform controller.
/// KO: 네이티브 지도 플랫폼 컨트롤러의 생명주기 리스입니다.
library;

import 'package:flutter/services.dart';

/// EN: Owns one controller reference and invalidates stale async operations.
/// KO: 하나의 컨트롤러 참조를 소유하고 오래된 비동기 작업을 무효화합니다.
class FieldMapControllerLease<T extends Object> {
  T? _controller;
  int _generation = 0;

  /// EN: The currently usable controller, or null while the map is inactive.
  /// KO: 현재 사용 가능한 컨트롤러이며 지도 비활성 중에는 null입니다.
  T? get controller => _controller;

  /// EN: Attaches the controller created by the current native map instance.
  /// KO: 현재 네이티브 지도 인스턴스가 생성한 컨트롤러를 연결합니다.
  void attach(T controller) {
    _generation += 1;
    _controller = controller;
  }

  /// EN: Clears the reference before platform disposal can trigger callbacks.
  /// KO: 플랫폼 dispose가 콜백을 발생시키기 전에 참조를 먼저 제거합니다.
  void release({void Function(T controller)? dispose}) {
    final released = _controller;
    _controller = null;
    _generation += 1;
    if (released == null || dispose == null) return;
    try {
      dispose(released);
    } on Object catch (error, stackTrace) {
      if (!isUnavailableFieldMapControllerError(error)) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }

  /// EN: Runs a platform call only on the current controller lease.
  /// KO: 현재 컨트롤러 리스에서만 플랫폼 호출을 실행합니다.
  Future<void> run(Future<void> Function(T controller) operation) async {
    final leased = _controller;
    if (leased == null) return;
    final callGeneration = _generation;
    try {
      await operation(leased);
    } on Object catch (error, stackTrace) {
      if (!isUnavailableFieldMapControllerError(error)) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      // EN: A late failure from an old map must not clear a new controller.
      // KO: 이전 지도의 느린 실패가 새 컨트롤러를 제거하면 안 됩니다.
      if (_generation == callGeneration && identical(_controller, leased)) {
        _controller = null;
        _generation += 1;
      }
    }
  }
}

/// EN: Errors emitted when a native map view or channel is already gone.
/// KO: 네이티브 지도 뷰 또는 채널이 이미 제거됐을 때의 오류입니다.
bool isUnavailableFieldMapControllerError(Object error) {
  return error is StateError ||
      error is MissingPluginException ||
      error is PlatformException;
}
