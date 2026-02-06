# MRMS (Marathon Registration Management System) PLAN.md

## 🎯 핵심 구현 지침

### `go` - 구현 사이클

1. **Test First**: 가장 첫 번째 미완료 테스트 케이스를 작성한다
2. **Minimal Code**: 테스트를 통과시키는 최소한의 코드만 작성한다
3. **Lint**: `bundle exec rubocop` 실행 (필요시 `-a`로 safe autocorrect)
4. **Run Tests**: `bundle exec rails test` 실행
5. **Report & Wait**: 결과를 보고하고 사용자 확인을 기다린다

> ⚠️ 이후 자동 진행 금지. 사용자 피드백에 따라 수정하거나 `commit`을 기다린다.

### `commit` - 완료 처리

1. **Commit**: 변경사항을 커밋한다
2. **Update PLAN.md**: 완료된 항목에 체크박스 표시

### 명령어

| 명령어     | 동작                                 |
| ---------- | ------------------------------------ |
| `go`       | 구현 사이클 실행 후 사용자 확인 대기 |
| `commit`   | 커밋 및 PLAN.md 체크박스 표시        |
| `status`   | 현재 진행 상황 보고                  |
| `refactor` | 테스트 통과 후 리팩토링 제안         |

### 필수 실행 명령어

```bash
# 구현 사이클 (파일 편집/추가/삭제 후)
bundle exec rubocop                # 확인 먼저, 필요시 -a로 safe autocorrect

# 테스트 실행 (통과할 때까지 반복)
bundle exec rails test

# 마이그레이션 변경 시에만
bundle exec rails db:migrate

# 앱 정상 로드 확인
bundle exec rails runner "puts 'OK'"
```

### 마일스톤 규칙

- 하나의 마일스톤은 "동작"이 완성되는 단위, 단일 책임
- Milestone 순서대로 진행
- 이전 Milestone 완료 전 다음으로 진행 금지
- **구현 방식은 TECHSPEC.md 참조** (CLAUDE.md의 참조 가이드 확인)

---

## 📋 구현 진행 상황

### Milestone 1: 프로젝트 초기화

**목표:** Rails 8 프로젝트 생성 및 기본 설정

- [x] Rails 프로젝트 생성 (`rails new mrms -d sqlite3`)
- [x] RuboCop 설정 (.rubocop.yml)
- [x] 보안 gem 추가 (brakeman, bundler-audit - development group)
- [x] dotenv-rails 추가 및 .env 설정
- [x] .gitignore 업데이트 (.env 추가)
- [x] `rails runner "puts 'OK'"` 통과 확인

> **Note:** Rails 8은 SQLite에서 WAL 모드 + IMMEDIATE 트랜잭션이 기본 적용됨. 1000명 규모에서 충분.

**완료 조건:** `rubocop` 경고 없음, 앱 정상 로드

- Commits: 9237578

---

### Milestone 2: 스키마 & 시드

**목표:** 핵심 테이블 생성 및 초기 데이터

> 📖 TECHSPEC 섹션 6 참조

- [ ] Race 테이블 생성
- [ ] Course 테이블 생성
- [ ] Registration 테이블 생성
- [ ] Unique Index: `(race_id, name, phone_number)`
- [ ] Unique Index: `confirmation_code`
- [ ] Seed: Race 1개, Course 4개

**완료 조건:** `rails db:migrate db:seed` 성공, 스키마 확인

- Commits:

---

### Milestone 3: 모델 기본 설정

**목표:** 모델 관계 및 기본 검증

> 📖 TECHSPEC 섹션 6.1 참조

**Tests**

- [ ] Race has_many :courses, :registrations
- [ ] Course belongs_to :race, has_many :registrations
- [ ] Registration belongs_to :race, :course
- [ ] Registration 필수 필드 검증 (name, phone_number, birth_date)

**완료 조건:** 모든 유닛 테스트 통과

- Commits:

---

### Milestone 4: 신청 - 기본 폼

**목표:** 신청 폼 및 입력 검증

> 📖 TECHSPEC 섹션 7.1 참조

