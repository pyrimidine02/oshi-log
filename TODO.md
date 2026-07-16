# TODO

- Complete production and device QA for generalized fan subjects and travel reviews (2026-07-16):
  - Verify project, unit/band, and voice-actor preference reads/writes against
    the deployed HTTPS API and confirm project-scoped authorization is
    unchanged. Artist/anime remain server-side future types for now.
  - Create, reopen, edit, and delete a travel review on iOS and Android with a
    real verified visit and verified live attendance record.
  - Add image selection/upload IDs, editable tags, full-field edit controls, and
    infinite-scroll pagination to the travel-review UI.
  - Removal criteria: both device families pass the real account flow and the
    server record retains ordered stops, proof IDs, subjects, dates, and note.

- Add canonical cross-role person identity before dual-role catalog import
  (2026-07-16):
  - A voice actor who also releases music must keep one user-facing fan identity
    instead of separate `VOICE_ACTOR` and `ARTIST` subscriptions.
  - Removal criteria: catalog import resolves aliases to one canonical subject,
    role facets remain queryable, and subscription/content history is not split.

- Verify authoritative schedule synchronization after reviewed deployment (2026-07-16):
  - The local server now owns rolling official BanG Dream schedule synchronization;
    the app must continue consuming only the API, never scraping the site.
  - Verify source freshness, cancellation/restoration, multi-day projection, and
    parser-failure retention through production HTTPS and calendar UI.
  - Removal criteria: freshness alerting is active and a source parser failure
    cannot remove existing calendar rows.

- [x] Replace the travel-review mock routes with a real API contract (completed locally 2026-07-16):
  - DTO, data source, repository, Riverpod state, real list/detail/create/update/delete,
    ordered stops, event/visit proof references, trip metadata, and fan-subject links
    are implemented and covered by focused tests.
  - The audit notes below describe the pre-change state and are retained only as
    historical context; they no longer describe the routed implementation.
  - 현재 `travel_review_create_page.dart`는 실제 저장 없이 지연 후 성공으로 처리하고,
    `travel_review_detail_page.dart`는 route ID에 연결된 서버 데이터 대신 더미 내용을
    표시한다.
  - 작성·수정·삭제, 여행 일자, 장소 ID, 방문 기록 ID, 이벤트 ID, 이미지,
    공개 범위를 포함한 서버 계약을 먼저 확정한다.
  - 실제 계약 전에는 새로운 샘플 후기나 거짓 통계를 추가하지 않는다.
  - 제거 기준:
    - 실제 API·DTO·repository·controller·작성/상세 위젯 테스트와 운영 HTTPS
      end-to-end 저장·재조회가 모두 통과하면 제거.

- Remove unrouted legacy presentation siblings after parity verification (2026-07-15):
  - 구형 `home_page.dart`, `explore_page.dart`, `calendar_page.dart`, `live_events_page.dart`,
    `live_event_detail_page.dart`, `board_page.dart`, `feed_page.dart`, `info_page.dart`,
    `user_profile_page.dart`, `my_page.dart`는 현재 실제 GoRoute에서 열리지 않는다.
  - 삭제 전 deep link, 위젯 직접 import, 테스트·스토리 참조를 전수 검색하고
    신규 Field 화면이 동일 기능을 보존하는지 확인한다.
  - 제거 기준:
    - 참조 0건과 iOS·Android 핵심 루트 패리티 확인 후 별도 cleanup 변경으로 제거.

- Deploy and verify the calendar live-schedule backend contract (2026-07-15):
  - 서버의 `GET /api/v1/calendar/events` 공개 읽기 권한과
    `LiveEventSummaryDto.endTime` 응답 필드를 운영에 배포한다.
  - 미인증 상태에서 팬 캘린더가 200을 반환하고, 라이브 목록이
    `endTime`을 포함하는지 공개 HTTPS 경로로 확인한다.
  - 뱅드림 2026년 7월을 실제 앱에서 열어 `MyGO!!!!! 9th LIVE`가
    7월 18일과 19일, 대상 상세가 제공하는 다일 일정은 모든
    해당 날짜에 표시되는지 확인한다.
  - 제거 기준:
    - 서버 배포 후 미인증 캘린더 200, 라이브 `endTime`, 다일
      표시를 운영 API와 iOS/Android 각 1기기에서 확인하면 제거.

- Establish authoritative schedule synchronization and project-timezone projection (2026-07-15):
  - 뱅드림 등 공식 일정 소스의 추가·변경·취소를 서버에서
    주기적으로 대조하는 멱등 동기화 작업을 설계한다. 모바일 앱은
    공식 사이트를 직접 스크래핑하지 않는다.
  - 안정적인 외부 키, 출처 URL, 최종 확인 시각, 원본 수정 시각과
    멱등 upsert/중복 제거 규칙을 서버 계약으로 확정한다.
  - 캘린더 조회·월 필터·일별 투영이 기기의 `toLocal()` 대신
    선택한 `Project.defaultTimezone` IANA 시간대를 사용하도록 도메인
    날짜 정책을 분리한다.
  - 제거 기준:
    - 공식 일정 동기화의 재실행 멱등성·취소/일시 변경 반영과,
      `Asia/Tokyo`·`Asia/Seoul`·UTC 경계 테스트가 서버/앱에서 모두
      통과하면 제거.

- Run device QA for Urban Travel Field Notes UI rebuild (2026-07-15):
  - iOS/Android에서 홈 → 탐방(지도/이벤트/기록/도감) → 정보 → 커뮤니티 → 마이
    루트 전환과 기존 딥링크 진입을 확인.
  - 탐방 상단에 모드 선택기가 다시 쌓이지 않고, 60dp 별도 모드 도크가
    메인 하단바 위 8dp 간격과 일치하는지 확인. 지도·이벤트·여정 원장·
    표본 아카이브 전환 시 본문이 두 하단바에 가려지지 않는지 확인.
  - 커뮤니티 진입 시 기존 별도 하단바가 표시되고 피드/발견/여행후기 전환 및
    뒤로가기가 기존과 동일하게 동작하는지 확인.
  - 프로젝트 선택 바텀시트에서 다른 프로젝트 행 한 번으로 장소·일정·도감
    컨텍스트가 정확히 한 번 전환되고 시트가 닫히는지 확인. 현재 프로젝트를
    다시 탭하면 저장값과 선택 유닛이 바뀌지 않는지도 확인.
  - 홈에서 대표 일정/장소가 아래 섹션에 중복되지 않고, 오늘의 원정 브리핑
    → 그다음 일정 → 프로젝트 성지 → 프로젝트 소식 순서와 첫 주요 행동이
    하단바 위에서 읽히는지 확인.
  - 위치 권한 허용/거부/미결정 각각에서 지도 거리가 거짓 도쿄 기준값으로
    표시되지 않고 실제 거리 또는 서버 제공 순서를 유지하는지 확인.
  - 이벤트 즐겨찾기·출석·공식 티켓 링크·세트리스트와 유저 프로필의
    팔로우·차단·신고·연결 목록·편집 흐름을 실제 계정으로 회귀 확인.
  - 여정 원장에서 장소 방문/이벤트 출석 전환, 월별 정렬, GPS 인증 표시,
    상세·통계 라우팅과 도감 표본의 진행·완료 상태가 실제 계정 데이터와
    일치하는지 확인.
  - 지도 → 이벤트/기록/도감 → 지도 재진입을 반복해 폐기된 네이티브 지도
    controller 예외나 카메라 멈춤이 없는지 확인.
  - 앱을 종료한 후 도감 탭 딥링크로 바로 진입해도 저장된 프로젝트가
    복원되고, 복원 실패·빈 프로젝트 목록에서는 재시도/선택 상태로 전환되어
    표본 색인이 로딩에 머물지 않는지 확인.
  - VoiceOver/TalkBack으로 지도 검색·필터·원장 초기화/접기, 이벤트 모드·필터·
    출석, 프로젝트 렌즈와 방문 기록 행을 실제로 실행할 수 있는지 확인.
  - 노치/홈 인디케이터가 있는 기기, 320dp 폭, 200% 글자, 라이트/다크에서
    하단바 겹침·텍스트 잘림·터치 타깃 축소가 없는지 확인.
  - 제거 기준:
    - iOS/Android 각 1기기 이상에서 위 흐름과 접근성 QA를 통과하고,
      신규 Crashlytics 레이아웃/라우팅 오류가 24시간 발생하지 않으면 제거.

- Run QA for iOS native-assets objective_c runtime load fix (2026-03-31):
  - iOS Simulator(arm64/x64)에서 앱 시작 직후
    `DOBJC_initializeApi` / `objective_c.framework/objective_c` 예외가
    더 이상 발생하지 않는지 확인.
  - 홈/커뮤니티에서 `CachedNetworkImage`가 정상 로드되고
    이미지 캐시 경로 초기화 예외가 재발하지 않는지 확인.
  - 실기기(iOS 17+)에서도 동일 시나리오(앱 시작, 이미지 다수 화면 진입) 재확인.
  - 제거 기준:
    - 시뮬레이터 2종(arm64/x64) + 실기기 1대 이상에서 재현 실패 시 본 항목 제거.

- Run QA for client request guard hardening (2026-03-31):
  - 이미지 업로드에서 `contentType`이 대소문자 혼합(`Image/JPEG`)이어도
    direct upload로 정상 라우팅되는지 확인.
  - 빈 파일(`size=0`) 또는 비정상 `contentType` 입력에서
    서버 요청 없이 클라이언트에서 즉시 실패 처리되는지 확인.
  - 인증 만료/무효 세션 상태에서 홈/피드/알림/동의 상태 호출이
    반복 401 루프로 이어지지 않고 인증 해제 상태로 정리되는지 확인.
  - 로그 기준으로 `GET /api/v1/home/summary/by-project`,
    `GET /api/v1/community/feed/recommended/cursor`,
    `GET /api/v1/notifications`의 동일 세션 반복 401 빈도가 감소했는지 확인.
  - 제거 기준:
    - 내부 QA 2기기 이상에서 재현 실패 + 운영 로그에서 동일 시나리오 401 반복 패턴 감소 확인 시 본 항목 제거.

- Run QA for GIF upload direct-routing fix (2026-03-31):
  - Android/iOS에서 GIF 첨부 업로드 시 `POST /api/v1/uploads` direct endpoint로
    요청이 나가는지 앱 로그/서버 로그로 확인.
  - 동일 시나리오에서 `POST /api/v1/uploads/presigned-url` 요청이
    더 이상 발생하지 않는지 확인.
  - 업로드 후 게시글 본문/리스트/상세에서 GIF 애니메이션 재생이
    기대대로 유지되는지 확인.
  - JPEG/WEBP 등 일반 이미지 업로드 회귀(실패/속도 저하)가 없는지 확인.
  - 제거 기준:
    - Android/iOS 각 1기기 이상에서 GIF + 일반 이미지 업로드 QA 통과 시 본 항목 제거.

- Run QA for community compose FAB tap/overlap fix (2026-03-31):
  - iOS 커뮤니티 탭(`/community`)에서 작성 FAB 메인 버튼 탭 시
    메뉴 열림/닫힘이 매번 반응하는지 확인.
  - iOS에서 확장 액션(`게시글 작성`, `내 신고 내역`, `커뮤니티 제재 관리`)이
    터치 누락 없이 정상 동작하는지 확인.
  - Android 커뮤니티 탭에서 FAB/확장 액션이 하단바 위에 완전히 노출되고
    하단바와 겹치지 않는지 확인.
  - iOS/Android 모두에서 FAB가 하단바 상단에 과도하게 뜨지 않고,
    하단바 바로 위 사용자 요구 간격으로 배치되는지 확인.
  - 메인 피드의 커뮤니티 FAB(`feed_page`)도 동일하게 하단바 간섭 없이
    동작하는지 확인.
  - 제거 기준:
    - iOS/Android 각 1기기 이상에서 FAB 탭/라우팅 + 하단 정렬 QA 통과 시 본 항목 제거.

- Run QA for social notification delivery hardening (2026-03-30):
  - 팔로우 유저가 새 글 작성 시 `POST_CREATED` 계열 알림이 수신되는지 확인.
  - 내 글에 새 댓글 작성 시 `COMMENT_CREATED` 계열 알림이 수신되는지 확인.
  - 내 댓글에 새 답글 작성 시 `COMMENT_REPLY_CREATED` 계열 알림이 수신되는지 확인.
  - 위 3종 알림에서 foreground/background 모두 알림 수신 + 알림함 반영 + 탭 라우팅이
    정상 동작하는지 확인.
  - `notificationType/type/eventType` 키 중 어떤 조합으로 와도
    타입 매핑이 정상 적용되는지 로그 기반으로 샘플 검증.
  - 제거 기준:
    - Android/iOS 각 1기기 이상에서 3종 알림 end-to-end QA 통과 시 본 항목 제거.

- Superseded — Android-only Material 3 visual polish (2026-03-30, replaced 2026-07-15):
  - 2026-07-15 전면 재설계로 플랫폼별 구 디자인 유지 요구를 폐기하고,
    iOS/Android 모두 Urban Travel Field Notes 디자인을 검수 대상으로 삼는다.
  - Android에서만 하단 네비게이션/커뮤니티 서브 하단바가
    라운드 컨테이너 + 톤드 surface + 선택 상태 강조로 표시되는지 확인.
  - iOS/Android에서 새 메인 하단바·프로필 디자인과 탐방 전용 하단 도크가
    동일한 정보 구조로 동작하는지 확인한다.
  - 프로필 페이지 Android에서:
    - 헤더 뒤로가기 버튼 가독성/터치 영역(최소 44dp) 확인
    - `프로필 수정/칭호`, `팔로우/차단` 버튼 높이/패딩 증가가 의도대로 반영되는지 확인
    - 팔로워/팔로잉 영역 ripple 피드백 및 탭 이동 동작 확인
    - 스티키 탭바 스크롤 시 elevation 계층이 자연스러운지 확인
  - 작성한 글/댓글 목록에서 Android 카드 간 간격/메타 텍스트 가독성 개선이
    일관되게 적용되는지 확인.
  - 제거 기준:
    - Android/iOS 각 1기기 이상에서 시각 QA 및 기본 네비게이션 플로우 통과 시 본 항목 제거.

