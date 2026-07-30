# ADR-20260730: 서버 주도 약관 동의와 위치 고지 1회 동의

## 문제 (Problem)

1. 브랜드 표기가 `oshi@log`(소문자 o)로 배포되어 있었으나 확정 표기는
   `Oshi@log`다.
2. 회원가입에서 약관에 동의했는데 앱을 다시 켜면 필수 동의 게이트가
   "최신 약관이 아니다"라며 같은 동의를 다시 요구했다. 즉 가입 1회 흐름에서
   동의가 두 번 노출됐다.
3. 장소 인증(위치 인증) 바텀시트가 열릴 때마다 위치 수집 사전 고지 체크박스를
   매번 다시 요구했다.

## 원인 (Root cause)

- `legalPoliciesProvider`는 서버 조회 실패나 미해결 상태에서 조용히
  `LegalPolicyConstants.policies`(내장 상수, `v2026.03.12`)로 폴백했다.
- `register_page`는 이 프로바이더를 `.valueOrNull`로 읽어, 아직 로드되지
  않았거나 실패한 경우 내장 버전으로 동의를 제출했다.
- 서버가 요구하는 `requiredVersion`과 제출 버전이 달라지면 서버는
  `needsReconsent`를 반환하고, `_MandatoryConsentGate`가 가입 직후 다시
  동의를 요구했다.
- `VerificationSheet._agreedLocationNotice`는 위젯 로컬 상태여서 시트를 열 때마다
  false로 초기화됐고, 동의 사실이 어디에도 저장되지 않았다.

## 대안 (Alternatives)

1. 게이트에서 가입 직후 일정 시간 동의 요구를 억제한다 — 증상만 가림.
2. 내장 상수 버전을 서버와 맞춰 올린다 — 배포마다 재발.
3. (채택) 동의 기록은 서버가 현재 요구하는 버전만 사용하고, 내장 상수는
   화면 표시 폴백으로만 쓴다.

## 결정 (Decision)

- `legalPoliciesProvider`는 폴백하지 않고
  `ServerFailure('LEGAL_POLICIES_UNAVAILABLE')`로 실패한다.
- 표시 경로는 `resolveLegalPolicy(serverList, type)`로 서버 값을 우선 사용하고
  실패 시 내장 상수로 degrade한다 (설정 화면, 인증 시트, 약관 링크 섹션).
- 회원가입은 제출 전에 `legalPoliciesProvider.future`를 await 하고, 실패하면
  안내 메시지와 함께 가입을 진행하지 않는다. 확인 다이얼로그·제출 payload·
  로컬 동의 이력이 모두 동일한 서버 버전과 동일한 동의 시각을 공유한다.
- 위치 수집 고지는 1회만 요구한다. `LocationNoticeConsentStore`가
  `location_notice_consent_log` 키에
  `{"action":"AGREED","at":"2026-07-30T04:15:00.000Z"}` 형태(UTC ISO-8601,
  최근 20건)로 append-only 기록한다. 동의 이후에는 시트에서 고지 카드를
  표시하지 않고 바로 인증을 시작한다.
- 설정 > 위치 수집 동의 행에서 동의일을 표시하고, 철회할 수 있으며 철회
  시각도 같은 로그에 기록한다. 철회 후 다음 인증에서 다시 동의를 받는다.

## 영향 범위 (Impact)

- `lib/core/constants/legal_policy_constants.dart` — `resolveLegalPolicy` 추가.
- `lib/core/providers/core_providers.dart` — 폴백 제거.
- `lib/core/location/location_notice_consent.dart` — 신규 스토어/프로바이더.
- `lib/core/storage/local_storage.dart` — `locationNoticeConsentLog` 키 추가.
- `lib/features/auth/presentation/pages/register_page.dart` — 서버 버전 await.
- `lib/features/settings/presentation/pages/settings_page.dart` — 서버 버전 표시,
  위치 동의 상태·철회 UI.
- `lib/features/verification/presentation/widgets/verification_sheet.dart` —
  1회 동의, 서버 버전 표시.
- 브랜드 표기: `lib/**`, `l10n/**`, `ios/Runner/Info.plist`,
  `android/app/src/main/AndroidManifest.xml`, README/CHANGELOG/TODO.

## 근거·검증 (Rationale / Verification)

- 서버가 게시한 버전으로만 동의를 기록하는 것이 재동의 요구의 근본 해결이다.
  알 수 없는 버전으로 동의를 남기면 기록이 무효가 될 수 있어 가입 차단이 옳다.
- `dart analyze lib test` — 이슈 없음.
- `flutter test` — 594 tests 전부 통과 (신규
  `test/core/location/location_notice_consent_test.dart` 4건,
  `test/core/branding/brand_contract_test.dart` 11건 포함).
- Flutter SDK / 패키지 버전은 `pubspec.lock` 기준 변경 없음.