**Unit Tests**

- [ ] 이름 정규화: "홍 길 동" → "홍길동"
- [ ] 전화번호 정규화: "010-1234-5678" → "01012345678"
- [ ] 필수 필드 누락 시 에러

**Integration Tests**

- [ ] 신청 폼 표시 (available 코스만, 잔여 인원 표시)
- [ ] 입력 에러 시 폼 상태 유지 + 입력값 보존

**완료 조건:** 신청 폼 동작, 정규화 적용, 에러 시 입력값 보존

- Commits:

---

### Milestone 5: 신청 - 정원 관리 (P0)

**목표:** 정원 초과 방지

> 📖 TECHSPEC 섹션 7.2 참조 (트랜잭션 + lock! 패턴)

**Unit Tests**

- [ ] Course#full? - applied 수 >= capacity 시 true
- [ ] Course#available? - 마감 + 정원 조합 검증

**Integration Tests (P0)**

- [ ] 정원 1명, 동시 신청 2건 → 1건만 성공
- [ ] 정원 초과 시 에러: "선택하신 코스의 정원이 마감되었습니다."

**완료 조건:** 동시성 테스트 통과, 정원 초과 차단

- Commits:

---

### Milestone 6: 신청 - 중복 방지 (P0)

**목표:** 중복 신청 차단

> 📖 TECHSPEC 섹션 7.2 참조 (Unique Index + RecordNotUnique)

**Unit Tests**

- [ ] 동일 (race_id, name, phone_number) 중복 저장 시 에러

**Integration Tests (P0)**

- [ ] 동일 정보로 동시 신청 2건 → 1건만 성공
- [ ] 중복 시 에러: "이미 동일한 이름과 전화번호로 신청된 내역이 있습니다."

**완료 조건:** 중복 신청 차단, 동시성 테스트 통과

- Commits:

---

### Milestone 7: 신청 - 마감 판정 (P0)

**목표:** 시간/정원 마감 후 신청 차단

> 📖 TECHSPEC 섹션 7.3 참조

**Unit Tests**

- [ ] Race#registration_closed? - 마감일 경과 시 true
- [ ] Course#available? - 마감 OR 정원 초과 시 false

**Integration Tests (P0)**

- [ ] 마감일 경과 후 신청 → 차단, 메시지: "신청 기간이 종료되었습니다."
- [ ] 정원 마감 후 신청 → 차단, 메시지: "선택하신 코스의 정원이 마감되었습니다."

**완료 조건:** 마감 후 신청 완전 차단

- Commits:

---

### Milestone 8: 신청 완료 & 고유 코드

**목표:** 신청 성공 시 고유 코드 발급

> 📖 TECHSPEC 섹션 7.4 참조

**Unit Tests**

- [ ] confirmation_code 형식: 영문 대문자 + 숫자 8자리
- [ ] confirmation_code 유니크 보장

**Integration Tests**

- [ ] 신청 완료 → 완료 페이지에 코드 표시

**완료 조건:** 신청 시 고유 코드 발급, 완료 페이지 표시

- Commits:

---

### Milestone 9: 조회 & 취소

**목표:** 신청 내역 조회 및 취소 (멱등성 보장)

> 📖 TECHSPEC 섹션 7.5 참조
> 🎯 이 마일스톤 완료 시점 = 첫 사용자 테스트 가능

**Unit Tests**

- [ ] Registration#cancelable? - applied 상태 + 마감 전만 true
- [ ] Registration#cancel! - 멱등성: 이미 취소면 성공 반환
- [ ] 마감 후 cancel! → NotCancelableError

**Integration Tests**

- [ ] confirmation_code + 이름으로 조회 성공
- [ ] 잘못된 정보로 조회 → 에러 메시지
- [ ] 취소 성공 → status 변경, canceled_at 기록
- [ ] 이미 취소된 신청 다시 취소 → 에러 없이 성공 (P1)
- [ ] 마감 후 취소 시도 → 차단 (P0)

**완료 조건:** 조회/취소 플로우 동작, 멱등성 보장

- Commits:

---

### Milestone 10: 관리자 인증

