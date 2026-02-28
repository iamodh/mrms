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
  lock!                              # SELECT ... FOR UPDATE
  raise RegistrationClosedError if race.registration_closed?
  raise CapacityExceededError if full?
  registrations.create!(params)
end
```

- `lock!`으로 같은 코스에 대한 동시 트랜잭션을 직렬화
- 마감일 체크와 정원 체크를 동일한 트랜잭션 내에서 수행 — 모델이 자기 데이터를 스스로 보호
- 컨트롤러의 `available?` 사전 체크는 UX를 위한 빠른 거부용이고, 모델이 최종 안전장치

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
| Controller | 빠른 거부 (UX) | `available?` 사전 체크 | redirect + flash alert |
| Model | 마감일 초과 | `lock!` + `registration_closed?` | `RegistrationClosedError` |
| Model | 정원 초과 | `lock!` + count 체크 | `CapacityExceededError` |
| Model | 순차 중복 요청 | `validates uniqueness` | 폼 re-render + 에러 메시지 |
| Database | 동시 중복 요청 | Unique Index | `RecordNotUnique` 발생 |
| Controller | 500 에러 방지 | `rescue RecordNotUnique` | redirect + flash alert |

---

# 스키마 설계: Registration에 race_id가 있는 이유

## 배경

MVP는 단일 Race로 동작한다. Registration은 Course에 속하고, Course는 Race에 속하므로 `registration.course.race`로 대회를 알 수 있다. 그런데도 Registration 테이블에 `race_id` 컬럼을 직접 두었다.

## 이유: 교차 코스 중복 방지를 위한 Unique Index

같은 대회에서 한 사람이 5km와 10km에 동시에 신청하는 것을 방지해야 한다. 이를 DB 레벨에서 보장하려면 `(race_id, name, phone_number)` unique index가 필요하다.

```ruby
add_index :registrations, [:race_id, :name, :phone_number], unique: true
```

`course_id`만으로는 **같은 코스** 내 중복만 막을 수 있고, **다른 코스** 간 중복은 막을 수 없다. `race_id`를 Registration에 직접 두어야 대회 단위의 1인 1신청을 인덱스 하나로 보장할 수 있다.

## race_id 자동 세팅

MVP에서 Race는 하나뿐이므로, 사용자가 폼에서 Course만 선택하면 race_id는 자동으로 채운다.

```ruby
before_validation :set_race_from_course

def set_race_from_course
  self.race = course.race if course.present? && race.blank?
end
```

컨트롤러와 폼에서 race를 명시적으로 다룰 필요가 없어지고, 코스 선택만으로 신청이 완성된다.

---

# 취소의 멱등성 설계

## 문제

사용자가 취소 버튼을 두 번 누르거나, 완료 후 새로고침하면 같은 취소 요청이 중복으로 들어온다. 이때 에러를 보여주면 사용자는 "취소가 안 된 건가?"라고 혼란스러워한다.

## 해결: 이미 처리된 상태면 성공 반환

```ruby
def cancel!
  return true if canceled?
  raise NotCancelableError, "취소 가능 기간이 지났습니다." unless cancelable?
  update!(status: :canceled, canceled_at: Time.current)
end
```

- `canceled?` → 이미 원하는 결과(취소)가 달성된 상태이므로 에러 없이 `true` 반환
- `applied?` + 마감 전 → 정상 취소 처리
- `applied?` + 마감 후 → `NotCancelableError` (이 경우만 에러)

에러를 던지는 기준은 "사용자의 의도를 달성할 수 없는 경우"뿐이다.

> `refunded` 상태의 멱등성 처리는 결제 기능 도입 후 작성 예정.

---

# render vs redirect: 에러 전달 방식의 차이

## render — 같은 요청에서 뷰를 다시 그린다

- 인스턴스 변수(`@registration.errors`)가 유지되므로 뷰에서 필드별 에러를 직접 표시
- 폼 입력값이 보존됨
- 용도: validation 실패 (필수 필드 누락, 형식 오류 등)

```ruby
rescue ActiveRecord::RecordInvalid => e
  @registration = e.record
  render :new, status: :unprocessable_entity
