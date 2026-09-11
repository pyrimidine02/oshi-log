# 아키텍처 점검 보고서

> **2026-09-11 보정:** 아래 내용은 2026-03-05의 과거 점검 기록이며 현재
> 구현 상태를 나타내지 않습니다. 현재 결정과 검증은
> [Oshi-log 리팩토링 ADR](../adr/ADR-20260911-oshilog-architecture-and-release-channels.md)을
> 따릅니다. 특히 `FutureProvider` 안의 `ref.watch`를 일괄 `ref.read`로 바꾸면
> 의존성 갱신이 끊길 수 있습니다. 비동기 작업 이후의 수명과 구독을 각각
> 확인해야 합니다. `StateNotifier` 자체는 현재 Riverpod 2.x 앱의 결함이
> 아니며, domain → data 의존성을 예외로 허용하는 과거 권고는 철회합니다.

> **작성일**: 2026-03-05
> **점검 방법**: 정적 분석 (sub-agent 3개 병렬 실행)
> **점검 범위**: 의존성 방향, Riverpod 상태관리, 라우터/보안/테스트

---

## 1. 레이어 구조 개요

```
lib/
├── core/               # 공유 유틸, DI, 디자인 시스템, 라우터
├── features/           # 기능별 모듈 (30+ feature)
│   └── <feature>/
│       ├── presentation/   # Widget, Page
│       ├── application/    # Controller (StateNotifier), Service
│       ├── domain/         # Entity, Repository interface
│       └── data/           # DTO, DataSource, RepositoryImpl
└── main.dart
```

현재 프로젝트는 **Clean Architecture** 4계층 구조를 따르고 있으며, 전반적으로 레이어 분리가 잘 유지되고 있습니다.

---

## 2. 의존성 방향 위반

### 2-1. Domain → Data 역방향 임포트 (24개 파일)

