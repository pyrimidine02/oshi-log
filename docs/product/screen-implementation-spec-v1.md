# 화면 구현 명세 PR9–PR21 v1

- 작성: GPT astra (gpt-6-astra), 2026-10-02
- 상위: `screen-design-v1.md`, `app-architecture-redesign-v1.md`
- 실행 규칙: router/shell/nav, route inventory, 공용 배럴, CHANGELOG는 통합 담당 1명.

읽기 전용 실행 명세. 파일·git 변경, 테스트 실행 없음. **PR6–8 이동 완료 후 PR9 착수**, 아래 경로는 관측 시점 기준이며 이동 후 같은 심볼의 최종 경로에 적용합니다.

우선순위는 **공연 준비 → 장소 현장 이용 → 홈 → 일정 → 기록·저장 → 지도 → 음악**. GBT 토큰·Riverpod 유지, 목록 밀도는 조밀하게 만들지 않습니다. [구조·PR 순서](/Users/sonhoyoung/dev/oshi-log-redesign/docs/product/app-architecture-redesign-v1.md:127), [밀도 결정](/Users/sonhoyoung/dev/oshi-log-redesign/docs/product/screen-design-v1.md:306).

**계약 대조에서 확인한 보정**

- **취소·연기:** 앱에는 `scheduleStatus/rescheduledEventId` 대응이 있지만, 확인한 서버 DTO에는 없습니다. 서버 `status`만으로 `中止/変更`를 확정할 수 없습니다. S2 회신에 상세·목록의 일정 상태 계약도 보완해야 합니다. [앱](/Users/sonhoyoung/dev/oshi-log-redesign/lib/features/live_events/domain/entities/live_event_entities.dart:114), [서버 DTO](/Users/sonhoyoung/Documents/00_소스코드/oshilog-api/server/src/main/kotlin/org/pyrimidines/oshilog/oshikatsu/event/dto/LiveEventDtos.kt:16), [서버 상태 계산](/Users/sonhoyoung/Documents/00_소스코드/oshilog-api/server/src/main/kotlin/org/pyrimidines/oshilog/oshikatsu/event/service/LiveEventService.kt:819).
- **게시글 저장:** 통합 Favorite는 PLACE/NEWS/LIVE이지만 별도 게시글 북마크 목록 API가 있습니다. 마이 保存에 조합 가능. 곡·스폿집 저장은 S11 대기. [북마크 API](/Users/sonhoyoung/Documents/00_소스코드/oshilog-api/server/src/main/kotlin/org/pyrimidines/oshilog/community/gateway/MyPostBookmarkController.kt:26).
- **공개 읽기:** 장소·공연 외 뉴스·캘린더도 공개 GET 대상입니다. 홈·음악·도감·커뮤니티·검색 공개는 S1 대기. 앱 라우트 개방과 서버 공개를 구분합니다. [서버 보안 설정](/Users/sonhoyoung/Documents/00_소스코드/oshilog-api/server/src/main/kotlin/org/pyrimidines/oshilog/identity/security/SecurityConfig.kt:350).
- 요청서에는 **S3가 없습니다**. 번호를 새 의미로 채우지 않습니다. 티켓 회차·마감·당락·입금 관리는 계속 제외. [요청서](/Users/sonhoyoung/dev/oshi-log-redesign/docs/backend-api-requests/2026-10-02-product-direction-sync.md:16).

**PR9 — IA 적용 / 규모 중대**

현재 `StatefulShellRoute.indexedStack` 유지. 브랜치와 `NavIndex`를 함께 변경합니다. [라우터](/Users/sonhoyoung/dev/oshi-log-redesign/lib/app/router/app_router.dart:45), [인덱스 계약](/Users/sonhoyoung/dev/oshi-log-redesign/lib/core/router/app_router.dart:144).