```

## redirect — 새 요청을 보낸다

- 인스턴스 변수가 소멸하므로 `flash`로 메시지를 전달
- 폼 입력값이 사라짐
- 용도: 권한 거부, 중복 신청, 마감 등 폼 보존이 불필요한 경우

```ruby
redirect_to new_course_registration_path(@course), alert: "정원이 마감되었습니다."
```

## 테스트에서의 차이

| 방식 | 응답 검증 | 메시지 검증 |
|------|-----------|-------------|
| render | `assert_response :unprocessable_entity` | `assert_select ".field-errors"` |
| redirect | `assert_redirected_to path` | `assert_equal "메시지", flash[:alert]` |

redirect 후에는 페이지 본문이 없으므로 `assert_select`를 쓸 수 없고, flash로 검증한다.

---

# Turbo Drive와 POST → render 충돌

일반적인 Rails POST 흐름은 "데이터 생성 → redirect → 새 페이지"이다. Turbo Drive는 이를 전제로 설계되어, POST 응답이 200(render)이면 에러를 발생시킨다. redirect(303) 또는 4xx/5xx만 허용한다.

**문제:** lookup은 POST가 "생성"이 아니라 "검색"이다. 결과를 그 자리에서 render하고 싶지만, Turbo가 이를 거부한다. redirect하려면 URL에 confirmation_code와 이름을 실어야 하는데, 이는 개인정보 노출이므로 안 된다.

**해결:** 해당 폼에서만 Turbo를 비활성화한다.

```erb
<%= form_with url: lookup_path, method: :post, data: { turbo: false } do |f| %>
```

---

# if/else vs rescue: 에러 처리 방식 선택 기준

- **if/else** — 예상된 분기. 정상 흐름의 일부. (예: 조회 실패, 사전 체크)
- **rescue** — 예외 상황. 정상 흐름에서 벗어난 경우. (예: 동시성 충돌, DB 제약 위반)

---

# Rails normalizes vs before_validation

## normalizes — 선언적 정규화 (Rails 7.1+)

```ruby
normalizes :name, with: ->(name) { name.gsub(/\s+/, "") }
normalizes :phone_number, with: ->(phone) { phone.gsub(/\D/, "") }
```

- 속성이 **대입되는 즉시** 변환됨 (`registration.name = "홍 길 동"` → 바로 `"홍길동"`)
- `find_by`에도 정규화가 적용됨 (`Registration.find_by(name: "홍 길 동")` → `"홍길동"`으로 검색)
- 선언적이라 의도가 명확하고, 콜백 순서에 의존하지 않음

## before_validation — 콜백 기반 정규화

```ruby
before_validation :normalize_name
def normalize_name
  self.name = name.gsub(/\s+/, "")
end
```

- `valid?`나 `save` 호출 시에만 변환됨 — 대입 직후에는 원본값이 남아 있음
- `find_by`에 적용되지 않음 — 검색 시 수동으로 정규화해야 함
- 콜백 순서에 따라 다른 validation과 충돌할 수 있음

## 이 프로젝트에서의 선택

이름과 전화번호에 `normalizes`를 사용하여, 저장뿐 아니라 조회 시에도 일관된 정규화를 보장한다. 특히 조회 기능(`find_by(name:)`)에서 사용자가 공백을 포함해 입력해도 정확히 매칭된다.

---

# 인프라 선택: Hetzner Cloud

SQLite 단일 서버 + Kamal 배포 환경에서 AWS 대신 Hetzner를 선택한 이유.

## 스펙 비교

| | AWS 프리티어 (t2.micro) | Hetzner CX22 (~€4.5/월) |
|---|---|---|
| vCPU | 1 | 2 |
| RAM | 1GB | 4GB |
| 디스크 | 30GB EBS (IOPS 제한) | 40GB NVMe SSD |
| 트래픽 | 15GB/월 (초과 시 과금) | 20TB/월 |
| 비용 | 1년 무료 → 이후 ~$8/월 | 처음부터 ~€4.5/월 |
| 설정 | VPC, 보안그룹, IAM 필요 | SSH 키만 등록하면 끝 |
| 한국 리전 | 있음 (서울) | 없음 (독일/핀란드/미국) |

## 선택 이유

1. **스펙 대비 가격** — 같은 비용으로 4배 메모리. SQLite + Rails는 메모리 여유가 유리
2. **SQLite 궁합** — 로컬 NVMe SSD라 디스크 I/O가 빠름. EBS의 IOPS 제한이 없음
3. **단순함** — 서버 생성 → SSH 접속 → Kamal 배포. AWS의 VPC/IAM 설정 불필요
4. **예측 가능한 비용** — 프리티어 1년 후 갑작스러운 과금 전환 없음

## 실질적 이득과 손해

**이득**

- RAM 4배(1GB → 4GB) — Rails 프로세스 여유. 메모리 부족으로 서버 죽을 걱정 없음
- NVMe SSD — SQLite 읽기/쓰기 빠름. 동시 신청 시 lock 대기 시간 감소
- 트래픽 20TB — 사실상 무제한. AWS 프리티어는 15GB 초과 시 과금
- 설정 단순 — VPC/보안그룹/IAM 없이 SSH만으로 바로 배포
- 고정 비용 — 월 €4.5 예측 가능. 프리티어 만료 후 요금 폭탄 없음

**손해**

- 레이턴시 증가 — 한국 ↔ 독일 약 200~250ms 추가. 페이지 로딩이 체감상 느려짐
- 프리티어 없음 — 첫 달부터 과금 (신규 가입 €20 크레딧으로 약 4개월 커버)

레이턴시는 마라톤 신청 서비스 특성상 문제되지 않는다. 밀리초 단위 선착순 경쟁이 아니라 며칠에 걸쳐 신청이 분산되는 패턴이기 때문.
