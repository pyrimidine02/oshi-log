import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/app/session/pending_login_action.dart';

void main() {
  test('successful login releases the pending action only once', () {
    final pending = PendingLoginAction();
    final ticket = pending.begin()!;
    expect(pending.begin(), isNull);
    expect(
      pending.consume(
        ticket,
        successSession: 7,
        currentSession: 7,
        authenticated: true,
      ),
      isTrue,
    );
    expect(
      pending.consume(
        ticket,
        successSession: 7,
        currentSession: 7,
        authenticated: true,
      ),
      isFalse,
    );
  });
  test('cancel and an account replacement never release an old action', () {
    final pending = PendingLoginAction();
    final canceled = pending.begin()!;
    pending.cancel();
    expect(
      pending.consume(
        canceled,
        successSession: 7,
        currentSession: 7,
        authenticated: true,
      ),
      isFalse,
    );
    final switched = pending.begin()!;
    expect(
      pending.consume(
        switched,
        successSession: 7,
        currentSession: 8,
        authenticated: true,
      ),
      isFalse,
    );
    final loggedOut = pending.begin()!;
    expect(
      pending.consume(
        loggedOut,
        successSession: 8,
        currentSession: 8,
        authenticated: false,
      ),
      isFalse,
    );
  });
}
