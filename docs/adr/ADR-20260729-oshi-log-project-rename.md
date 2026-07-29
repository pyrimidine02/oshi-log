# ADR-20260729: oshi@log 프로젝트 리네임

## 상태

Accepted

## 문제

앱·Dart 패키지·저장소가 기존 프로젝트명을 사용했다. 새 사용자 표시
브랜드는 `oshi@log`지만 `@`는 Dart 패키지명과 플랫폼 식별자에 사용할 수
없다. 이미 Play Store와 App Store에 연결된 앱 식별자를 바꾸면 기존 앱의
업데이트 경로, Firebase, OAuth, 딥링크가 끊길 수 있다.

## 결정

- 사용자 표시 브랜드는 모든 지원 언어와 Android/iOS에서 `oshi@log`를
  사용한다.
- 비공개 Dart 패키지명은 유효한 snake_case인 `oshi_log`를 사용한다.
- GitHub 저장소 slug는 `oshi-log`를 사용한다.
- 다음 호환성 식별자는 기존 값을 유지한다.
  - Android `applicationId`와 namespace:
    `cc.noraneko.girlsbandtabi_app`
  - iOS bundle identifier: `cc.noraneko.girlsbandtabi`
  - Firebase와 OAuth 클라이언트 설정
  - `girlsbandtabi://` 딥링크
  - `gbt_notifications_high` 알림 채널
  - 캐시·SharedPreferences 키, 정책 URL, 레거시 미디어 버킷
- 내부 `GBT*`/`gbt_*` 디자인 시스템 심볼은 사용자에게 노출되지 않고 현재
  작업 중인 파일과 충돌하므로 이번 변경에서 유지한다.

## 대안

플랫폼 식별자까지 `oshi` 기반으로 바꾸는 안은 기존 Store 앱과 별도 앱으로
취급될 위험이 있어 제외했다. 내부 `GBT*` 심볼을 동시에 바꾸는 안은 사용자
가치 없이 변경 범위와 충돌 위험만 크게 늘려 별도 작업으로 분리했다.

## 영향

- 앱 설치·업데이트·서명·푸시·로그인·기존 딥링크 호환성은 유지된다.
- Dart import는 `package:oshi_log/`를 사용한다.
- Store Console의 상품 표시 이름 변경은 코드 식별자 변경과 별도 운영
  절차다.
- 새 소스 계약 테스트가 표시 브랜드와 보존 식별자를 함께 고정한다.
