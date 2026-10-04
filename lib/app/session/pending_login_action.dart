/// EN: A login attempt may release one action, only in its successful session.
/// KO: 로그인 시도는 성공한 동일 세션에서 행동을 한 번만 재개합니다.
class PendingLoginAction {
  int _serial = 0;
  int? _pending;

  int? begin() {
    if (_pending != null) return null;
    return _pending = ++_serial;
  }

  bool consume(
    int ticket, {
    required int? successSession,
    required int currentSession,
    required bool authenticated,
  }) {
    if (_pending != ticket) return false;
    _pending = null;
    return authenticated &&
        successSession != null &&
        successSession == currentSession;
  }

  void cancel() => _pending = null;
}
