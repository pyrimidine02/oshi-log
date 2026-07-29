# 아키텍처 개선 로드맵

> **기준일**: 2026-03-05
> **근거 문서**: [ARCHITECTURE_REVIEW.md](./ARCHITECTURE_REVIEW.md)
> **우선순위 기준**: 보안 위험 > 런타임 안정성 > 성능 > 유지보수성

---

## Phase 1 — 즉시 수정 (1~2일)

### P1-1. 인증 가드 완성
**파일**: `lib/core/router/app_router.dart`

```dart
// redirect 콜백 수정
redirect: (context, state) {
  final isLoggedIn = ref.read(isAuthenticatedProvider);
  final loc = state.matchedLocation;
  final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.register;
  final isPublicRoute = loc == AppRoutes.home ||
                        loc.startsWith('/info');  // 비로그인 허용 경로 추가

  if (!isLoggedIn && !isAuthRoute && !isPublicRoute) {
    return '${AppRoutes.login}?redirect=${Uri.encodeComponent(state.uri.toString())}';
  }
  if (isLoggedIn && isAuthRoute) return AppRoutes.home;
  return null;
},
```

---

### P1-2. state.extra 안전 캐스팅
**파일**: `lib/core/router/app_router.dart` (라인 299, 332, 349 근방)

```dart
// Before (크래시 위험)
final args = state.extra as Map<String, dynamic>;

// After (안전)
final args = state.extra as Map<String, dynamic>?;
if (args == null) return const ErrorPage(message: 'Invalid navigation');
```

---

### P1-3. 프로덕션 로그 가드
**파일**: `lib/core/logging/app_logger.dart`, `lib/core/router/app_router.dart`

```dart
// app_router.dart
debugLogDiagnostics: kDebugMode,

// app_logger.dart — 각 메서드에 추가
if (!kDebugMode) return;
```

---

## Phase 2 — 단기 개선 (1~2주)

### P2-1. family 프로바이더 autoDispose 일괄 적용

대상 21개 `.family` 프로바이더 전체에 `.autoDispose` 추가.

```dart
// 패턴 교체 (sed 또는 수동)
FutureProvider.family      →  FutureProvider.autoDispose.family
StreamProvider.family      →  StreamProvider.autoDispose.family
StateNotifierProvider.family → StateNotifierProvider.autoDispose.family
```

**우선 처리 대상** (화면 반복 진입 빈도 높음):
- `placeDetailProvider`
- `visitSummaryProvider`
- `liveEventDetailProvider`
- `postDetailProvider`
- `memberDetailProvider`

---

### P2-2. FutureProvider 내 ref.watch → ref.read 교체

**대상 파일**:
```
lib/features/places/application/places_controller.dart
lib/features/visits/application/visits_controller.dart
lib/features/home/application/home_controller.dart
lib/features/feed/application/feed_controller.dart
lib/core/providers/core_providers.dart
```

```dart
// Before (FutureProvider async body 내부)
final user = await ref.watch(userProvider.future);

// After
final user = await ref.read(userProvider.future);
```

---

### P2-3. Core → Feature 역방향 임포트 제거
**파일**: `lib/core/widgets/navigation/gbt_profile_action.dart`

```dart
// Before
import 'package:oshi_log/features/settings/application/settings_controller.dart';

// After: 콜백 파라미터로 역전
class GbtProfileAction extends StatelessWidget {
  const GbtProfileAction({super.key, required this.onTap});
  final VoidCallback onTap;
  // ...
}
```

---

### P2-4. 팔레트 유틸 중복 제거

```
신규: lib/core/utils/palette_utils.dart
  - kPalette: List<Color>
  - paletteColor(int index): Color

제거 대상:
  - lib/features/projects/.../member_detail_page.dart (_kPalette, _pc)
  - lib/features/projects/.../unit_detail_page.dart (_kPalette, _pc)
  - lib/features/feed/.../... (_kPalette 또는 유사)

신규: lib/core/utils/date_utils.dart (또는 기존 파일)
  - daysUntilBirthday(DateTime birthday): int?
```

---

### P2-5. 미사용 패키지 제거

확인 후 제거:
```yaml
# pubspec.yaml에서 제거 대상
graphql_flutter:
freezed:
freezed_annotation:
json_serializable:
equatable:
table_calendar:
flutter_sfsymbols:
crypto:
patrol:       # 통합 테스트 사용 전까지 보류
faker:
```

```bash
flutter pub remove graphql_flutter equatable table_calendar
```

---

## Phase 3 — 중기 리팩토링 (1~2개월)

### P3-1. feed_controller.dart 분리

```
Before: feed_controller.dart (848줄, 8 controller)

After:
  feed/application/
  ├── board_controller.dart      # BoardController, boardProvider
  ├── post_controller.dart       # PostController, postDetailProvider
  ├── member_controller.dart     # MemberController, memberDetailProvider
  ├── unit_controller.dart       # UnitController, unitDetailProvider
  └── reaction_controller.dart   # ReactionController, commentProvider
```

---

### P3-2. 핵심 Controller 테스트 추가

**우선순위 순**:
1. `VerificationController` — 인증 핵심 로직
2. `SettingsController` — 이의제기, 프로필 수정
3. `PlacesController` — 장소 목록/상세
4. `VisitsController` — 방문 기록

```
test/features/
├── verification/
│   └── verification_controller_test.dart
├── settings/
│   └── settings_controller_test.dart
└── places/
    └── places_controller_test.dart
```

---

### P3-3. StateNotifier → AsyncNotifier 점진적 전환

Riverpod 2.x 표준 패턴으로 신규 컨트롤러부터 적용:

```dart
// 신규 컨트롤러 작성 시
class NewController extends AsyncNotifier<SomeState> {
  @override
  Future<SomeState> build() async {
    return await _loadInitialData();
  }

  Future<void> doAction() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.doAction());
  }
}

final newControllerProvider = AsyncNotifierProvider<NewController, SomeState>(
  NewController.new,
);
```

---

### P3-4. Domain → Data 의존 정책 결정

세 가지 옵션 중 팀 합의 후 문서화:

**Option A (현상 유지)**: `fromDto`를 entity에 두는 것을 팀 컨벤션으로 명시.
```
// AGENTS.md에 추가:
// "domain/entities/*.dart는 자신의 feature data/dto/*.dart를 import할 수 있습니다.
//  이는 fromDto 패턴을 위한 의도적 예외입니다."
```

**Option B (Mapper 분리)**: data 계층에 `*_mapper.dart` 파일 추가.
```
data/
├── dto/place_dto.dart
└── mappers/place_mapper.dart  ← 여기서 DTO → Entity 변환
```

**Option C (Shared DTO)**: DTO를 domain 패키지로 이동 (대규모 리팩토링).

---

## 빠른 참조: 파일별 수정 우선순위

| 파일 | 수정 항목 | 우선순위 |
|------|-----------|---------|
| `core/router/app_router.dart` | 인증 가드, state.extra 안전 캐스팅, debugLogDiagnostics | P1 |
| `core/logging/app_logger.dart` | kDebugMode 가드 | P1 |
| `features/*/application/*_controller.dart` (21개) | autoDispose 추가 | P2 |
| `features/*/application/*_controller.dart` (5개) | ref.watch → ref.read | P2 |
| `core/widgets/navigation/gbt_profile_action.dart` | Feature import 제거 | P2 |
| `pubspec.yaml` | 미사용 패키지 제거 | P2 |
| `features/feed/application/feed_controller.dart` | 파일 분리 | P3 |
| `test/features/verification/` | Controller 테스트 추가 | P3 |
