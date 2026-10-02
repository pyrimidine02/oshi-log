# 앱 구조 이행 명세 PR5–PR8 v1

- 작성: GPT astra (gpt-6-astra), 2026-10-02, 기준 커밋 992d2b7
- 상위: `app-architecture-redesign-v1.md` (승인됨)
- 실행 규칙: 이동 PR은 한 담당자가 순차 반영. git stash/reset 금지.

기준은 **`992d2b7`**. 아래 `file:line`도 해당 커밋 기준입니다. 파일·Git 수정 없이 정적 의존 그래프로 허용 목록 **74건(R2 20 / R4 7 / R5 47)**을 재현했습니다. 빌드·테스트는 실행하지 않았습니다.

**먼저 수량 정정:** 기준 커밋의 feed는 **81파일**입니다. 기존 84파일 중 `board_page.dart`, `info_page.dart`, `user_profile_page.dart`는 `7ddae2d`에서 삭제됐습니다. 아래 표에 삭제된 3파일까지 포함했습니다. 동시 작업자가 삭제한 파일도 복원하지 않습니다.

**경로 표기:** `F=lib/features`, `A=lib/app`, `D=lib/design_system`, `T=lib/platform`. `{r}`은 하위 상대 경로 전체를 그대로 유지한다는 뜻입니다. 구체적인 예외·분할 규칙이 일괄 이동보다 우선합니다.

**PR5 — 상태 소유권·세션 정리·화면 조합**

| 현 경로·심벌 | 새 경로 |
|---|---|
| `F/home/presentation/{r}` | `A/compositions/home/presentation/{r}` |
| `F/home/{application,data,domain}/{r}` | `F/shared/home/{application,data,domain}/{r}` |
| `F/my/presentation/{r}` | `A/compositions/my/presentation/{r}` |
| `F/search/presentation/{r}` | `A/compositions/search/presentation/{r}` |
| `F/search/{application,data,domain}/{r}` | `F/shared/search/{application,data,domain}/{r}` |
| `F/explore/presentation/{r}` | `A/compositions/explore/presentation/{r}` |
| `lib/shared/main_scaffold.dart` | `A/shell/main_scaffold.dart` |
| `lib/core/providers/core_providers.dart:327` 프로젝트 선택 상태 | `F/projects/application/project_context.dart` → PR6에서 catalog |
| 같은 파일 `:345` 탭 상태 | `A/shell/navigation_state.dart` |
| 같은 파일 `:356`, `:441` 인증 상태·refresh tick | `F/auth/application/session_state.dart` → PR8에서 identity/auth |
| 같은 파일 `:254` 테마·locale 상태 | `F/settings/application/app_preferences.dart` → PR8에서 account |
| 같은 파일 `:416` 법률 정책 조회 | `F/auth/application/legal_policies_provider.dart`; 응답 변환은 auth data |
| 같은 파일 나머지 인프라 provider | `T/providers/platform_providers.dart` |
| `lib/core/constants/legal_policy_constants.dart` | 순수 타입·정책 값 → `F/auth/domain/entities/legal_policy.dart`; JSON 변환 → `F/auth/data/mappers/legal_policy_mapper.dart`; UI label은 표시 위젯으로 |
| `lib/core/notifications/{local_notifications_service,remote_push_service,firebase_runtime_options}.dart` | `T/notifications/`의 동일 파일명. 아래 업무 코드 분리 필수 |
| `lib/core/notifications/in_app_notification_queue.dart` | `F/notifications/application/in_app_notification_queue.dart` |
| `lib/core/widgets/overlays/in_app_notification_banner.dart` | `A/compositions/notifications/in_app_notification_banner.dart` |