| 인덱스 | 탭 KO / JA | 대표 URL | 루트 위젯·구성 |
|---|---|---|---|
| 0 | 홈 / ホーム | `/home` | 기존 `FieldHomePage` |
| 1 | 지도 / マップ | `/map` | 신규 `FieldMapHubPage`: `PlacesMapPage(embedded: true)` + `FieldZukanArchivePage`의 スポット/スポット集 전환 |
| 2 | 라이브 / ライブ | `/live` | 신규 `FieldLiveHubPage`: スケジュール / 楽曲・アーティスト |
| 3 | 커뮤니티 / コミュニティ | `/community` | 기존 `FieldCommunityPage`; 내부 탐색은 상단으로 |
| 4 | 마이 / マイ | `/mypage` | 기존 `TravelPassportPage`; 비로그인은 소개·로그인·언어/테마 진입 |

라이브 루트의 구체 구성:

- `/live`는 스케줄. PR9에서는 `FieldLiveEventsPage(embedded: true)` 재사용, 월 목록·캘린더 통합은 PR13.
- **`/live/music` 신설**, 이름 `music-archive`. 같은 라이브 브랜치에서 `FieldLiveHubPage`의 아카이브 세그먼트를 선택합니다.
- `/live`와 `/live/music`는 같은 안정적인 페이지 키의 루트로 구성. 세그먼트 전환은 `go`, 상세 진입은 `push`. 허브를 두 겹 쌓지 않습니다.
- 아카이브 본문은 `MusicCatalogTab`과 기존 아티스트 목록 재사용. 공연 선택 없이 직접 진입 가능.
- 기존 `FieldGuidePage._openMusicArchive()`의 `Navigator.push`를 named route로 교체. 홈·검색도 같은 경로 사용. [현재 URL 없는 진입](/Users/sonhoyoung/dev/oshi-log-redesign/lib/features/feed/presentation/field_guide/field_guide_page.dart:68).

**URL 호환 명세**

| 기존 URL | PR9 처리 |
|---|---|
| `/explore`, `?tab=0` | `/map` redirect alias |
| `/explore?tab=1` | `/live` |
| `/explore?tab=2` | `/mypage/records`; 기존 `FieldVisitLedgerPage` 연결 |
| `/explore?tab=3` | `/map?section=collections` |
| `/explore/places/:placeId` | `/map/places/:placeId` |
| `/explore/events/:eventId` | `/live/events/:eventId` |
| `/information` | `/live/music` |
| `/information/news/:newsId` | `/home/news/:newsId` |
| `/information/units/:unitId` 및 `/members/:memberId` | `/live/artists/:unitId` 및 동일 하위 멤버 경로 |
| `/information/voice-actors/:voiceActorId` | `/live/voice-actors/:voiceActorId` |
| `/information/songs/:songId` | `/live/music/songs/:songId` |
| `/community/discover`, `/community/travel-reviews-tab` | URL 유지, 상단 섹션을 선택하고 동일 메인 하단 바 표시 |
| `/calendar`, `/zukan`, `/visits`, `/overlay/*`, 설정·작성 경로 | 기존 전체화면·overlay 동작 보존. 대표 진입점만 새 IA에 배치 |

- 기존 경로의 **route name도 alias에 유지**, canonical 경로에는 새 이름 부여. 기존 `goNamed` 호출도 계속 작동합니다.
- `projectId/eventId/projectCode/name`, 기타 query·fragment 보존. `/explore`의 옛 `tab`만 새 목적지 선택으로 소비합니다.
- 잘못된 `tab`은 기존 파싱·clamp 동작 유지. 필수 프로젝트 인자 누락은 기존 오류 화면 유지; 현재 선택 프로젝트로 추측 복구하지 않습니다.
- 루트 alias가 하위 상세를 삼키지 않도록 정확한 경로별 redirect 작성. ID·쿼리는 `Uri`로 인코딩합니다.
- `extra` 없이 cold link 복원. `extra`는 초기 표시 최적화에만 사용합니다. [기존 인자 검증](/Users/sonhoyoung/dev/oshi-log-redesign/lib/app/router/routes/info_routes.dart:36).

