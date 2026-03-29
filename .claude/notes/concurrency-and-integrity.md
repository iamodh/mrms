# 동시성 환경에서의 데이터 무결성 보장

마라톤 대회 신청 시스템에서 정원 초과와 중복 신청을 방지하기 위해 설계한 다층 방어 전략.

---

## 1. 정원 초과 방지: lock! 사용

**예시:** 풀코스 정원 100명, 현재 99명 신청 완료. 홍길동과 김철수가 동시에 마지막 1자리에 신청한다.

- lock 없이: 둘 다 `COUNT = 99 < 100`으로 판단 → 둘 다 INSERT 성공 → 101번째 신청 발생
- lock 사용: 홍길동이 먼저 lock 획득 → INSERT 후 lock 해제 → 김철수가 lock 획득 → `COUNT = 100 >= 100` → 정원 초과로 실패

Course 행을 잠가 같은 코스에 대한 동시 트랜잭션을 직렬화한다.

```ruby
Course.transaction do
  lock!                              # SELECT ... FOR UPDATE
  raise RegistrationClosedError if race.registration_closed?
  raise CapacityExceededError if full?
  registrations.create!(params)
end
```

- 마감일 체크와 정원 체크를 동일한 트랜잭션 내에서 수행 — 모델이 자기 데이터를 스스로 보호
- 컨트롤러의 `available?` 사전 체크는 UX를 위한 빠른 거부용이고, 모델이 최종 안전장치

---

## 2. SQLite lock의 한계와 PostgreSQL 대안

**예시:** 홍길동(풀코스)과 김철수(하프코스)가 동시에 신청한다. PostgreSQL에서는 서로 다른 Course 행을 lock하므로 두 트랜잭션이 병렬로 처리된다. SQLite에서는 어떤 Course를 lock하든 DB 전체 Write Lock이 걸리므로 직렬화된다.

- PostgreSQL: `course.lock!`은 해당 Course 행만 잠금 → 다른 코스 신청은 동시에 처리 가능
- SQLite: Row Lock이 없어 DB 파일 전체에 Write Lock → 코스와 무관하게 모든 신청이 직렬화

이 프로젝트에서 SQLite Write Lock은 문제가 없다:
- 1,000명 규모에서 신청 트랜잭션은 수 밀리초면 완료
- 며칠에 걸쳐 분산되는 패턴이라 동시 경합이 거의 없음
- WAL 모드로 읽기는 잠금 없이 처리됨

SQLite Write Lock이 걸리면 트랜잭션이 완료될 때까지 다른 모든 쓰기 요청이 대기한다. 밀리초 단위 선착순 경쟁이 생기면 병목이 되므로 PostgreSQL + Row Lock으로 전환한다. 전환 기준은 `decisions/002-sqlite.md` 참조.

---

## 3. 중복 신청 해결: 3단계 방어

중복 신청은 lock과 무관하게 기존 유효성 검사 절차를 따른다.

```
[요청] → Model Validation → DB Unique Index → Controller Rescue
         (순차 요청 차단)    (동시 요청 차단)   (500 에러 방지)
```

**1단계 — Model Validation (순차 요청 차단)**

```ruby
validates :name, uniqueness: {
  scope: [:race_id, :phone_number],
  message: "이미 동일한 이름과 전화번호로 신청된 내역이 있습니다."
}
```

- `SELECT`로 중복 여부를 확인하여 순차 요청은 100% 차단
- 한계: SELECT와 INSERT 사이의 시간차로 동시 요청이 모두 통과할 수 있음

**2단계 — DB Unique Index (동시 요청 차단)**

```ruby
add_index :registrations, [:race_id, :name, :phone_number], unique: true
```

- 1단계를 동시에 통과한 요청이 INSERT될 때 DB 레벨에서 물리적으로 차단
- `RecordNotUnique` 발생 — `RecordInvalid`와 다른 예외

**3단계 — Controller Rescue (사용자 경험)**

```ruby
rescue ActiveRecord::RecordNotUnique
  redirect_to new_course_registration_path(@course),
    alert: "이미 동일한 이름과 전화번호로 신청된 내역이 있습니다."
```

- `RecordNotUnique`를 잡지 않으면 500 에러로 노출됨
- rescue로 사용자에게 동일한 안내 메시지를 표시

---

## 요약

| 계층 | 방어 대상 | 수단 | 실패 시 |
|------|-----------|------|---------|
| Controller | 빠른 거부 (UX) | `available?` 사전 체크 | redirect + flash alert |
| Model | 마감일 초과 | `lock!` + `registration_closed?` | `RegistrationClosedError` |
| Model | 정원 초과 | `lock!` + count 체크 | `CapacityExceededError` |
| Model | 순차 중복 요청 | `validates uniqueness` | 폼 re-render + 에러 메시지 |
| Database | 동시 중복 요청 | Unique Index | `RecordNotUnique` 발생 |
| Controller | 500 에러 방지 | `rescue RecordNotUnique` | redirect + flash alert |