- **로그아웃:** [auth_controller.dart:1366](/Users/sonhoyoung/dev/oshi-log-redesign/lib/features/auth/application/auth_controller.dart:1366)의 프로젝트·탭·프로필·알림 설정·즐겨찾기·게시물/공연 outbox·북마크 정리를 `A/session/session_cleanup.dart`로 추출합니다. 게시물 draft prefix와 사용자별 로컬 데이터 정리(`:1313`, `:1348`, `:1401`, `:1425`)도 함께 이동합니다.
- auth는 app을 import하지 않습니다. 필요한 정리 함수를 주입하고, `A/bootstrap/session_overrides.dart`에서 실제 feature provider를 연결합니다. 호출 지점 **`:603`, `:660`, `:747`, `:834` 전부** 교체합니다. 화면의 로그아웃 버튼만 감싸는 방식은 불충분합니다.
- auth 내부 직렬화·세대 번호는 유지합니다. `:676` 중복 정리 대기 → `:772` 세대 증가 → `:773` 미인증 전환 → `:774` 진행 작업 drain → 원격 로그아웃·push 해제 → 캐시·저장소 정리 → provider 무효화 순서 보존. 실패 처리·토큰 교체·재로그인 격리도 유지합니다.
- `core_providers.dart:66`의 API 인증 실패 callback과 `:156` push 인증 listener는 app bootstrap에서 연결합니다. platform이 auth를 참조하지 않게 하고, 만료 응답의 세대가 바뀌었으면 새 세션을 정리하지 않습니다.
- 조합 근거: `home/.../field_home_page.dart:20`, `my/.../travel_passport_page.dart:11`, `search/.../search_page.dart:23`, `explore/.../field_explore_page.dart:10`. 저장소·업무 DTO는 app으로 옮기지 않습니다.
- 탭 활성 조건도 app 소유로 전환합니다. `board_controller.dart:23`, `news_controller.dart:15`, `home_controller.dart:41`, `live_events_controller.dart:89`, `places_controller.dart:36`에 활성값/activate callback을 공급합니다. feature의 `app/shell` 역참조 금지.

**PR5 R4 7건의 개별 처리**

| 현재 간선 근거 | 제거 방법 |
|---|---|
| `local_notifications_service.dart:10` → NotificationItem | `:172` 표시 어댑터를 `F/notifications/application/notification_delivery.dart`로; platform은 원시 envelope 수신 |
| 같은 파일 `:11` → navigation | `:233` 업무 payload 해석을 같은 어댑터로; 플랫폼 tap은 원시 payload 전달 |
| `remote_push_service.dart:21` → NotificationItem | `:715`, `:791` 변환을 notification delivery로; 플랫폼 stream은 원시 메시지 |
| 같은 파일 `:22` → navigation | 경로 결정은 `A/compositions/notifications/notification_coordinator.dart` |
| `core_providers.dart:25` → AuthRemoteDataSource | 법률 정책 조회·변환을 auth 내부로 이동 |
| 같은 파일 `:26` → NotificationItem | feature 타입 stream provider를 `F/notifications/application/notification_delivery.dart`로 이동 |
| `in_app_notification_banner.dart:15` → navigation | 위 표대로 app 조합으로 이동 |

추가로 push의 장치 등록·해제·열람 추적(`remote_push_service.dart:496`, `:531`, `:600`, `:658`)은 `F/notifications/data/notification_device_registration.dart`로 분리합니다. `main.dart:106`의 background handler 등록·진입점 annotation은 유지합니다. `core/widgets/legal/legal_policy_links_section.dart:36`도 provider 소비를 제거하고 표시값·callback을 받게 해야 새 R4가 생기지 않습니다.

**PR6 — feed 전체 배치**

목적지 약어: `P=F/community/posts`, `N=F/community/news`, `R=F/community/reviews`, `M=F/community/moderation`, `C=F/oshikatsu/catalog`, `S=F/identity/social`, `U=F/identity/account`, `AC=A/compositions/community`, `AG=A/compositions/guide`, `AP=A/compositions/user_profile`.
아래 현 경로는 모두 **`F/feed/` 기준**입니다. 목적지가 약어 하나이면 **그 루트 아래에 현 상대 경로를 그대로 붙입니다**.