**PR9 변경 파일·회귀 방지**

| 소유 파일 | 변경 |
|---|---|
| `lib/app/router/app_router.dart`, `routes/{home,explore,info,my,community}_routes.dart` | 브랜치 재배치, canonical 등록, 이전 route builder를 alias로 전환 |
| 신규 `routes/live_routes.dart`, `routes/legacy_alias_routes.dart` | 라이브·아카이브 라우트, 호환 redirect |
| `lib/core/router/{app_router,nav_extensions}.dart` | `NavIndex.map=1/live=2/community=3/mypage=4`, 새 이름·이동 헬퍼; 옛 인덱스 상수는 필요 시 호환 별칭 |
| `lib/app/shell/main_scaffold.dart` | `CommunitySubBottomNav`, 관련 enum·분기·커뮤니티 전용 뒤로가기 제거. 루트/세그먼트에서 동일 `GBTBottomNav` |
| 신규 `lib/app/compositions/{map,live}/presentation/*_hub_page.dart` | 기존 화면 조합, URL이 선택 상태를 소유; 지도 활성 상태·스크롤 보존 |
| `FieldCommunityPage`, `board_controller.dart`, `news_controller.dart` | 상단 내부 탐색, 갱신 활성 조건 수정 |
| `lib/app/router/auth_guard.dart`, 마이 루트 | `/map`, `/live` 공개 읽기, 마이 비회원 소개. S1 대상은 보호 데이터 호출 없이 로그인 안내 |
| `test/contracts/{route_inventory,auth_redirect_contract}_test.dart` 등 | 새 IA·alias·공개 범위 계약 검증 |

특히 `board_controller.dart`의 **`_kBoardNavIndex=4`**는 3으로 수정해야 합니다. `news_controller.dart`의 “정보 탭 2에서만 로드” 조건도 제거하고 실제 소비 화면의 활성 조건으로 바꿉니다. 라이브 탭 활성화로 뉴스가 갱신되면 안 됩니다. [게시판](/Users/sonhoyoung/dev/oshi-log-redesign/lib/features/feed/application/board_controller.dart:23), [뉴스](/Users/sonhoyoung/dev/oshi-log-redesign/lib/features/feed/application/news_controller.dart:13).

`route_inventory`는 **기존 snapshot 삭제·검사 완화 금지**. 옛 `path|name` 항목을 alias로 유지하고 새 canonical 항목을 추가한 전체 snapshot으로 명시 갱신합니다. 별도 테스트에서 브랜치 순서와 alias 도착 경로를 검증합니다. [현재 계약](/Users/sonhoyoung/dev/oshi-log-redesign/test/contracts/route_inventory_test.dart:35).

PR9 완료 조건: 5탭 순서·상태 유지, 아카이브 직접 진입, 기존 URL/name 전부 도달, query 보존, redirect 반복 없음, 로그인 후 목적지 복귀, overlay 복귀, Android back, 커뮤니티 갱신·지도 controller 수명 정상. 커뮤니티 하단 바 테스트는 **메인 바 유지 회귀 테스트**로 교체합니다.

**PR10+ — 화면별 지금 가능 / 서버 대기**

“지금 가능”은 현재 계약으로 구현 가능하다는 뜻입니다. 인증이 필요한 API를 비회원에게 공개한다는 뜻은 아닙니다. 화면 기준은 [전체 목록](/Users/sonhoyoung/dev/oshi-log-redesign/docs/product/screen-design-v1.md:23), 보류 번호는 [S 요청 목록](/Users/sonhoyoung/dev/oshi-log-redesign/docs/backend-api-requests/2026-10-02-product-direction-sync.md:24).

