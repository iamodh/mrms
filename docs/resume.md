# 동시성 환경에서의 데이터 무결성 보장

마라톤 대회 신청 시스템에서 정원 초과와 중복 신청을 방지하기 위해 설계한 다층 방어 전략.

---

## 해결해야 할 문제

### 정원 초과

정원이 1명 남은 상태에서 2명이 동시에 신청하면, 둘 다 `SELECT COUNT`에서 여유 있음으로 판단하고 INSERT에 성공하여 정원을 초과한다.

### 중복 신청

같은 사람이 브라우저 탭 2개로 동시에 제출하면, 둘 다 uniqueness validation의 `SELECT`에서 레코드 없음으로 판단하고 INSERT에 성공하여 중복 저장된다.

---

## 방어 전략

### 정원 초과 방지: 트랜잭션 + Row Lock

```ruby
Course.transaction do
  lock!                    # SELECT ... FOR UPDATE
  raise CapacityExceededError if full?
  registrations.create!(params)
end
```

- `lock!`으로 같은 코스에 대한 동시 트랜잭션을 직렬화
- 두 번째 요청은 첫 번째 커밋 이후에 count를 다시 확인하므로 정원 초과를 정확히 감지

### 중복 신청 방지: 3단계 방어

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
- `RecordInvalid` 발생 → 폼을 re-render하여 필드별 에러 메시지를 표시
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

- 2단계에서 발생한 `RecordNotUnique`를 잡지 않으면 500 에러로 노출됨
- rescue를 추가하여 사용자에게 동일한 안내 메시지를 표시

### 다른 코스 동시 신청 문제

같은 사람이 5km, 10km에 동시 제출하는 경우:

- `course.lock!`은 각각 다른 행을 잠그므로 직렬화되지 않음
- 1단계 validation을 둘 다 통과할 수 있음
- 이때 2단계 DB unique index + 3단계 rescue가 최종 안전망으로 작동

---

## 테스트

### 설계 원칙

- 동시성 테스트는 모델 레벨(`ActiveSupport::TestCase`)에서 작성
- `Thread` + `ActiveRecord::Base.connection_pool.with_connection`으로 별도 DB 커넥션 확보
- 통합 테스트의 `post`는 `@response` 인스턴스 변수를 공유하여 thread-safe하지 않으므로 사용 금지

### 검증 항목

| 시나리오 | 입력 | 기대 결과 |
|----------|------|-----------|
| 정원 1명, 동시 신청 2건 | 서로 다른 사람 | 1건 성공, 1건 `CapacityExceededError` |
| 동일 정보 동시 신청 2건 | 같은 사람 | 1건 성공, 1건 `RecordNotUnique` 또는 `RecordInvalid` |

---

## 요약

| 계층 | 방어 대상 | 수단 | 실패 시 |
|------|-----------|------|---------|
| Application | 순차 중복 요청 | `validates uniqueness` | 폼 re-render + 에러 메시지 |
| Application | 정원 초과 | `lock!` + count 체크 | redirect + flash alert |
| Database | 동시 중복 요청 | Unique Index | `RecordNotUnique` 발생 |
| Controller | 500 에러 방지 | `rescue RecordNotUnique` | redirect + flash alert |