| # | 현 경로 | 새 경로 |
|---|---|---|
| 1 | `application/board_controller.dart` | P |
| 2 | `application/community_ban_view_helper.dart` | M |
| 3 | `application/community_moderation_controller.dart` | `S/application/block_status_controller.dart` |
| 4 | `application/community_translation_controller.dart` | P |
| 5 | `application/feed_controller.dart` | P |
| 6 | `application/feed_repository_provider.dart` | P |
| 7 | `application/local_post_bookmarks_controller.dart` | P |
| 8 | `application/new_posts_indicator_notifier.dart` | P |
| 9 | `application/news_controller.dart` | N |
| 10 | `application/pending_post_reaction_mutation.dart` | P |
| 11 | `application/post_compose_autosave_controller.dart` | P |
| 12 | `application/post_compose_draft_store.dart` | P |
| 13 | `application/post_controller.dart` | P |
| 14 | `application/reaction_controller.dart` | P |
| 15 | `application/report_rate_limiter.dart` | M |
| 16 | `application/travel_reviews_controller.dart` | R |
| 17 | `application/user_activity_controller.dart` | P |
| 18 | `application/user_follow_controller.dart` | S |
| 19 | `application/user_follow_list_controller.dart` | S |
| 20 | `data/datasources/community_remote_data_source.dart` | M |
| 21 | `data/datasources/feed_remote_data_source.dart` | P |
| 22 | `data/datasources/travel_reviews_remote_data_source.dart` | R |
| 23 | `data/dto/community_moderation_dto.dart` | M |
| 24 | `data/dto/community_translation_dto.dart` | P |
| 25 | `data/dto/news_dto.dart` | N |
| 26 | `data/dto/post_comment_dto.dart` | P |
| 27 | `data/dto/post_dto.dart` | P |
| 28 | `data/dto/travel_review_dto.dart` | R |
| 29 | `data/mappers/feed_entities_mappers.dart` | P |
| 30 | `data/mappers/travel_review_mappers.dart` | R |
| 31 | `data/repositories/community_repository_impl.dart` | M |
| 32 | `data/repositories/feed_repository_impl.dart` | P |
| 33 | `data/repositories/travel_reviews_repository_impl.dart` | R |
| 34 | `domain/entities/community_moderation.dart` | M |
| 35 | `domain/entities/feed_entities.dart` | P |
| 36 | `domain/entities/travel_review.dart` | R |
| 37 | `domain/repositories/community_repository.dart` | M |
| 38 | `domain/repositories/feed_repository.dart` | P |
| 39 | `domain/repositories/travel_reviews_repository.dart` | R |
| 40 | `presentation/field_community/field_community_page.dart` | AC |
| 41 | `presentation/field_community/field_community_providers.dart` | P |
| 42 | `presentation/field_community/sections/field_community_timeline_section.dart` | P |
| 43 | `presentation/field_community/sections/field_community_travel_section.dart` | R |
| 44 | `presentation/field_community/widgets/field_community_masthead.dart` | AC |
| 45 | `presentation/field_community/widgets/field_community_mode_bar.dart` | AC |
| 46 | `presentation/field_community/widgets/field_community_post_entry.dart` | P |
| 47 | `presentation/field_guide/field_guide_music_page.dart` | AG |
| 48 | `presentation/field_guide/field_guide_page.dart` | AG |
| 49 | `presentation/field_guide/field_guide_providers.dart` | `C/application/field_guide_artists_provider.dart` + `N/application/field_guide_updates_provider.dart` |
| 50 | `presentation/field_guide/sections/field_guide_artists_section.dart` | C |
| 51 | `presentation/field_guide/sections/field_guide_kit_section.dart` | AG |
| 52 | `presentation/field_guide/sections/field_guide_updates_section.dart` | N |
| 53 | `presentation/field_guide/widgets/field_guide_masthead.dart` | AG |
| 54 | `presentation/field_guide/widgets/field_guide_section_switcher.dart` | AG |
| 55 | `presentation/field_user_profile/field_user_profile_page.dart` | AP |
| 56 | `presentation/field_user_profile/field_user_profile_view_data.dart` | U |
| 57 | `presentation/field_user_profile/widgets/field_profile_activity.dart` | AP |
| 58 | `presentation/field_user_profile/widgets/field_profile_calling_card.dart` | U |
| 59 | `presentation/field_user_profile/widgets/field_profile_ledger.dart` | U |
| 60 | `presentation/field_user_profile/widgets/field_user_profile_document.dart` | AP |
| 61 | `presentation/models/feed_native_ad_placement.dart` | P |
| 62 | `presentation/pages/feed_page.dart` | P; 동시 작업에서 삭제됐다면 제외 |
| 63 | `presentation/pages/member_detail_page.dart` | C |
| 64 | `presentation/pages/news_detail_page.dart` | N |
| 65 | `presentation/pages/post_bookmarks_page.dart` | P |
| 66 | `presentation/pages/post_create_page.dart` | P |
| 67 | `presentation/pages/post_detail_page.dart` | P |
| 68 | `presentation/pages/post_edit_page.dart` | P |
| 69 | `presentation/pages/travel_review_create_page.dart` | R |
| 70 | `presentation/pages/travel_review_detail_page.dart` | R |
| 71 | `presentation/pages/unit_detail_page.dart` | C |
| 72 | `presentation/pages/user_connections_page.dart` | S |
| 73 | `presentation/pages/voice_actor_detail_page.dart` | C |
| 74 | `presentation/widgets/community_fab_layout.dart` | P |
| 75 | `presentation/widgets/community_report_sheet.dart` | M |
| 76 | `presentation/widgets/community_translation_panel.dart` | P |
| 77 | `presentation/widgets/post_compose_components.dart` | P |
| 78 | `presentation/widgets/travel_review_compose_sections.dart` | R |
| 79 | `presentation/widgets/travel_review_edit_sheet.dart` | R |
| 80 | `presentation/widgets/travel_review_place_picker_sheet.dart` | R |
| 81 | `presentation/widgets/voice_actor_directory_tab.dart` | C |
| 82 | `presentation/pages/board_page.dart` | 삭제 완료; 이동 없음 |
| 83 | `presentation/pages/info_page.dart` | 삭제 완료; 이동 없음 |
| 84 | `presentation/pages/user_profile_page.dart` | 삭제 완료; 이동 없음 |