| 화면 | (a) 서버 변경 없이 구현 | (b) 보류·조건 |
|---|---|---|
| 첫 실행 | 언어·推し 선택, 모두 건너뛰기, 로컬 완료 상태 — PR20a | 관심 합산 추천 S5 |
| 검색·결과 | 현재 검색·최근 검색·빈 결과·오류 정리 — PR20c | 비회원 S1 |
| 알림 목록 | 현재 목록·읽음·설정 진입 — PR20c | 근접 알림 S20; 새 공연 구독 의미 추가 확인 |
| 로그인 시트 | 기존 로그인 UI 조합, 취소·복귀·원래 행동 1회 실행 — PR20b | 공개 읽기 S1은 별개 |
| 언어·테마 시트 | 기존 preference provider 재사용 — PR20a | 없음 |
| 홈 | 선택 프로젝트 공연·장소·뉴스, 음악 진입, 상태별 구성 — PR12 | 공개 S1, 홈 상태 S2, 참가 예정 S4, 관심 합산 S5 |
| 지도 | 3단 시트·목록·현재 필터·지역 탐색·실패 대체 — PR15 | 코스 S12, 기간 한정 S16, 완성형 지역 허브 S18 |
| 장소 상세 | 현재 이름·주소 확대/복사, 가이드 매너·입구 안내, 팬 Tips — PR11 | 원문 보장 S15, 구조화 주의·출처·도보 S6, 공개지점 인증 S7, 장면 근거·권리 S17 |
| 스폿집·코스 | 설명·표시순서·방문 진행도, **スポット集** 명칭 — PR15 | 저장 확장 S11, 이동 경로·시간 코스 S12 |
| 장소 정정 제안 | 접수 전 UI 설계까지 | S6/S17 회신에 **정정 접수 계약 추가 확인**. 게시물 신고로 대체 금지 |
| 스케줄 | 월 목록/캘린더·시간축·현행 참전 기록 배지 — PR13 | 참가 예정 S4, 취소·연기·변경정보 S2 보완, 시리즈 그룹 계약 확인 |
| 공연 상세 | 개장/개연/종료·공식 티켓·회장·가이드·세트리스트·주변 직선거리 — PR10 | S4·S8·S9·S13·S14·S21, 취소·연기 S2 보완 |
| 음악 아카이브 | 곡·앨범·밴드/멤버 탐색, 지원 데이터 필터 — PR18 | 공개 S1, 곡 저장 S11, 미지원 패싯·일괄 콜 유무 추가 확인 |
| 곡 상세 | 콜·파트·크레딧·공식 링크·공연 이력 — PR16 | 콜 출처 추가 계약, 팬 제안·검수 S21, 가사 권리 확인 |
| 아티스트 상세 | 기존 프로필·명시된 연결 자료 재배치 — PR18 | 캐릭터에 실제 출연 자동 귀속 금지; 구독 계약 확인 |
| 커뮤니티 피드 | 추천·팔로우·기존 레포 전환·상태 정리 — PR19 | 공개 S1, 질문 전용 분류·조회 추가 확인, 일본어 운영 준비 |
| 게시글 상세·작성 | 기존 작성·댓글·북마크·신고 — PR19 | 대상 연결·대상별 조회 S8 |
| 레포 상세·작성 | 장소 포함 현행 레포·작성 진입 복원 — PR19 | 공연 단독 S9, 같은 장소 재방문·서버 비공개 앨범 S19 |
| 게시물 신고 | 기존 사유·접수·실패 UI — PR19 | 장소 정정과 분리 |
| 마이 | 프로필·저장 3종+게시글 북마크·기록·진행도 — PR14 | 참가 예정 S4, 곡·스폿집 저장 S11 |
| 기록 타임라인·상세·편집 | 방문/참전 합성, 실제 지원 취소·이의신청; 로컬 부가 기록 — PR14·21b | 서버 방문 자기신고·날짜/메모/사진/공개범위 편집은 추가 계약; S19 |
| 설정 | 계정·언어·테마·알림·동의·차단 재정렬 — PR20a/c | 새 알림 카테고리 S20 |
| 공개 프로필 | 기존 프로필·활동·칭호·실패 상태 — PR20c | 새 공개 범위·집계 계약 확인 |
| 오늘 목록·다운로드 | 수동 선택·순서·건너뛰기, 텍스트 저장·갱신일 — PR21a | 자동 시간 최적화 S6/S12; 지도 다운로드 별도 |
| 旅·비공개 앨범 | 로컬 여행 후보·병합/분리·날짜 확인·선택 공개 초안 — PR21b | 서버 동기화·재방문 레포 S19 |
| 스포일러·공유 | 알려진 세트리스트/장면 블록 가림, 공유 본문 제외 — PR10·17 | 투어 잔여 일정 자동 판정·레포 flag 추가 계약; 콘텐츠 유니버설 링크 S10 |

