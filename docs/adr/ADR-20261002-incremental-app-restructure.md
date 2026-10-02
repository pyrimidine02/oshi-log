# ADR-20261002: 점진 앱 재구조화 — 의존 규칙, 허용 목록, PR 순서

**Status:** Approved 2026-10-02

**Updated:** 2026-10-02

---

## Summary

oshi@log 재구조화를 빅뱅 재작성 대신 **점진(strangler)** 방식으로 진행한다. 기존 repository·provider·라우트를 유지하며, feature 경계를 업무 소유권(oshikatsu·place·community·identity·shared·platform)으로 재편성한다. PR 1과 후속 정리 커밋에서 미라우팅 레거시 코드 약 16,900줄(PR 1: 13,451줄, 정리: 3,434줄)을 삭제하고, 각 PR마다 **축소하는 허용 목록(shrinking allowlist) 검사**로 신규 위반을 차단한다. Riverpod·GoRouter는 유지.

---

## Decision

### 의존 규칙 (R1–R6)

| 규칙 | 내용 |
|---|---|
| **R1 레이어** | presentation → application → domain. data → domain + platform. DTO 변환은 data에서 끝냄 |
| **R2 feature 간** | 다른 하위 feature의 **domain 타입과 공개 provider**(`<feature>/<feature>.dart` 배럴)만 import. data·내부 controller·페이지 직접 참조 금지 |
| **R3 조합** | 여러 업무를 잇는 흐름(홈, 마이, 로그아웃 정리)은 `app/` 조립 계층에서 구성 |
| **R4 platform** | platform → features 금지. design_system → features 금지 |
| **R5 순환** | 하위 feature 간 순환 금지 |
| **R6 상태 소유** | 세션(auth), 관심 프로젝트(oshikatsu/catalog), 탭 상태(app/shell) 중앙화 |

### 구조 재편성

**주요 변경:**
- feed 해체: 아티스트 → oshikatsu/catalog, 뉴스 → community/news, 여행후기 → community/reviews, 게시판 → community/posts
- place 순환 제거: places/visits/verification/collections 간 의존성 정리, 흐름은 app에서 조합
- core 역방향 import 0: 라우터·알림·조합은 app/에서만 feature 참조
- 라우터 분할: 경로 상수/guard/shell/도메인별 routes로 분리 (동작 변경 없음)

기존 Riverpod 유지, StateNotifier → AsyncNotifier 일괄 교체 및 codegen 도입은 미실시.

### 축소하는 허용 목록 (Shrinking Allowlist)

**목표:** 각 PR마다 허용 목록 진입 수가 감소해야 함.

- 기준선(현재): 133개 위반 기록
- PR 2 도입 시 133건, PR 3(라우터 분할) 후 74건
- PR 2(경계 검사 확장): 신규 위반 금지, 기존 예외만 제거 가능
- PR 8 최종: 0개 목표

**검사 범위:** 상대·package URI 정규화, 배럴 export 추적, R2·R4·R5 위반 감지. `test/architecture/layer_import_boundary_test.dart` 기준.

---

## PR 순서 및 레거시 삭제 규모

### 주요 마일스톤

| # | 항목 | 내용 | 통과 조건 |
|---|---|---|---|
| **0** | 기준선 | 의존 그래프 스냅샷, 라우트 목록·인증·로그아웃 계약 테스트 강화 | 기존/신규 실패 구분 |
| **1** | **레거시 삭제** | 7 파일 12,140줄 + 사용 종료 provider 정리 | analyze/test 통과, 허용 목록 감소 |
| **2** | 경계 검사 확장 | R1–R6 정규화 검사, 허용 목록 점진 축소 | 신규 위반 0 |
| **3** | 라우터 분할 | 경로 상수/guard/shell/routes, 동작 불변 | 딥링크·로그인 복귀·탭 스택 |
| **4** | 일본어 기반 | fallback 정의, 핵심 여정 하드코딩 제거, ja golden | ja/ko/en 테스트·golden |
| **5** | app 조립 계층 | session orchestration, compositions 이동, R4 0 | 로그아웃·계정 전환·outbox 격리 |
| **6** | feed 해체 | 아티스트/뉴스/여행후기/게시판 이동 | URL·테스트 유지, 허용 목록 감소 |
| **7** | place 순환 제거 | 의존성 정리 | 순환 간선 0 |
| **8** | 최종 이동 | oshikatsu/identity/shared로 폴더 이동 | 허용 목록 0 목표 |
| **9** | **IA 적용** | 5탭 재배치, 커뮤니티 바 교체 제거, 라이브 허브, 음악 경로 | 탭 순서·상태·비로그인 접근 |
| **10+** | 화면 단위 재구성 | screen-design-v1.md 기준 화면별 | 해당 widget/provider 테스트, golden |

### 레거시 삭제 규모 (PR 1)

**12,140줄 삭제 대상:**
- `HomePage` (1,156줄)
- `BoardPage` (4,818줄)
- `InfoPage`, `UserProfilePage`, `MyPage`, `LiveEventDetailPage`, `ZukanPage` (6,166줄)

**별도 확인:** `test/core/branding/brand_contract_test.dart`가 Board/Home 파일을 직접 읽음 → 대체 화면으로 마이그레이션 필요.

추가 미라우팅 레거시(~4,800줄)는 개별 검증 후 병렬 PR로 처리 가능.

---

## 검사 메커니즘

**PR 2에서 도입:**
- 상대 경로(`../../`) 및 package URI(`package:oshi_log/...`) 정규화
- 배럴 export(`lib/features/oshikatsu/oshikatsu.dart`) 추적
- 각 파일의 import를 전개하여 실제 의존 대상 확인
- 현재 위반 133개를 허용 목록에 기록
- **신규 위반 감지 시 fail**
- 기존 목록 감소만 허용

---

## 검증 및 제약

- **빅뱅 재작성 거절:** 인증·오프라인 큐·딥링크·지도 수명을 전부 재증명해야 하고, 190개 기존 테스트와 정상 data 계층을 버림
- **이동과 동작 변경 분리:** 같은 PR에서 두 작업을 섞지 않음
- **API 필드·nullability·저장 키 불변:** 레거시 테스트와 사용자 기기 호환성 보장
- **테스트 커버리지:** 기존 대비 하락 금지 (AGENTS.md 규칙)
- **통합 테스트:** integration_test/ 없음 → PR 0은 위젯/계약 테스트로 라우트·redirect·계정 전환 정리를 고정. 실제 integration_test 여정은 IA 적용(PR 9) 전에 추가(TODO)

---

## 위험 관리

| 위험 | 대응 |
|---|---|
| 폴더 이동으로 대규모 import diff | 이동 PR은 짧게, 즉시 rebase |
| 로그아웃 정리 중 데이터 누수 | PR 0에서 계정 A→B 전환 테스트 선행 |
| 딥링크·푸시 경로 깨짐 | PR 0 라우트 스냅샷, 기존 경로 유지 |
| 커버리지 하락 | 레거시 테스트와 신규 테스트 분리 기록 |

---

## 근거

- `app-architecture-redesign-v1.md` §2–§3: 목표 구조, 점진 이행 이유
- 기존 테스트 190개 및 data 계층의 신뢰도
- 프로덕션 사용자에 대한 회귀 위험 최소화

---

## References

- `docs/product/app-architecture-redesign-v1.md` v1
- `test/architecture/layer_import_boundary_test.dart` (현재 133개 허용 목록)
- Commits: ad85c49..eb600ae (2026-09-11..2026-10-02)