- Run QA for cache tiering + sensitive local storage hardening (2026-03-30):
  - 캐시/스토리지 데이터 분류 기준 점검:
    - 메모리/로컬 캐시 허용 데이터(비민감 목록/피드/카탈로그/설정 스냅샷)가
      정상 조회되고 앱 재시작 후 LocalStorage fallback이 동작하는지 확인.
    - 민감 데이터(`notificationDeviceId`, `notificationPushToken`)가
      LocalStorage에 남지 않고 SecureStorage 우선 저장으로 유지되는지 확인.
  - 로그아웃 직후 `feed_post_create_draft_*`, `feed_post_edit_draft_*` 키가
    모두 제거되는지 확인.
  - 오래된 작성 draft(`savedAt + retention` 경과)가 조회 시 자동 삭제되는지 확인.
  - 푸시 등록 해제 성공/404 케이스에서 secure + legacy 키가 모두 정리되는지 확인.
  - 제거 기준:
    - iOS/Android 각 1기기 이상에서 캐시 hit/재시작 fallback/로그아웃 정리/푸시 키 정리 QA 통과 시 본 항목 제거.

- Superseded — My sub-page appbar standardization (2026-03-30, replaced 2026-07-15):
  - 2026-07-15 전면 재설계 이후에는 기존 AppBar 복원이 아니라 각 도메인의
    문서형 헤더와 48dp 이상 터치 영역을 기준으로 검수한다.
  - `정보/유저` 탭과 동일한 상단바 톤(배경/타이포/그림자 없음)이
    아래 페이지에서 일관되게 적용되는지 확인:
    `나의 덕력`, `성지순례 도감(목록/상세)`, `응원 가이드(목록/상세)`,
    `명대사 카드`, `즐겨찾기`, `북마크한 글`, `방문 기록`, `방문 통계`,
    `칭호 관리`, `이벤트 캘린더`.
  - `나의 덕력` 진입 시 `점수 부여 행위 전체` 섹션에
    점수 부여 행위 카테고리가 모두 노출되는지 확인.
  - `점수 획득 내역`에는 0점 항목이 제외되고
    실제 점수 획득 항목만 표시되는지 확인.
  - 라이트/다크 모드 각각에서 상단바 대비와 가독성이 유지되는지 확인.
  - 제거 기준:
    - iOS/Android 각 1기기 이상에서 상단바 통일 + 덕력 섹션 QA 통과 시 본 항목 제거.

- Run QA for news controller dispose-safety fix (2026-03-30):
  - `Info` 또는 커뮤니티 이동 직후 빠르게 탭 전환/뒤로가기를 반복해도
    `Bad state: Tried to use NewsListController after dispose` 크래시가 재발하지 않는지 확인.
  - 뉴스 목록/상세 요청 중 화면 이탈 후 복귀했을 때 로딩/재시도 UX가 정상인지 확인.
  - Crashlytics에서 동일 시그니처
    (`NewsListController.load`, `NewsDetailController.load`) 신규 발생이 없는지 확인.
  - 제거 기준:
    - 내부 QA 기기 2대 이상에서 재현 시도 실패 + Crashlytics 신규 발생 0건 24시간 유지 시 본 항목 제거.

- Superseded — explore map edge-to-edge fill (2026-03-30, replaced 2026-07-15):
  - 새 지도 기준은 56dp 미션 스트립 + 지도 캔버스 + 하단 현장 원장이며,
    검색/필터 헤더와 상단 서브탭은 더 이상 존재하지 않는다.
  - 탐방 탭 지도 모드에서 지도 타일이 상태바 영역(노치/다이내믹 아일랜드 상단 포함)까지 연속적으로 채워지는지 확인.
  - 상단 검색/필터 헤더가 상태바와 겹치지 않고 기존 터치 영역/가독성을 유지하는지 확인.
  - 탐방 내 다른 서브탭(이벤트/방문기록/성지도감) 진입 시 AppBar 상단 여백/터치 영역이 기존과 동일한지 확인.
  - iOS/Android 각 1기기 이상에서 상단 빈 여백 회귀가 없는지 확인.
  - 제거 기준:
    - iOS/Android 탐방 탭 시각 QA 통과 후 본 항목 제거.

- Superseded — explore map top readability blur layer (2026-03-30, replaced 2026-07-15):
  - 새 지도는 상단 블러·검색 카드·필터 칩을 사용하지 않는다. 56dp 미션
    스트립의 대비와 지도 팬/줌 성능을 기준으로 검수한다.
  - 탐방 지도 상단에서 상태바 시간/아이콘 가독성이 밝은 지도 타일에서도 유지되는지 확인.
  - 상단 검색 카드/필터 칩 뒤 배경이 과도하게 뿌옇지 않고, 지도 맥락이 유지되는지 확인.
  - iOS/Android에서 상단 오버레이 경계(블러 종료 지점) 밴딩/이음선이 보이지 않는지 확인.
  - 성능 측면에서 지도 팬/줌 중 프레임 드랍(jank) 증가가 없는지 확인.
  - 제거 기준:
    - iOS/Android 각 1기기 이상에서 시각+성능 QA 통과 시 본 항목 제거.

- Run QA for home top header readability improvement (2026-03-30):
  - 홈 상단(스크롤 전)에서 `Girls Band Tabi` 타이틀과 검색/알림 아이콘이
    밝은 색으로 충분히 구분되어 보이는지 확인.
  - 밝은/복잡한 헤더 배경 이미지에서도 인사말 title/subtitle 및 featured live 칩 텍스트가
    읽기 쉬운 대비를 유지하는지 확인.
  - 스크롤 후 AppBar가 반투명 배경으로 전환될 때
    타이틀/아이콘 색상이 자연스럽게 다크 톤으로 바뀌고 가독성이 유지되는지 확인.
  - iOS에서 상태바 시계/아이콘, Android에서 상태바 아이콘이
    스크롤 전/후 모두 배경과 충돌 없이 표시되는지 확인.
  - 제거 기준:
    - iOS/Android 각 1기기 이상에서 메인 홈 상단 시각 QA 통과 시 본 항목 제거.

- Run QA for user profile header visual refresh (2026-03-30):
  - 커버 이미지가 밝거나 복잡한 경우에도 뒤로가기 버튼(원형 배경 포함) 가독성이
    유지되는지 확인.
  - 상단 AppBar 타이틀 제거 후 스크롤(확장/축소) 시 헤더 정보 구조가 어색하지
    않은지 확인.
  - 아바타가 커버/본문 경계에 반씩 걸쳐 보이고, 내/타인 프로필 모두에서
    가려짐 없이 유지되는지 확인.
  - 커버 이미지가 `contain` 기준으로 잘림 없이 전체 노출되는지,
    가로/세로 비율이 다른 이미지 각각에서 확인.
  - 커버 헤더 높이 상향(`280`) 이후 상단 잘림/여백 과다 없이
    원하는 범위가 노출되는지 확인.
  - 프로필 사진/커버 이미지 탭 시 풀스크린 확대 뷰어가 열리고,
    핀치 줌/팬이 동작하는지 확인.
  - 확대 뷰어에서 다운로드 버튼/저장 액션이 노출되지 않는지 확인.
  - `프로필 수정/칭호` 버튼이 흰 경계 바로 아래(우측 상단)에 배치되는지 확인.
  - 표시 이름 우측에 활성 칭호 배지가 나란히 표시되고,
    긴 닉네임에서도 레이아웃 깨짐이 없는지 확인.
  - 닉네임/가입일/소개가 아바타 바로 아래에서 시작되는지 확인.
  - 활동 통계 2열 카드 패널(그라데이션 카드)에서 라벨/값 가독성과
    라이트/다크 대비가 충분한지 확인.
  - `작성한 글`/`작성한 댓글` 카드가 동일한 톤으로 표시되고,
    긴 텍스트/빈 내용 케이스에서 줄바꿈/말줄임이 안정적인지 확인.
  - `덕력/성지 기록/라이브 기록` 숏컷이 3열 카드형으로 균일 폭/높이로
    렌더링되고 통계 카드와 톤이 일치하는지 확인.
  - 제거 기준:
    - iOS/Android 각 1기기 이상에서 내/타인 프로필 QA 통과 시 본 항목 제거.

- Run QA for FanLevelPage entry animation + Hero swipe-back (2026-03-29):
  - `FanLevelPage` 진입 시 등급 카드와 활동 목록이 순차 슬라이드업 애니메이션으로 표시되는지 iOS/Android 실기기 확인.
  - `disableAnimations`(접근성 설정 > 모션 줄이기) 활성화 시 애니메이션 없이 즉시 표시되는지 확인.
  - 장소 카드 → 상세 페이지 전환 + iOS 스와이프 백 시 Hero 이미지 전환이 자연스러운지 확인.
  - 이벤트 카드 → 상세 페이지 전환 + iOS 스와이프 백 시 Hero 포스터 전환이 자연스러운지 확인.
  - `GBTFeaturedEventCard`(16:9 배너) Hero도 동일하게 동작하는지 확인.
  - 제거 기준:
    - iOS/Android 각 1기기 이상 실기기 QA 통과 + 애니메이션 jank 미발생 시 본 항목 제거.

- Run QA for user profile activity overview + cover visibility update (2026-03-26):
  - 내 프로필/타인 프로필에서 활동 요약 카드(XP/레벨/성지/라이브/글/댓글)가
    레이아웃 깨짐 없이 노출되는지 확인.
  - 내 프로필에서 덕력/성지 기록/라이브 기록 숏컷 칩이 각각
    `/fan-level`, `/visits`, `/visits?tab=live`로 정확히 이동하는지 확인.
  - 프로필 편집 크롭 비율(16:9)과 프로필 헤더 표시 비율(16:9)이
    Android/iOS에서 동일하게 보이는지 시각 검수.
  - 커버 업로드 고해상도(`2560x1440`) 반영 후에도 업로드 실패율/지연이
    증가하지 않는지 확인.
  - 백엔드 기본값 응답(`0`, `fanLevel=1`, `fanGrade="일반인"`)에서
    활동 카드가 `-`가 아닌 값으로 정상 표시되는지 확인.
  - 제거 기준:
    - 내/타인 프로필 각각 2회 이상 실기기 QA 통과 + 크래시 미발생 시 본 항목 제거.

- Run QA for Android image_cropper single-reply guard (2026-03-26):
  - Samsung 실기기(Android 13/14/15 우선)에서 프로필 사진/배경 변경을
    빠르게 연속 탭해도 플로우가 1회만 진행되고 크래시가 없는지 확인.
  - 크롭 완료/취소/뒤로가기/앱 백그라운드 복귀 시
    `Reply already submitted` 크래시가 재발하지 않는지 Crashlytics로 확인.
  - Samsung 단말에서는 임시 우회 정책에 따라
    크롭 UI 없이 업로드가 정상 완료되는지 확인.
  - 이미지 선택/크롭 시작 실패(권한 거부, 액티비티 실행 실패) 상황에서
    앱이 종료되지 않고 에러 메시지로 복귀하는지 확인.
  - 제거 기준:
    - Samsung 2기기 이상에서 2일 이상 모니터링 시
      동일 크래시 시그니처 신규 발생 0건이면 본 항목 제거.

- Run QA for Android image_cropper ActivityNotFound fix (2026-03-26):
  - Samsung 실기기(Android 13/14/15 우선)에서 이미지 선택 후 크롭 진입 시
    `PlatformException(activity_not_found)` 없이 편집 화면이 열리는지 확인.
  - 원형/사각 크롭 각각에서 완료/취소 플로우가 정상 복귀하는지 확인.
  - 앱 릴리즈 빌드(AAB 설치본)에서 동일 플로우 재검증.
  - 제거 기준:
    - 내부 테스터 2기기 이상에서 1일 내 크래시 재발 0건이면 본 항목 제거.

- Run QA for Android in-app profile cropper migration (2026-03-30):
  - Android 13/14/15 실기기에서 프로필 사진(1:1), 커버(16:9) 크롭 UI가
    앱 내부 다이얼로그로 정상 표시되는지 확인.
  - 크롭 적용/취소/뒤로가기/앱 백그라운드 복귀 시 앱 프로세스 크래시 없이
    편집 화면으로 안전 복귀하는지 확인.
  - 크롭 결과 업로드 후 미리보기(프로필/커버)가 의도한 비율로 반영되는지 확인.
  - 제거 기준:
    - Android 3기기 이상에서 2일 모니터링 동안 크롭 관련 fatal crash 0건.

- Run QA for SSE disconnect fatal-error guard (2026-03-26):
  - Samsung 실기기에서 알림/커뮤니티 화면 활성 상태로 유지한 뒤
    Wi-Fi ↔ LTE 전환을 반복해 `Connection closed while receiving data`
    발생 시 앱이 종료되지 않고 자동 재연결되는지 확인.
  - 앱 백그라운드 전환(30초~2분) 후 복귀 시 SSE가 정상 재연결되고
    알림 목록 백그라운드 동기화가 유지되는지 확인.
  - 알림/피드에서 네트워크 강제 차단 후 해제했을 때
    unhandled/fatal 크래시 리포트가 추가로 발생하지 않는지 확인.
  - 제거 기준:
    - Samsung 2개 이상 기기에서 1일 이상 soak test 수행 후
      fatal crash 미재현이면 본 TODO 항목 제거.

- Run QA for iOS archive native-asset dSYM fix (2026-03-26):
  - Xcode Archive 생성 후 `Runner.xcarchive/dSYMs/objective_c.framework.dSYM` 존재 확인.
  - `dwarfdump --uuid`로 `Runner.app/Frameworks/objective_c.framework/objective_c`와
    dSYM UUID가 동일한지 확인.
  - App Store Connect 업로드에서 `objective_c.framework missing dSYM` 오류가
    재발하지 않는지 확인.
  - 제거 기준:
    - 내부/외부 테스트 채널 업로드 1회 이상 성공 시 본 TODO 항목 제거.

- Run QA for mobile push integration hardening (2026-03-26):
  - Android/iOS 실기기에서 `POST /api/v1/notifications/devices` payload에
    `deviceHash`(64자 hex), `timezone`(IANA)가 포함되는지 프록시/로그로 확인.
  - 앱 종료 상태 푸시 탭, 백그라운드 탭, 로컬 fallback 알림 탭 각각에서
    `POST /api/v1/notifications/{id}/open`가 호출되는지 확인.
  - 인증 만료/네트워크 실패 상황에서 오픈 추적 실패가 UX(라우팅/알림함)에
    영향이 없는지 확인.
  - 제거 기준:
    - 내부 테스트 채널에서 Android/iOS 각각 최소 1회 이상 정상 수집 확인 후
      본 TODO 항목 제거.

