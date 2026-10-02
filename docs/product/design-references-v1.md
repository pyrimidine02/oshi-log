# oshi@log 디자인 레퍼런스 v1

- 조사일: 2026-10-02 (WebSearch/WebFetch. Firecrawl은 크레딧 부족으로 사용 못 함)
- 조사: 순례·여행 앱 20, 라이브·팬·음악 앱 20, 일본 UI 관습·디자인 시스템 22 (Claude 서브에이전트 3개 병렬)
- 검증 표기: **V** = 공식 페이지·스토어를 직접 열어 확인 / **S** = 공식 도메인·신뢰할 언론의 검색 결과로만 확인 / **U** = 미검증·추론. U 항목은 디자인 가설로만 쓴다.
- 원칙: **기능 구조와 흐름만 빌린다.** 시각 표현·데이터·자산·문구는 복제하지 않는다.
- 연결 문서: `screen-design-v1.md`(화면별 적용), `product-direction-v1.md`(범위)

---

## 1. 핵심 결론 10개

| # | 결론 | 근거 레퍼런스 | 적용 |
|---|---|---|---|
| 1 | **장면 비교가 장소 상세의 주인공**이다. 그 바로 아래 매너 블록을 둔다. 둘을 함께 잘하는 앱이 없다 → oshi@log가 차지할 빈자리 | Anitabi, JapanAnimeMaps, 聖地巡礼マップ(indie) | 장소 상세 헤더 |
| 2 | 체크인 시 **고스트 오버레이 카메라**(장면 반투명 겹치기). 장면 이미지 권리가 없으면 촬영 위치·방향 텍스트 안내로 대체 | Anitabi | 체크인 흐름 |
| 3 | **컬렉션 = 색 핀 + 진행도.** 스폿집마다 핀 색/아이콘, "12/30か所" | Google Maps Lists, Komoot, アニメ聖地88, Pokémon GO Routes | 지도, 스폿집 |
| 4 | **기간 한정 랠리·콜라보는 공용 카드 하나.** GPS 또는 QR로 스탬프, 캐릭터 그리드, 종료일·보상 상태 | 각종 디지털 스탬프 랠리, 舞台めぐり | 기간 한정 스폿, 마이 |
| 5 | **당일 모드는 오프라인·무료.** 순서 있는 목록, 구간 이동, 역+거리, 「電車で行く」 외부 연결, 지역별 텍스트 팩 | Wanderlog, NAVITIME, Airbnb Today, Tabelog, Komoot | 오늘 목록 |
| 6 | **여행 앨범은 체크인으로 만든다, 상시 추적 아님.** 체크인 시각·장소·사진 EXIF로 묶고 겹치는 공연을 붙인다 | Polarsteps(반면교사: 상시 GPS), 舞台めぐり 자동 일기, TripIt | 마이 旅 |
| 7 | **참전 2단계 → 기록.** 気になる(=저장) / 参加予定 → 날짜 지나면 参戦済み 확인 → 이력·통계·연간 회고 | Songkick, LiveFans 参戦チェック, setlist.fm "I was there" | 공연 상세, 마이 |
| 8 | **스포일러 가드가 시장 공백.** 검증한 어떤 앱도 제대로 안 한다. 일정이 남은 투어의 세트리스트·레포·공유 카드를 가린다 | LiveFans(없음), setlist.fm(임시 제목뿐) | 공연 상세, 커뮤니티, 공유 |
| 9 | **연간 회고 = 스토리 카드 묶음**(9:16 정적 이미지). 참전 수, 가장 많이 본 밴드, 방문 도도부현, 성지 수. 연말에만 열지 않고 해가 끝나면 언제든 | Spotify Wrapped, LINE MUSIC My推し | 마이 推し活年表 |
| 10 | **일본어 UI 규칙은 デジタル庁 DADS + SmartHR**를 기준으로 삼는다(타이포·날짜·상태어·버튼 문구·에러) | DADS, SmartHR Design System | 전 화면 |

---

## 2. 순례·여행 레퍼런스

