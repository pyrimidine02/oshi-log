# oshi@log 앱 구조 재설계 계획 v1

- 작성일: 2026-10-02
- 상태: **Approved — 2026-10-02 사용자 승인 (AGENTS.md "대규모 리팩토링 → Plan → 승인")**
- 작성: Claude와 GPT astra 협의(3·4차). 수치는 2026-10-02 로컬 작업 트리 정적 측정. analyze/test는 아직 실행하지 않음.
- 상위 문서: `product-direction-v1.md`, `screen-design-v1.md`

---

## 1. 진단

### 수치

| 항목 | 값 |
|---|---|
| 규모 | `lib/` 515 파일, 154,049행, feature 26개, `core/` 91 파일·22,795행 |
| feed | 84 파일, 39,610행(앱의 26%). 게시판·뉴스·여행 후기·사용자 프로필·**밴드/멤버/성우 화면**까지 보유 |
| 800행 넘는 파일 | 29개. 살아 있는 화면 중 `music_song_detail_page.dart` 3,427행, `post_detail_page.dart` 3,335행, `places_map_page.dart` 2,079행 |
| 레거시(미라우팅) | `HomePage/BoardPage/InfoPage/UserProfilePage/MyPage/LiveEventDetailPage/ZukanPage` 7 파일, 12,140행. 외부 참조 없음. `test/core/branding/brand_contract_test.dart`가 Board/Home 파일을 직접 읽음 |
| 교차 feature import | 53 간선, 184 구문. `feed→projects` 26, `feed→settings` 12 등 |
| feature 순환 | 7개 feature가 하나의 강연결 요소: auth·feed·live_events·places·settings·verification·visits. 예: places → verification → visits → places |
| 라우터 | `core/router/app_router.dart` 1,570행, GoRoute 65개. 경로 상수·인증 redirect·페이지 생성·overlay·확장이 한 파일 |
| core 역방향 | core → feature 66 구문(5 파일). 라우터 59, 나머지는 공용 provider·알림 |
| provider 소유권 | `core_providers.dart`에 선택 프로젝트·유닛·탭·법률 정책이 섞임. auth가 다른 feature의 로그아웃 정리를 직접 호출(`auth_controller.dart:1366`) |
| l10n | 인라인 `context.l10n(ko:, en:, ja:)` 1,773회, ja 인자 누락 0. 하드코딩 한국어 `Text` 107~188건(측정 방식에 따라). 비지원 언어·누락 fallback이 ko. golden은 ko 고정 |
| 테스트 | `_test.dart` 190개, golden 3 소스·PNG 13, `integration_test/` 없음. 레이어 경계 테스트 존재(`test/architecture/layer_import_boundary_test.dart`) |

### 이미 괜찮은 것 (건드리지 않는다)

- presentation → data 직접 참조 0. domain → data 0. 레이어 방향은 지켜지고 있다.
- 디자인 시스템은 하나다. Field 위젯은 GBT 토큰 위에 있다(GBT 64, Field 82 클래스, KT 0). "디자인 시스템 3개" 진단은 틀렸다.
- `feed_controller.dart`는 이미 12행 배럴로 분리됨.
- Riverpod + repository + DTO 매핑 구조.

### 진짜 문제

1. **feature 경계가 업무 소유권이 아니라 개발 순서로 생겼다.** feed가 남의 도메인 화면을 갖고 있고, 7개 feature가 순환한다.
2. **조합 지점이 없다.** 홈·마이·로그아웃처럼 여러 도메인을 묶는 흐름이 core나 auth 안에 흩어져 있다.
3. **라우터가 단일 거대 파일.** 탭 재배치(IA 변경)를 하려면 1,570행 파일을 통째로 만져야 한다.
4. **죽은 코드 12k행**이 검색·리뷰·에이전트 컨텍스트를 오염시킨다.
5. **거대 화면 파일.** 상태·행동·표현이 한 파일에 섞여 있다.
6. **일본어 출시 기준 부재.** 번역 인자는 있으나 fallback·하드코딩·ja golden이 없다.

---

## 2. 목표 구조

탭은 탐색 구조, feature는 업무 소유권. 서버 모듈 이름은 **분류용 상위 폴더**로만 쓰고, 의존 경계는 하위 feature 단위로 둔다.

