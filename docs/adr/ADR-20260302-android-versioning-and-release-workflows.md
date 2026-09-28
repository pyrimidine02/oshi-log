# ADR-20260302-android-versioning-and-release-workflows

- Date: 2026-03-02
- Status: Accepted

## Context

Android 배포 자동화는 내부테스터 라인만 존재했고,
버전명/빌드번호 관리 방식이 명확하게 문서화되어 있지 않았다.
이 상태에서는 수동 버전코드 충돌과 릴리스 절차 누락 위험이 있었다.

## Decision

- 버전 정책을 다음으로 표준화한다.
  - `pubspec.yaml`을 버전명의 단일 소스로 사용
  - CI에서 `build-number = YYYYMMDD + 2자리 sequence` 자동 주입
    (`sequence = (run_number + run_attempt - 1) % 100`)
- 워크플로를 2라인으로 분리한다.
  1. `android-internal-distribution.yml`: PR 검증 + main 내부테스터 자동 배포
  2. `android-production-release.yml`: `release` 브랜치 push 기준 production draft 업로드 (2026-09-28, D-027)
- 릴리스 워크플로에서 태그 버전과 pubspec 버전의 일치 여부를 강제한다.
- 버전 업데이트 편의를 위해 `scripts/bump_version.sh`를 추가한다.
- 운영 문서를 `docs/모바일버전배포가이드_v1.0.0.md`로 제공한다.

## Alternatives Considered

1. 내부테스터 워크플로만 유지하고 태그 릴리스 미분리
- 장점: 구성 단순
- 단점: 정식 릴리스 경로가 불명확하고 절차 누락 위험 증가

2. 빌드번호를 pubspec 수동 증가로만 운영
- 장점: CI 로직 단순
- 단점: 병렬/재시도 시 versionCode 충돌 가능성 높음

## Consequences

- 장점: 테스트 단계부터 배포까지 흐름이 자동화되고 명확해짐
- 장점: 릴리스 태그와 앱 버전 불일치 문제를 사전에 차단
- 장점: 날짜 기반 versionCode로 기존 고값 코드와 충돌 위험을 줄이고,
  run attempt를 반영해 재시도 빌드 충돌을 완화
- 단점: GitHub Secrets 미설정 시 배포 단계가 실패할 수 있음

## Validation

- 두 워크플로 YAML 파싱 검증 완료
- 변경 사항 문서/스크립트 반영 완료
