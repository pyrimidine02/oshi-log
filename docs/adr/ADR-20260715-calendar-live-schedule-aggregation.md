# ADR-20260715: Calendar Live Schedule Aggregation

## 상태

Accepted — 2026-07-15

## 배경

앱의 전체 일정 화면은 `GET /api/v1/calendar/events`만 조회했다.
이 API는 생일·발매·티켓 등 팬 캘린더 도메인을 반환하지만,
별도의 `live_events`에 저장된 라이브 일정은 포함하지 않았다.
또한 클라이언트는 서버가 요구하는 `projectKey`가 아닌
`projectId`를 쿼리로 전송하고 있었다.

운영 확인에서 다음 계약 차이도 확인했다.

- 팬 캘린더 컨트롤러는 공개 읽기 API로 설계됐지만 운영
  보안 설정에서 미인증 요청이 401을 받았다.
- 라이브 목록은 페이지네이션되며, 다일 라이브의 종료 시각은
  상세 응답에만 있고 목록 `LiveEventSummaryDto`에는 없었다.
- 일본 라이브 날짜를 기기 로컬 시간대로 변환하면 해외
  시간대에서 공식 표기일과 다른 날짜로 보일 수 있다.

## 결정 동인

- 생일·발매·티켓과 라이브를 하나의 월별 일정에서 보여준다.
- 뱅드림처럼 일정이 많은 프로젝트에서도 페이지 경계로 누락하지
  않는다.
- 한 소스의 실패가 정상적인 다른 일정을 숨기지 않게 한다.
- 다일·월 경계 라이브를 보이는 달의 모든 해당 날짜에 표시한다.
- 모바일 앱에 공식 일정 수집 책임을 두지 않는다.

## 결정

1. 팬 캘린더 쿼리는 선택한 프로젝트의 slug/code인
   `projectKey`를 사용한다.
2. 캘린더 repository는 팬 캘린더와 선택 프로젝트의 라이브
   목록을 동시에 요청하고 일정 ID로 병합한다.
3. 라이브 목록은 `size=100`으로 요청하고 응답이 100개인 동안
   다음 페이지를 조회한다. 비정상 서버 응답이 무한 요청으로 이어지지
   않도록 20페이지를 안전 상한으로 둔다.
4. 이전 달에 시작해 현재 달로 이어지는 라이브를 포함하도록
   조회 시작을 한 달 앞으로 확장하고, repository에서 현재 달만
   다시 필터링한다.
5. `endTime`이 있는 일정은 시작일부터 종료일까지 하루당 하나의
   불변 `CalendarEvent`로 투영한다. 추가 날짜 행은
   `sourceId:yyyy-MM-dd`를 표시 ID로 사용하되 상세 이동은 같은
   `relatedEntityId`를 유지한다.
6. 한 소스가 실패해도 다른 소스의 표시 가능한 일정은 반환한다.
   다만 병합 후 현재 달의 일정이 비어 있고 어느 소스든 실패했다면
   정상적인 빈 달로 처리하지 않고 오류를 전달한다.

## 서버 계약과 배포 순서

다일 투영과 비인증 팬 캘린더를 완성하려면 다음 서버 변경이
먼저 운영에 배포되어야 한다.

- `GET /api/v1/calendar/events` 및 하위 경로를 공개 읽기로 허용한다.
- `LiveEventSummaryDto`에 nullable `endTime` 필드를 추가하고 서비스의
  `LiveEventEntity.endTime`을 매핑한다.

서버 배포 전에도 클라이언트는 라이브 시작일을 표시할 수 있지만,
`endTime`이 없으므로 다일 일정의 나머지 날짜는 표시할 수 없다.

## 고려한 대안

### 팬 캘린더 API만 사용

요청 수는 적지만 `live_events`에 있는 뱅드림 라이브가 계속
누락되므로 선택하지 않았다.

### 라이브 API만 사용

라이브 표시는 해결되지만 생일·발매·티켓 일정을 잃으므로 선택하지
않았다.

### 라이브별 상세 API 추가 조회

기존 운영 계약만으로도 `endTime`을 얻을 수 있지만, 월 일정 조회가
N+1 네트워크 요청이 된다. 목록 DTO 계약을 확장하는 편이 일관성과
성능에 유리해 선택하지 않았다.

## 영향과 제약

### 긍정적 영향

- 팬 캘린더와 라이브를 하나의 월 그리드와 어젠다에서 탐색한다.
- 다일·월 경계 라이브의 모든 해당 날짜가 같은 상세로 이어진다.
- 페이지 상한으로 인한 조용한 누락을 줄인다.
- 팬 캘린더의 운영 보안 설정이 배포되기 전에도 공개 라이브
  소스가 정상이면 라이브 일정은 표시할 수 있다.

### 부정적 영향·제약

- 월별 조회마다 최대 20개 페이지의 라이브 요청이 발생할 수 있다.
- 현재 일별 투영은 기기 로컬 시간대를 사용한다. 선택한
  `Project.defaultTimezone`을 사용하는 도메인 날짜 정책은 후속 작업이다.
- 클라이언트 병합은 이미 서버에 있는 일정만 표시한다. 공식
  일정 추가·변경·취소를 자동으로 수집하지 않는다.

## 후속 결정

1. 공식 일정 동기화는 서버 작업으로 설계한다. 안정적인 외부 키,
   출처 URL, 원본 수정 시각, 최종 확인 시각과 멱등 upsert/중복
   제거 규칙을 먼저 합의한다.
2. 캘린더는 선택 프로젝트의 `defaultTimezone`으로 조회 범위·월 필터·
   일별 투영을 수행하도록 시간대 정책을 도메인 계층에 분리한다.

## 검증

- `flutter test test/features/calendar/data/calendar_event_dto_test.dart`
- `flutter test test/features/calendar/data/calendar_remote_data_source_test.dart`
- `flutter test test/features/calendar/data/calendar_repository_impl_test.dart`
- 서버 배포 후 미인증 공개 API 검증:
  - `GET /api/v1/calendar/events?projectKey=bang-dream&year=2026&month=7`
  - `GET /api/v1/projects/bang-dream/live-events?from=...&to=...&page=0&size=100`

## 관련 결정

- `ADR-20260130-project-key-selection.md`
- `ADR-20260202-project-slug-api-usage.md`
- `ADR-20260715-urban-travel-field-notes.md`