단순 이동 전에 다음 혼합 파일을 분리합니다.

- **뉴스:** `feed_entities.dart:9`, `feed_entities_mappers.dart:13`, `feed_repository.dart:11`, `feed_remote_data_source.dart:45`, `feed_repository_impl.dart:30`의 뉴스 심벌을 각각 `N/domain/entities/news_entities.dart`, `N/data/mappers/news_entities_mappers.dart`, `N/domain/repositories/news_repository.dart`, `N/data/datasources/news_remote_data_source.dart`, `N/data/repositories/news_repository_impl.dart`로 추출합니다. `N/application/news_repository_provider.dart` 연결 후 posts 쪽 뉴스 심벌·export 제거.
- **소셜:** `community_remote_data_source.dart:69`, `community_moderation_dto.dart:29`, `community_moderation.dart:357`, `community_repository_impl.dart:55`의 follow/block 계열을 S의 `data/datasources/social_remote_data_source.dart`, `data/dto/social_dto.dart`, `domain/entities/social_entities.dart`, `data/repositories/social_repository_impl.dart`로 추출합니다. `domain/repositories/social_repository.dart`, `application/social_repository_provider.dart` 연결.
- `community_moderation_controller.dart:15`는 실제로 BlockStatusController입니다. 이를 S로 옮기고 `:87`의 moderation 저장소 provider는 `M/application/community_repository_provider.dart`로 분리합니다.
- `field_guide_providers.dart:15`는 news, `:22`부터는 catalog 소유입니다. artist/news가 app provider를 역참조하지 않도록 분리합니다. `feed_controller.dart:8`의 news 재export도 제거합니다.
- 게시물 작성·수정의 ProjectSelector, 상세의 ActiveTitleBadge, 신고 sheet는 app route 조합에서 slot/callback으로 공급합니다. 목적지 `A/compositions/posts/post_{create,edit,detail}_route.dart`; 남아 있는 feed 화면도 같은 원칙 적용. 공개 provider 배럴로 페이지·위젯을 재export하지 않습니다.