- Backend follow-up for banner feature (2026-03-13):
  - `GET /api/v1/users/me/banner`, `PUT /api/v1/users/me/banner`, `DELETE /api/v1/users/me/banner`,
    `GET /api/v1/banners` 엔드포인트 서버 구현 확인.
  - `BannerItem.isActive` 필드를 서버가 사용자 컨텍스트 기반으로 올바르게 반환하는지 확인.
  - 배너 카탈로그 cache TTL(1h)이 서버 업데이트 주기와 적절한지 운영 협의.
  - 배너 해금 조건(tier, title) 서버-클라 동기화 방식 확정 (현재: `unlockDescription` 문자열 기반).
  - Widget test 추가: `BannerPickerPage` 로딩/오류/데이터 상태 최소 커버리지 확보.



- Run QA for offline mode phase 1 (2026-03-13):
  - 오프라인 진입 시 홈/장소/피드 등 캐시 기반 화면이 네트워크 재시도 루프 없이 기존 캐시를 즉시 보여주는지 확인.
  - 오프라인 + 캐시 미스 화면에서 `offline_cache_miss` 메시지 정책이 일관되게 노출되는지 확인.
  - 즐겨찾기 토글을 오프라인에서 반복 변경했을 때 마지막 상태만 대기 작업으로 유지되는지 확인.
  - 온라인 복귀 직후 즐겨찾기 대기 작업이 자동 동기화되고 목록 상태가 서버와 일치하는지 확인.
  - 게시글 좋아요/북마크 토글을 오프라인에서 반복 변경했을 때 마지막 상태만 대기 작업으로 유지되는지 확인.
  - 게시글 상세/피드 카드에서 오프라인 토글 후 즉시 UI 반영되고, 온라인 복귀 후 서버 상태와 재동기화되는지 확인.
  - 라이브 상세에서 출석 토글을 오프라인으로 반복 변경했을 때 마지막 상태만 대기 작업으로 유지되는지 확인.
  - 오프라인 상태로 라이브 상세 재진입 시 대기 작업 기준 출석 상태가 즉시 반영되는지 확인.
  - 온라인 복귀 직후 라이브 출석 대기 작업이 자동 동기화되고 방문 기록(라이브 탭)에 반영되는지 확인.
  - 로그아웃 상태에서 즐겨찾기/라이브 출석 대기 작업이 오작동/무한재시도하지 않는지 확인.

- Run brand QA for logo concept v1 (2026-03-12):
  - `docs/design/logo/girlsbandtabi_logo_v1.svg`를 iOS/Android 앱아이콘 마스킹 기준으로 시각 검수.
  - 작은 크기(24/32/48px)에서 음표/픽 식별성 확인.
  - 다크/라이트 배경 각각에서 대비(contrast) 기준 확인.

- Backend follow-up for community report reason enum expansion (2026-03-12):
  - 서버 `community report reason` enum에
    `TRADE_INDUCEMENT`, `FALSE_REPORT_ABUSE`, `MANIPULATION_ABUSE`
    정식 추가 가능 여부 확인.
  - 서버 정식 지원 완료 시 프런트 fallback(`reason=OTHER + description marker`)
    제거하고 직접 코드 전송으로 전환.

- Run policy-ops QA for community rules hardening (2026-03-12):
  - `docs/legal/커뮤니티이용규칙_v2026.03.12.md` 공지본 반영 전 운영/법무 최종 검토.
  - 신고 사유 UI에 `거래 유도`, `허위/보복 신고`, `조작/어뷰징` 추가 필요 여부 확정.
  - 운영툴 임시조치(게시글/댓글 잠금, 쿨다운) 액션 지원 범위 확정.

- Run QA for music information + live setlist frontend integration (2026-03-12):
  - Info > 악곡 탭에서 앨범/곡 목록이 프로젝트 전환 시 정상 갱신되는지 확인.
  - 곡 목록 하단 스크롤 시 cursor 기반 load-more가 중복 호출 없이 동작하는지 확인.
  - 곡 상세에서 `Romanized/Translated` 토글 시 가사 요청 파라미터와 화면 반영이 일치하는지 확인.
  - 라이브 상세 세트리스트에서 `eventStatus=COMPLETED` 케이스가 정상 렌더되는지 확인.
  - 세트리스트 `songId=null` 항목은 비활성, `songId!=null` 항목은 곡 상세로 이동되는지 확인.
  - 오버레이 컨텍스트(검색/알림/설정 등)에서 곡 상세 라우팅이 스택 깨짐 없이 동작하는지 확인.

- Backend follow-up for music info API request doc (2026-03-12):
  - `docs/api-spec/악곡정보_백엔드요청서_v1.0.0.md` 기준으로
    앨범/곡/가사/파트/콜표 엔드포인트 확정안을 백엔드와 합의.
  - 버전/세트리스트/크레딧/난이도/미디어/가용성 6개 확장 항목의
    엔드포인트 제공 방식(개별 API vs 곡 상세 확장) 확정.
  - 더미데이터(JSON)를 서버 스테이징에 적재해 모바일 화면에서
    타임라인 정합성(lyrics/parts/callGuide 동일 버전) 점검.
  - `MUSIC_*` 에러코드 및 `version/lang` 파라미터 표준 계약 확정.
  - 추가 제한사항(`size/q/cursor`, 타임라인 무결성, 필드 길이/개수,
    `ETag/revision`, `429 Retry-After`) 서버 구현 가능 범위 확정.

- Run QA for home greeting header small-device wrapping fix (2026-03-11):
  - iPhone SE급/좁은 폭 기기에서 홈 인사말 title/subtitle이 말줄임만 되고 의미가 잘리지 않는지 확인.
  - 사용자명이 긴 계정에서도 인사말이 2줄 내에서 자연스럽게 노출되는지 확인.
  - featured live 칩이 함께 있을 때도 헤더 하단 요소가 겹치거나 잘리지 않는지 확인.

- Run QA for OAuth state nonce hardening (2026-03-11):
  - 소셜 로그인 진입 시 authorize URL에 `state`가 포함되는지 네트워크 탭에서 확인.
  - 콜백 `state`가 누락/변조된 경우 로그인 완료가 차단되고 에러 안내가 노출되는지 확인.
  - 정상 콜백 후 pending state가 secure storage에서 제거되는지 확인.

- Run QA for admin access + mandatory consent repository migration (2026-03-11):
  - 일반 사용자 계정으로 운영센터 진입 시 Admin API 호출이 발생하지 않는지 확인.
  - 필수 동의 차단 상태에서 `GET /users/me/consent-status` 로딩/실패/재시도 동작 확인.
  - `동의하고 계속` 제출 시 `POST /users/me/consents` 성공 후 차단 해제가 되는지 확인.

- Run QA for places map frame-callback/dispose hardening (2026-03-11):
  - 장소 탭 진입/이탈 반복 시 지도 관련 dispose 에러/경고가 재발하지 않는지 확인.
  - 탭 활성 상태에서 프레임마다 카메라 센터링 콜백이 누적되지 않는지 로그로 확인.
  - 장시간 사용 후 지도 메모리 사용량이 이전 대비 안정적인지 확인.

- Run QA for notification settings conflict auto-recovery (2026-03-10):
  - 알림 설정 저장 시 `409 CONFLICT`가 발생해도 최신값 재조회 후 재시도로
    최종 저장 성공까지 이어지는지 확인.
  - `NOTIFICATION_SETTINGS_VERSION_CONFLICT` + `error.details.current` 응답에서
    서버 최신 스냅샷(version/categories/updatedAt) 기준으로 복구되는지 확인.
  - 복구 재시도 중 토글이 이전값으로 튀지 않고 사용자 의도값을 유지하는지 확인.
  - 복구 재시도까지 실패하면 저장 실패 스낵바가 노출되는지 확인.
  - `FOLLOWING_POST` 토글 ON/OFF가 저장 후 재진입 시 유지되는지 확인.
  - 알림 타입 `FOLLOWING_POST_CREATED`, `MY_POST_COMMENT_CREATED`,
    `MY_COMMENT_REPLY_CREATED` 수신 시 알림함/탭 라우팅이 정상 동작하는지 확인.

- Run QA for unit/member/voice-actor integration (2026-03-10):
  - 정보(Info) 화면 `성우` 탭에서 목록/검색/페이지네이션이 정상 동작하는지 확인.
  - 유닛 상세/멤버 상세가 `unitIdentifier` slug/UUID 혼용에서 모두 진입 가능한지 확인.
  - 멤버 상세에서 `voiceActors[]` 역할 타입이 누락 없이 렌더링되는지 확인.
  - 성우 상세 `담당 캐릭터/크레딧` 탭이 빈 상태/에러/정상 상태에서 일관되게 노출되는지 확인.
  - 장소 상세 후기 카드에서 작성자/모더레이터만 삭제 메뉴가 보이고,
    삭제 성공 시 목록이 즉시 갱신되는지 확인.

- Run QA for image processing policy update + admin media deletion flow (2026-03-10):
  - place detail 방문 후기 카드에서 `사진 승인/사진 반려` 버튼이 완전히 제거됐는지 확인.
  - 일반 사용자 후기 이미지가 업로드 직후 별도 승인 대기 없이 노출되는지 확인.
  - 운영 센터 `미디어 삭제` 탭에서 `PENDING` 요청 목록이 로드되는지 확인.
  - `미디어만 삭제` 승인 시 요청이 처리되고 목록/대시보드 카운트가 갱신되는지 확인.
  - `연관 콘텐츠 포함 삭제` 승인 시 `deleteLinkedContents=true`로 요청되는지 확인.
  - `반려` 처리 시 요청이 목록에서 제거되고 재조회 시 상태가 반영되는지 확인.

- Run QA for mandatory consent status dynamic contract v1.0.0 (2026-03-10):
  - 로그인 직후 `GET /api/v1/users/me/consent-status`가 호출되고,
    `canUseService=false`면 앱 전역 차단 오버레이가 노출되는지 확인.
  - `requiredConsents` 중 `needsReconsent=true` 항목만 체크 가능하며,
    모든 필수 항목 동의 전까지 `동의하고 계속` 버튼이 비활성인지 확인.
  - 동의 항목의 `보기` 버튼이 `policyUrl` 링크를 정확히 여는지 확인.
  - `POST /api/v1/users/me/consents` 성공 후 즉시 상태 재조회되고
    차단이 해제되는지 확인.
  - 상태 조회 실패 시 오버레이의 `동의 상태 다시 확인` 버튼으로 복구되는지 확인.
  - 제출 실패 시 스낵바(토스트)가 노출되고 재시도 가능한지 확인.

- Run QA for admin role-request flow integration (2026-03-09):
  - 계정도구 `권한 요청` 탭에서 `수정권한/관리권한` 요청 생성이 실제 API(`POST /projects/role-requests`)로 반영되는지 확인.
  - 내 요청 목록(`GET /projects/role-requests`) 상태 배지와 취소(`DELETE /projects/role-requests/{requestId}`) 동작 확인.
  - 운영센터 `권한 요청` 탭에서 목록 필터/승인/거절(`PATCH /admin/projects/role-requests/{requestId}/review`) 동작 확인.
  - 승인/거절 후 목록 상태가 즉시 갱신되고 중복 처리(연타) 시 UI가 안정적인지 확인.

- Run QA for home project-switch instant cache apply (2026-03-09):
  - 홈에서 프로젝트 칩을 바꿀 때 수동 새로고침 없이 요약 섹션이 즉시 전환되는지 확인.
  - 프로젝트 연속 전환(빠르게 2~3회) 시 마지막 선택 프로젝트 요약만 남는지 확인.
  - selectedProjectKey/selectedProjectId 갱신 경계에서 이전 프로젝트 데이터가 재등장하지 않는지 확인.

- Run QA for Samsung physical-device community thumbnail issue (2026-03-09):
  - Samsung Galaxy 실기기에서 게시글 작성 직후 피드/게시판 카드 썸네일이 즉시 노출되는지 확인.
  - 작성 직후 게시글 상세/수정 페이지에서 이미지 URL이 비어 있지 않은지 확인.
  - 로그에서 `PostCreatePage`/`PostEditPage` unresolved URL warning이 반복되는지 확인.

- Run QA for Android post thumbnail normalization hardening (2026-03-09):
  - Android에서 새 게시글 작성 직후 피드/게시판 카드에 썸네일이 즉시 노출되는지 확인.
  - 상대경로/스킴 없는 URL 응답(`uploads/...`, `r2.pyrimidines.org/...`) 케이스에서도 카드 썸네일이 깨지지 않는지 확인.
  - 게시글 상세 진입 시 기존 이미지 노출/확대보기 동작이 회귀 없이 유지되는지 확인.

- Run QA for settings privacy/consent repository migration (2026-03-09):
  - 개인정보 및 권리행사 페이지 진입 시 privacy settings/요청 이력이
    repository 경유로 정상 로드되는지 확인.
  - 자동번역 토글 저장/충돌 복구/처리정지 요청/회원탈퇴 동작이 기존 UX와
    동일하게 유지되는지 확인.
  - 동의 이력 페이지에서 로딩/에러/빈상태/리스트 상태가 정상 노출되는지 확인.

- Run QA for board lifecycle and polling policy update (2026-03-09):
  - Board 탭 진입/이탈 반복 시 SSE 연결/해제가 중복 없이 안정적으로 동작하는지 확인.
  - foreground 폴링이 25초 간격으로 동작하고, 체감 최신성 문제가 없는지 확인.
  - 앱 백그라운드 전환 후 복귀 시 즉시 새로고침 동작이 정상인지 확인.

- Test debt: feed integration test environment bootstrap (2026-03-09):
  - `test/features/feed/presentation/pages/post_compose_autosave_integration_test.dart`
    실행 시 `AppConfig.baseUrl` 미초기화(`LateInitializationError`) 이슈를
    공통 테스트 bootstrap에서 해결.

- Run QA for Firebase Analytics event wiring (2026-03-09):
  - 로그인 성공 시 Firebase DebugView에서 `login(method=password|provider)`
    이벤트가 수신되는지 확인.
  - 회원가입 성공 시 `signup(method=password)` 이벤트가 수신되는지 확인.
  - 통합검색 제출 시 `search(query)` 이벤트가 수신되는지 확인.
  - 게시글 작성 성공 시 `post_create(category)` 이벤트가 수신되는지 확인.
  - 홈 `추천 장소/트렌딩 라이브` 카드 탭 시 `place_visit/live_event_view`
    이벤트가 수신되는지 확인.
  - 라우트 이동 시 `screen_view`가 경로 변경 기준으로 기록되는지 확인.

