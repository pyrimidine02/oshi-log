# Project Agent Playbook (AGENTS.md)

> 이 문서는 AI 에이전트(Claude/Codex/Gemini)가  
> **Flutter (Dart + Flutter 3.x+ + Clean Architecture + Riverpod/BLoC + REST/GraphQL API Client + Local Persistence)**  
> 프로젝트를 자동으로 작업할 때 따라야 할 **간결한 플레이북**입니다.  
> **핵심만 짧게** 유지하세요. 상세 설명은 `docs/`에 ADR로 남깁니다.

## Goals

- 기능/화면 단위로 **동작하는 Flutter UI**를 빠르게 만들고, 회귀 없이 확장하기.
- 변경 시 항상:
  - **테스트 우선** (unit/widget/integration)
  - **성능(빌드 빈도, Rebuild scope, 렌더링 비용)**과
  - **접근성·반응형 레이아웃**을 기본 가드레일로 삼기.
- **캡슐화(Encapsulation) · 관심사 분리(Separation of Concerns) · 확장 가능성(Extensibility)**을 모든 변경의 기본 원칙으로 삼기.

---

## Repo Layout (assumed)

- `lib/` : 앱 소스 코드
  - `lib/main.dart` : 진입점
  - `lib/app.dart` : MaterialApp / Router 설정
  - `lib/core/` : 공통 인프라 (theme, routing, error, utils, localization)
  - `lib/features/` : 도메인/기능 모듈 (예: user, pilgrimage, live_schedule, stats 등)
- `test/` : unit/widget 테스트
- `integration_test/` : 통합 테스트 (플로우/네비게이션)
- `assets/` : 이미지, 폰트, lottie, json 등
- `docs/` : ADR, 설계 다이어그램, UX 플로우
- `scripts/` : 코드 생성, 릴리즈 자동화 등

---

## Commands

- Build:
  - `flutter pub get`
  - `flutter build apk` / `flutter build ios` / `flutter build web`
- Run (local):
  - `flutter run` (디바이스/에뮬레이터 지정)
- Test:
  - `flutter test`
  - `flutter test integration_test` (필요 시)
- Lint/Format:
  - `dart format .`
  - `flutter analyze`

---

## Tools / Boundaries

- 허용 툴:
  - 코드 읽기/검색: Read, Grep, Glob
  - 코드 수정: Edit, MultiEdit, Write
  - 스크립트/명령: Bash (Flutter/Dart 관련 명령만)
  - WebFetch: Flutter/Dart 공식 문서, 패키지 메타데이터(pub.dev) 조회

- **금지:**
  - iOS/Android 네이티브 설정(`android/`, `ios/`)의 위험한 변경 (서명/프로비저닝 등)
  - 프로덕션 API 키/시크릿 노출
  - 배포 파이프라인(스토어 업로드) 직접 변경

- 외부 네트워크 접근은 **문서/공식 레지스트리/패키지 메타데이터** 범위로 제한.

---

## Memory / Artifacts

- 의미 있는 작업 후 반드시:
  - `CHANGELOG.md`에 요약 기록
  - `docs/adr/ADR-YYYYMMDD-<topic>.md` 작성
    - 변경 전 문제 / 대안 / 결정 / 근거 / 영향 범위
  - `TODO.md`에 남긴 임시 조치/부채와 제거 기준을 명시

---

## Security & Secrets

- 모든 시크릿(API 키, 클라이언트 시크릿 등)은:
  - 런타임 환경(.env, .json config, native secure storage)에서 주입
  - **코드/깃에 절대 커밋 금지**
- TLS/HTTPS만 사용하고, self-signed / insecure HTTP는 개발용에서만 사용.
- 민감한 로깅(토큰, 패스워드, 주민번호 등)은 금지.

---

## Approval Rules (에이전트)

- 대규모 리팩토링/디렉터리 구조 변경/라우팅 전략 변경은  
  **Plan 문서(텍스트) → 사용자 승인** 후 진행.
- 테스트 커버리지:
  - 기존 대비 **하락 금지** (widget/unit/integration 조합 기준).
- 성능:
  - 스크롤 시 잦은 jank(프레임 드랍) 유발 변경 금지.
  - 리스트/애니메이션 추가 시 성능 영향 분석 메모를 남긴다.

---

## Escalation

- 요구사항이 불명확하거나 UX/설계 충돌 발견 시:
  1. 작업 중단
  2. 질문/모호점 목록 작성
  3. 사용자의 승인/답변을 받은 뒤 진행

- 외부 문서 인용 시:
  - **출처 링크/버전**(Flutter SDK 버전, 패키지 버전)을 ADR에 남긴다.

---

## Flutter 전용 추가 지침

- 이 리포지토리는 **Flutter (Dart) 애플리케이션**을 위한 것입니다.
- 새로운 화면, 위젯, 상태 관리 로직을 작성하기 전에 반드시 아래를 먼저 수행합니다.
    1. `AGENTS.md`를 읽고 전체 아키텍처·코딩 규칙을 파악한다.
    2. 변경 범위(어떤 feature / layer / 파일)에 대한 **간단한 Plan**을 텍스트로 작성한다.
    3. 위젯 트리 영향 범위(부모/자식 위젯, Router 경로, Provider/Bloc 의존성)를 정리한다.
- 코드를 수정할 때는:
    - **구조(architecture)**: presentation / application(state) / domain / data 계층을 유지한다.
    - **상태 관리**: 기존 프로젝트에서 채택한 패턴(Riverpod, BLoC, Provider 등)을 그대로 따른다.
    - **테스트**: 새로운 기능에는 최소한의 widget/unit 테스트를 추가한다.
- 항상 `AGENTS.md`에 정의된 **Effective Dart 스타일, 이중 언어(EN/KO) 주석 규칙, 테스트·성능·접근성 체크리스트**를 우선적으로 따른다.

## Detailed guides (load on demand)
Open the skill before code changes; the root keeps only always-on rules.
- `.agents/skills/gbt-app-conventions/SKILL.md` — girlsbandtabi_app conventions: multi-CLI collaboration protocol (Codex/Claude/Gemini), Google + Effective Dart coding and commenting standard, API client and networking principles (dio), architecture and encapsulation rules, self-review checklist. Load before writing or reviewing Dart/Flutter code or touching the API client layer.

## Skills (load on demand, by name)
- Project: `gbt-app-conventions` (in `.agents/skills/`)
- Global: `dart-flutter-patterns`, `e2e-testing`, `backend-patterns`, `frontend-patterns`, `coding-standards`, `tdd-workflow`, `security-review`, `systematic-debugging`, `writing-plans`, `verification-loop`
