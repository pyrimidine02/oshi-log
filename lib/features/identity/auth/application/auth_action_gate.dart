/// EN: App-injected login prompt used at the point of a protected action.
/// KO: 보호된 행동 시점에 사용하는 앱 주입 로그인 안내입니다.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef AuthenticationGate = Future<bool> Function(BuildContext context);

final authenticationGateProvider = Provider<AuthenticationGate>(
  (ref) =>
      (_) async => false,
);

/// EN: In-memory return URI for an external OAuth round trip; never an action.
/// KO: 외부 OAuth 왕복용 메모리 복귀 URI이며 자동 실행할 행동은 저장하지 않습니다.
final externalLoginReturnProvider = StateProvider<String?>((ref) => null);