| 분할 PR | 범위·선행 조건 |
|---|---|
| 6a | `F/projects/{r} → C/{r}` 23파일; guide 조합·artist 분리. 업데이트 section/provider는 6b까지 현 위치 유지 |
| 6b | 뉴스 계약 추출 → news 이동 → guide updates 연결 |
| 6c | travel review 체인·travel section 이동. 현재 beta 표시 동작 유지 |
| 6d | posts·moderation·social 계약 분리, 공개 프로필 조합, 나머지 feed 이동·옛 배럴 제거 |

**PR7 — place 계열 순환 제거**

| 현 경로 | 새 경로 |
|---|---|
| `F/places/{r}` | `F/place/places/{r}` |
| `F/visits/{application,data,domain}/{r}` | `F/place/visits/{application,data,domain}/{r}` |
| `F/visits/presentation/{r}` | `A/compositions/visits/presentation/{r}` |
| `F/verification/{r}` | `F/place/verification/{r}` |
| `F/zukan/{r}` | `F/place/collections/{r}` |
| `F/settings/presentation/pages/account_tools_page.dart` | `A/compositions/account/presentation/pages/account_tools_page.dart` |

- **場所詳細→認証:** `places/presentation/pages/place_detail_page.dart:1474`의 sheet 열기, `:1480` reset, `:1491` verify, `:1494` 후기 연결을 `A/compositions/places/place_verification_flow.dart`로 추출합니다. 상세 위젯에는 `onVerify`·`onWriteReview` 주입. `app/router/routes/explore_routes.dart:33`과 `global_overlay_routes.dart:191` 양쪽 진입점에 동일 조합 적용.
- **인증→방문·성장:** [verification_controller.dart:260](/Users/sonhoyoung/dev/oshi-log-redesign/lib/features/verification/application/verification_controller.dart:260)의 방문 reload(`:263`), summary(`:266`), ranking(`:268`), title cache/refresh(`:273`, `:275`)를 `A/compositions/places/verification_completion.dart`로 이동하고 성공 callback 주입. 기존 호출 `:93`, `:242` 유지. **일반 live 성공 `:175`에는 refresh가 없으므로 이동 PR에서 추가하지 않습니다.** await·예외 삼키기·중복 호출 방지 보존.
- **방문→장소:** `visits/application/visits_controller.dart:86`, `:112`의 `visitPlacesMapProvider`, `visitAllProjectsPlacesMapProvider`를 `A/compositions/visits/application/visit_place_context.dart`로 이동합니다. 조회 호출 `:97`, `:131`도 이동. 소비자 `field_visit_ledger_page.dart:52`, `visit_detail_page.dart:42`, `visit_stats_page.dart:43`는 위 표대로 app 소속.
- **지도→방문·catalog:** `places_map_page.dart:127`, `:186`의 방문 로드/구독, `:215`의 탭 상태, `:891`, `:969`의 picker 호출을 `A/compositions/places/places_map_host.dart`로 올립니다. 지도에는 방문 ID·활성값·picker callback 공급. `zukan/.../field_zukan_archive_page.dart`의 catalog picker도 `A/compositions/collections/collections_host.dart`에서 공급.
- **account→verification 역방향:** `settings/.../account_tools_page.dart:25` 때문에 화면을 app으로 이동합니다. `settings_controller.dart:639`, `settings_remote_data_source.dart:286`, `settings_repository_impl.dart:638`, `account_tools.dart:45`, `account_tools_dto.dart:92`의 appeal 체인은 verification 아래 `application/verification_appeals_controller.dart`, `data/datasources/verification_appeals_remote_data_source.dart`, `data/repositories/verification_appeals_repository_impl.dart`, `domain/entities/verification_appeal.dart`, `data/dto/verification_appeal_dto.dart`로 추출; repository 계약·mapper도 같은 feature에 분리합니다.

**PR8 — 잔여 이동·최종 경계 고정**

