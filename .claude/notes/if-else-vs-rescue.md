# if/else vs rescue: 에러 처리 방식 선택 기준

에러 상황을 if/else로 처리할지 rescue로 처리할지에 대한 Rails 컨벤션.

---

## 1. 문제: 에러 처리 방식 혼용

**예시:** 조회 결과가 없을 때와 동시성 충돌이 발생했을 때, 둘 다 "에러 상황"처럼 보이지만 처리 방식이 다르다.

---

## 2. 선택 기준

**if/else** — 예상된 분기. 정상 흐름의 일부.

```ruby
registration = Registration.find_by(confirmation_code: code, name: name)
if registration
  # 조회 성공
else
  # 조회 실패 — 예상된 상황, 정상 흐름
end
```

**rescue** — 예외 상황. 정상 흐름에서 벗어난 경우.

```ruby
course.create_registration!(params)
rescue ActiveRecord::RecordNotUnique
  # 동시성 충돌 — 예외 상황, 정상 흐름 밖
```

| 방식 | 사용 시점 | 예시 |
|------|-----------|------|
| if/else | 예상된 분기, 정상 흐름의 일부 | 조회 실패, 사전 체크 |
| rescue | 예외 상황, 정상 흐름 밖 | 동시성 충돌, DB 제약 위반 |