- Run QA for Android platform UX branching (2026-03-09):
  - Android에서 메인 하단 네비가 Material `NavigationBar`로 노출되고
    탭 ripple/선택 인디케이터가 보이는지 확인.
  - Android에서 게시판 서브 하단 네비(피드/발견/여행후기)가
    Material 스타일로 표시되고 back/탭 전환이 정상인지 확인.
  - iOS에서 기존 유리(blur) 네비게이션 디자인이 유지되는지 확인.
  - Android 접근성 큰 글꼴(시스템 글꼴 확대)에서 `1.6` 범위까지
    주요 화면 레이아웃이 깨지지 않는지 확인.
  - Search/LiveDetail 뒤로 아이콘이 Android/iOS에서 각 플랫폼 스타일로
    노출되는지 확인.
  - Home/Settings/Profile 등 주요 세로 스크롤 화면에서 Android는
    clamping, iOS는 bouncing 체감이 유지되는지 확인.

- Run QA for community/detail/notification stability bundle (2026-03-09):
  - 커뮤니티 프로필 `작성한 글/댓글`에서 게시글 상세 진입 시 본문/댓글이
    정상 노출되는지 확인(프로젝트 혼합 데이터 포함).
  - 즐겨찾기 `장소/게시글` 탭에서 상세 진입이 흰 화면 없이 정상 동작하는지 확인.
  - 알림 설정 토글을 빠르게 연타해도 저장 실패 토스트 없이 최종 상태가 유지되는지 확인.
  - 게시글 액션에서 `좋아요`와 `저장` 문구/동작/실패 메시지가 분리되어
    사용자에게 명확히 전달되는지 확인.
  - 커뮤니티 피드에서 신규 글/댓글 반영 지연이 기존 대비 줄었는지
    (SSE + 12초 폴링 보조) 실기기에서 체감 확인.

- Run QA for home-card detail loading fix (2026-03-09):
  - 홈 `추천 장소` 카드 탭 시 장소 상세가 로딩 고정 없이 정상 노출되는지 확인.
  - 홈 `트렌딩 라이브` 카드 탭 시 라이브 상세가 로딩 고정 없이 정상 노출되는지 확인.
  - 프로젝트 선택 직후/앱 재시작 직후(프로젝트 컨텍스트 늦게 준비되는 상황)에도
    상세 페이지가 무한 로딩이 아닌 정상 로드 또는 명시적 에러로 전환되는지 확인.
  - 현재 선택 프로젝트와 다른 프로젝트 데이터 카드 탭 시에도 fallback 탐색으로
    상세를 가져오는지 확인.

- Run QA for Xcode Cloud iOS plist injection flow (2026-03-09):
  - Xcode Cloud Archive 로그에서 `GoogleService-Info.plist` 생성 로그
    (`GOOGLE_SERVICE_INFO_PLIST`/`GOOGLE_SERVICE_INFO_PLIST_B64`)가 노출되는지 확인.
  - Archive 단계에서 `Build input file cannot be found: ...GoogleService-Info.plist`
    에러가 재발하지 않는지 확인.
  - Secret 미주입/오타 시 `ci_post_clone` 단계에서 즉시 실패(`Missing
    GoogleService-Info.plist secret.`)하는지 확인.
  - `ci_post_clone` 로그에서 `pod install --repo-update`가 실행되는지 확인
    (spec 갱신 누락으로 인한 의존성 해석 실패 방지).
  - `CI_PRIMARY_REPOSITORY_PATH is required` 에러가 나오면
    워크플로의 스크립트 실행 컨텍스트를 점검(잘못된 스크립트 단계 구성 가능).

- Run QA for Android version-code automation flow (2026-03-09):
  - `./scripts/bump_version.sh build`를 연속 2회 실행했을 때 build number가
    정확히 `+1`씩 증가하는지 확인.
  - `./scripts/build_android_internal.sh build` 실행 시
    `pubspec.yaml` 버전 갱신 + AAB 생성이 한 번에 되는지 확인.
  - 수동 값 강제(`--build-number`)와 상한 초과 방어(2,100,000,000) 동작 확인.

- Run QA for community on-demand translation flow (2026-03-08):
  - 게시글 상세 본문에서 `번역` 탭 시 `POST /api/v1/community/translations`
    호출이 1회만 발생하는지 확인.
  - 동일 콘텐츠(`post/comment`)에 대해 같은 목표 언어로 재탭 시
    중복 호출 없이 메모리 캐시 결과가 즉시 표시되는지 확인.
  - 댓글/답글/스레드 뷰에서 번역 성공 시 원문 아래 번역문이 노출되는지 확인.
  - `translated=false` 응답 케이스에서 `번역 결과 없음` 상태가 노출되는지 확인.
  - 비로그인 상태에서 번역 버튼 탭 시 로그인 유도 스낵바가 노출되고
    API가 호출되지 않는지 확인.
  - 401/500 오류 시 크래시 없이 `번역 다시 시도` 액션이 동작하는지 확인.

- Backend confirm needed for mandatory consent enforcement request v1.0.0 (2026-03-08):
  - `docs/api-spec/필수동의강제_백엔드요청서_v1.0.0.md` 기준으로
    `POST /api/v1/users/me/consents` 제공 여부 확정.
  - `GET /api/v1/users/me/consent-status` 제공 여부 및 응답 필드(`canUseService`, `needsReconsent`) 확정.
  - 정책 버전 변경 시 재동의 트리거(`requiresReconsent`) 계산 기준 확정.
  - 동의 저장 멱등 정책(중복 제출/재시도 처리) 확정.

- Run QA for mandatory terms/privacy consent gate (2026-03-08):
  - 로그인 상태에서 약관/개인정보 동의 최신 버전 이력이 없을 때 전역 차단 팝업이 즉시 표시되는지 확인.
  - 차단 팝업 노출 중에는 Home/Board/Settings 등 모든 페이지 터치/라우팅이 차단되는지 확인.
  - 팝업 내 `보기` 버튼으로 이용약관/개인정보 문서 외부 링크가 열리는지 확인.
  - 필수 체크박스 미체크 상태에서는 `동의하고 계속` 버튼이 비활성인지 확인.
  - 체크 후 동의 시 차단 해제되고 기존 페이지를 계속 사용할 수 있는지 확인.
  - 앱 재시작 후 동일 계정에서 로컬 동의 스냅샷 기준 재차단이 해제 유지되는지 확인.
  - 서버 `GET /users/me/consents` 실패 시에도 로컬 이력 fallback으로 판정이 동작하는지 확인.

- Run QA for feed header community settings page (2026-03-08):
  - 피드 상단 삼선 버튼 탭 시 `/community-settings`로 이동하는지 확인.
  - 커뮤니티 설정 페이지에서 `내 프로필/팔로워/팔로잉/알림함/저장한 글/게시글 작성/알림 설정` 라우팅이 정상인지 확인.
  - 프로필 카드(아바타/표시명/이메일 마스킹/프로필 수정 버튼)가 라이트/다크 모드에서 가독성 유지되는지 확인.
  - 운영 권한 사용자에서 `운영 센터` 노출, 일반 사용자에서 `전체 설정` 노출 분기 확인.

- Run QA for live attendance history view (2026-03-08):
  - 라이브 탭 AppBar 히스토리 버튼으로 `/live-attendance` 진입이 되는지 확인.
  - 방문기록 페이지 AppBar 음악 아이콘으로 라이브 방문기록 진입이 되는지 확인.
  - `DECLARED/VERIFIED` 상태 배지와 취소 불가 안내 문구가 기록 카드에서 정확히 노출되는지 확인.
  - 캐시 스냅샷이 없는 기존 기록에서도 이벤트 상세 보강 후 제목/일정/포스터가 표시되는지 확인.
  - 라이트/다크 모드에서 카드 대비/텍스트 가독성/탭 동작이 정상인지 확인.

- Run QA for live attendance v1 toggle integration (2026-03-08):
  - 라이브 상세에서 `라이브 방문` 토글 ON 시 `DECLARED/canUndo=true`가 즉시 반영되는지 확인.
  - self-declared 상태에서 토글 OFF 시 `NONE/canUndo=false`로 복귀하는지 확인.
  - `VERIFIED` 상태에서 OFF 불가(토글 비활성 + 안내 문구) 동작 확인.
  - `ATTENDANCE_UPDATE_FAILED` 400 응답 시 사용자 안내 문구가 정상 노출되는지 확인.
  - 화면 재진입 시 로컬 캐시 기반 상태 복원 후 재토글 시 서버 응답 기준으로 정합성 회복되는지 확인.

- Run QA for comment/reply consistency fixes (2026-03-08):
  - 추천/팔로잉/최신 피드에서 프로젝트가 다른 게시글 상세 진입 후 댓글/답글 등록이 정상 동작하는지 확인.
  - 댓글/답글 등록 및 삭제 직후 게시글 상세의 댓글 목록/카운트가 서버값과 일치하는지 확인.
  - 댓글 삭제 시(답글 포함 스레드 포함) 댓글 수 표시가 즉시 정상화되는지 확인.
  - 유저 프로필 `작성한 글/작성한 댓글` 탭에서 상세 진입 후 복귀 시 삭제 반영이 즉시 갱신되는지 확인.

- Run QA for feed project badge emphasis (2026-03-08):
  - Board 피드 카드에서 프로젝트명 알약 배지 가독성 확인(라이트/다크).
  - 긴 프로젝트명/좁은 폭(iPhone mini급)에서 줄바꿈 및 레이아웃 깨짐 여부 확인.
  - 부모 댓글 삭제 후 post detail에서 `삭제된 댓글입니다` 플레이스홀더와
    답글 목록이 함께 유지되는지 확인.
  - 부모 댓글 삭제 후 답글이 하나도 없으면 플레이스홀더가 노출되지 않는지 확인.
  - 루트 댓글에 대한 답글/답글의 답글 작성 시 `@부모닉네임` 표시가
    기대대로 동작하는지 확인.
  - depth 10 댓글에 대한 `답글` 버튼이 비활성/숨김되고,
    답글 타겟 선택 시도도 차단되는지 확인.
  - 삭제 placeholder 값이 `[Deleted comment]`로 내려와도
    한국어 플레이스홀더 UI로 정상 렌더되는지 확인.

- Run QA for privacy-rights API alignment (2026-03-08):
  - 개인정보 및 권리행사 페이지 진입 시 `GET /api/v1/users/me/privacy-settings`로
    자동번역 토글 초기값/updatedAt/version이 서버값으로 표시되는지 확인.
  - 자동번역 토글 변경 시 `PATCH /api/v1/users/me/privacy-settings` 요청에
    `version`이 포함되는지 확인.
  - 동시 수정 충돌(`PRIVACY_SETTINGS_VERSION_CONFLICT`) 시
    최신 설정 재조회 후 UI가 서버값으로 복구되는지 확인.
  - 처리정지 요청 시 `requestType=RESTRICTION`로 전송되는지 확인.
  - 권리행사 요청 이력(`GET /api/v1/users/me/privacy-requests`)이
    페이지에서 상태 배지와 함께 노출되는지 확인.
  - 동의 이력 호출이 `page/size/sort` 파라미터 포함으로 나가는지 확인.

- Backend confirm needed for community comment consistency request v1.0.0 (2026-03-08):
  - `docs/api-spec/커뮤니티_댓글일관성_백엔드요청서_v1.0.0.md` 기준으로
    `projectCode` 응답 포함 여부 확정.
  - 답글 생성 실패 코드 세분화(`COMMENT_THREAD_DEPTH_EXCEEDED` 등) 확정.
  - 댓글 삭제 응답 메타(`deletedCount`, `postCommentCount`) 제공 가능 여부 확정.

- Run QA for notification payload alignment v1.1.0 (2026-03-08):
  - `notificationType + type` 동시 수신 시 `notificationType` 우선 처리 확인.
  - `targetId + entityId` 동시 수신 시 `targetId` 우선 라우팅 확인.
  - `deeplink/deepLink`와 `actionUrl` 동시 존재 시 딥링크 우선 이동 확인.
  - `/community/posts/{postId}` 링크 탭 시 `/board/posts/{postId}`로 정상 이동 확인.
  - 미지원 type 수신 시 크래시 없이 알림함 진입/잔류 처리 확인.

- Backend confirm needed for notification publish request v1.0.0 (2026-03-08):
  - `docs/api-spec/알림발행_백엔드요청서_v1.0.0.md` 기준으로 eventCode/카테고리 매핑 확정.
  - `notificationId` 단일 멱등 키 정책(푸시/SSE/알림함 공통) 확정.
  - 카테고리(`LIVE_EVENT`, `FAVORITE`, `COMMENT`) 필터링 위치/정책 확정.
  - 운영 공지(`SYSTEM_NOTICE`) 우선순위 및 발행 빈도 정책 확정.

- Run QA for ads `deliveryType=none` fallback visibility policy (2026-03-08):
  - Home 슬롯에서 `/api/v1/ads/decision`이 `deliveryType=none`일 때도 로컬 폴백 카드가 노출되는지 확인.
  - Board feed 슬롯에서 `deliveryType=none` 응답 시 빈 간격 대신 폴백 카드가 노출되는지 확인.
  - `deliveryType=none` 경로에서는 `/api/v1/ads/events`가 불필요하게 전송되지 않는지 확인.
  - 운영 정책상 `none=숨김`이 필요한 슬롯이 생기면 `DeliveryNoneStrategy.hide`로 개별 설정하는 가이드를 문서화.

- Run QA for post compose topic/tag catalog options integration (2026-03-08):
  - 작성/수정 진입 시 `GET /api/v1/community/posts/options`가 1회 호출되는지 확인.
  - 옵션 API 성공 시 토픽/태그 선택 목록이 서버 카탈로그 기준으로 표시되는지 확인.
  - 옵션 API 실패(예: 401/500) 시 토픽이 자유입력 모드로 폴백되고 작성이 막히지 않는지 확인.
  - 태그 입력에서 중복 제거/최대 5개/항목당 16자 제한이 저장 payload에 반영되는지 확인.
  - 작성/수정 제출 payload에 `topic`, `tags`가 optional 규칙대로 전송되는지 확인.

