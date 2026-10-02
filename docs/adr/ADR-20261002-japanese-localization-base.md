# ADR-20261002: 일본어 기본 로케일과 일본어 글꼴 처리

## 상태

Accepted — 2026-10-02 (커밋 6d3546b, 문구 전환 e5cb6da·4eb4f03·a7c2e4b)

## 문제

- 지원하지 않는 단말 언어와 번역 누락이 모두 한국어로 대체됐다.
- 전역 글꼴 Pretendard에는 가나(히라가나·가타카나)가 없다. 일본어가 `Apple SD Gothic Neo` 등 한국어 글꼴로 대체되어 한자가 한국어 자형으로 보일 수 있었다.
- 노출 화면에 하드코딩된 한국어 문구가 약 400곳 남아 있었다.

## 대안

1. gen_l10n(ARB)으로 전면 전환: 인라인 호출 1,773곳 중 ja 누락이 0이라 이득이 작고 비용이 크다. 외부 번역가 워크플로가 생기면 재검토. **기각**
2. Noto Sans JP 번들: 기기·golden 재현성은 좋지만 앱 용량이 크게 늘어난다. **기각**
3. 인라인 헬퍼 유지 + 해석 규칙 변경 + ja 시스템 글꼴 우선. **채택**

## 결정

- 지원하지 않거나 없는 단말 언어 → `ja` (`lib/core/localization/locale_resolution.dart`).
- 번역 누락 fallback: 선택 언어 → ja → en → ko. null과 빈 문자열은 같게 처리.
- 사용자가 저장한 언어 선택(`locale` 키, system|ko|en|ja)은 그대로 우선한다.
- ja 테마: fontFamily를 비우고 `Hiragino Sans`, `Hiragino Kaku Gothic ProN`, `Noto Sans JP`, `Noto Sans CJK JP` 순 fallback. 본문 16sp·줄높이 1.6·자간 0.02em, 최소 14sp (デジタル庁 DADS).
- ko·en은 기존 Pretendard 번들을 그대로 쓴다.
- `ThemeData(textTheme:)`는 기본 TextTheme와 merge되어 null fontFamily가 Roboto로 채워지므로 `copyWith(textTheme:)`로 교체한다.
- 노출 화면 하드코딩 문구를 `context.l10n(ko:, en:, ja:)`로 전환. 일본어 문구 규칙은 `design-references-v1.md` §4.3(SmartHR·DADS).
- 위젯 테스트 기본 로케일은 en_US라, 한국어 문자열을 검사하는 테스트는 `locale: Locale('ko')`를 명시한다.

## 영향

- 일본어 golden 기준 이미지는 아직 없다(TODO).
- 공연 시각의 JST 표시 정책은 로케일과 별개로 화면 작업에서 정한다.