**구현 PR별 파일·위젯·테스트·완료 조건**

경로 약어: `A=lib/app`, `L=lib/features/live_events`, `P=lib/features/places`, `M=lib/features/music`, `F=lib/features/feed`, `C=lib/features/calendar`, `Z=lib/features/zukan`, `V=lib/features/visits`. 신규 파일은 아래 위젯/함수명의 snake_case로 해당 소유 폴더에 둡니다. 여러 업무의 데이터 조합은 `A/compositions`, 순수 표현은 해당 feature가 소유합니다.

| PR·규모 | 변경 파일 / 새 위젯 | 해당 테스트·완료 조건 |
|---|---|---|
| **10 공연 준비 허브 · 대** | `L/presentation/field_events/{field_live_event_detail_page,field_event_detail_sections,field_event_detail_widgets}.dart`; `A/compositions/live/` 조합; `EventAccessSection`, `EventPreparationSection`, `EventActionBar`; 공용 `SpoilerGuard` | `field_event_widgets_test`, 신규 `event_preparation_test`, `event_time_policy_test`. 전/당일/후 순서, 주소·길찾기·공식 티켓 1개, 부분 실패 독립. 주변은 **직선거리**. 세트리스트 기본 가림 |
| **11 장소 현장 상세 · 대** | `P/presentation/pages/place_detail_page.dart`, `widgets/place_description_body.dart`, `application/places_controller.dart`, 필요한 DTO·data source; `PlaceVisitNotice`, `PlaceAccessSection`, `PlacePresentationSheet`, `PlaceTipsSection` | `place_detail_page_design_test`, 신규 Tips·현지표시 테스트. 매너→접근→가이드/Tips 순서, 현재 이름·주소는 **원문 미확인** 가능, 복사·오프라인 마지막 저장 표시. 정보 없음≠허용 |
| **12 홈 상태 · 중** | `A/compositions/home/presentation/field_home/{field_home_page,field_home_view_data}.dart`, `widgets/field_home_components.dart`, 홈 조합 provider; `HomeEntryPrompt`, `HomeMusicShortcut`, `HomeSectionRetry` | 기존 view-data·visual 테스트 확장. 비회원/推し 미선택/계획 없음/부분 실패 fixture. 현재 프로젝트 범위 명시, 시작된 오늘 공연 즉시 제거 금지 |
| **13 스케줄·배지 · 중대** | `L/presentation/field_events/{field_live_events_page,field_event_agenda_widgets,field_event_view_data,live_schedule_status_badge}.dart`; `C/presentation/field_calendar/{field_calendar_page,calendar_view_data,field_month_grid}.dart`; `EventStatusBadges` | `live_schedule_status_test`, `field_event_view_data_test`, `field_month_grid_test`. 월 목록 기본·달력 토글, 종일 일정 날짜 보존, 각 축 최대 1개. PR10 시간 정책 재사용 |
| **14 마이 기록·保存 · 중대** | `A/compositions/my/presentation/travel_passport/{travel_passport_page,travel_passport_view_data,passport_sections}.dart`; favorites 페이지, `V/presentation/field_visit_ledger/*`, `F/presentation/pages/post_bookmarks_page.dart`; `MySavedSection`, `UnifiedRecordTimeline` | passport·ledger 테스트, 신규 통합 timeline 테스트. 저장과 참가 예정 분리, 자기신고/위치 인증 분리, 페이지네이션·부분 실패 유지, 중복 ID 충돌 없음 |
| **15 지도 시트·필터·스폿집 · 중대** | `P/presentation/pages/places_map_page.dart`, `widgets/{field_map_controls,field_place_sheet_row}.dart`; `Z/presentation/{field_archive,field_detail}/`, `pages/zukan_detail_page.dart`; `MapFilterSummary`, `MapResultStatus` | map controls/search-sheet/controller-lease/platform-gate 및 zukan 테스트. 접힘/중간/전체, 위치 거부·지도 실패 시 목록, 재검색·필터 해제, 스폿집 순서를 이동 경로로 표시하지 않음 |
| **16 곡 상세·콜 · 중** | `M/presentation/pages/music_song_detail_page.dart`, 필요한 `application/music_controller.dart`; `SongCallSection`, `SongOfficialLinks`, `SongPerformanceSection` | `music_song_detail_page_test`, setlist/song entry 통합 테스트. 공연 준비 진입 시 콜·이력 우선, live-context 재사용·누락만 추가 요청, 실연 주체 별도 표기 |
| **17 스포일러 확장 · 중** | PR10의 공용 `SpoilerGuard` 재사용; 음악 이력, zukan 장면, 레포·공유 생성부 | 신규 guard widget/semantics 테스트와 대상 golden. 펼치기 전 본문·접근성 트리·공유 결과에서 차단. 닫기·화면 재진입 초기화. 투어 상태 추정 금지 |
| **18 아카이브·아티스트 · 중** | `F/presentation/field_guide/field_guide_music_page.dart`, `M/presentation/widgets/music_catalog_tab.dart`, 기존 `pages/{unit_detail_page,member_detail_page,voice_actor_detail_page}.dart`; `MusicArchiveSections` | music catalog·archive·artist widget/golden. 曲/アルバム/メンバー, 지원 필터만 표시, 밴드·캐릭터·실제 인물 구분, URL 재진입 선택 유지 |
| **19 커뮤니티·레포 · 중** | `F/presentation/field_community/field_community_page.dart`, `pages/{post_detail_page,post_create_page,travel_review_create_page,travel_review_detail_page}.dart`, `widgets/community_report_sheet.dart`; 기존 문서 위젯 재사용 | community·post document·travel-review document 테스트. 레포 작성 진입 복원, 현행 장소 필수 조건 설명, 실패 시 입력 보존, 신고/정정 구분 |
| **20a 첫 실행·언어/테마 · 소중** | 신규 `A/compositions/onboarding/`; settings `app_preferences.dart`, `settings_page.dart`, 기존 project selector; `FirstRunPreferencesSheet`, `LocaleThemeSheet` | 신규 first-run widget, 기존 locale/theme 테스트. 전부 건너뛰기 가능, 명시 언어 보존, 로그인 없이 언어·테마 변경 |
| **20b 행동 시점 로그인 · 중** | `A/session/` 복귀 조합, auth `login_page.dart`·기존 인증 위젯, `A/router/auth_guard.dart`; `ActionLoginSheet` | login redirect·account isolation 및 신규 pending-action 테스트. 원래 URI 보존, 성공 후 의도한 행동 1회, 취소/계정 전환 시 자동 실행 없음 |
| **20c 검색·알림·설정·프로필 상태 · 중** | `A/compositions/search/presentation/pages/search_page.dart`; notifications/settings 페이지; `F/presentation/field_user_profile/field_user_profile_page.dart`; 기존 loading/empty/error 위젯 재사용 | 화면별 widget/golden. 삭제·비공개·검색 없음·알림 거부의 이유와 다음 행동, 원치 않는 권한 팝업 없음 |
| **21a 오늘 목록·텍스트 저장 · 중** | 신규 `A/compositions/today/`, 마이 진입, 기존 로컬 저장·캐시 어댑터; `TodayPlaceList`, `DownloadStatusRow` | 순서/건너뛰기/재시작 복원·다운로드 실패·갱신일 테스트. 주소·주의 텍스트의 저장 성공 범위만 오프라인 가능으로 표시 |
| **21b 로컬 여행·앨범 · 대** | 신규 `A/compositions/trips/`, 기존 기록 조회·레포 작성 연결; `TripCandidateCard`, `PrivateTripEditor`, `PublishSelectionSheet` | 병합/분리/날짜 수정·계정 격리·초안 복원 테스트. 사진 영속 저장까지 검증, 공개 전 항목별 확인, 서버 게시 요청은 최종 공개 때만 |