- Run QA for unified-search global entry + reference-style discovery UI (2026-03-08):
  - Home/Feed/Board/Places의 돋보기 아이콘(또는 검색 카드 탭)에서 모두 `/search`로 이동하는지 확인.
  - 탐방 지도 56dp 미션 스트립을 탭하면 장소 검색/필터 흐름이 열리는지 확인.
  - 통합 검색 페이지 상단 레이아웃(뒤로가기 + 라운드 검색 입력창 + 범위 토글)이 레퍼런스 톤으로 표시되는지 확인.
  - query empty 상태에서 `인기 통합 검색`, `인기 탐색 카테고리`, `검색 둘러보기` 섹션 노출 확인.
  - query 입력 상태에서 기존 통합검색 결과 로드/탭 필터(`전체/장소/이벤트/뉴스`)가 정상 동작하는지 확인.
  - 검색 결과 아이템 탭 시 상세 라우팅(장소/라이브/뉴스/게시글)이 정상 동작하는지 확인.

- Run QA for live upcoming featured-card single-selection policy (2026-03-08):
  - 예정 탭에서 당일 이벤트가 여러 개인 경우 피처드 카드가 1개만 노출되는지 확인.
  - 피처드 대상이 현재 시각 기준 가장 가까운 당일 이벤트인지 확인.
  - 당일 이벤트가 없는 경우 `SCHEDULED` 상태 이벤트 중 가장 가까운 항목이 피처드로 폴백되는지 확인.
  - 피처드 제외 이벤트는 기존 `GBTEventCard`로 정상 렌더링되는지 확인.

- Run QA for remote push notification-center delivery (2026-03-08):
  - 포그라운드(iOS)에서 FCM 수신 시 시스템 알림(배너/알림센터)이 중복 없이 1회 표시되는지 확인.
  - 포그라운드(Android)에서 FCM 수신 시 로컬 알림이 알림센터에 표시되는지 확인.
  - 백그라운드/종료 상태에서 `notification` payload 메시지가 알림센터에 표시되는지 확인.
  - 백그라운드 data-only 메시지 수신 시 로컬 브리지 알림이 표시되는지 확인(Android 중심).
  - 알림 탭 시 라우팅 payload(`notificationId`, `deeplink`, `entityId`)가 정상 전달되는지 확인.
  - iOS/Android Firebase 설정 파일 미구성 환경에서는 크래시 없이 push 경로만 비활성화되는지 확인.

- Run QA for board top-bar simplification (2026-03-08):
  - 피드 상단에 `추천/팔로잉` + 프로젝트 선택 알약만 노출되는지 확인.
  - 기존 2차 칩 행의 `전체`가 제거되었는지 확인.
  - 프로젝트 알약에서 프로젝트 선택 후 프로젝트 피드 목록으로 즉시 전환되는지 확인.
  - `추천/팔로잉` 탭 전환 시 기존 커뮤니티 피드 로딩/무한스크롤이 정상 동작하는지 확인.

- Run QA for feed reaction 404 normalization + conditional project pill (2026-03-08):
  - 피드 상단에 `추천/팔로잉/프로젝트별`만 보이고 프로젝트 선택 알약은 `프로젝트별` 선택 시에만 노출되는지 확인.
  - `추천/팔로잉` 피드에서 반응 상태 조회 URL이 UUID 경로(`/projects/{uuid}/posts/...`)로 호출되지 않는지 확인.
  - mixed-project 피드 카드의 like/bookmark 상태 조회가 404 스팸 없이 정상 렌더링되는지 확인.
  - 프로젝트 매핑 불가 edge case에서 앱이 네트워크 에러 스팸 없이 동작하는지 확인.
  - `프로젝트별` 탭의 프로젝트 선택 알약이 기존보다 축소(dense)되어 가로 공간을 덜 차지하는지 확인.

- Run QA for iOS camera compose crash fix (2026-03-08):
  - iOS physical device에서 작성/수정 화면 카메라 아이콘 탭 시 앱 종료 없이 카메라가 열리는지 확인.
  - iOS simulator(카메라 미지원)에서 카메라 아이콘 탭 시 크래시 없이 안내 문구(`이 기기에서는 카메라를 사용할 수 없어요.`)가 노출되는지 확인.
  - 최초 카메라 접근 시 iOS 권한 팝업 문구가 정상 노출되는지 확인.

- Run QA for page-scoped API trigger enforcement (2026-03-07):
  - 프로젝트 전환 후 현재 탭이 아닌 페이지 API가 호출되지 않는지 확인(Home/Places/Live/Board/Info).
  - 프로젝트 선택 직후 `GET /api/v1/projects/{project}/units` 중복 호출(동일 파라미터 2회)이 제거됐는지 확인.
  - Board 비활성 상태에서 `GET /api/v1/community/subscriptions`와 feed reload/loadMore가 발생하지 않는지 확인.
  - Board 재진입 시 필요한 피드/구독 데이터가 1회 정상 갱신되는지 확인.
  - Info 탭에서 비활성 탭(뉴스/유닛)의 불필요 API 호출이 줄었는지 확인.

- Run QA for compose bottom toolbar camera/gallery-only update (2026-03-07):
  - 작성/수정 하단 툴바에 갤러리/카메라 아이콘만 노출되는지 확인.
  - 갤러리 아이콘 탭 시 멀티 이미지 선택이 실제 동작하는지 확인.
  - 카메라 아이콘 탭 시 카메라 캡처가 실제 동작하는지 확인.
  - 권한 미허용/디바이스 제한 환경에서 실패 메시지 노출(`갤러리를 열지 못했어요`, `카메라를 열지 못했어요`) 확인.
  - 최대 첨부 수(6장)와 중복 이미지 방지 메시지 동작 확인.
- Run QA for compose audience-chip size + transparent input tuning (2026-03-07):
  - 작성/수정 화면 상단 프로젝트 칩 높이/타이포가 축소된 상태로 자연스럽게 보이는지 확인.
  - 제목/본문 입력 필드가 투명 fill 상태에서 포커스/커서/플레이스홀더 가독성이 유지되는지 확인.
  - 다크 모드에서 축소된 칩 대비(테두리/텍스트/아이콘)와 터치 정확도 확인.
- Run QA for audience-like project chip compose update (2026-03-07):
  - 작성/수정 화면에서 제목/본문 입력 배경이 라이트는 흰색, 다크는 다크 서피스로 자동 전환되는지 확인.
  - 아바타 오른쪽 상단 칩(`프로젝트`) 탭 시 바텀시트가 열리고 프로젝트 선택이 즉시 반영되는지 확인.
  - 기존 본문 하단의 별도 프로젝트 선택 행이 제거되었는지 확인.
  - 프로젝트 변경 후 게시글 작성/수정 저장 시 선택된 프로젝트로 정상 전송되는지 확인.
  - 프로젝트 선택 바텀시트에서 현재 선택 항목 check 표시/재선택 no-op 동작 확인.
- Run QA for single-tone compose editor + project picker rework (2026-03-07):
  - 작성/수정 화면 배경이 단색(화이트)으로 통일되고 회색 구간 분리가 제거됐는지 확인.
  - 제목 입력과 본문 입력 사이 연한 가로 구분선 노출/두께/대비 확인.
  - 본문 플레이스홀더에 커뮤니티 준수 문구가 표시되고 입력 시작 시 사라지는지 확인.
  - 프로젝트 선택 UI가 기존 가로 pill 스크롤이 아닌 단일 드롭다운 방식으로 동작하는지 확인.
  - 프로젝트 선택 바텀시트에서 선택 시 현재 프로젝트가 즉시 반영되고 관련 데이터가 정상 갱신되는지 확인.
- Run QA for immersive post compose editor update (2026-03-07):
  - `/board/posts/new`, `/board/posts/:postId/edit`에서 shell 하단 네비게이션이 노출되지 않는지 확인.
  - 작성/수정 화면 진입 직후 키보드가 자동으로 열리는지 확인.
  - 제목 입력 폰트가 이전 대비 커졌는지(`titleLarge`) 라이트/다크 모드에서 확인.
  - 제목 힌트가 `제목을 입력해주세요`로 반영됐는지 확인.
  - 제목 아래 커뮤니티 준수 안내 문구가 표시되는지 확인.
  - 프로젝트 선택 영역이 별도 회색 박스 없이 단색 입력 화면에 자연스럽게 표시되는지 확인.
- Run QA for post compose copy-trim + selector integration update (2026-03-07):
  - 작성/수정 화면 하단 툴바에서 공개 안내 문구가 제거되고 아이콘 행만 남는지 확인.
  - 제목 플레이스홀더가 `(선택) 헤드라인을 입력해 주세요`로 반영되고,
    본문 플레이스홀더 문구(`무슨 일이 일어나고 있나요?`)가 제거되었는지 확인.
  - 프로젝트 선택 영역이 별도 박스 느낌 없이 입력 영역 톤과 자연스럽게 연결되어 보이는지 확인.
  - 라이트/다크 모드 전환 시 프로젝트 선택 영역 배경 대비와 텍스트 가독성이 유지되는지 확인.
- Run QA for post compose timeline-like redesign (2026-03-07):
  - 작성/수정 화면 AppBar의 `취소 / 임시 보관함 / 게시(수정)하기` 동작 및 비활성 상태를 확인.
  - 입력 레이아웃(아바타 + 제목 + 본문)이 키보드 표시/회전 상태에서 깨지지 않는지 확인.
  - 이미지 가로 스트립 미리보기/삭제/확대 보기 동작을 작성/수정 모두에서 확인.
  - 하단 툴바(공개 안내 문구 + 아이콘 행)가 노치/홈인디케이터 영역과 겹치지 않는지 확인.
  - 임시저장 복구/삭제 플로우가 `임시 보관함`에서 정상 동작하는지 확인.
- Run QA for board feed timeline-like redesign (2026-03-07):
  - 피드 섹션 상단 커스텀 헤더(타이틀/아이콘/탭/토픽칩)가 iOS/Android 모두에서 레이아웃 깨짐 없이 표시되는지 확인.
  - `추천/팔로잉/뉴스/콘텐츠` 탭 전환 시 모드 매핑(`recommended/following/latest/project`)이 의도대로 동작하는지 확인.
  - 구독 프로젝트 칩 탭 시 프로젝트 선택 동기화 + `콘텐츠` 탭 전환이 정상인지 확인.
  - 피드 카드 타임라인 레이아웃(작성자행/본문 5줄 미리보기/더보기/액션행)에서 탭 타깃/가독성/오버플로우 이슈가 없는지 확인.
  - 본문이 5줄을 넘을 때만 `더보기` 버튼이 노출되고 탭 시 상세로 이동하는지 확인.
  - 본문이 5줄 이하인 카드에서는 `더보기`가 노출되지 않는지 확인.
  - 이미지가 있을 때 트위터형 와이드 배치(넓은 비율 + 라운드 경계)로 표시되는지 확인.
  - 앱바 제거된 피드 섹션에서 상태바/노치 안전영역 겹침이 없는지 확인.
- Run UI QA for board sub-nav pill restyle (2026-03-07):
  - 게시판 진입 시 하단 서브 내비게이션이 플로팅 pill 형태로 렌더링되는지 확인.
  - 라이트/다크 모드 전환 시 배경/텍스트/선택 색상이 기존 앱 테마 토큰과 일관되게 바뀌는지 확인.
  - iOS에서 연속 곡률(continuous corner)로 보여지는지, Android에서 과도한 곡률 왜곡 없이 자연스럽게 보이는지 확인.
  - back 원형 버튼 터치 영역/햅틱/동작(`이전 위치 복귀`) 정상 확인.
  - `피드/발견/여행후기` 선택 상태 대비(밝기)와 탭 전환 가시성 확인.
  - iPhone notch 기기/Android gesture nav 환경에서 하단 safe-area 겹침 없이 표시되는지 확인.
- Run QA for recommended-feed endpoint switch (2026-03-07):
  - `추천` 탭 첫 진입/새로고침/무한스크롤에서
    `GET /api/v1/community/feed/recommended/cursor` 호출 여부 확인.
  - `추천` 탭에서 응답 `200 + data>0`일 때 카드가 즉시 렌더링되는지 확인.
  - `추천` 탭에서 `hasMore/nextCursor` 판정이 응답 필드 기준으로 정상 동작하는지 확인.
  - 삭제된 엔드포인트(`/community/feed/cursor`)가 더 이상 호출되지 않는지 확인.
- Run QA for mixed-project feed reaction 400 hotfix (2026-03-07):
  - `추천/팔로잉` 피드에서 다른 프로젝트 글이 포함된 카드에 대해
    `GET /projects/{project}/posts/{postId}/like|bookmark`가 `400` 없이
    `200`으로 응답하는지 확인.
  - 동일 시나리오에서 좋아요/북마크 토글(`POST/DELETE`)이 정상 반영되는지 확인.
  - 게시글 상세(`/board/posts/:postId`) 진입 시에도 반응 상태 조회/토글이
    글 소속 프로젝트 기준으로 호출되는지 확인.
  - 이전 오류 문구(`Post does not belong to project`)가 로그에서 재발하지 않는지 확인.
- Run QA for notifications SSE reconnect throttle/cooldown (2026-03-07):
  - `/api/v1/notifications/stream`가 `401/403`일 때 즉시 재연결 루프 없이 약 5분 쿨다운 후 재시도되는지 확인.
  - `/api/v1/notifications/stream`가 `400/404`일 때 약 10분 쿨다운 후 재시도되는지 확인.
  - 서버 down(`connection refused`) 시 지수 백오프 + 지터로 재시도 간격이 점진 증가하는지 확인.
  - 동일 원인 SSE 오류가 2분 내 반복될 때 중복 에러 로그가 억제되는지 확인.
  - SSE 실패 상태에서도 알림 폴링 동작/알림 목록 렌더링이 정상 유지되는지 확인.
- Run QA for map theme forced-sync (2026-03-07):
  - 앱 테마가 `라이트`일 때 iOS/Android 모두 지도(장소 지도/방문 상세/여행후기 생성·상세)가 라이트 톤으로 표시되는지 확인.
  - 앱 테마가 `다크`일 때 iOS AppleMap/Android GoogleMap 모두 다크 톤으로 표시되는지 확인.
  - OS 시스템 테마를 앱 테마와 반대로 둬도 지도는 앱 테마를 따르는지 확인.
  - 지도 줌/이동/마커 터치 시 오버레이로 인한 입력 차단이 없는지 확인.
- Configure Firebase project files for real remote push delivery (2026-03-07):
  - add `android/app/google-services.json`
  - add `ios/Runner/GoogleService-Info.plist`
  - verify iOS Runner target has Push Notifications capability + valid APNs entitlement/profile
  - verify Android Firebase sender/project linkage for current package id (`org.pyrimidines.girlsbandtabi_app`)
