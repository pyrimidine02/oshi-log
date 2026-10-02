# 서버 협의 요청: 일본 메인 제품 방향 동기화

- 작성일: 2026-10-02
- 보낸 쪽: 모바일 앱(girlsbandtabi_app) 설계 세션 — Claude + GPT astra
- 받는 쪽: oshilog-api 서버 세션
- 상태: **협의 요청. 구현 지시 아님.** 범위·순서·계약 형태는 서버 쪽 판단을 받은 뒤 확정한다.

## 배경

앱의 제품 방향·화면 설계를 새로 정했다. 메인 시장은 일본, 한국은 가오픈이다.

- 제품 방향: `girlsbandtabi_app/docs/product/product-direction-v1.md`
- 화면 설계: `girlsbandtabi_app/docs/product/screen-design-v1.md` (§10에 서버 요구 요약)
- 앱 구조 재설계: `girlsbandtabi_app/docs/product/app-architecture-redesign-v1.md`

핵심 루프는 탐색 → 준비 → 현장 → 기록이다. 공연 상세를 준비 허브로 쓴다(공식 티켓 링크·응원/콜·세트리스트·주변 성지·레포). 티켓 접수 회차·마감·당락·입금 관리는 범위에서 제외했다(사용자 결정).

계약 원칙: 기존 필드·nullability 변경 없음. 필드 추가·엔드포인트 추가로만 확장. 모듈 경계(`docs/dev/architecture/module-and-database-contract.md`)는 서버 결정을 따른다.

## 요청 목록

| # | 우선 | 요청 | 현재 상태(앱 쪽 정적 확인) | 서버에 묻는 것 |
|---|---|---|---|---|
| S1 | P0 | **공개 읽기 정책**: 비로그인으로 music·zukan·community 읽기·검색·홈 조회 | `SecurityConfig.kt:346` 기준 장소·공연 GET만 공개. zukan은 메서드 권한 제한(`ZukanController.kt:47`) | 공개 가능한 범위와 rate limit·캐시 정책 |
| S2 | P0 | 홈 공연 DTO에 공연 `status` 추가 | `HomeController.kt:34` 홈 공연에 상태 없음. 상세에는 있음 | 필드 추가 가능 여부 |
| S4 | P1 | **참가 예정 상태**: 참전 기록과 분리 | `PUT …/attendance`는 `DECLARED / SELF_DECLARED / attendedAt=now` 과거 참석 기록(`VerificationService.kt:727`) | 별도 테이블/엔드포인트 형태, 소유 모듈(identity 추정) |
| S5 | P1 | 관심 합산 홈(프로젝트 미지정 시 구독·관심 전체) | `HomeController.kt:133` 프로젝트 필수 | gateway 조합 엔드포인트로 가능한지 |
| S6 | P1 | 장소 구조화 방문 정보: 영업시간·휴무, 촬영 가능, 주거지·사유지, 最寄駅·도보 분, 각 항목 출처·확인일. "정보 없음"과 "허용" 구분 | `PlaceEntity.kt`, `PlaceDtos.kt`에 해당 필드 없음(설명 Markdown·태그만) | 필드 설계, 관리자 입력 |
| S7 | P1 | 주거지 등 지정 장소의 **공개 지점 체크인** 또는 인증 제외 정책 | 인증 반경 기본 10m(`PlaceCommandService.kt:127`) | 정책 필드·판정 방식 |
| S8 | P1 | 게시글 연관 대상(장소·공연·곡 중 하나) + 대상별 게시글 조회 | `PostDtos.kt:21` 생성 DTO에 연관 필드 없음 | 필드·조회 엔드포인트 |
| S9 | P1 | 공연 단독 레포 허용 | `TravelReviewDtos.kt:27` 장소 stop 최소 1개 필수 | 검증 완화 또는 별도 타입 |
| S10 | P1 | 콘텐츠 유니버설 링크: 장소·공연·곡·레포·프로필 URL 체계 + AASA/assetlinks | AASA가 `/oauth/x/callback`만 허용 | URL 체계, 비회원 웹 랜딩 여부 |
| S11 | P2 | 즐겨찾기 타입 확장(곡·스폿집·게시글) | `FavoriteController.kt:211` 목록 조립은 PLACE/NEWS/LIVE만 | 타입 검증·제목/이미지 조회 |
| S12 | P2 | 코스: 이동 순서·구간 이동 수단·거리·예상 시간 | zukan `sortOrder`는 표시 순서만(`ZukanDtos.kt:60`) | zukan 확장 vs 별도 모델 |
| S13 | P2 | 공연·투어별 빈출곡 집계 | 곡별 공연 이력만(`MusicController.kt:221`) | 집계 기준(기간·출연 밴드·미수집 공연) |
| S14 | 검토 | 티켓 OCR 참전 확인 (서버 세션에서 이미 검토 중) | 위치 인증만 | 앱 쪽 영향: S4의 참전 기록·위치 인증과 별도 "티켓 확인" 상태로 표시할 예정. OCR 이미지 보관·APPI 처리 목적 명시 필요 |
| S15 | P0 | 장소 원문 필드(원문 이름·주소·언어·누락 여부) 추가 | `nameJa/addressJa`는 DB에만, DTO는 선택 언어 + fallback | 필드 추가 형태 |
| S16 | P1 | 기간 한정 행사(콜라보·스탬프 랠리·타이업): 장소와 분리된 개최 건, 기간·시간대·휴무·취소·공식 링크·확인일 | 장소 종류 카탈로그만, 캘린더는 단일 `eventDate` | 소유 모듈(place vs oshikatsu), 모델 |
| S17 | P1 | 장면 근거: 공식 확인/팬 추정, 장면 이미지 권리 근거·노출 조건, 촬영 지점·방향, 추천 계절·시간대 | zukan `sceneDescription/sceneImageUrl`만 | 필드 위치(place vs zukan) |
| S18 | P1 | 지역 허브 조합(지역 소개 + 스폿 + 회장 + 기간 한정 + 스폿집) | 지역 트리·지역별 장소 있음 | gateway 조합 가능 여부 |
| S19 | P1 | 레포의 재방문 표현(동일 장소 중복), 비공개 앨범과 공개 레포 분리 | 장소 1~20개·중복 금지, 생성 시 `PUBLISHED` | 앨범은 앱 로컬로 시작 예정 — 서버 측 의견 |
| S20 | P2 | 근접 알림 카테고리 | COMMENT/FAVORITE/LIVE_EVENT/FOLLOWING_POST만 | APPI 연속 위치정보 관점 |
| S21 | P1 | 初参戦ガイド 데이터: 멤버별 펜라이트 색, 필수곡, 준비물·매너(공연/투어 단위) + 팬 콜 제안·검수 흐름 | cheer_guides(섹션) 있음, 멤버 색·콜 제안 미확인 | cheer_guides 확장 vs 신규, 검수 주체 |

## 함께 정할 비기술 항목

- 일본어 모더레이션 담당과 처리 기준.
- APPI(주) 및 한국 위치정보법(가오픈 범위) 검토. 서버 `docs/future-development/07-bm-strategy.md`의 행동 데이터 수익화 방향은 **현재 범위 외**로 두자는 것이 앱 쪽 제안.

## 회신 요청

각 S 항목에 대해: 수용 / 수정 제안 / 거절 + 이유, 소유 모듈, 대략 규모. 앱은 회신을 받은 뒤 `screen-design-v1.md` §10을 갱신하고 화면 작업 순서를 정한다.