PR10 근거: [현재 상세 조합](/Users/sonhoyoung/dev/oshi-log-redesign/lib/features/live_events/presentation/field_events/field_live_event_detail_page.dart:127), PR11: [장소 상세 공급 데이터](/Users/sonhoyoung/dev/oshi-log-redesign/lib/features/places/presentation/pages/place_detail_page.dart:196), PR12: [현재 시작 시각 필터](/Users/sonhoyoung/dev/oshi-log-redesign/lib/app/compositions/home/presentation/field_home/field_home_view_data.dart:61), PR15: [지도 수명·활성 제어](/Users/sonhoyoung/dev/oshi-log-redesign/lib/features/places/presentation/pages/places_map_page.dart:64), PR16: [기존 콜 조합](/Users/sonhoyoung/dev/oshi-log-redesign/lib/features/music/presentation/pages/music_song_detail_page.dart:1025).

**각 PR에 적용할 세부 판정**

- 공연 시간 정책은 PR10에서 한 번 정의. 일본 공연은 JST로 날짜·당일 경계 계산하고 단말 시간대가 다르면 병기. `endTime` 없으면 당일 말까지 카드 유지하되 실제 공연 진행·종료 확정으로 표현하지 않습니다. 해외 회장 현지 시간 보장은 별도 timezone 계약 필요.
- `参加予定`는 S4 전 출시하지 않습니다. 기존 attendance는 **자기신고 참전 기록**입니다. 저장을 참가 예정으로, 위치 인증을 사용자가 선택하는 토글로 바꾸지 않습니다.
- 홈 `/home` 한 요청이 실패했는데 일부 섹션이 성공한 것처럼 처리하지 않습니다. 별도 공급 데이터·캐시가 있는 섹션만 독립 표시/재시도합니다.
- 장소 `guide.updatedAt`은 **가이드 수정일**입니다. 현장 확인일·공식 근거일로 승격하지 않습니다. JA 요청의 fallback도 원문 보장이 아닙니다. [장소 언어 fallback](/Users/sonhoyoung/Documents/00_소스코드/oshilog-api/server/src/main/kotlin/org/pyrimidines/oshilog/place/persistence/entity/PlaceEntity.kt:329).
- 콜 출처 필드와 곡 목록 `hasCallGuide`가 없습니다. 공식 콜로 표시하거나 배지 때문에 목록 전체를 N+1 조회하지 않습니다. 가사는 권리 조건을 확인한 범위만 표시합니다. [음악 DTO](/Users/sonhoyoung/Documents/00_소스코드/oshilog-api/server/src/main/kotlin/org/pyrimidines/oshilog/oshikatsu/music/dto/MusicDtos.kt:137).
- 여행 후보 날짜는 사용자 확인 대상. `visitedAt`을 여행 날짜로 확정하지 않습니다. `travel-reviews`는 생성 시 공개되므로 비공개 앨범 저장소로 쓰지 않습니다. [공개 생성](/Users/sonhoyoung/Documents/00_소스코드/oshilog-api/server/src/main/kotlin/org/pyrimidines/oshilog/community/travel/service/TravelReviewService.kt:128).
- 연간 통계는 전체 조회·집계가 확보된 항목만. 일부 페이지 합계를 연간 전체로 표시하지 않습니다.

