# MRMS (Marathon Registration Management System) PLAN.md

## 🎯 핵심 구현 지침

### `go` - 구현 사이클

1. **Test First**: 가장 첫 번째 미완료 테스트 케이스를 작성한다
2. **Minimal Code**: 테스트를 통과시키는 최소한의 코드만 작성한다
3. **Lint**: `bundle exec rubocop` 전체 실행 (파일 지정 금지, 필요시 `-a`로 safe autocorrect)
4. **Run Tests**: `bundle exec rails test` 실행
5. **Report & Wait**: 결과를 보고하고 사용자 확인을 기다린다

> ⚠️ 이후 자동 진행 금지. 사용자 피드백에 따라 수정하거나 `commit`을 기다린다.

### `commit` - 완료 처리

1. **코드 커밋**: 변경사항을 성격별로 나누어 커밋한다 (리팩토링, fixture, 기능 등)
2. **PLAN 체크**: 완료된 항목에 체크박스 표시 + `- Commits:` 줄에 커밋 해시 추가 (매 항목마다 커밋하지 않고, 마일스톤 완료 시 또는 사용자 요청 시 한 번에 커밋)

### `verify` - 마일스톤 완료 후 수동 검증

마일스톤 완료 시 사용자가 직접 확인할 수 있는 검증 명령어를 제안한다.

**제안 범위:**
- `rails console`에서 실행할 수 있는 코드 스니펫 (모델 관계, 검증, 비즈니스 로직)
- `rails dbconsole`에서 확인할 수 있는 스키마/데이터 쿼리
- 브라우저에서 확인할 수 있는 URL과 기대 동작 (UI 마일스톤인 경우)
- `bundle exec rubocop`, `bundle exec rails test` 등 CLI 명령어

**규칙:**
- `commit` 직전 또는 직후에 제안
- 해당 마일스톤에서 구현한 기능에 한정 (이전 마일스톤 내용 반복 금지)
- 복사-붙여넣기로 바로 실행 가능한 형태로 제공

### 명령어

| 명령어     | 동작                                 |
| ---------- | ------------------------------------ |
| `go`       | 구현 사이클 실행 후 사용자 확인 대기 |
| `commit`   | 커밋 및 PLAN.md 체크박스 표시        |
| `status`   | 현재 마일스톤 진행 테이블 + 요약 + 다음 항목 출력 |
| `verify`   | 마일스톤 완료 후 수동 검증 제안      |
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
- [x] RuboCop 설정 (.rubocop.yml, ERB 파일 Exclude 포함)
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

- [x] Race 테이블 생성
- [x] Course 테이블 생성
- [x] Registration 테이블 생성
- [x] Unique Index: `(race_id, name, phone_number)`
- [x] Unique Index: `confirmation_code`
- [x] Seed: Race 1개, Course 4개

**완료 조건:** `rails db:migrate db:seed` 성공, 스키마 확인

- Commits: f9f8837, e3198e6, bc21012, 4739793, 399882d, 1645f88

---

### Milestone 3: 모델 기본 설정

**목표:** 모델 관계 및 기본 검증

> 📖 TECHSPEC 섹션 6.1 참조

**Fixture 도입**

- [x] Fixture 생성 (races, courses, registrations)
- [x] M2 스모크 테스트 삭제 및 Fixture 기반으로 전환

**Tests**

- [x] Race has_many :courses, :registrations
- [x] Course belongs_to :race, has_many :registrations
- [x] Registration belongs_to :race, :course
- [x] Registration 필수 필드 검증 (name, phone_number, birth_date, gender, address)

**완료 조건:** 모든 유닛 테스트 통과

- Commits: 1efce8a, 8ff35e0, 0d0e543, ea6caee, a30813c

---

### Milestone 4: 신청 - 기본 폼

**목표:** 신청 폼 및 입력 검증

> 📖 TECHSPEC 섹션 7.1 참조

**Unit Tests**

- [x] 이름 정규화: "홍 길 동" → "홍길동"
- [x] 전화번호 정규화: "010-1234-5678" → "01012345678"

**Integration Tests**

- [x] 신청 폼 표시 (available 코스만, 잔여 인원 표시)
- [x] 필수 필드 누락 제출 시 폼 상태 유지 + 입력값 보존

**완료 조건:** 신청 폼 동작, 정규화 적용, 에러 시 입력값 보존

- Commits: 74d04d1, b27ac56, b133a69, 1598721, 30734ad, 95653ba, a705d01

---

### Milestone 5: 신청 - 정원 관리 (P0)

**목표:** 정원 초과 방지

> 📖 TECHSPEC 섹션 7.2 참조 (트랜잭션 + lock! 패턴)

**Unit Tests**

- [x] Course#full? - applied 수 >= capacity 시 true
- [x] Course#available? - 마감 + 정원 조합 검증

**Concurrency Tests (P0)** ← Issues #1 참조

- [x] 정원 1명, 동시 신청 2건 → 1건만 성공

**Integration Tests**

- [x] 정원 초과 시 에러: "선택하신 코스의 정원이 마감되었습니다."