**목표:** 환경변수 기반 관리자 로그인/로그아웃

> 📖 TECHSPEC 섹션 7.6 참조

**Unit Tests**

- [ ] 올바른 ID/PW → 세션 생성
- [ ] 잘못된 ID/PW → 로그인 실패
- [ ] 로그아웃 → 세션 삭제

**Integration Tests**

- [ ] 비인증 상태로 /admin 접근 → 로그인 페이지 리다이렉트
- [ ] 로그인 후 /admin 접근 → 성공

**완료 조건:** 관리자 인증 플로우 동작

- Commits:

---

### Milestone 11: 관리자 - 대회/코스 조회

**목표:** 관리자가 대회 정보와 코스 목록 확인

> 📖 TECHSPEC 섹션 5.2 참조

**Tests**

- [ ] Race 정보 조회
- [ ] Course 목록 조회 (capacity, 현재 신청 수 포함)
- [ ] 대회/코스 정보 페이지 표시

**완료 조건:** 관리자 페이지에서 대회/코스 정보 확인 가능

- Commits:

---

### Milestone 12: 관리자 - 코스 설정

**목표:** 관리자가 코스 정원 및 마감일 수정

> 📖 TECHSPEC 섹션 5.2 참조

**Tests**

- [ ] Course capacity 업데이트 → DB 반영
- [ ] Race registration_deadline 업데이트 → DB 반영
- [ ] 수정 폼 표시 및 저장 동작

**완료 조건:** 관리자가 정원/마감일 수정 가능

- Commits:

---

### Milestone 13: 관리자 - 신청자 목록

**목표:** 신청자 목록 조회, 정렬, 필터링

> 📖 TECHSPEC 섹션 1.1 (관리자 기능) 참조

**Tests**

- [ ] 신청일 기준 정렬
- [ ] 이름 기준 정렬
- [ ] 코스별 필터
- [ ] 상태별 필터 (applied, canceled, refunded)
- [ ] 목록 페이지 표시, 정렬/필터 동작

**완료 조건:** 관리자가 신청자 목록 조회/정렬/필터 가능

- Commits:

---

### Milestone 14: 에러 처리 & UI 마무리

**목표:** 에러 페이지 및 사용자 경험 개선

> 📖 TECHSPEC 섹션 1.1 (에러 처리) 참조

**Tests**

- [ ] 404 페이지 표시
- [ ] 500 페이지 표시
- [ ] 에러 로깅 동작
- [ ] 폼 에러 시 입력값 보존 (전체 점검)

**완료 조건:** 에러 상황에서 사용자 친화적 대응

- Commits:

---

### Milestone 15: 배포 준비 & 프로덕션

**목표:** Kamal 배포 설정 및 프로덕션 배포

> 📖 TECHSPEC 섹션 4.2 참조

**보안 점검**

- [ ] `bundle exec brakeman -q --no-pager` 통과
- [ ] `bundle audit check --update` 통과

**배포**

- [ ] Kamal 설정 완료
- [ ] 프로덕션 환경변수 설정
- [ ] SSL 설정
- [ ] 프로덕션 배포 성공
- [ ] 전체 플로우 동작 확인 (신청 → 조회 → 취소)

**완료 조건:** 보안 점검 통과, 프로덕션 환경에서 전체 플로우 동작

- Commits:

---

## 🧪 P0 테스트 체크리스트

> 모든 P0 테스트가 통과해야 배포 가능

| 마일스톤 | 테스트                               | 상태 |
| -------- | ------------------------------------ | ---- |
| M5       | 정원 1명, 동시 신청 2건 → 1건만 성공 | [ ]  |
| M6       | 동일 정보 동시 신청 → 1건만 성공     | [ ]  |
| M7       | 마감 후 신청 차단                    | [ ]  |
| M9       | 마감 후 취소 차단                    | [ ]  |

---

## Issues

> 구현 중 발견된 이슈나 TODO를 기록합니다.

| #   | 마일스톤 | 내용 | 상태 |
| --- | -------- | ---- | ---- |
|     |          |      |      |

---