| 레퍼런스 | 빌릴 패턴 | 적용 위치 | 따라 하지 않을 것 | 검증 |
|---|---|---|---|---|
| [Anitabi](https://apps.apple.com/app/id6745898838) · [web](https://www.anitabi.cn/map) | 핀마다 장면 스크린샷 + 실제 사진 나란히. 비교 카메라(고스트 오버레이, 0.5×/1×/2×). 오프라인 지도 캐시 | 지도 핀, 장소 상세 장면 블록, 체크인 카메라 | 핀 과밀, 매너 정보 없음, 검수 없는 크라우드 제보 | V |
| [JapanAnimeMaps](https://apps.apple.com/jp/app/id6608967051) | 작품별·지역별 탐색, 장면 이미지 + 지도. 체크인·추억 남기기·같은 장소 팬 글 보기 | 장소 상세 커뮤니티 줄 | 작은 카탈로그를 전국 커버처럼 보이게 함 | S |
| [聖地巡礼マップ (indie, 2026)](https://apps.apple.com/us/app/id6765700715) | 작품별 스폿 묶음, 앱 안의 현장 매너 가이드(JA/EN) | 매너 블록, 작품별 목록 | 방문 기록·오프라인 없음 | V |
| [舞台めぐり (종료)](https://applion.jp/android/app/jp.linknetwork.anitrip) | 체크인 보상(캐스트 보이스·배경화면), 사진·경로·코멘트 자동 일기, 작품별 코스 | 체크인 보상, 여행 앨범, 코스 | 권리 계약에 의존한 핵심 흐름. 계약 종료 = 서비스 종료. 서비스는 2023-10-02 종료로 확인 | S |
| [アニメ聖地88](https://www.gotokyo.org/jp/anime-and-manga/animetourism88/) | 연간 인증 88곳, 실물 御朱印·인증 플레이트, 지역 스탬프북 | 지역 허브 "聖地88認定" 배지, 진행도 x/88 | 종이 대체. 디지털은 실물 스탬프의 **기록**으로만 | S |
| 디지털 스탬프 랠리 ([Fan Fun Spot](https://fanfunspot.bn-ent.net/stamprally/), [ワールドダイスター×台東区](https://world-dai-star.com/taitorally/)) | GPS 지오펜스 또는 현장 QR로 스탬프, 캐릭터 카드 그리드, 완주 보상, 완주 후 AR 사진 | 기간 한정 랠리 카드 | 이벤트마다 별도 미니앱·별도 가입 | S |
| [NAVITIME Japan Travel](https://apps.apple.com/app/id686373726) | 오프라인 주변 Wi-Fi·ATM·관광안내소·역 목록(현재 위치/선택 역 기준), 최근 경로 50건 오프라인 | 오늘 목록 오프라인 팩 | AR 길안내, 기본 기능 유료화 | S |
| Japan Official Travel App (JNTO) | 운행 지연·중단 정보가 붙은 경로, 재해 알림·대피소·회화 카드 | 접근 블록 지연 배지(외부 연결), 마이 안전 링크 | 일반 기사 피드 | S |
| [Google Maps Lists](https://9to5google.com/2023/09/08/google-maps-saved-places-emoji/) | 목록별 이모지가 지도 핀이 됨, 공유 목록·이모지 투표 | 스폿집 핀(推し 색·아이콘), 공동 계획(P2) | 플랫폼별 핀 표시 불일치 | S |
| [Apple Maps Guides](https://support.apple.com/guide/maps/mps23f9c5bb1/mac) | 장소 카드에서 "가이드에 추가", 인라인으로 새 가이드 생성, 공식 가이드와 내 가이드 병렬 | 저장 시트, 공식 코스 vs 내 목록 | 저장을 More 메뉴에 숨김 → 우리는 주 버튼 | S |
| [Wanderlog](https://wanderlog.com) | 날짜별 칼럼, 연속 스폿 사이 이동 시간·거리, 지도+목록 분할, 드래그 순서 변경 | 코스, 오늘 목록 순서 | 오프라인 유료화 | S |
| [Polarsteps](https://www.polarsteps.com/travel-tracker) | 여행이 "step"으로 자동 분할, 각 step에 사진·글, 인쇄 책 | 여행 앨범 구조 | **상시 백그라운드 GPS**. 체크인·EXIF로 대체 | S |
| [Komoot](https://www.komoot.com/features) | 큐레이션 컬렉션 + "Highlights"(커뮤니티 추천 지점), 경로+지역 원탭 다운로드 | 코스, 지역 허브 오프라인 다운로드 | 고도·노면 등 스포츠 정보 | S |
| AllTrails | 구조화 정보 + 최근 방문자 사진·후기로 현재 상태 파악 | 장소 상세 "최근 방문자 사진·메모" | 오프라인 유료화 | S |
| [Pokémon GO Routes](https://pokemongo.fandom.com/wiki/Routes) | 시작점 도착 대기 "따라가기", 진행에 따라 경로선 색 변화, 반복 배지(브론즈/실버/골드) | 코스 "コースを始める", 진행 경로선 | 체류·반복을 부추기는 보상(주거지 성지 민폐) | S |
| [駅メモ！](https://ekimemo.com/help/howto/radar_access) | 우하단 단일 체크인 버튼, 타임라인/지도 토글 | 체크인 버튼 위치, 기록 타임라인/지도 토글 | 원격 체크인(레이더). 순례 체크인은 실제 현장만 | V |
| 食べログ | 상세 고정 탭 순서, 헤더에 "○○駅 徒歩5分 (380m)" | 장소 상세 접근 줄 | 점수 랭킹. 성지를 점수로 줄 세우지 않음 | S |
| [Yahoo!乗換案内](https://transit.yahoo.co.jp) · [ジョルダン](https://norikae.jorudan.co.jp/openapi/) | 출발·도착을 채운 외부 딥링크(앱 스킴/웹 URL, 조르단은 공개 API) | 「電車で行く」 버튼 | 자체 경로 탐색. 야후 딥링크 전체 사양은 비공개(U) | S |
| Airbnb (2025) | Trips 일자별 일정, Today 시간대 뷰·캘린더 동기화, 다녀온 곳 프로필 | 당일 모드, 마이 방문 지도 | 일정 안 판촉 | S |
| [TripIt](https://www.tripit.com/web/blog) | 날짜가 겹치는 계획을 하나의 여행으로 자동 병합 | 여행 앨범에 같은 기간 공연 자동 연결 | 메일함 스캔 | S |

---

## 3. 라이브·팬·음악 레퍼런스

| 레퍼런스 | 빌릴 패턴 | 적용 위치 | 따라 하지 않을 것 | 검증 |
|---|---|---|---|---|
| [LiveFans](https://www.livefans.jp/app/) | 원탭 "参戦チェック"로 개인 라이브 일기, 세트리스트를 곡 순서대로 재생, 팬의 세트리스트 기여 | 마이 참전 이력, 공연 상세 "曲順で聴く"(외부 스트리밍) | 가짜 공연장 음향 효과. 스포일러 처리 없음 | V |
| [setlist.fm](https://www.setlist.fm/faq) | "I was there" → 프로필 통계, **참전 기록 공개 범위 별도 설정**, 투어 평균 세트리스트 | 마이 통계·공개 설정, 공연 상세 "このツアーの定番曲"(스포일러 약한 예습) | 합동 공연을 아티스트당 1회로 셈 → 우리는 공연당 | V |
| [Songkick](https://www.songkick.com/info/about) | Track(관심, 알림) / I'm going(참가 확정) 2단계 | 気になる(저장) / 参加予定 → 날짜 후 参戦済み | 티켓 구매 리마인더(범위 제외) | S |
| [Bandsintown](https://play.google.com/store/apps/details?id=com.bandsintown) | 아티스트 팔로우 = 개인 공연 캘린더, 음악 앱의 팔로우 가져오기 | 라이브 캘린더 推し 필터, 온보딩 推し 선택 | 위치 우선 발견(우리 팬은 원정을 간다) | S |
| [Weverse](https://apps.apple.com/us/app/weverse-connect-with-artists/id1456559188) | 생일·발매·라이브를 한 캘린더에, 리마인더·북마크·공유 | 스케줄 혼합 일정 + 유형 색 칩, 일정 공유 카드 | 유료 멤버십 게이팅, 샵 푸시 | S |
| [Spotify](https://support.spotify.com/us/article/concerts-near-you/) · [Wrapped 2025](https://newsroom.spotify.com/2025-12-03/2025-wrapped-user-experience/) | 공식 판매처로 나가는 단일 버튼, 데이터 스토리당 카드 1장 공유 | 공연 상세 「公式チケット」 1개, 연간 회고 카드 | 12월 한정·무거운 모션 → 정적 이미지, 연말 이후 상시 | V |
| [Apple Music](https://support.apple.com/guide/iphone/show-song-credits-and-lyrics-iphb9bf483aa/ios) | 가사 발음/번역 토글, 크레딧 화면, 아티스트 브랜드 색 | 곡 상세 가사(권리 확인분) + 로마자 토글 + 作詞/作曲/編曲, 밴드 페이지 공식 색 | 보컬 제거 노래방 | V |
| [Musixmatch](https://apps.apple.com/us/app/musixmatch-lyrics-finder/id448278467) | 커뮤니티가 구조·싱크·번역 기여 → 큐레이터 검수 → 포인트·배지 | **콜 가이드 기여**: 팬 제안 → 모더레이터 승인 → 기여자 배지 | 무허가 가사 본문 호스팅 | S |
| [LINE MUSIC My推し](https://www.lycorp.co.jp/ja/news/release/018365/) | 推し별 전용 공간: 내 기록·커버 커스텀·활동 배지·공유 | 마이 → 推し별 페이지(라이브 10회, 성지 5곳 등 배지) | 재생 수 경쟁 랭킹 | V |
| [Oshibana](https://oshibana.fun/) | 다음 일정 카운트다운 위젯, 推し始め記念日 | 홈/위젯 "次の参戦まで N日", 회고의 기념일 | 기능 난립(신규 개발 종료 보도는 U) | S |
| [=LOVE コール](https://ikorabucall.com/) (팬 사이트) | 곡별 마커(콜 있음·라이브 정번·인기·콜 없음), 곡별 콜 대본, **초참전 가이드**(필수 5곡·멤버별 펜라이트 색·준비물·매너) | 곡 상세 콜 블록·"コールあり" 배지, 공연 상세 「初参戦ガイド」 | 비공식 라이브 영상 임베드 | V |
| [Bestdori](https://bestdori.com/) · [bandori.party](https://bandori.party/songs/) | 밴드·작곡·작사·편곡 패싯 검색, 이벤트 목록 분리 | 악곡 아카이브 필터(밴드·작사·작곡·연도·라이브 연주 이력) | 게임 전용 데이터(난이도·컷라인) 전면 노출 | V |
| [BanG Dream! 公式](https://bang-dream.com/events) | 밴드 태그 이벤트, DAY1/2/3 날짜별 페이지(하루 한 밴드), 開場/開演·회장 | **데이터 모델: 시리즈 > 일자별 공연 > 출연 밴드**, 스케줄 시리즈 그룹 | 마이크로사이트 분산 | V |
| [ガールズバンドクライ LIVE](https://girls-band-cry.com/live/) | NEWS와 분리된 LIVE 목록, 공연별 페이지 | 투어 구간 필드 필요 근거 | 뉴스·굿즈 혼합 | V |
| [チケットぴあ](https://t.pia.jp/guide/favorite.jsp) | 아티스트 하트 → 새 공연 발표만 新着 탭·푸시 | 推し 팔로우 → **새 공연 발표 알림만** | 결제·발권 마감 푸시, 리세일 알림(범위 제외) | S |
| [Peatix](https://services.peatix.com/ja) · [Luma](https://help.luma.com/p/calendar-memberships) | 주최자/캘린더 구독 → 새 일정 자동 알림, 예정/지난 탭, 캘린더에 추가 | 밴드별 구독, 공연 상세 「カレンダーに追加」(.ics), 밴드 페이지 예정/지난 탭 | 주최자 메시지, 결제 | S |
| [コミックナタリー 라이브 레포](https://natalie.mu/comic/news/662072) | 제목에 숫자, "（セットリストあり / 写真43枚）", 블록별 서술, 세트리스트는 맨 끝 | 레포 템플릿: 공연 자동 태그, "セトリあり" 칩, 세트리스트는 하단 가림 | 긴 기사체 강요 | V |
| X 공유 문화 | 세트리 이미지·参戦 카드 + 해시태그, 9:16/16:9 | 공유 카드 생성기(해시태그·딥링크 포함) | 자동 게시. 항상 미리보기·편집 | U |
| bubble / Fanicon | 재직 기간에 따라 늘어나는 답글 길이(신뢰 단계) | 커뮤니티 신뢰 단계(U) | 유료 1:1 아티스트 DM, 폐쇄형 유료 팬클럽 | S/U |

---

## 4. 일본어 UI 규칙 (기준: DADS + SmartHR)

### 4.1 타이포그래피

| 항목 | 규칙 | 근거 |
|---|---|---|
| 글꼴 | 일본어 Noto Sans JP(400/700), 한국어 Noto Sans KR. **로케일 명시 + 로케일별 `fontFamilyFallback`** — 안 하면 한자가 중국어 자형으로 나옴(예: 骨) | [DADS](https://design.digital.go.jp/dads/foundations/typography/) V, [flutter#16870](https://github.com/flutter/flutter/issues/16870) V |
| 숫자 옵션 | 날짜·시각·수량에 BIZ UDPGothic(오독 방지, Google Fonts 무료) 검토 | [Morisawa](https://www.morisawa.co.jp/about/news/6706) V |
| 본문 | 16sp, 줄높이 1.6, 자간 0.02em. 최소 14sp | DADS V |
| 밀집 목록 | 줄높이 1.2–1.3, 자간 0 | DADS V |
| 버튼·칩 | 줄높이 1.0 | DADS V |
| 큰 제목 | 줄높이 1.4, 자간 0.01em, `palt`는 제목에만(`FontFeature('palt')`). 본문 금지 | DADS V, [TypeSquare](https://blog.typesquare.com/archives/788) V |

### 4.2 날짜·숫자·기호

| 항목 | 규칙 | 근거 |
|---|---|---|
| 날짜 | JA `2026/10/12` 또는 `2026年10月12日`, KO `2026년 10월 12일`. 목록 축약 `10/12(月)`는 관용(출처 없음, U) — 쓰면 괄호 반각/전각 통일 | [SmartHR 数字](https://smarthr.design/products/contents/idiomatic-usage/count/) V |
| 시각 | 24시간 `17:00`. 공연은 `開場 17:00 / 開演 18:00` | SmartHR V |
| 범위 | `〜` 공백 없이: `10/12〜10/13` | SmartHR V |
| 숫자 | 반각, 세 자리 콤마 `1,000円`. 조수사 `12か所`, `3件` | SmartHR V |
| 기호 | 일본어와 영숫자 사이 공백 없음, 전각 （）「」！？, 반각 ¥ % | [SmartHR 記号](https://smarthr.design/products/contents/idiomatic-usage/symbol/) V |
| 날짜 입력 | 서기, 예시는 helper text(`例）2026年10月12日`), 전각 숫자 자동 반각, 오늘 달로 열기, 포커스로 달력 자동 오픈 금지 | [DADS date picker](https://design.digital.go.jp/dads/components/date-picker/usage/) V |
| 캘린더 시작 요일 | 일요일 시작(일본 벽달력 관행, U) | U |

### 4.3 문구

| 항목 | 규칙 | 근거 |
|---|---|---|
| 버튼 | 동사 기본형: `保存する` `削除する` `記録する` | SmartHR(2024 갱신) V |
| 제목·항목명 | 명사 | SmartHR V |
| 본문 | です・ます | SmartHR V |
| 동작 동사 | `押す`(タップ·クリック 금지), 링크는 `開く`, 스위치는 `有効にする/無効にする`, 외래어보다 고유어(インポート → 取り込む) | [SmartHR 動作](https://smarthr.design/products/contents/idiomatic-usage/action/) V |
| 상태어 | `○○前`(시작 전) `○○中` `○○待ち` `○○済み` `終了` `要○○` `○○失敗` 고정 패턴 → 공연 `開催前/開催中/終了/中止`, 방문 `訪問済み`, 전송 `送信待ち` `送信失敗` | [SmartHR status](https://smarthr.design/products/contents/ui-text/statuslabel/) V |
| 에러 | 무엇이(事象)·왜(原因)·어떻게(対処). 공간 부족 시 원인 → 대처 우선. 사용자 시점 | [SmartHR error](https://smarthr.design/products/contents/error-messages/overview/) V |
| 빈 상태 | 왜 비었는지 + 이 화면의 역할 + 시작 버튼 하나 | [NN/g 일본어판](https://u-site.jp/alertbox/empty-state-interface-design) V |

### 4.4 레이아웃·컴포넌트

| 항목 | 규칙 | 근거 |
|---|---|---|
| 하단 탭 | 3–5개, 모두 라벨, 이동 전용(행동 금지), 모달 외에는 항상 표시, 배지는 중요한 것만 | [HIG tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars) V, [MDC nav bar](https://github.com/material-components/material-components-android/blob/master/docs/components/BottomNavigation.md) V(높이 80dp, 아이콘 24dp, 인디케이터 56×32dp) |
| 지도 시트 | 비모달 표준 시트, medium(≈½)·large 단계, grabber(VoiceOver 조작 가능), 핸들 터치 영역 ≥48dp, 태블릿 최대 폭 640dp. 시트 위에 시트 쌓지 않음. 필터는 모달 시트 | [HIG sheets](https://developer.apple.com/design/human-interface-guidelines/sheets) V, [MDC bottom sheet](https://github.com/material-components/material-components-android/blob/master/docs/components/BottomSheet.md) V |
| 터치·대비 | 44×44pt 기본(28pt 절대 최소), 대비 4.5:1(17pt 이하), 3:1(18pt+·굵게) | [HIG accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) V |
| 정보 밀도 | **사용자 결정(2026-10-02): 조밀하게 하지 않는다.** 일본 UI 밀도 관행(一休 Design, Galactus)은 참고만. 목록 행은 날짜·제목·상태 중심, 나머지는 상세로 | 사용자 결정 |
| 한국어 문자열 | 같은 레이아웃에서 약간 느슨한 간격이 필요할 수 있음 | 一休 Design V |

### 4.5 시각 방향

기존 **Urban Travel Field Notes**(종이색 캔버스, 먹색 텍스트, 블루 = 행동·현재 상태, 틸 = 장소·방문, 빨강 = `中止`·`失敗`만) 유지. 여행 수첩 미감(MUJI, ほぼ日, トラベラーズノート)에 대한 신뢰할 디자인 시스템 근거는 찾지 못했다. 그래서 이 방향은 **자체 아트 디렉션**으로 둔다(U).

---

## 5. 하지 않을 것 (레퍼런스에서 배운 반면교사)

- 오프라인·당일 모드 유료화(Wanderlog, AllTrails, NAVITIME)
- 상시 백그라운드 위치 추적(Polarsteps)
- 원격 체크인(駅メモ 레이더), 체류·반복을 부추기는 보상(Pokémon GO)
- 권리 계약에 핵심 흐름을 묶는 것(舞台めぐり)
- 점수 랭킹으로 성지 줄 세우기(食べログ)
- 결제·발권 마감 푸시, 리세일 알림(ぴあ) — 범위 제외
- 유료 1:1 DM, 폐쇄형 유료 팬클럽(bubble, Fanicon)
- 무허가 가사 본문, 비공식 라이브 영상
- 탭이 행동을 하는 것, 시트 겹치기, 업데이트마다 배지
- 문구에 「タップ」「クリック」, 본문 `palt`, 14sp 미만 글자

---

## 6. 미확인·후속 조사

- 推しごよみ: 이번 검색에서 다시 찾지 못함(이전 회차에는 App Store 링크 확인). 표에서 제외.
- 야후 乗換案内 딥링크 전체 사양, Oshibana 개발 종료, X 공유 관행, bubble/Fanicon UI: U.
- Mercari·LINE 디자인 시스템 수치: 공식 아님/렌더 실패 → 사용 전 확인.
- freee 접근성 가이드라인(https://a11y-guidelines.freee.co.jp/), Mobbin 패턴: 미조사.
- 실제 화면 캡처 수집(무드보드)은 별도 작업. 저작권 때문에 레포에 캡처 이미지를 커밋하지 않고 링크로만 관리한다.