**완료 조건:** 동시성 테스트 통과, 정원 초과 차단

- Commits: 1601373, 22a4463, 486c4a4, 7355866

---

### Milestone 6: 신청 - 중복 방지 (P0)

**목표:** 중복 신청 차단

> 📖 TECHSPEC 섹션 7.2 참조 (Unique Index + RecordNotUnique)

**Unit Tests**

- [x] 동일 (race_id, name, phone_number) 중복 저장 시 에러

**Concurrency Tests (P0)** ← Issues #1 참조

- [x] 동일 정보로 동시 신청 2건 → 1건만 성공

**Integration Tests**

- [x] 중복 시 에러: "이미 동일한 이름과 전화번호로 신청된 내역이 있습니다."

**완료 조건:** 중복 신청 차단, 동시성 테스트 통과

- Commits: ca85d33, a5862cc, f897a6a

---

### Milestone 7: 신청 - 마감 판정 (P0)

**목표:** 시간/정원 마감 후 신청 차단

> 📖 TECHSPEC 섹션 7.3 참조

**Unit Tests**

- [x] Race#registration_closed? - 마감일 경과 시 true
- [x] Course#available? - 마감 OR 정원 초과 시 false

**Integration Tests (P0)**

- [x] 마감일 경과 후 신청 → 차단, 메시지: "신청 기간이 종료되었습니다."
- [x] 정원 마감 후 신청 → 차단, 메시지: "선택하신 코스의 정원이 마감되었습니다."

**완료 조건:** 마감 후 신청 완전 차단

- Commits: 7aac534, 4eb119b, e2c95f2, 2cf2c45, 71abcf8

---

### Milestone 8: 신청 완료 & 고유 코드

**목표:** 신청 성공 시 고유 코드 발급

> 📖 TECHSPEC 섹션 7.4 참조

**Unit Tests**

- [x] confirmation_code 형식: 영문 대문자 + 숫자 8자리

**Integration Tests**

- [x] 신청 완료 → 완료 페이지에 코드 표시

**완료 조건:** 신청 시 고유 코드 발급, 완료 페이지 표시

- Commits: e26d442, bef2bb3

---

### Milestone 9: 조회 & 취소

**목표:** 신청 내역 조회 및 취소 (멱등성 보장)

> 📖 TECHSPEC 섹션 7.5 참조
> 🎯 이 마일스톤 완료 시점 = 첫 사용자 테스트 가능

**Unit Tests**

- [x] Registration#cancelable? - applied 상태 + 마감 전만 true
- [x] Registration#cancel! - 멱등성: 이미 취소면 성공 반환
- [x] 마감 후 cancel! → NotCancelableError

**Integration Tests**

- [x] confirmation_code + 이름으로 조회 성공
- [x] 잘못된 정보로 조회 → 에러 메시지
- [x] 취소 성공 → status 변경, canceled_at 기록
- [x] 이미 취소된 신청 다시 취소 → 에러 없이 성공 (P1)
- [x] 마감 후 취소 시도 → 차단 (P0)

**완료 조건:** 조회/취소 플로우 동작, 멱등성 보장

- Commits: 830d05d, 1b27243, 4f0101d, ee8c85f

---

### Milestone 9.5: 첫 배포 (Hetzner + Kamal)

**목표:** M9 완료 시점(첫 사용자 테스트 가능)에서 Hetzner Cloud에 프로덕션 배포

> 📖 TECHSPEC 섹션 4.2, 4.3 참조

**보안 점검**

- [x] `bundle exec brakeman -q --no-pager` 통과
- [x] `bundle audit check --update` 통과

**배포**

- [x] Hetzner CX23 VPS 생성 및 SSH 접속 확인
- [x] Kamal 배포 설정 (deploy.yml, Dockerfile, .kamal/secrets)
- [x] 프로덕션 배포 성공 (IP 직접 접속, HTTP)
- [x] 프로덕션에서 신청 → 조회 → 취소 플로우 동작 확인

**완료 조건:** 프로덕션 환경에서 핵심 플로우 동작 확인

- Commits:

---

### Milestone 10: 관리자 인증

**목표:** 환경변수 기반 관리자 로그인/로그아웃

> 📖 TECHSPEC 섹션 7.6 참조

**Unit Tests**

- [x] 올바른 ID/PW → 세션 생성
- [x] 잘못된 ID/PW → 로그인 실패
- [x] 로그아웃 → 세션 삭제

**완료 조건:** 관리자 인증 플로우 동작

- Commits: 0e062b8

---

### Milestone 11: 관리자 - 대회/코스 조회

**목표:** 관리자가 대회 정보와 코스 목록 확인

> 📖 TECHSPEC 섹션 5.2 참조

**Tests**

- [x] 비인증 상태로 /admin 접근 → 로그인 페이지 리다이렉트
- [x] 로그인 후 /admin 접근 → 성공
- [x] Race 정보 조회
- [x] Course 목록 조회 (capacity, 현재 신청 수 포함)
- [x] 대회/코스 정보 페이지 표시