**검증·완료 기준 — 모든 UI PR 공통**

- **widget:** ja/ko × light/dark × 320dp × 200%에서 overflow 없음, 마지막 행동 도달, 긴 제목·빈값·로딩·부분 실패·권한 거부 검증.
- **golden:** ja/ko 각각 기본 크기 light/dark와 **320dp+200%** 주요 상태. 현재 홈 compact 검증은 150%이므로 추가가 필요합니다. [현재 테스트](/Users/sonhoyoung/dev/oshi-log-redesign/test/features/home/presentation/field_home_visual_test.dart:34).
- GBT spacing·typography·colors 재사용. 기본 여백 `md=16`, 섹션 `xl=32` 유지. 행은 날짜·제목·상태 중심, 배지는 줄바꿈. 글자 축소로 맞추지 않습니다. [기존 토큰](/Users/sonhoyoung/dev/oshi-log-redesign/lib/core/theme/gbt_spacing.dart:23).
- 주요 터치 영역 48dp, 텍스트 포함 상태 배지, VoiceOver 순서·가림 콘텐츠 semantics 검증. 지도 핸들 접근성·하단 CTA 가림도 포함.
- 순수 상태 계산은 고정 `now`로 검증. widget/golden은 provider override·고정 이미지 사용. golden 성공을 실제 지도 수명·스크롤 성능 증거로 대체하지 않습니다.
- 구현자가 `flutter analyze`, 대상 `flutter test --no-pub`, 계약 테스트 실행. PR9 통합 후 전체 테스트, 이후 영향 범위 중심 검증. 실패를 감추는 baseline 일괄 갱신 금지.
- 각 구현 PR에 CHANGELOG·해당 ADR·남은 TODO 반영. 이번 설계 응답에서는 작성하지 않았습니다.

