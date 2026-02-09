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

### ❌ 작성하지 않는 테스트

**스키마 레벨 테스트** (컬럼 타입, 존재 여부 확인)
```ruby
# 🚫 BAD - Rails가 이미 보장하는 것을 재확인
test 'name column is string type' do
  assert_equal :string, Race.columns_hash['name'].type
end

test 'races table has expected columns' do
  columns = Race.column_names
  assert_includes columns, 'name'
  assert_includes columns, 'event_date'
end
```

**이유:**
- 마이그레이션 파일이 이미 명세서 역할
- `rails db:migrate` 실패하면 테스트 실행 전에 이미 터짐
- 테스트 셋업이 성공했다면 스키마는 이미 정상

---

### 🟡 M2: 스모크 테스트

**마일스톤 2 (스키마 & 시드)** 단계에서는 모델이 기본적으로 생성되는지만 확인.
각 모델의 컬럼과 타입은 **TECHSPEC.md § 6 데이터베이스 스키마**를 참고하여 작성:
```ruby
# test/models/race_test.rb
class RaceTest < ActiveSupport::TestCase
  test "race can be created" do
    race = Race.create!(
      name: "Test Race",
      event_date: 1.month.from_now,
      location: "Seoul",
      registration_deadline: 2.weeks.from_now
    )
    assert race.persisted?
  end
end
```

**목적:**
- 마이그레이션 + 모델 기본 동작 확인
- CI 파이프라인 초기 검증
- M3에서 validations 추가하면 자연스럽게 대체됨

---

### ✅ M3+: 작성하는 테스트 (우선순위 순)

**마일스톤 3 (모델 기본 설정)** 부터는 본격적인 테스트 작성:

#### 1. Validations (검증 로직)

비즈니스 규칙이 **제대로** 작동하는지 확인:
```ruby
# ✅ GOOD - 비즈니스 규칙 테스트
test "requires name" do
  race = Race.new(event_date: 1.month.from_now)
  assert_not race.valid?
  assert_includes race.errors[:name], "can't be blank"
end

test "requires event_date" do
  race = Race.new(name: "Test Race")
  assert_not race.valid?
  assert_includes race.errors[:event_date], "can't be blank"
end

test "enforces uniqueness of confirmation_code" do
  existing = registrations(:john_5k)
  duplicate = Registration.new(
    confirmation_code: existing.confirmation_code,
    race: races(:marathon_2024),
    name: "Another Person",
    phone_number: "010-9999-9999"
  )
  
  assert_not duplicate.valid?
  assert_includes duplicate.errors[:confirmation_code], "has already been taken"
end
```

#### 2. Associations (관계 동작)

모델 간 관계가 **실제로** 동작하는지 확인:
```ruby
# ✅ GOOD - 실제 관계 동작 확인
test "race has many courses" do
  race = races(:marathon_2024)
  assert_equal 4, race.courses.count
end

test "race has many registrations" do
  race = races(:marathon_2024)
  assert_respond_to race, :registrations
end

test "destroys associated courses when destroyed" do
  race = races(:marathon_2024)
  course_ids = race.courses.pluck(:id)
  
  race.destroy
  
  assert_empty Course.where(id: course_ids)
end
```

#### 3. Business Logic (비즈니스 로직 - M4+ 모델 메서드 추가 시)

모델에 메서드를 추가할 때만 작성:
```ruby
# ✅ GOOD - 비즈니스 로직 테스트
test "registration_open? returns false after deadline" do
  race = Race.new(registration_deadline: 1.day.ago)
  assert_not race.registration_open?
end

test "registration_open? returns true before deadline" do
  race = Race.new(registration_deadline: 1.day.from_now)
  assert race.registration_open?
end

test "full? returns true when capacity reached" do
  course = courses(:full_10k)
  assert course.full?
end
```

---

### 원칙

1. **Rails를 믿어라**: 프레임워크가 보장하는 건 테스트하지 마 (컬럼 타입, 존재 여부)
2. **비즈니스 규칙만 테스트해라**: 그게 바뀌면 앱이 망가지는 것들
3. **Red → Green → Refactor**: 테스트 실패 → 최소 구현 → 리팩토링 순서 엄수
4. **Fixtures 활용**: `test/fixtures/*.yml`에 실제 데이터 흐름을 담아라
5. **단계별 진화**: M2 스모크 → M3 검증 로직 → M4+ 비즈니스 로직

---

## CONSTRAINTS

- [ ] 테스트 없이 프로덕션 코드 작성 금지
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
- **문자열:** 작은따옴표 우선 (RuboCop 기본)
