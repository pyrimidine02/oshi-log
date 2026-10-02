// EN: Unit test for the post-login redirect target validator shared by the
//     router guard and LoginPage (open-redirect safety).
// KO: 라우터 가드와 LoginPage가 공유하는 로그인 후 리다이렉트 대상 검증기에
//     대한 단위 테스트입니다 (오픈 리다이렉트 방지).
import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_log/app/router/auth_guard.dart';

void main() {
  test('accepts a plain relative in-app path', () {
    expect(safeRedirectTarget('/mypage'), '/mypage');
  });

  test('rejects null/empty', () {
    expect(safeRedirectTarget(null), isNull);
    expect(safeRedirectTarget(''), isNull);
  });

  test('rejects protocol-relative and absolute URLs (open redirect)', () {
    expect(safeRedirectTarget('//evil.com'), isNull);
    expect(safeRedirectTarget('https://evil.com'), isNull);
  });

  test('rejects redirecting back into auth routes', () {
    expect(safeRedirectTarget('/login'), isNull);
    expect(safeRedirectTarget('/login?redirect=/mypage'), isNull);
    expect(safeRedirectTarget('/auth/callback'), isNull);
  });
}