- Run end-to-end remote push QA on physical devices (2026-03-07):
  - login -> permission grant -> backend `POST /api/v1/notifications/devices` registration 확인
  - token refresh path (`PATCH /api/v1/notifications/devices/{deviceId}/token`) 확인
  - foreground FCM 수신 시 로컬 배너 노출/탭 라우팅 확인
  - background/terminated FCM 알림 탭 시 앱 라우팅 확인
  - logout/푸시OFF 후 device deactivate 동작 확인
- Run startup resilience QA for Firebase-missing environments (2026-03-07):
  - when `google-services.json` / `GoogleService-Info.plist` are absent, app must boot without `[core/no-app]` crash.
  - verify remote push bootstrap logs warning and disables push paths gracefully.
- Run regression QA for runtime hotfixes (2026-03-07):
  - ads tracking 이벤트에서 `decisionId` 없을 때 더 이상 `POST /api/v1/ads/events 400`가 발생하지 않는지 확인
  - 프로젝트 전환/빠른 이동 반복 시 `ProjectUnitsController after dispose` 예외가 재발하지 않는지 확인
- Run design QA for post-create/profile-edit consistency update (2026-03-07):
  - `게시글 작성` 화면의 섹션 헤더/카드 톤이 `프로필 수정` 화면과 시각적으로 일관적인지 확인.
  - AppBar `등록` 액션의 활성/비활성 조건이 입력 유효성 + 제출중 상태와 정확히 일치하는지 확인.
  - 사진 섹션의 borderless embed(`useCardChrome=false`)가 이중 테두리 없이 정상 렌더링되는지 확인.
  - 프로젝트 섹션에서 `현재 프로젝트: <slug>` 보조 문구가 제거되었는지 확인.
  - 게시글 업로드 성공 후 `feed_post_create_draft_v1` 임시저장 데이터가 재생성되지 않고 삭제 상태로 유지되는지 확인.
- Run QA for home project-gate loading guard (2026-03-07):
  - `GET /api/v1/projects`가 5xx일 때 홈이 무한 스피너가 아니라 에러/재시도 상태를 노출하는지 확인.
  - 에러 상태에서 `다시 시도` 시 프로젝트 목록 재조회 + 홈 재조회가 함께 트리거되는지 확인.
  - 프로젝트 목록이 복구되면 첫 프로젝트 자동 선택 후 홈 콘텐츠가 정상 진입되는지 확인.
  - 프로젝트 목록이 비어있는 환경에서 명시적 빈 상태 메시지가 표시되는지 확인.
- Run QA for home service-hub removal (2026-03-07):
  - 홈 중앙 `장소/게시판/정보` 3버튼이 완전히 제거되었는지 확인.
  - 제거 이후 hero/project-selector/sponsored-slot 간 간격과 스크롤 리듬이 어색하지 않은지 확인.
- Run QA for notification toggle resilience + login permission prompt (2026-03-07):
  - 알림 설정에서 `push ON -> OFF` 전환 시 서버 디바이스 해제 호출 실패 상황에서도 UI가 저장 실패 스낵바를 띄우지 않고 OFF 상태를 유지하는지 확인.
  - 로그인 직후(권한 미허용 상태) OS 알림 권한 요청이 노출되는지 iOS/Android에서 확인.
  - 로그인 직후(앱 내 알림 설정이 OFF 상태) 권한 요청이 뜨지 않는지 확인.
- Run QA for backend-alignment patch (2026-03-07):
  - 로그인 `429` 응답에서 대기시간 안내 문구(`N초 후 재시도`)가 노출되는지 확인.
  - 로그인 `409` 충돌 응답이 전용 문구로 표시되는지 확인.
  - 로그인 `409` 재시도 지연이 짧은 지터 범위(`220~340ms`)로 1회만 동작하는지 확인.
  - 알림 SSE 재연결 백오프가 `1s -> 2s -> 4s -> 8s(+jitter)`로 동작하고 중복 연결이 없는지 확인.
  - 앱 백그라운드 진입 시 SSE 연결이 정리되고 포그라운드 복귀 시 단일 연결로 재시작되는지 확인.
  - `POST_CREATED` 알림에서 `postId`가 없는 payload도 `/board`로 안전 폴백되는지 확인.
  - 장소 가이드 first-page 호출이 `guides/high-priority?limit=20` 우선이며, 미지원 환경에서 `/guides?page&size` 폴백이 정상 동작하는지 확인.
- Run QA for following-tab dedicated cursor endpoint split (2026-03-07):
  - `팔로잉` 탭에서 `GET /api/v1/community/feed/following/cursor` 호출 여부 확인.
  - `추천` 탭은 `GET /api/v1/community/feed/recommended/cursor`를 사용하는지 확인.
  - `팔로잉/추천` 탭에서 삭제 경로(`/community/feed/cursor`) 호출이 없는지 확인.
  - 팔로우 계정이 글을 작성한 케이스에서 응답 `items` 및 UI 리스트 건수 일치 여부 확인.
  - 팔로우 계정이 없는 케이스에서 빈 상태 문구/페이징 처리(`hasNext/nextCursor`) 확인.
- Run QA for recommended-feed cursor migration (2026-03-07):
  - `추천` 탭 첫 진입 시 cursor 없이 `GET /api/v1/community/feed/recommended/cursor?size=20` 호출 여부 확인.
  - 다음 페이지 요청 시 응답 `nextCursor` 값을 그대로 재전달하는지 확인.
  - `추천` 탭 무한스크롤 시 `nextCursor` 기반으로 다음 데이터가 정상 append 되는지 확인.
  - `추천/팔로잉` 탭에서 `400`(잘못된 커서) 응답 시 오류 상태가 노출되는지 확인.
  - `추천/팔로잉` 탭에서 `401` 응답 시 로그인 유도 메시지/플로우가 노출되는지 확인.
  - 프로젝트 선택 변경 시 `추천/팔로잉` 모드에서 불필요한 재요청이 발생하지 않는지 확인.
- Backend rollout follow-up:
  - verify live environment contracts for
    `GET /api/v1/community/feed/recommended/cursor` and
    `GET /api/v1/community/feed/following/cursor` (items/nextCursor/hasNext)
    against at least one real follower graph account.

- Run QA for settings quick-action navigation blank-screen fix (2026-03-07):
  - `/settings` -> `즐겨찾기/방문기록/통계` 진입 후 카드 탭 시 상세 화면이 정상 렌더링되는지 확인.
  - overlay 화면에서 `장소/라이브/뉴스/게시글` 상세로 이동 시 빈 화면 없이 라우팅되는지 확인.
  - 동일 상세 재진입 케이스(`settings -> favorites -> same place detail`)에서
    `duplicated page key`/`GlobalKey used multiple times` 예외가 재발하지 않는지 확인.
  - iOS/Android에서 상세 뒤로가기 시 원래 overlay 리스트(`/favorites`/`/visits`/`/visit-stats`)로 정확히 복귀하는지 확인.
- Run QA for profile-entry consistency and user-profile redesign (2026-03-07):
  - post detail author area: avatar tap -> profile navigation, and no standalone `프로필 보기` button.
  - compact follow CTA readability/tap accuracy on small-width devices.
  - user profile header layout validation (`cover/avatar/name/bio/actions/stats`) in light/dark mode and dynamic text scaling.
  - settings 페이지 프로필 카드 상단 탭 시 내 프로필(`/users/{me}`)로 이동하는지 확인.
  - 내 프로필에서 팔로워/팔로잉 수가 `-`가 아닌 실제 값(또는 목록 길이 기반 값)으로 표시되는지 확인.
  - 내 프로필 `작성한 글/작성한 댓글` 중 한쪽 API 실패 시 다른 탭 데이터가 유지 표시되는지 확인.
  - 내 프로필 `작성한 글/작성한 댓글` 탭에서 프로필 헤더+목록이 함께 스크롤되는지(내부 박스 스크롤 아님) 확인.
- Run QA for notification toggle/push-action routing contract (2026-03-07):
  - `pushEnabled=false`에서 하위 카테고리 토글 비활성/회색 처리 확인 및 재활성 시 기존 선택 유지 확인.
  - `POST_CREATED` 알림 탭(로컬 알림/인박스) 시 게시글 상세(`/board/posts/:postId`) 이동 확인.
  - `SYSTEM_NOTICE` 알림 탭 시 `actionUrl` 우선 이동, 없으면 `/notifications` 폴백 확인.
  - 백그라운드/포그라운드 알림 탭 후 읽음 처리 반영 및 중복 네비게이션 방지 확인.
- Run auth regression QA for 2026-03-06 login hardening:
  - verify rapid multi-tap on login CTA still issues a single `POST /api/v1/auth/login`.
  - verify same-account concurrent login attempts are deduplicated client-side.
  - verify `409`/`429` retry behavior matches UX expectations and does not trigger immediate retry loops.
  - verify login success no longer reproduces immediate protected-API `401` (`/api/v1/home/summary`) on real devices.
- Confirm backend `429` hint contract (`retryAfter` body unit, `Retry-After`, `X-RateLimit-Reset` format) and simplify client parsing once fixed.
- Replace hardcoded legal policy URLs/versions in `LegalPolicyConstants` with server-driven metadata once `/api/v1/policies/metadata` is available.
- Confirm backend `POST /api/v1/auth/register` consent DTO handling in production and remove temporary legacy-register retry fallback once all environments accept `consents` payload.
- Add widget tests for legal compliance UX:
  - register required-consent gating + final confirmation modal
  - verification pre-notice consent gating before onVerify invocation
  - settings/profile legal-policy link visibility
- Replace privacy self-service fallback behavior with fully server-backed flow once contracts are finalized:
  - `GET /api/v1/users/me/consents` authoritative source + pagination/audit fields
  - `PATCH /api/v1/users/me/privacy-settings` response contract for opt-out sync confirmation
  - `POST /api/v1/users/me/privacy-requests` typed status tracking (`PENDING/APPROVED/REJECTED`)
  - `DELETE /api/v1/users/me` graceful post-delete response and re-login policy
- Run device QA for foreground local-alert rollout:
  - iOS/Android에서 앱 foreground 상태에서 신규 알림 수신 시 배너/사운드 노출 확인.
  - 알림 설정 `푸시 알림` off 시 foreground 로컬 알림 미노출 확인.
  - 로그아웃/다른 계정 로그인 후 이전 계정 알림이 잘못 표시되지 않는지 확인.
- Follow up backend push integration request (`docs/api-spec/푸시알림연동요청서_v1.0.0.md`) and start Phase B client work (`firebase_messaging`, token register/unregister API binding) once endpoints are confirmed.
- Run full-device visual QA for service-fit redesign phase1 (`home`, `places`, `live`, `board`, `search`) focusing on bottom-nav reachability, segmented-tab readability, and search-field focus states (remove once validated).
- Run QA for the unified event schedule filter sheet:
  - 100dp 상단 컨트롤에서 일정 필터 시트 진입과 48dp 터치 영역을 확인.
  - 시트에서 연도+유닛 동시 필터 적용 시 예정/기록 결과가 기대대로 좁혀지는지 확인.
  - 필터 적용·초기화 후 NEXT LIVE 포스터와 하단 아젠다가 같은 범위를 표시하는지 확인.
- Run board Toss-style nav redesign QA:
  - 게시판 탭 진입 시 하단바가 `← + 피드/발견/여행후기`로 전환되고, 화살표 탭 시 기존 메인 5탭(`홈/장소/라이브/게시판/정보`)으로 복귀하는지 확인.
  - 레거시/호환 경로 리다이렉트(` /feed`, `/discover`, `/travel-reviews-tab`, `/posts/...`, `/travel-reviews/...`)가 `/board/...`로 정상 동작하는지 확인.
  - board 전용 내비게이션 바 (`뒤로가기 + 피드/발견/여행후기`) 탭 전환 정확도와 back fallback (`canPop` 없을 때 홈 이동) 확인.
  - 섹션 전환 `fade-through` 모션과 탭 햅틱 피드백 체감 품질(iOS/Android) 확인.
  - `피드` ↔ `발견` 전환 시 모드 동기화(발견=trending 강제, 피드 복귀 시 추천 모드 복귀) 확인.
  - 패널형 피드 카드 스크롤 밀도, 탭 전환 후 FAB 액션 가시성/권한 노출 규칙 확인.
  - 카드 메타 문구 `프로젝트명에 남긴 글` 프로젝트명 매핑 정확성(`id/code` 혼합 응답 포함) 확인.
- Run board search-sheet QA:
  - community feed/discover 탭에서 search icon -> bottom-sheet input -> result/apply/clear flow 확인.
  - search sheet 키보드 인셋/회전/다크모드에서 overflow 없이 표시되는지 확인.
- Replace static board sponsored-slot copy/campaigns with server-driven ad inventory + impression/click logging contract once backend ad endpoint is available.
- Run UX QA for sponsored-slot density (`home: 1 slot`, `board feed: max 1 slot`) and tune exposure threshold with real usage feedback.
- Replace AdMob test App IDs/Unit IDs with production values before store rollout:
  - Android `com.google.android.gms.ads.APPLICATION_ID` in `android/app/src/main/AndroidManifest.xml`
  - iOS `GADApplicationIdentifier` in `ios/Runner/Info.plist`
  - Dart defines:
    - `ADMOB_ANDROID_NATIVE_HOME_UNIT_ID`
    - `ADMOB_IOS_NATIVE_HOME_UNIT_ID`
    - `ADMOB_ANDROID_NATIVE_BOARD_UNIT_ID`
    - `ADMOB_IOS_NATIVE_BOARD_UNIT_ID`
- Confirm backend availability for `/api/v1/ads/decision` + `/api/v1/ads/events` and switch from client fallback-only operation to server-driven campaign control.
- Remove temporary ads endpoint compatibility fallback (`/api/v1/ads/decisions`, `/api/v1/ads/event`) once backend path contract is finalized across all environments.
- Run QA for JP place directions deeplink rollout:
  - `directions` CTA visibility rule (`JP only show`, `KR/others hidden`) on place detail and places list cards.
  - provider action-sheet ordering (`iOS: Apple first`, `Android: Google first`) and external-app open + browser fallback behavior.
- Run QA for 2026-03-05 board redesign: feed mode segmented control readability (`추천/최신/구독/인기`), mode-context hint tone, and action-row tap accuracy on iOS/Android (remove once validated).
- Run QA for 2026-03-05 post-detail comment density update: nickname→content spacing, overflow-menu right alignment, and reply row consistency on small-width devices (remove once validated).
- Run role-based UX QA for new bottom action entry points (`board` expandable FAB, `live` calendar FAB): verify non-auth/non-admin users do not see restricted actions.
- Split `recommended` and `following` feed contracts once backend exposes dedicated recommendation context/ranking fields (currently both use integrated cursor feed).
- Optimize community feed reaction loading by introducing a batch viewer-state endpoint (`/posts/reactions:batch`) to replace current per-card reaction-status calls.
- Add server-side typed search support (`title/author/content/media`) or separate search endpoints so current client-side post-filtering can be replaced with backend-ranked results.
- Run compose/edit draft QA after local auto-save rollout:
  - create/edit page debounce save, restore/delete banner behavior, successful-submit cleanup, and image-path restore fallback when local files are missing.