| 현 경로 | 새 경로 |
|---|---|
| `F/music/{r}` | `F/oshikatsu/music/{r}` |
| `F/{live_events,calendar,cheer_guides}/{r}` | 각각 `F/oshikatsu/live/{r}` |
| `F/quotes/{r}` | `F/oshikatsu/quotes/{r}` |
| `F/auth/{r}` | `F/identity/auth/{r}` |
| `F/settings/{r}` | `F/identity/account/{r}`; PR7 추출분·아래 social 추출분 제외 |
| `F/{fan_level,titles,profile_banner}/{r}` | 각각 `F/identity/progression/{r}` |
| `F/admin_ops/{r}` | `F/community/moderation/{r}` |
| `F/{favorites,uploads,notifications,ads}/{r}` | 각각 `F/shared/{동일 feature명}/{r}` |
| `lib/core/{theme,widgets,accessibility,localization}/{r}` | `D/{동일 디렉터리}/{r}`; PR5 이동분 제외 |
| `lib/core/utils/palette_utils.dart` | `D/utils/palette_utils.dart` |
| `lib/core/constants/profile_media_constants.dart` | `F/identity/account/domain/profile_media_constants.dart` |
| `lib/core/security/user_access_level.dart` | `F/identity/account/domain/entities/user_access_level.dart` |
| `lib/core/location/location_notice_consent.dart` | `F/identity/account/application/location_notice_consent.dart`; 순수 상태 타입은 account domain으로 분리 |
| `lib/core/models/registrant_dto.dart` | `F/shared/contributors/data/dto/registrant_dto.dart` |
| `lib/core/providers/registrant_provider.dart` | `F/shared/contributors/application/contributors_provider.dart`; HTTP·DTO 변환은 같은 feature data로 분리 |
| `lib/core/providers/auth_provider{,.g}.dart` | 참조 0 재확인 후 삭제; 실제 session_state와 합치지 않음 |
| `lib/core/router/app_router.dart` | shim 제거; 순수 경로 상수·확장은 기존 `A/router` 소유 파일로 직접 연결 |
| 그 외 남은 `lib/core/{r}` | `T/{r}` |
| `lib/app.dart` | `A/app.dart`; `main.dart` 진입점은 유지하고 초기화 본문만 `A/bootstrap/bootstrap.dart`로 추출 |

- settings의 차단 목록 체인도 S로 이동: `settings_controller.dart:497`, `settings_remote_data_source.dart:211`, `settings_repository_impl.dart:488`, `account_tools.dart:19`, `account_tools_dto.dart:37`. 목적지는 PR6의 social repository/data 체인을 재사용하고 `S/application/user_blocks_controller.dart` 추가.
- `registrant_credit_widget.dart`는 contributor provider 소비를 제거하고 표시값을 받게 합니다. `gbt_profile_action.dart:47`의 기본 라우팅도 callback으로 전환. 디자인 시스템에 feature·app 의존을 남기지 않습니다.
- live 합치기로 calendar→live badge R2 두 건 제거. `field_calendar_page.dart`·`field_live_events_page.dart`의 catalog lens는 `A/compositions/live/` host에서 공급하여 나머지 두 건 제거. 분할 순서는 **8a live → 8b identity/shared → 8c platform/design_system**입니다.

**검사기 변경 — PR5부터 하위 feature 인식, PR8까지 R2 완전 적용**

- [dependency_checker.dart:76](/Users/sonhoyoung/dev/oshi-log-redesign/test/architecture/dependency_checker.dart:76): 알려진 그룹 `oshikatsu/place/community/identity/shared`이면 owner=`parts[2]/parts[3]`; 이행 중 기존 경로는 `legacy/<feature>`로 식별합니다. 그룹 바로 아래 업무 파일은 실패 처리. `shared` 전체를 하나의 feature로 취급하지 않습니다.
- `:47`의 R4에 `lib/platform/`, `lib/design_system/` 추가. 기존 core/shared 검사도 이동 완료까지 유지합니다. feature→app 역참조도 실패 처리합니다.
- `:40`의 R2는 현재 data/presentation만 막아 내부 application 직접 import를 놓칩니다. 각 PR에서 참조를 공개 provider로 정리하고 PR8에서 **외부 domain 또는 정확한 `<sub>/<sub>.dart`만 허용**하도록 고정합니다.
- 공개 배럴은 명시적 `show`로 domain·공개 provider만 노출합니다. controller 전체·DTO·위젯 export 금지. export 추적은 유지하되 public provider 구현의 private import까지 외부 소비자의 의존으로 확장하지 않습니다.
- 회귀 사례: 같은 그룹의 다른 subfeature, shared 내부 두 feature의 순환, 외부 application 직접 참조, export 우회, platform/design_system 역참조, 허용된 public provider. app presentation의 DTO 직접 소비도 R1로 검사합니다.

