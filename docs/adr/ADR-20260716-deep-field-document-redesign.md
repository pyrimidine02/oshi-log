# ADR-20260716: 깊은 화면의 Field Document 재설계

## 상태

Accepted — 2026-07-16

## 배경

루트와 얕은 탐색 화면은 Urban Travel Field Notes 디자인으로 전환됐지만,
게시글 작성·수정·상세·댓글, 지도 선택 상태, 공개 프로필, 프로필 수정은 과거의
설정 카드·소셜 피드·지도 pill 문법이 섞여 있었다. 특히 본인 기록을 보여주는
여권형 마이 페이지와 타인 프로필 사이에 시각적 연결이 약했다.

이번 변경은 API, Riverpod provider, 네이티브 지도, 업로드, 저장, 권한 및 기존
딥링크를 유지하면서 활성 라우트의 프레젠테이션 계층만 재구성한다.

## 조사한 제품 패턴

2026-07-16 기준 공식 지원 문서와 스토어 설명을 비교했다.

- [Polarsteps Step design](https://support.polarsteps.com/hc/en-us/articles/27359026422930-How-to-use-the-new-step-design-video)과
  [Step 작성·수정](https://support.polarsteps.com/hc/en-us/articles/23760478173586-What-are-steps-and-how-do-I-add-or-edit-them):
  장소와 미디어를 한 여행 기록 단위에 연결하고 작성·수정을 같은 문맥으로 유지한다.
- [Day One 미디어 기록](https://dayoneapp.com/guides/getting-started-with-day-one/adding-media-in-day-one/):
  글 본문과 미디어를 분리된 소셜 카드가 아니라 하나의 기록 문서로 다룬다.
- [Strava 프로필](https://support.strava.com/en-us/articles/15402175-your-strava-profile-page)과
  [Athlete Posts](https://support.strava.com/en-us/articles/15401802-athlete-posts):
  신원, 관계, 실제 활동과 작성 콘텐츠를 같은 프로필 안에서 연결한다.
- [Wanderlog 지도 레이어](https://help.wanderlog.com/hc/en-us/articles/5159543865499-Hide-lists-or-days-on-map):
  지도 정보 밀도를 레이어 단위로 제어하고 사용자의 현재 탐색 범위를 명확히 한다.
- [Letterboxd iOS](https://apps.apple.com/us/app/letterboxd/id1054271011):
  프로필에서 작성 기록과 사회적 활동을 지속적으로 탐색하게 한다.

제품의 자산이나 고유 UI를 복제하지 않고, 기록 단위·레이어·활동 원장이라는
정보 구조 원칙만 적용한다.

## 결정

### 게시글

- 작성과 수정은 공용 `PostComposeDocumentEditor`를 사용한다.
- 제목과 본문을 하나의 Field Note 문서로 묶고, 기존 미디어 선택·업로드·
  프로젝트 범위·저장 동작은 유지한다.
- 상세는 헤더 → 본문 → 행동 → 댓글 원장 → 작성기의 고정된 문서 순서를 사용한다.
- 댓글과 좋아요 수는 제공된 실제 값만 표시한다.

### 지도

- 네이티브 Apple/Google 지도와 controller lease는 변경하지 않는다.
- 지도 위에는 탐색 레이어와 현재 선택한 장소의 Field Card만 합성한다.
- 선택 카드에서 장소 상세와 길안내로 직접 이동한다. 길안내 provider가 없으면
  동작을 비활성화한다.

### 공개 프로필과 내 프로필

- 본인 마이 페이지의 여행 여권은 유지한다.
- 공개 프로필은 `TRAVELER FIELD CARD`로 바꾸고, 컴팩트 커버·직사각형 증명사진·
  접근 등급·관계 수치·행동을 한 장의 신원 문서로 구성한다.
- 작성한 글, 작성한 댓글, 방문 기록은 고정 활동 원장 탭으로 연결한다.
- 공개 방문 기록 API가 없는 현재는 방문 횟수 또는 비어 있음만 정직하게 표시하며
  다른 사용자의 방문 내역을 추정하지 않는다.

### 프로필 수정

- 과거 `iOS settings style` 카드 묶음을 `IDENTITY AMENDMENT` 문서로 교체한다.
- 배경은 128px 스트립, 아바타는 여권 증명사진 비율로 미리 본다.
- 이름·소개는 소유자 정보, 마스킹 이메일·권한·가입일은 발급 기록으로 분리한다.
- 이미지 선택, 크롭, 업로드, 저장, 미저장 이탈 확인 로직은 그대로 유지한다.
- Android 인앱 크롭 다이얼로그는 별도 위젯 파일로 캡슐화한다.

## 접근성·성능

- 새 미디어·프로필·지도 행동은 최소 48dp 터치 영역을 갖는다.
- 320dp와 200% 텍스트 확대에서 overflow가 없어야 한다.
- 큰 프로필 문서는 sliver와 lazy list를 유지하고, 활동 탭은 pinned header로 둔다.
- 지도 overlay는 네이티브 map view와 분리해 지도 재생성 범위를 늘리지 않는다.
- 서버 모델과 provider state는 변경하거나 가짜 데이터로 보완하지 않는다.

## 영향

- 기존 라우트와 딥링크, API 계약은 바뀌지 않는다.
- 작성/수정 중복이 줄고 프로필 수정 페이지 파일에서 과거 설정 UI 약 600줄이
  제거된다.
- 공개 방문 활동의 완전한 원장은 서버 계약 추가 후 확장한다.
- iOS/Android 실기기에서 지도 길안내, 이미지 크롭·저장, 프로필 활동 복귀 상태를
  추가 검증해야 한다.