- Expand compose autosave widget coverage with edge cases:
  - restored draft containing missing local image paths (graceful skip behavior)
  - successful submit path clears footer autosave text + persisted draft together.
- Extend compose autosave snapshot schema to persist edit-page `existing remote image` removal state (`_existingImageUrls`) so recoverable drafts restore full attachment intent, not text/local images only (remove once draft model migration + QA complete).
- Complete push-device lifecycle integration:
  - register device on login/app-start (`POST /api/v1/notifications/devices`) and persist `deviceId`
  - rotate push token via `PATCH /api/v1/notifications/devices/{deviceId}/token`
  - keep `notificationDeviceId` local-storage key synchronized with server registration state (remove once fully wired + QA complete).
- Finalize server contracts for client SSE rollout (`/community/events/stream`, `/notifications/stream`) and then reduce foreground polling cadence:
  - event schema (`eventType`, `entityId`, `projectCode`, `occurredAt`) and replay policy (`Last-Event-ID`).
  - reconnect/rate-limit guidance (`retry` hint, idle timeout, auth-expiry behavior).
- Follow up server draft API proposal (`/posts/drafts`) and remove local-only limitation once backend contract is available.
- Run Account Tools UX QA after selector unification: tab switching state retention, selection bottom-sheet open/close behavior, and selected value persistence (`프로젝트/권한/대상 유형/사유`).
- Continue architecture roadmap Phase 3 by migrating direct imports from `feed_controller.dart` to dedicated modules (`board_controller.dart`, `news_controller.dart`, `post_controller.dart`, `reaction_controller.dart`) and remove transitional barrel when migration is complete.
- Expand controller tests from guard-level coverage to success/error/mutation scenarios for roadmap priority modules (`verification`, `settings`, `places`, `visits`).
- Decide/record policy for Domain↔Data DTO dependency exception (`fromDto` in entities) and align with `AGENTS.md`/ADR guidance.
- Plan staged migration path from `StateNotifier<AsyncValue<T>>` to `AsyncNotifier` for 신규 컨트롤러 and low-risk existing modules.
- Apply service-fit redesign phase2 to detail/editor screens (`post_detail`, `post_create`, `profile_edit`, `live_detail`, `place_detail`) using the same visual rhythm/tokens (remove once completed).
- Capture before/after screenshots for redesigned primitives and align with product acceptance criteria from UX references (`uxdnas + mobile guideline links`) (remove once reviewed).
- Complete community overhaul phase-4 by unifying comment-level trust/safety UX (댓글 신고/관리 액션 배치, 관리자 액션 시각 우선순위, 답글 스레드 내 일관성) with the new post-level safety model.
- Run UI QA for requested chrome trim: full-width post-detail comment composer and intro-card removal on `places`, `live`, `board` screens (portrait/landscape, iOS/Android).
- Add paginated/infinite loading for followers/following lists (current implementation fetches first 100 items) and expose server pagination metadata in API client if needed.
- Run UX QA for new profile/connections flows on iOS/Android: tab retention, refresh behavior, blocked-state interactions, and route back-stack consistency.
- Run QA for user-profile follow/block flows after API follow integration: initial follow status load, follow/unfollow toggle, blocked-state disable behavior, and snackbar copy validation (remove once validated).
- Verify backend follow count fields (`targetFollowerCount`, `targetFollowingCount`) consistency after rapid follow/unfollow toggles from multiple devices (remove once validated).
- Run end-to-end visual QA for the UXDNAS core-rule rollout (intro-card flattening, unified segmented tabs, unified search fields, full-width post composer) on iOS/Android and remove regressions (remove once validated).
- Run QA for UXDNAS methodology rollout after icon/skeleton/slider updates (feed/board/live/search, light/dark, Korean text scale, low-end device perf) and remove regressions (remove once validated).
- Configure GitHub repository secrets for Android delivery workflows (`internal` + `release`): `ANDROID_UPLOAD_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`, `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (remove once first successful Internal + tag-release draft uploads are confirmed).
- Run first tag-release dry run (`vX.Y.Z`) and verify pubspec/tag parity gate + production draft creation in Play Console (remove once validated).
- Verify live-event detail poster visibility on small iPhone screens and landscape mode after switching header image fit to `BoxFit.contain` (remove once QA passes).
- Verify live-detail header controls (back/favorite/share) remain clearly visible on bright/dark posters after overlay-button update (remove once QA passes).
- Verify live-detail poster top offset (status-bar clearance) and neutral gradient background look natural across notch/non-notch iPhones and Android devices (remove once QA passes).
- Verify compact segmented-tab sizing (`라이브: 예정/완료`, `게시판: 커뮤니티/여행 후기`) looks balanced with Korean text scaling on iOS/Android (remove once QA passes).
- Run visual QA pass on all primary routes after the new global theme/chrome layer (`home`, `places`, `live-events`, `community`, `search`, `settings`) and capture before/after screenshots (remove once reviewed).
- Roll out `GBTPageIntroCard` + `GBTSegmentedTabBar` to remaining content routes (`home`, `info`, `feed`, `travel_review_detail`, `visit_detail`) for full-page parity (remove once completed).
- Run color-contrast QA for the new blue primary palette on CTA-heavy screens (`auth`, `post_create`, `profile_edit`) in both light/dark mode (remove once validated).
- Run iOS device QA for interactive swipe-back on detail/overlay routes (`place_detail`, `live_detail`, `news_detail`, `settings`) after stack-first navigation change (remove once validated).
- Run Android QA for shell-root double-back exit (3-second grace window, snackbar visibility, and no impact on in-stack back behavior) on physical devices (remove once validated).
- Run iOS device QA for shell-nested community/profile flows (`board/posts/:id`, `users/:id`, `settings/profile`) after dynamic `PopScope` back handling update (remove once validated).
- Verify no keyboard-dismiss side effects in rich editor flows (`post_create`, `post_edit`, `profile_edit`) after global tap-to-dismiss was enabled (remove once QA passes).
- Add widget golden tests for global theme consistency (card radius, input radius, popup/tooltip colors, list tile density) to prevent drift (remove once coverage lands).
- Add widget tests for `PostCreatePage` (draft-exit confirmation, image max/duplicate handling, submit button enablement) and `ProfileEditPage` (dirty-state save enablement + unsaved-exit confirmation).
- Add a HomePage widget test that verifies the ProjectSelector renders during loading and triggers a reload after selection (remove once CI covers the flow).
- Run on-device QA for home hero image fallback and featured-live chip tap flow (poster present/absent cases) and capture screenshots (remove once validated).
- Run on-device QA for home `트렌딩 라이브` carousel poster visibility (relative URL, nested banner payload, missing-poster fallback) and capture screenshots (remove once validated).
- Run QA for post-detail comment UX updates (sort chip behavior, composer focus jump from comment icon, multiline submit disabled/enabled states) on iOS/Android (remove once validated).
- Run QA for redesigned board/post timeline UX (feed action-row tap targets, full-width media cropping, compact comment thread indentation/readability, quick-reply composer height) on iOS/Android (remove once validated).
- Run QA for redesigned community action colors (comment/like/bookmark/share contrast in light/dark, color-blind legibility, pressed state visibility) on iOS/Android (remove once validated).
- Run QA after repost-action removal (3-action row balance and accidental-tap rate on board/detail) on iOS/Android (remove once validated).
- Verify like toggle failure copy in both directions (like and unlike) and confirm localization tone with product owner (remove once validated).
- Run QA for places region filter UX updates (reactive loading without stuck spinner, compact chip entry, multi-select search/apply/clear, selected-count badge, single-region camera move) on iOS/Android (remove once validated).
- Run QA for `계정 도구` flows on iOS/Android: blocks list load/unblock, access-level summary rendering (`accountRole/baseline/effective`), verification appeal submit/list (remove once validated).
- Request backend fix: `GET /api/v1/home/summary` currently returns 500 (confirmed on both slug and UUID `projectId` as of 2026-03-01).
- Request backend fix: `GET /api/v1/users/me` returns 500 in authenticated app bootstrap flow (as of 2026-03-01).
- Request backend fix: `DELETE /api/v1/projects/{projectId}/posts/{postId}/like` intermittently returns 500 after token refresh on valid authenticated flow (observed 2026-03-02, projectId `girls-band-cry`).
- Add a CI step (or pre-commit hook) to run `build_runner` so generated files stay in sync.
- Add CI check to compare `ApiEndpoints` against `/v3/api-docs` and fail on missing/removed paths.
- Verify community-ban management sheet filter/sort controls (query/sort chips) remain usable without overflow on small-width devices (remove once mobile QA passes).
- Follow up backend feature request for moderation-ban search endpoint (`/api/v1/projects/{projectCode}/moderation/bans:search`) and `bannedUser.email` response guarantee; remove client-side fallback once API is available.
- Re-run `flutter analyze --no-pub` and `flutter test --no-pub` for updated community-ban UX/tests after local Xcode license acceptance and dependency cache recovery (remove once green run is recorded).
- Verify `tags` field availability on all place summary endpoints; if absent on 일부 응답, decide fallback strategy (detail prefetch vs summary contract update).
- Verify the new places-sheet collapse/expand floating toggle does not overlap map FABs on small iPhone/Android screen sizes.
- Confirm canonical request fields for `PATCH /api/v1/admin/community/reports/{reportId}` and `/assign` (then remove temporary multi-key compatibility payload).
- Expand admin operations center to additional endpoints (`/admin/projects/role-requests`, `/admin/projects/{projectId}/verification-appeals`, `/admin/media-deletions`) once UX priority is confirmed.
- Decide product/BE contract for community post appeals (current v3 spec has verification appeals only).
- Verify report cooldown UX for both post/comment reporting (first submit success, second submit blocked within 5 minutes).
- Verify quarantine banner visibility rules (`quarantined` only) and author-only appeal button behavior.
- Verify sanction precheck blocks post creation for `muted`/`banned` and allows `warning`/`none`.
- QA the new board feed 2-layer IA (`추천/팔로잉/프로젝트` + secondary chips) for route restore and mode persistence across `/board`, `/board/discover`, and `/board/travel-reviews-tab` (remove once confirmed on iOS/Android).
- Upload `0.0.3+2026030601` AAB to Play Console internal track and verify tester install/update path (remove once internal QA install confirmed).
- Expand locale coverage from shell/settings copy to feature pages with hard-coded Korean strings (board, places, live, info, post detail) now that `localeProvider` is active.
- Verify whether the iOS `FrameTiming` assertion reproduces after non-blocking bootstrap; if it does, test Flutter 3.40.x and decide on version pinning (remove once the regression is confirmed resolved).
- Verify whether the iOS `semantics.parentDataDirty` assertion reproduces after gating map builds by active tab; if it does, isolate additional offstage platform views (remove once stable).
- Verify whether the iOS `semantics.parentDataDirty` assertion reproduces after deferring connectivity overlay updates (remove once stable).
- Verify whether the iOS sliver ordering assertions disappear after moving staggered list animation setup to `didChangeDependencies` (remove once stable).
- Verify whether nav index provider sync errors disappear after deferring updates to post-frame (remove once stable).
- Confirm backend accepts `mockProvider: none` when `isMocked=false` in verification tokens; adjust placeholder if required (remove once validated).
- Re-verify Swagger for `{projectId}` usage on units endpoints once `http://localhost:8080/swagger-ui/index.html` is reachable, and adjust ID/slug usage if required.
- Add unit tests for `TokenService` JWE token generation (remove once verified with backend contract and coverage added).
- Add a `dart-define` (or similar) base URL override so QA builds can target staging without code edits (release defaults to production).
- Confirm verification config `jweAlg` matches the provided key type (remove RSA-OAEP-256 fallback once backend is consistent).
- Add device-key rotation/cleanup flow when server rejects a stored `kid` or key limit is reached.
- Verify backend error codes/messages for duplicate/simulated/invalid token failures and align the localization map once documented.
- Consider keying auth-scoped caches (profile/notifications/favorites) by user ID instead of clearing on login/logout.
- Consider keying verification device keys by user ID to avoid regenerating on account switches.
- Decide whether to add exponential backoff or limit retries for verification key re-registration failures.
- Consider aligning visit history caching with live updates (e.g., pushing updates into controller after background refresh).
- Verify pastel primary palette contrast on primary buttons and update onPrimary if needed.
- Remove visit detail route latitude/longitude query usage once the new visit detail endpoint is fully rolled out.
- Confirm backend accepts project slug/code for remaining project-scoped endpoints (places/live/news/verification) and document any exceptions.
- Expand verification error localization map as backend adds new failure reasons.
- Decide whether place detail should show favorites as "좋아요" or a true rating once backend exposes rating data.
- Request backend fix: disable CSRF for `/api/v1/**` or document CSRF token flow for mobile clients (nickname update currently 403).
- Add unit tests for `ApiClient` auth interceptor refresh outcomes (`invalidSession` vs transient failure) to prevent logout regressions on pull-to-refresh.
- Add unit tests for refresh `429 retryAfter` handling and concurrent `401` refresh deduplication in `ApiClient`.
- Confirm profile update payload handling for optional fields (avatar/bio/cover) when omitted vs empty.
- Add Firebase config files (`google-services.json`, `GoogleService-Info.plist`) and verify Analytics/Crashlytics runtime behavior.
- Complete app-wide cache policy rollout phase-2 from
  `docs/architecture/MOBILE_APP_CACHE_POLICY_V1.0.0.md` (phase-1 done:
  profile registry + major repository migration + feed reaction soft-fail):
  - Standardize remaining legacy cache key naming to
    `feature/resource/scope/variant` and publish key registry table.
  - Expand prefix-based invalidation matrix coverage to remaining mutation
    paths (`favorites`, `uploads`, `admin ops` secondary lists).
  - Add cache observability events (`hit/miss/stale/invalidation/refresh`) and
    run 1-week telemetry review for TTL tuning.
  - Add repository/controller tests for reaction-status 404 fallback + short
    negative-cache behavior (TTL window verification).