```
lib/
├── app/                       # 조립 계층: 업무 데이터 소유 안 함
│   ├── bootstrap/             # main, 환경, DI 조립
│   ├── router/                # 경로 상수, guard, shell, 도메인별 routes 등록
│   ├── shell/                 # 5탭 scaffold (홈/지도/라이브/커뮤니티/마이)
│   ├── session/               # 로그인·로그아웃 orchestration (계정 전환 정리)
│   └── compositions/          # 홈, 마이, 통합 검색 — 여러 feature 조합 화면
├── features/
│   ├── oshikatsu/
│   │   ├── catalog/           # project, unit, member, voice actor, fan subject (projects + feed의 아티스트 화면)
│   │   ├── music/             # 곡, 앨범, 가사, 콜, 크레딧
│   │   ├── live/              # 공연, 세트리스트, 캘린더, 응원 가이드, (신규) 티켓·계획
│   │   └── quotes/
│   ├── place/
│   │   ├── places/            # 장소, 지역, 가이드, 사진, 댓글
│   │   ├── visits/            # 방문 기록, 통계
│   │   ├── verification/      # 위치 인증, 이의 신청
│   │   └── collections/       # 도감 → 스폿집/코스
│   ├── community/
│   │   ├── posts/             # 게시글, 댓글, 반응, 북마크, 피드
│   │   ├── reviews/           # 여행 후기(레포)
│   │   ├── news/
│   │   └── moderation/        # 신고, 차단 보기, 관리 콘솔(admin_ops)
│   ├── identity/
│   │   ├── auth/
│   │   ├── account/           # 프로필, 설정, 동의, 프라이버시
│   │   ├── social/            # 팔로우, 차단
│   │   └── progression/       # 팬 레벨, 칭호, 배너
│   └── shared/                # favorites, uploads, notifications (서버 platform 대응)
├── platform/                  # HTTP, 보안 저장소, 캐시, 위치, 푸시 전달, SSE, 텔레메트리. feature import 0
└── design_system/             # GBT 토큰, 공용 위젯, Field 화면 위젯, l10n 헬퍼
```

각 하위 feature 안은 기존과 같다: `presentation / application / domain / data`.

### 의존 규칙

| 규칙 | 내용 |
|---|---|
| R1 레이어 | presentation → application → domain. data → domain + platform. DTO 변환은 data에서 끝 |
| R2 feature 간 | 다른 하위 feature의 **domain 타입과 공개 provider**(`<feature>/<feature>.dart` 배럴)만 import. data·내부 controller·페이지 직접 참조 금지 |
| R3 조합 | 여러 업무를 잇는 흐름(홈, 마이, 로그아웃 정리, 방문→인증→기록)은 `app/`에서 조합 |
| R4 platform | platform → features 금지. design_system → features 금지 |
| R5 순환 | 하위 feature 간 순환 금지 |
| R6 상태 소유 | 세션 = identity/auth, 관심 프로젝트 = oshikatsu/catalog, 탭 상태 = app/shell |

Riverpod 유지. StateNotifier → AsyncNotifier 일괄 교체, codegen 도입, use-case 클래스 일괄 추가는 하지 않는다. 새 의존성 없음.

### 라우팅

- `app/router/`가 조립과 인증 정책만 담당. 각 feature가 `routes.dart`로 자기 route 목록을 내놓는다.
- 경로 상수·인자 빌더는 UI 의존 없는 파일로 분리.
- 기존 URL·이름·별칭·root overlay·탭별 스택 보존. cold deep link는 `extra` 없이 ID로 복원.
- 음악 아카이브에 경로 추가.

### l10n (일본 메인)

- 인라인 헬퍼 유지. gen_l10n 전면 전환은 하지 않는다(외부 번역가 워크플로가 생기면 재검토).
- 정의 분리: (a) 지원하지 않는 단말 언어의 기본값 = **ja**, (b) 번역 누락 시 대체 = ja → en → ko. 사용자가 명시 선택한 ko/en은 유지.
- 노출 경로의 하드코딩 한국어 `Text` 제거.
- ja golden 추가. 공연 시각은 JST 기준 표시 정책 명시.

### 디자인 시스템

- GBT 토큰 단일 기준 유지. Field 이름은 화면 정체성으로 유지. 접두사 일괄 변경 금지.
- 실제 중복(커뮤니티 모드 바 ↔ 가이드 섹션 스위처 등)만 공용 표현으로 추출. enum·행동은 각 feature에 둔다.

---

## 3. 이행 전략: 점진(strangler)

| 방식 | 판단 |
|---|---|
| 빅뱅 재작성 | 인증·오프라인 큐·재시도·지도 수명·딥링크를 전부 다시 증명해야 한다. 테스트 190개와 정상 데이터 계층을 버리게 된다. **기각** |
| 점진 이행 | repository·provider를 유지하고 route·화면 단위로 옮긴다. PR마다 검증·되돌리기 가능. **채택** |

원칙: 이동과 동작 변경을 같은 PR에 섞지 않는다. 기존 API 필드·nullability·저장 키는 바꾸지 않는다.

### PR 순서