**병렬 실행 — 파일 충돌 기준**

| 조합 | 판정·조건 |
|---|---|
| PR9 ↔ PR6–8 | **순차**. 이동과 라우팅 동작 변경 분리 |
| PR9 ↔ 화면 PR | 구현 착수는 PR9 루트·경로·위젯 입력 계약 확정 후. router/shell/nav 파일은 PR9 담당자 1명 |
| PR10 · PR11 · PR12 · PR14 · PR16 | 화면 파일은 병렬 가능. 공용 시간 정책은 PR10 소유, 소비 PR은 확정 후 연결 |
| PR10 ↔ PR13 | **순차 권장**. 시간 정책·일정 상태·라이브 공통 위젯 충돌 |
| PR11 ↔ PR15 | 페이지는 병렬 가능. `places_controller`·DTO·data source를 PR11이 소유하면 PR15는 해당 변경 병합 후 필터 연결 |
| PR16 ↔ PR18 | **순차 또는 소유 분리**. `music_controller`, catalog 모델·배럴 동시 편집 금지 |
| PR17 ↔ PR10·PR16·PR19 | guard 자체는 PR10 완료 후 재사용. 세트리스트·곡 이력·레포 소비 파일 변경은 해당 PR 이후 |
| PR18 ↔ PR19 | PR6 이동 완료 후 catalog와 community 소유 폴더가 갈리면 병렬 가능 |
| PR20a ↔ PR20b ↔ PR20c | preferences/auth/검색·알림 파일을 나누면 병렬. router·세션 정리는 담당자 1명 |
| PR14 ↔ PR21a/b | 마이 진입·기록 조합 충돌. **PR14 → PR21a → PR21b** 권장 |
| 모든 PR | route inventory, 공용 배럴, GBT 토큰, CHANGELOG/TODO는 통합 담당자 1명. 새 ADR은 PR별 파일 |

권장 첫 묶음은 **PR9 완료 → PR10·11 병렬**, 이어 **PR12·13·14**, 이후 **PR15·16**입니다. S 회신은 관련 보류 기능의 착수 조건이며, 현재 계약으로 가능한 화면 재구성은 독립적으로 진행할 수 있습니다.