- Enable OAuth once backend is ready by providing authorize URLs and deep-link redirects.
- Confirm `HomeSummaryDto` field mapping with backend response and adjust parsing keys if needed.
- Confirm `PlaceDetailDto`/`PlaceSummaryDto` field mapping with backend response and adjust parsing keys if needed.
- Implement bounds-based refresh for Places map (current map uses the full list + region filter).
- Confirm whether Places Regions endpoints accept project slug; currently retrying with UUID when the slug call fails.
- Confirm whether visit stats should use `/api/v1/users/me/visits/summary` per place and expand UI if backend adds aggregate stats.
- Provide Android `MAPS_API_KEY` via `local.properties`/CI secrets for Google Maps rendering.
- Revisit chip label color overrides if design tokens change for tags/filters.
- Add UI feedback for large full-list loads (pagination or loading indicator).
- Consider adding geocoding-based search for map lookup (currently local search only).
- Validate project-specific place type taxonomy from `/api/v1/projects/{projectId}/place-types` and expand client synonym coverage where needed.
- Confirm `LiveEventDetailDto`/`LiveEventSummaryDto` field mapping with backend response and adjust parsing keys if needed.
- Confirm `NewsSummaryDto`/`NewsDetailDto` field mapping with backend response and adjust parsing keys if needed.
- Confirm `PostSummaryDto`/`PostDetailDto` field mapping + `projectCode` usage with backend response and adjust parsing keys if needed.
- Confirm `UserProfileDto` and `NotificationSettingsDto` mappings with backend response and adjust parsing keys if needed.
- Confirm avatar upload flow (presigned + confirm URL) is accepted by `PATCH /api/v1/users/me`.
- Remove temporary popular-keyword fallback list after production discovery APIs are confirmed stable across environments.
- Decide whether discovery category API failure should keep current "section hide + retry" policy or switch to explicit empty-state card.
- Decide when to remove legacy compatibility query params (`swLat/neLat/...`, `radiusKm`, `page/size`) after backend contract freeze.
- Confirm whether feed endpoints will standardize on `pageable` only, then drop dual-query fallback (`page`,`size` + `pageable`).
- Reduce or remove verbose network body logging once verification 400s are resolved.
- Confirm favorites API payload (`targetId`, `targetType`) with backend and adjust mapping if needed.
- Confirm notification item DTO field mapping (`title/body/category/read`) with backend response and adjust parsing keys if needed.
- Remove temporary notification category mapping once backend documents all supported category enums.
- Audit other dark-mode text buttons for contrast and remove local overrides if any exist.
- Verify community posts/comments pagination contract (`page`/`size` vs `pageable`) and adjust query params if needed.
- Request backend support for community post image attachments (create/update payload fields + response images list).
- Remove the post detail plain-URL attachment fallback once the backend preserves markdown or returns explicit `imageUrls`.
- Verify post detail no longer duplicates markdown-only images (remove once confirmed).
- Verify Xcode Cloud executes `ci_post_clone.sh` and the iOS archive succeeds (remove once stable).
- Reintroduce a compatible `test` dev dependency only if Dart-only tests are required (remove once decided).
- Verify pull-to-refresh gesture UX on `PlacesMapPage` bottom sheet across iOS/Android (remove once QA confirms).
- Verify iOS map search flow no longer throws `MissingPluginException` when selecting places from the bottom-sheet search modal.
- Verify logout cache clear behavior for stale list/detail screens after re-login (remove once QA confirms).
- Verify cache-first background revalidation cadence (10m) against backend rate limits and tune interval if needed.
- Verify report sheet keyboard dismiss behavior (tap outside/drag/done) on iOS and Android keyboards.
- QA post-detail comment thread readability after PHASE4 redesign (small-width devices, long-text wrapping, and deep reply indentation at depth >= 2).
- QA PHASE5 comment fixes on iOS/Android: root/reply indentation alignment, avatar tap-to-profile navigation, and bottom-sheet edit flow keyboard/submit behavior.
- QA deleted-root comment UX: `삭제된 댓글입니다` 행에서 `답글 N개 보기/숨기기`
  토글 동작, 접기 기본 상태, 다크/라이트 가독성 확인.
- Confirm user profile `bio` and `coverImageUrl` are returned on public profile endpoints (read + update).
- Confirm whether `username` should be an email for registration and align login labels accordingly.
- Confirm unit name/description semantics (`code` vs `displayName`) with backend and update mapping if the contract changes.
- Consolidate widget-test `AppConfig` bootstrap into a shared test helper:
  - current post-compose integration tests initialize `AppConfig` inline to
    avoid `ApiClient` late-init failures when `feedRepositoryProvider` is read.
  - remove per-test duplication once a common helper is introduced and adopted
    by all widget tests that touch repository providers.
- Keep the Flutter code standards guide in sync with AGENTS.md and lint rules.
- Confirm place guide/comment DTO mappings with backend (fields + pagination).
- Confirm place comment creation request (`CreatePlaceCommentRequest`) and photo upload flow (presigned + confirm) with backend.
- Confirm `ProjectDto`/`UnitDto` field mapping and selection persistence expectations with backend.
- Request backend fix: `GET /api/v1/projects/{projectId}/units` returns 500 for existing project (should be 200 empty list or 404 when missing).
- Request backend fix: `/v3/api-docs` returns 500 while Swagger UI relies on `/api-docs/api`.
- Confirm uploads list/approval behavior (URL availability after confirm, approval required before public access).
- Confirm rejected uploads are removed from comments after delete and whether backend clears photo references.
- Remove client-side media URL normalization once backend returns public CDN URLs by default.
- Investigate Apple Maps dark mode styling support once the plugin exposes map style controls.
- Replace iOS/macOS JPEG fallback with true WebP encoding (preserving metadata) once a supported encoder is available.
- Run on-device QA for Stage 9 flows (search/verification/favorites/notifications/projects/uploads) and record findings.
- Continue i18n rollout for remaining pages still using hardcoded Korean strings (admin/account-tools/notification-settings/travel-review mock screens) with the same `ko/en/ja` runtime locale behavior.
- Add widget tests to guard locale switching and key board/live/project localized strings against regressions.
- Confirm backend contract for community post `topic`/`tags` fields (create/update/read) and remove temporary optional compatibility fallback once API schema is finalized.
- Run on-device QA for compose topic/tag UX (bottom-sheet selection, duplicate guard, max-count guard, draft restore, and publish/update payload verification) on iOS/Android.
- Add widget tests for compose taxonomy failure states (retry button, 401/403
  login guidance, empty-catalog disabled picker behavior) with provider
  overrides to avoid real ApiClient bootstrap.
- Validate Admin taxonomy reorder propagation end-to-end:
  - update order in Admin `/community-taxonomy`
  - verify mobile compose/edit reflects identical order after re-entry.
- Re-verify `설정 > 방문 기록` 탭 분리(장소/라이브) UX on iOS/Android:
  - entry from `/visits`, `/visits?tab=live`, and legacy `/live-attendance`
    redirect path should all land on expected tab/state.
  - remove `/live-attendance -> /visits?tab=live` redirect after one release
    cycle once no external deep-link dependency remains.
- QA shell detail fullscreen policy on iOS/Android:
  - ensure bottom nav is hidden on detail/sub routes in shell branches
    (`/places/:id`, `/live/:id`, `/board/posts/:id`,
    `/board/travel-reviews/:id`, `/info/news/:id` etc.).
  - ensure bottom nav remains visible on branch root routes only.
- QA home trending-live poster hydration:
  - verify posters appear on `/home` trending-live cards for events that
    previously had blank image there but had poster on `/live`.
  - monitor latency impact when multiple trending rows require fallback detail
    lookups, and tune if needed.
- Decide iOS analytics IDFA policy:
  - if non-IDFA analytics is required, set
    `$FirebaseAnalyticsWithoutAdIdSupport = true` in `ios/Podfile`
    and re-verify ads/attribution impact before release.
- QA feed re-entry + write-refresh behavior on iOS/Android:
  - leaving feed and re-entering `/board` should always fetch fresh community feed data.
  - successful post/comment/reply submission should reflect in feed without manual pull-to-refresh.
  - remove after QA confirms expected refresh timing and no duplicate loading flashes.
- Verify Android community post image preview parity after JPEG-for-feed upload mitigation:
  - on Galaxy S21 (and at least one additional Android model), create posts
    with single/multiple images and confirm feed card preview appears
    immediately and after app restart.
  - if preview still misses while post detail shows images, collect
    `/api/v1/projects/{projectCode}/posts` summary payload for affected post
    (`thumbnailUrl`, `imageUrls`, `content`) and raise backend contract issue.
  - if "first image not selected as thumbnail" persists, verify backend
    upload approval timing/order for `imageUploadIds`:
    - `imageUploadIds[0]` should be approved by summary hydration time.
    - summary must preserve original upload order when deriving `thumbnailUrl`.
- QA post edit project-lock behavior:
  - on edit page, project selector must be non-interactive with lock affordance.
  - updating title/content/images should succeed without
    `입력값이 올바르지 않습니다` when user previously switched global project.
- Complete production push rollout checklist:
  - place Firebase native config files locally:
    `android/app/google-services.json`,
    `ios/Runner/GoogleService-Info.plist`.
  - verify Apple Developer Push capability + regenerated provisioning profiles.
  - upload APNs auth key (`.p8`) in Firebase Console (Cloud Messaging, iOS app).
  - run end-to-end push test (foreground/background/tap deep-link) on real
    iOS and Android devices.
- QA community feed thumbnail priority on Android/iOS:
  - create post with multiple images and verify feed card preview uses the
    first uploaded image (thumbnailUrl) consistently.
  - verify fallback behavior when `thumbnailUrl` is missing:
    `imageUrls` → content-extracted image.
- QA push toggle OFF↔ON roundtrip:
  - OFF should deactivate backend device registration without error toast.
  - ON should request permission (if needed) and re-register device token.
  - verify token update/registration logs and actual push delivery after ON.
- Verify Xcode Cloud Firebase plist injection path:
  - preferred secret: `GOOGLE_SERVICE_INFO_PLIST_B64` (full iOS plist, base64).
  - fallback secrets: `FIREBASE_IOS_API_KEY`,
    `FIREBASE_IOS_APP_ID`, `FIREBASE_IOS_MESSAGING_SENDER_ID`,
    `FIREBASE_IOS_PROJECT_ID`, `FIREBASE_IOS_BUNDLE_ID`,
    `FIREBASE_IOS_STORAGE_BUCKET` (optional).
  - confirm archive logs include
    `Generated GoogleService-Info.plist ...` line in `ci_post_clone.sh`.
  - if decode fails, regenerate base64 without newlines and re-save secret.
- Verify Xcode Cloud post-clone script discovery:
  - ensure workflow executes either root `ci_post_clone.sh` or
    `ci_scripts/ci_post_clone.sh` (both now supported).
  - confirm logs include `flutter pub get` and `pod install --repo-update`.
- Confirm `/api/v1/users/me` auth profile contract stabilization:
  - ensure backend consistently returns `accountRole` +
    `effectiveAccessLevel` (camelCase) without relying on legacy `role/roles`.
  - remove mobile-side alias/fallback compatibility mapping after one release
    cycle once payload format is fully stabilized in production.
- Confirm `/api/v1/users/me` project-role payload contract:
  - finalize canonical field shape for per-project roles
    (`projectRoles` map vs list form, key as project UUID/slug/code).
  - align backend response examples so mobile project-scope authorization can
    remove compatibility parser fallbacks.
- QA home by-project summary integration:
  - verify project switch uses by-project payload first and falls back to
    single-summary endpoint only on errors/missing row.
  - verify empty-state messaging follows source-count policy:
    hard empty (`sourceCounts=0`) vs soft empty (`sourceCounts>0`).
  - verify by-project response ordering/id matching when identifiers mix
    `slug` and `uuid`.
- Execute CODE_AUDIT.md P1 remediation batch:
  - move settings privacy/consent presentation API calls behind
    repository/controller boundaries.
  - remove Flutter framework imports from domain models
    (`admin_ops_entities.dart`).
  - split `board_controller.dart` responsibilities and add lifecycle-safe
    realtime provider strategy (`autoDispose` or explicit stop contract).
- QA platform-adaptive dialog/sheet behavior:
  - iOS should show Cupertino alert/action sheet for confirm/report/logout/
    delete flows in board/feed/post-detail/settings/register.
  - Android should keep Material dialog/sheet visuals and button hierarchy.
  - Verify destructive actions (delete/ban/account delete) are visually
    destructive on both platforms.
- QA voice-actor project-scope routing/cache (v1.4.0):
  - in 정보 > 성우 탭, switch project A/B and verify list/detail/members/credits
    always call `/api/v1/projects/{projectId}/units/voice-actors/**`.
  - verify deep link/open path with missing `projectId` is blocked with
    invalid-navigation guard instead of making legacy `/voice-actors/**` call.
  - verify cache separation by `projectId` (same `voiceActorId` from different
    projects never reuses stale detail/members/credits data).
- QA mandatory consent 3-type gate (v2026.03.12):
  - login 직후 `GET /api/v1/users/me/consent-status` 호출 여부 확인.
  - `LOCATION_TERMS` 미동의 상태에서 `canUseService=false` + 오버레이 차단 확인.
  - 동의 제출 요청이 항상 3종(`TERMS_OF_SERVICE`, `PRIVACY_POLICY`,
    `LOCATION_TERMS`) 1회로 전송되는지 네트워크 로그 확인.
  - 2종만 체크/제출 시 클라이언트 차단 또는 서버 400
    (`CONSENT_REQUIRED_FIELDS_MISSING`) 처리 UX 확인.
  - 토큰 갱신 직후 consent-status 자동 재확인 동작 확인.
- Finalize legal policy publish checklist (v2026.03.12):
  - replace placeholders in `docs/legal/이용약관_v2026.03.12.md`,
    `docs/legal/개인정보처리방침_v2026.03.12.md`,
    `docs/legal/위치정보이용약관_v2026.03.12.md` with real operator/contact data.
  - run legal review and then align app policy constants/version (`lib/core/constants/legal_policy_constants.dart`).
- Add widget tests for music tab unit classification:
  - selecting unit chip filters both album cards and track cards.
  - stale selected unit should fallback to `All` when option disappears.
  - verify empty-state copy for selected-unit no-results scenario.
- Add widget tests for member-part lyric colorization in song detail:
  - tap part badge selects member and toggles line emphasis.
  - `lyricLineId` missing segments map to lyric line via time-overlap fallback.
  - `DUET/UNISON/HARMONY` lines render mixed-color gradient state.