**import 일괄 갱신 — 경로 이동과 심벌 분할을 분리**

```dart
// 의사코드. 기본 dry-run; 단순 sed 전역 치환 금지.
manifest = expandExactMoveRules(snapshotPaths); // 예외 먼저, 삭제 파일 제외
assertUniqueDestinations(manifest);
for (oldFile in dartFiles(["lib", "test", "integration_test", "tool"])) {
  newFile = manifest[oldFile] ?? oldFile;
  for (uriToken in parseDirectiveUris(oldFile)) {
    // import/export, 조건부 URI, part/URI형 part of 포함
    oldTarget = resolveUri(oldFile, uriToken.value);
    newTarget = manifest[oldTarget] ?? oldTarget;
    patchToken(uriToken, renderUri(newFile, newTarget, uriToken.style));
  }
}
reportMissingSourcesCollisionsAndUnresolvedUris();
applyReviewedPlan(); // 승인된 실행 담당자만; 이 설계 작업에서는 실행하지 않음
```

뉴스·소셜처럼 한 파일이 여러 파일로 갈라지면 먼저 심벌별 import를 수정한 뒤 manifest를 적용합니다. 테스트·golden 파일 위치는 유지하여 경로 변경을 최소화합니다. 허용 목록은 같은 manifest로 경로만 대응시킨 뒤 해결된 행을 삭제하며, 전체 재생성으로 신규 위반을 숨기지 않습니다.

**검증·예상 허용 목록**

공통 명령: `dart format --output=none --set-exit-if-changed lib test` → `flutter analyze` → `flutter test --no-pub test/architecture test/contracts`. 아래 수치는 **기존 74개 간선에 대한 제거 예상치**입니다. 강화된 검사에서 발견되는 위반은 해당 PR에서 해결하며 새 예외를 추가하지 않습니다.

| PR | 추가 검증 명령·핵심 확인 | 예상 감소 → 잔여 |
|---|---|---|
| PR5 | `flutter test --no-pub test/features/auth/application test/core/network/api_client_auth_interceptor_test.dart test/features/home test/features/my test/features/search`; 계정 교체·토큰 만료·outbox 격리·중복 로그아웃 | **−41 → 33**: R4 −7, R2 −6, R5 −28 |
| PR6 | `flutter test --no-pub test/features/feed test/features/projects test/core/router/fan_subject_route_test.dart test/core/router/travel_review_route_test.dart`; 뉴스/게시물 분리·팔로우/차단·draft·번역·신고 | **−6 → 27**; 6a −1, 6b 0, 6c 0, 6d −5 |
| PR7 | `flutter test --no-pub test/features/places test/features/visits test/features/verification`; 일반 장소/일반 live/retry 성공 조합·실패 시 기록 보존·두 상세 진입점 | **−23 → 4**: R2 −4, R5 −19 |
| PR8 | `flutter test --no-pub` 및 `flutter build apk --debug --no-pub`; 기존 golden 유지, route inventory·deeplink·탭 복귀·알림 진입 | **−4 → 0** |

가장 큰 위험은 경로 변경보다 **세션 정리 순서, FCM background 초기화, 인증 후 중복 refresh, 새 하위 feature 순환**입니다. PR5는 `상태·hook → 알림 분리 → 화면 이동`, PR7은 `호출 추출 → 물리 이동`으로 나눕니다. API 필드·nullability·저장 키·탭 순서·route 이름은 유지합니다.

동시 편집 4개 작업이 끝난 파일부터 이동합니다. 실행 시 최신 파일 목록과 위 manifest를 대조하고, **router·bootstrap·checker·allowlist·이동 작업은 한 명이 순차 반영**합니다. 각 PR 완료 시 기존 CHANGELOG·TODO·설계 기록을 갱신하되 다른 작업자의 수정·삭제를 덮어쓰지 않습니다.