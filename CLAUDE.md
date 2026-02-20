# CLAUDE.md

## SESSION START

새 세션 시작 시 반드시 다음 순서로 진행한다:

1. `PLAN.md`에서 첫 번째 미완료 마일스톤 확인
2. 해당 마일스톤의 `📖 TECHSPEC` 참조 섹션 읽기
3. 첫 번째 미완료 체크박스부터 `go` 실행

---

## GOAL

- `PLAN.md`에 정의된 현재 마일스톤을 구현한다
- 마일스톤 내 체크되지 않은 항목을 순서대로 완료한다
- P0 테스트(동시성, 중복 방지, 마감 처리)는 반드시 통과해야 한다

---

## ROLE

다음 두 개발자의 관점을 결합하여 작업한다:

### Kent Beck (TDD 창시자)

- Red → Green → Refactor 사이클 엄수
- 테스트가 설계를 이끈다
- 작은 단계로 진행, 큰 도약 금지

### DHH (Rails 창시자)

- Convention over Configuration
- Rails Way 우선
- 실용적 단순함 추구

---

## TESTING GUIDELINES

> 코드 예제는 **TECHSPEC.md § 8.4** 참조

### 원칙

1. **Rails를 믿어라**: 프레임워크가 보장하는 건 테스트하지 마 (컬럼 타입, 존재 여부)
2. **비즈니스 규칙만 테스트해라**: 그게 바뀌면 앱이 망가지는 것들
3. **Red → Green → Refactor**: 테스트 실패 → 최소 구현 → 리팩토링 순서 엄수
4. **Fixtures 활용**: `test/fixtures/*.yml`에 실제 데이터 흐름을 담아라
5. **동일 성격 검증은 하나의 테스트로 합쳐라**: 필수 필드 3개 → 테스트 1개에서 모두 검증 (필드별 분리 금지)
6. **테스트 내 인라인 로직을 대체하는 모델 메서드가 추가되면, 기존 테스트도 해당 메서드를 사용하도록 수정한다**

### 단계별 테스트 범위

| 마일스톤 | 테스트 범위 | 설명 |
|----------|-------------|------|
| M2 | 스모크 테스트 | 모델 생성 확인, TECHSPEC § 6 참조 |
| M3 | Validations + Associations | 검증 로직, 관계 동작 확인 |
| M4+ | Business Logic | 모델 메서드 추가 시 작성 |

### M3 전환 작업 순서

1. **Fixture 생성** — `test/fixtures/*.yml` (races, courses, registrations)
2. **Association 선언** — 모델에 `has_many`, `belongs_to` 선언
3. **스모크 테스트 삭제 → Association 테스트 작성** — Fixture 로드가 모델 생성을 암묵적으로 검증하므로 M2 스모크 테스트는 삭제하고, Association 테스트로 대체
4. **Validation** — Red → Green TDD 사이클로 필수 필드 검증 추가

### Fixture 작성 규칙

- 날짜/시간 필드는 ERB로 상대 시점을 사용한다 (예: `<%= 3.months.from_now %>`) — 시간이 지나도 테스트가 깨지지 않도록
- 스키마에 default가 있는 컬럼은 fixture에서 생략한다 (예: `status: "applied"`)
- TECHSPEC에 정의된 데이터 형식을 반드시 확인 후 작성한다

### Seed / Fixture에서의 Association

- Association 선언(has_many, belongs_to)은 M3 범위이므로, M2 Seed에서는 association 메서드(`race.courses`) 대신 FK 직접 참조(`race_id: race.id`)를 사용한다
- M3 완료 후 Seed를 association 방식으로 리팩토링할 수 있다

### 테스트 작성 원칙

- 동시성(Thread) 테스트는 반드시 모델 레벨(`ActiveSupport::TestCase`)에서 작성
- `ActionDispatch::IntegrationTest`에서 Thread + post 조합 금지 (`@response` 공유 충돌)
- 통합 테스트는 단일 요청의 HTTP 플로우 검증에만 사용

### 작성하지 않는 테스트

- 스키마 레벨 테스트 (컬럼 타입, 존재 여부) — 마이그레이션이 명세서 역할

---

## CONSTRAINTS

### Gem 사용 규칙

- 새로운 gem을 사용하기 전에 반드시 Gemfile에 존재하는지 확인
- 없으면 코드 작성 전에 gem 추가 필요 여부를 먼저 알려줄 것
- 기존 의존성만으로 해결 가능한지 우선 검토

- [ ] 테스트 없이 프로덕션 코드 작성 금지 (단, Association 선언은 선언적 코드이므로 예외)
- [ ] 한 번에 여러 기능 구현 금지
- [ ] TECHSPEC.md에 명시되지 않은 기술 스택 도입 금지
- [ ] 테스트 통과 전 리팩토링 금지
- [ ] 이전 마일스톤 완료 전 다음으로 진행 금지
- [ ] 기존 마이그레이션 파일 수정 금지 - 스키마 변경은 항상 새 마이그레이션 파일로 처리

### BRANCH RULES

- main 브랜치에 직접 커밋 금지
- 마일스톤 시작 시 `feat/m{번호}-{설명}` 브랜치를 생성하고 전환한다
- 브랜치 생성/전환/머지는 사용자가 직접 수행
- 에이전트는 브랜치 생성/전환/커밋을 수행하되, 머지와 push는 하지 않는다

---

## GUARDRAIL

- 같은 테스트가 3회 연속 실패하면 멈추고 상황을 보고한다
- 무한 수정 루프에 빠지지 않기 위해 실패 패턴을 분석한다

---

## P0 마일스톤 주의

**M5, M6, M7, M9**는 데이터 무결성에 직접 영향을 미친다.

- M5 (정원 관리): 트랜잭션 + lock! 패턴 필수
- M6 (중복 방지): RecordNotUnique 예외 처리 필수
- M7 (마감 판정): 마감 조건 (OR) 로직 필수
- M9 (취소): 멱등성 보장 로직 필수

TECHSPEC 코드 패턴을 **정확히** 따를 것.

---

## PROJECT SPECIFIC

### Tech Stack

- **Framework:** Ruby on Rails 8.1.1
- **Ruby:** 3.4.7
- **Database:** SQLite (개발 및 프로덕션)
- **Testing:** Minitest (Rails 기본)
- **Frontend:** Hotwire (Turbo + Stimulus)
- **Deployment:** Kamal + Docker
- **Linter:** RuboCop

### Coding Conventions

- **들여쓰기:** 2 spaces
- **네이밍:** snake_case (Ruby)
- **커밋 메시지:** Conventional Commits 형식
- **문자열:** 더블쿼트 우선 (rubocop-rails-omakase 기본)
- **Skinny Controller, Fat Model:** 비즈니스 로직과 쿼리는 모델(scope, 메서드)에 두고, 컨트롤러는 요청/응답 흐름만 담당
