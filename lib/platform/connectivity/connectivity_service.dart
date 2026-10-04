/// EN: Connectivity service for monitoring network status
/// KO: 네트워크 상태 모니터링을 위한 연결 서비스
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// EN: Connectivity status enumeration
/// KO: 연결 상태 열거형
enum ConnectivityStatus { online, offline, unknown }

/// EN: Service for monitoring network connectivity
/// KO: 네트워크 연결 모니터링 서비스
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  StreamController<ConnectivityStatus>? _statusController;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// EN: Stream of connectivity status changes
  /// KO: 연결 상태 변경 스트림
  Stream<ConnectivityStatus> get statusStream {
    _statusController ??= StreamController<ConnectivityStatus>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _statusController!.stream;
  }

  /// EN: Start listening to connectivity changes
  /// KO: 연결 변경 수신 시작
  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final status = _mapResults(results);
      _statusController?.add(status);
    });
  }

  /// EN: Stop listening to connectivity changes
  /// KO: 연결 변경 수신 중지
  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// EN: Check current connectivity status
  /// KO: 현재 연결 상태 확인
  Future<ConnectivityStatus> checkStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _mapResults(results);
    } catch (_) {
      return ConnectivityStatus.unknown;
    }
  }

  /// EN: Check if currently online
  /// KO: 현재 온라인 여부 확인
  Future<bool> get isOnline async {
    final status = await checkStatus();
    return status == ConnectivityStatus.online;
  }

  /// EN: Check if currently offline
  /// KO: 현재 오프라인 여부 확인
  Future<bool> get isOffline async {
    final status = await checkStatus();
    return status == ConnectivityStatus.offline;
  }

  /// EN: Map connectivity results to status
  /// KO: 연결 결과를 상태로 매핑
  ConnectivityStatus _mapResults(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return ConnectivityStatus.offline;
    }

    // EN: Check if any connection type is available
    // KO: 사용 가능한 연결 타입이 있는지 확인
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.mobile:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.vpn:
          return ConnectivityStatus.online;
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.other:
          // EN: These may or may not provide internet
          // KO: 인터넷 제공 여부 불확실
          continue;
        case ConnectivityResult.none:
          continue;
      }
    }

    // EN: No valid connection found
    // KO: 유효한 연결 없음
    if (results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }

    return ConnectivityStatus.unknown;
  }

  /// EN: Dispose resources
  /// KO: 리소스 해제
  void dispose() {
    _stopListening();
    _statusController?.close();
    _statusController = null;
  }
}