**완료 조건:** 관리자 페이지에서 대회/코스 정보 확인 가능

- Commits: a797be8, 07b7586

---

### Milestone 12: 관리자 - 코스 설정

**목표:** 관리자가 코스 정원 및 마감일 수정

> 📖 TECHSPEC 섹션 5.2 참조

**Tests**

- [x] Course capacity 업데이트 → DB 반영
- [x] Race registration_deadline 업데이트 → DB 반영
- [x] 수정 폼 표시 및 저장 동작

**완료 조건:** 관리자가 정원/마감일 수정 가능

- Commits: 8867091, 9deb967, 8cbc570, fc16448, 2bad1da

---

### Milestone 13: 관리자 - 신청자 목록

**목표:** 신청자 목록 조회, 정렬, 필터링

> 📖 TECHSPEC 섹션 1.1 (관리자 기능) 참조

**Tests**

- [x] 신청일 기준 정렬
- [x] 이름 기준 정렬
- [x] 코스별 필터
- [x] 상태별 필터 (applied, canceled, refunded)
- [x] 목록 페이지 표시, 정렬/필터 동작

**완료 조건:** 관리자가 신청자 목록 조회/정렬/필터 가능

- Commits: 96fd5c5, 6ff3a08, 1dc5535, eb546d9, dd56d45, abed13f, f024502

---

### Milestone 14: 에러 처리 & 네비게이션

**목표:** 에러 페이지, 네비게이션 흐름 완성

> 📖 TECHSPEC 섹션 1.1 (에러 처리) 참조
> 한국어 UX (enum 한글화, 날짜 포맷, 플래시 메시지 등)는 뷰 작업 중 발견 시 즉시 수정

**에러 처리**

- [x] 404 커스텀 페이지 (한국어, 존재하지 않는 코스/신청 접근 시)
- [x] 500 커스텀 페이지 (한국어)
**네비게이션 & 흐름**

- [x] 관리자: 신청자 목록 → 대시보드 돌아가기 링크
- [x] 관리자: 코스/마감일 수정 페이지 → 대시보드 돌아가기 링크
- [x] 사용자: 신청 완료 페이지 → 조회 페이지 안내 링크
- [x] 사용자: 조회 결과/조회 폼 → 홈 돌아가기 링크

**완료 조건:** 에러 한국어화, 페이지 간 자연스러운 이동

- Commits:

---

### Milestone 15: UI 스타일링 & QA

**목표:** UI 스타일링, QA 폴리시

> 배포 파이프라인은 M9.5에서 구축 완료. 시드 데이터로 전체 플로우를 돌려보며 스타일링 진행.

**테스트 셀렉터 정리**

- [x] CSS 클래스 기반 assert_select를 태그+속성/텍스트 기반으로 전환

**UI 다듬기**

- [x] DESIGN.md 작성 (톤, 색상 토큰, 컴포넌트 패턴, 페이지별 가이드)
- [x] tailwindcss-rails gem 설치 + @theme 커스텀 색상/폰트 설정
- [x] 관리자 전용 레이아웃 분리 (admin.html.erb + 네비게이션 바)
- [x] 사용자 페이지 스타일링 (홈, 신청폼, 완료, 조회)
- [x] 관리자 페이지 스타일링 (대시보드, 목록, 수정폼)
- [x] 에러 페이지 스타일링 (404, 500)

**완료 조건:** UI 완성, QA 반영

- Commits:

---

### Milestone 16: 최종 배포

**목표:** 보안 점검, 도메인 연결, SSL 적용, 프로덕션 최종 배포

**보안 점검**

- [x] brakeman 재실행
- [x] bundler audit 재실행

**QA용 시드 데이터**

- [x] Faker gem 추가 (development group)
- [x] seeds.rb에 Faker 기반 가짜 신청자 생성 추가

**도메인 & SSL**

- [ ] 도메인 등록 및 DNS 설정
- [ ] kamal-proxy Let's Encrypt SSL 적용

**최종 배포 & 검증**

- [ ] 프로덕션 시드 데이터 확인 (실제 대회 정보)
- [ ] 전체 플로우 최종 동작 확인 (HTTPS)

**완료 조건:** 보안 점검 통과, 도메인 + SSL 적용, 프로덕션 환경 최종 확인

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
| 1   | M5, M6   | 동시성 테스트: `ActionDispatch::IntegrationTest`의 `post`는 `@response` 등 인스턴스 변수를 공유하여 thread-safe하지 않음. 모델 레벨에서 `Thread` + `ActiveRecord::Base.connection_pool.with_connection`으로 별도 커넥션을 확보하여 테스트한다 (TECHSPEC § 8.3 참조) | 적용 |
| 2   | M5       | `save` vs `create!`: 컨트롤러에서 `create_registration!`(`create!` 사용)로 전환 시, 예외 발생하면 `@registration`에 할당이 안 되어 뷰 렌더링 실패. `rescue ActiveRecord::RecordInvalid => e`에서 `e.record`로 실패한 객체를 꺼내 `@registration`에 할당하여 해결 | 적용 |

---