| # | PR | 내용 | 통과 조건 |
|---|---|---|---|
| 0 | 기준선 | 의존 그래프 스냅샷, 라우트 목록 스냅샷 테스트, 로그인 복귀·계정 A→B 전환·outbox 동작 테스트 보강 | 기존 실패와 신규 실패 구분 |
| 1 | **레거시 삭제** | 7 파일 12,140행 삭제. `brand_contract_test.dart` 검사 대상을 대체 화면으로 수정. 사용 종료 provider 함께 정리 | analyze, 전체 test, 라우트 목록 불변 |
| 2 | 경계 검사 확장 | `layer_import_boundary_test.dart`에 URI 정규화(상대/package), export 추적, R2·R4·R5 검사. 현재 위반은 허용 목록으로 기록하고 **신규 위반 금지·기존 예외 감소만 허용** | 검사기 자체 테스트(상대 경로, 배럴 우회, 순환 사례) |
| 3 | 라우터 분할 | 경로 상수 / guard / shell / 도메인별 routes 파일. 동작 변경 없음 | cold/warm deep link, 로그인 복귀, back, 탭 스택, overlay |
| 4 | 일본어 기반 | fallback 정의 변경, 핵심 여정의 하드코딩 제거, ja golden | 명시 언어/단말 언어/fallback 테스트, ja golden |
| 5 | app 조립 계층 | `app/session`(로그아웃 orchestration), `app/compositions`(홈·마이·검색), core의 역방향 import 제거 | 로그아웃·계정 전환·토큰 만료·outbox 격리, R4 위반 0 |
| 6 | feed 해체 | (a) 아티스트 화면 → oshikatsu/catalog (b) 뉴스 → community/news (c) 여행 후기 → community/reviews (d) 게시판 → community/posts | 기존 URL·화면 테스트, 허용 목록 감소 |
| 7 | place 정리 | places/visits/verification/collections 순환 제거. 방문→인증→기록 흐름은 app에서 조합 | 해당 순환 간선 0, 인증·방문 의미 보존 |
| 8 | 나머지 이동 | oshikatsu(music, live), identity, shared로 폴더 이동 | 허용 목록 최종 0 목표 |
| 9 | **IA 적용** | 5탭 재배치(홈/지도/라이브/커뮤니티/마이), 커뮤니티 하단 바 교체 제거, 라이브 허브, 음악 아카이브 경로 | 탭 순서·상태 유지, 비로그인 접근, 저장 후 재진입 |
| 10+ | 화면 단위 재구성 | `screen-design-v1.md` 기준으로 화면별. 거대 화면은 상태·행동·표현으로 분리 | 해당 widget/provider 테스트, ja/ko·light/dark·320dp·200% golden |

IA 적용(9)을 구조 정리 뒤에 두는 이유: 라우터 분할(3)과 조립 계층(5)이 끝나야 탭 재배치가 파일 몇 개 수정으로 끝난다. 화면 재구성(10+)은 서버 신규 계약이 필요한 화면(티켓, 계획)과 아닌 화면(지도, 곡 상세)을 나눠 병렬로 진행할 수 있다.

### 매 PR 공통

- `dart format`, `flutter analyze`, `flutter test --no-pub`.
- UI 변경 PR은 golden 실행. 실패를 일괄 baseline 갱신으로 덮지 않는다.
- `integration_test`(SDK 포함, 새 패키지 없음)는 핵심 여정부터: 게스트 탐색 → 저장 → 로그인 복귀, 계정 교체, 위치 권한 거부, 외부 티켓 링크 복귀.
- 각 PR에 ADR(`docs/adr/`)과 CHANGELOG 기록(AGENTS.md).

---

## 4. 위험

| 위험 | 대응 |
|---|---|
| 폴더 이동으로 대규모 import diff → 다른 작업과 충돌 | 이동 PR은 짧게, 머지 직후 다른 브랜치 rebase. 현재 미커밋 작업(작업 트리 30여 파일)을 먼저 정리·커밋 |
| 로그아웃 정리 이동 중 계정 데이터 누수 | PR 0에서 계정 A→B 전환 테스트 선행 |
| 딥링크·푸시 경로 깨짐 | PR 0 라우트 스냅샷, `girlsbandtabi://` 스킴·기존 경로 유지 |
| 커버리지 하락(AGENTS.md 금지) | 삭제 PR은 레거시 전용 테스트만 제거, 커버리지 비교 기록 |

---

## 5. 승인 요청

1. 목표 구조(§2)와 의존 규칙 R1–R6.
2. 점진 이행과 PR 순서(§3). 특히 PR 1(레거시 삭제)을 먼저 하는 것.
3. 시작 전 현재 미커밋 변경을 먼저 커밋할지(권장) 여부.