Clean Architecture 원칙상 domain 계층은 data 계층을 몰라야 합니다.
현재는 **domain/entities/*.dart 파일들이 data/dto/*.dart를 직접 import**합니다.

```
// 예시 패턴 (의도적 설계이나 원칙 위반)
// lib/features/places/domain/entities/place_entities.dart
import '../../data/dto/place_dto.dart';  // ← data → domain 역방향

factory Place.fromDto(PlaceDto dto) { ... }
```

**영향 받는 feature**: places, visits, projects, live_events, feed, verification, notifications, settings, favorites, uploads, etc. (전 feature에 걸쳐 있음)

**현재 선택의 이유**: `fromDto` factory 패턴을 entity에 두어 매핑 로직을 한 곳에 모은 의도적 설계.

**개선 방안 (선택 사항)**:
```
Option A: 현상 유지 — 실용적, 팀 컨벤션으로 문서화
Option B: Mapper 클래스 분리 — data 계층에 PlaceMapper 생성
Option C: DTO를 domain 패키지로 이동 (shared DTO)
```

> **권고**: Option A (현상 유지 + 문서화). 26개 파일을 일괄 리팩토링할 위험 대비 실익이 적음.

---

### 2-2. Core → Feature 역방향 임포트 (1개 파일) ⚠️

```
// lib/core/widgets/navigation/gbt_profile_action.dart:12
import 'package:oshi_log/features/settings/application/settings_controller.dart';
```

core 위젯이 특정 feature의 controller를 직접 참조하고 있습니다. core 패키지는 어떤 feature도 알아서는 안 됩니다.

**개선 방안**: 콜백(VoidCallback / callback parameter)으로 의존성 역전, 또는 core용 별도 프로바이더 추출.

---

### 2-3. Uploads domain → Data DTO 임포트

```
// lib/features/uploads/domain/repositories/uploads_repository.dart:6
import '../../data/dto/upload_dto.dart';
```

Repository **인터페이스**(domain)가 DTO(data)를 메서드 시그니처에 사용하고 있습니다. 인터페이스는 domain entity만 참조해야 합니다.

---

## 3. Riverpod 상태관리 이슈

### 3-1. autoDispose 전무 (심각) ⚠️

```
전체 프로바이더 수: ~120개
autoDispose 적용: 0개
family 프로바이더: 21개 (모두 autoDispose 미적용)
```

`.family` 프로바이더는 인수가 다를 때마다 새 인스턴스를 생성하고, `autoDispose` 없이는 절대 해제되지 않습니다.
특히 ID 기반 `.family`는 화면을 반복 탐색할수록 메모리가 선형 증가합니다.

**영향 받는 주요 family 프로바이더**:
| 프로바이더 | 위치 | 위험도 |
|-----------|------|--------|
| `placeDetailProvider(placeId)` | places_controller.dart | 높음 |
| `visitSummaryProvider(placeId)` | visits_controller.dart | 높음 |
| `liveEventDetailProvider(eventId)` | live_events_controller.dart | 높음 |
| `postDetailProvider(postId)` | feed_controller.dart | 높음 |
| `memberDetailProvider(memberId)` | projects_controller.dart | 중간 |

**수정 방법**:
```dart
// Before
final placeDetailProvider = FutureProvider.family<Place, String>((ref, id) async { ... });

// After
final placeDetailProvider = FutureProvider.autoDispose.family<Place, String>((ref, id) async { ... });
```

---

### 3-2. FutureProvider 내 `await ref.watch(...)` 오용 ⚠️

`ref.watch()`는 동기 컨텍스트(build/notifier body)에서만 사용해야 합니다.
`FutureProvider` async 본문에서 `await ref.watch()`를 사용하면 재구독이 정상 동작하지 않습니다.

**확인된 위치**:
```
lib/features/places/application/places_controller.dart
lib/features/visits/application/visits_controller.dart
lib/features/home/application/home_controller.dart
lib/features/feed/application/feed_controller.dart
lib/core/providers/core_providers.dart
```

**수정 방법**: `ref.watch()` → `ref.read()` 로 교체 (FutureProvider async body 내부)

---

### 3-3. feed_controller.dart 비대화 (구조적 문제)

```
lib/features/feed/application/feed_controller.dart
  ├── 라인 수: 848줄
  ├── Controller 클래스: 8개
  └── Provider: 12개
```

단일 파일에 게시판, 공지, 멤버, 유닛, 리액션, 댓글 등 여러 도메인이 혼재합니다.

**권고 분리안**:
```
feed/application/
├── board_controller.dart      # 게시판 목록/상세
├── post_controller.dart       # 게시글 작성/수정/삭제
├── member_controller.dart     # 멤버 관련
├── unit_controller.dart       # 유닛 관련
└── reaction_controller.dart   # 리액션/댓글
```

---

### 3-4. StateNotifier vs AsyncNotifier 패턴

```
StateNotifier<AsyncValue<T>> 사용: 34개 전체
AsyncNotifier 사용: 0개
```

현재 모든 컨트롤러가 구버전 `StateNotifier<AsyncValue<T>>` 패턴을 사용합니다.
Riverpod 2.x부터는 `AsyncNotifier` / `AsyncNotifierProvider`가 표준이며 보일러플레이트가 적습니다.

> **권고**: 신규 컨트롤러는 `AsyncNotifier` 패턴 사용. 기존은 점진적 교체.

---

## 4. 라우터 / 보안

### 4-1. 인증 가드 미완성 (보안 취약점) ⚠️

`lib/core/router/app_router.dart`의 `redirect` 로직:

```dart
// 현재 코드 (문제 있음)
redirect: (context, state) {
  final isLoggedIn = ref.read(isAuthenticatedProvider);
  final isAuthRoute = state.matchedLocation == AppRoutes.login || ...;

  if (isLoggedIn && isAuthRoute) return AppRoutes.home;
  return null;  // ← 비로그인 + 보호 경로일 때 null 반환 → 통과됨!
}
```

비로그인 사용자가 `/settings`, `/favorites` 등 보호된 경로에 직접 URL로 접근 가능합니다.

**수정 코드**:
```dart
redirect: (context, state) {
  final isLoggedIn = ref.read(isAuthenticatedProvider);
  final isAuthRoute = state.matchedLocation == AppRoutes.login ||
                      state.matchedLocation == AppRoutes.register;
  final isPublicRoute = state.matchedLocation == AppRoutes.home ||
                        state.matchedLocation.startsWith('/info');

  if (!isLoggedIn && !isAuthRoute && !isPublicRoute) {
    return '${AppRoutes.login}?redirect=${Uri.encodeComponent(state.uri.toString())}';
  }
  if (isLoggedIn && isAuthRoute) return AppRoutes.home;
  return null;
},
```

---

### 4-2. `state.extra` 강제 캐스팅 (충돌 위험) ⚠️

```dart
// app_router.dart:299
final args = state.extra as Map<String, dynamic>;  // NPE 위험

// app_router.dart:332
final visitId = (state.extra as Map<String, dynamic>)['visitId'] as String;

// app_router.dart:349
final data = state.extra as SomeType;
```

`state.extra`가 null이거나 예상과 다른 타입일 경우 런타임 크래시가 발생합니다.

**수정 방법**:
```dart
final args = state.extra as Map<String, dynamic>?;
if (args == null) return const SomeFallbackWidget();
```

---

### 4-3. 프로덕션 로그 노출

```dart
// lib/core/logging/app_logger.dart
// debugLogDiagnostics: true  — app_router.dart에 하드코딩
// AppLogger.info/warning/error — kDebugMode 가드 없음
```

**수정 방법**:
```dart
// app_router.dart
debugLogDiagnostics: kDebugMode,

// app_logger.dart
static void info(String msg, ...) {
  if (kDebugMode) print('[INFO] $msg');
}
```

---

## 5. 코드 중복

### 5-1. 팔레트 유틸

```
_kPalette (List<Color>) : 3개 파일에 동일하게 선언
_pc / _paletteColor (함수): 3개 파일에 동일하게 선언
```

**권고**: `lib/core/utils/palette_utils.dart` 추출 후 공통 사용.

### 5-2. `_daysUntilBirthday` 함수

```
lib/features/projects/...member_detail_page.dart
lib/features/projects/...unit_detail_page.dart
```

두 파일에 동일한 함수 로직이 중복됩니다.

**권고**: `lib/core/utils/date_utils.dart` (또는 기존 utils 파일)에 추출.

---

## 6. 미사용 패키지

`pubspec.yaml`에 선언되어 있으나 코드베이스에서 실제 사용이 확인되지 않는 패키지:

| 패키지 | 비고 |
|--------|------|
| `graphql_flutter` | REST API 전환으로 미사용 추정 |
| `freezed` / `freezed_annotation` | DTO에 미사용 |
| `json_serializable` | 수동 fromJson/toJson 사용 |
| `equatable` | 수동 == 구현 사용 |
| `table_calendar` | 캘린더 UI 미사용 추정 |
| `flutter_sfsymbols` | SF Symbols 직접 참조 없음 |
| `crypto` | 직접 import 없음 |
| `patrol` | 통합 테스트 미사용 |
| `faker` | 테스트 외 미사용 |

**확인 후 제거 시 빌드 속도 및 앱 용량 개선 가능**.

```bash
# 확인 명령
flutter pub deps | grep <package_name>
dart pub deps --style=list
```

---

## 7. 테스트 커버리지

```
전체 테스트 파일: 29개
├── DTO 직렬화 테스트: 19개 ✅
├── Widget 테스트: 2개
├── Repository 테스트: 2개
├── Application 로직 테스트: 2개
├── Core 유틸 테스트: 2개
└── Controller 테스트: 0개 ❌
```

**가장 중요한 미테스트 영역**:
- `VerificationController` — 인증 핵심 로직
- `feed_controller.dart` — 8개 컨트롤러 전부 미테스트
- `SettingsController` — 이의제기 제출 등 중요 액션

---

## 8. 요약 위험도 매트릭스

| 항목 | 심각도 | 긴급도 | 난이도 |
|------|--------|--------|--------|
| 인증 가드 미완성 | 🔴 높음 | 🔴 즉시 | 🟢 낮음 |
| family 프로바이더 autoDispose 누락 | 🟠 중간 | 🟠 단기 | 🟢 낮음 |
| FutureProvider await+watch 오용 | 🟠 중간 | 🟠 단기 | 🟢 낮음 |
| state.extra 강제 캐스팅 | 🟠 중간 | 🟠 단기 | 🟢 낮음 |
| feed_controller.dart 비대화 | 🟡 낮음 | 🟡 중기 | 🟠 중간 |
| Domain→Data 역방향 임포트 | 🟡 낮음 | 🟡 중기 | 🔴 높음 |
| Core→Feature 역방향 임포트 | 🟠 중간 | 🟡 중기 | 🟢 낮음 |
| 프로덕션 로그 노출 | 🟠 중간 | 🟠 단기 | 🟢 낮음 |
| Controller 테스트 부재 | 🟡 낮음 | 🟡 중기 | 🟠 중간 |
| 미사용 패키지 | 🟢 낮음 | 🟡 중기 | 🟢 낮음 |
