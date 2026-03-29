# 취소의 멱등성 설계

같은 요청이 여러 번 들어와도 동일한 결과를 보장하는 설계.

---

## 1. 문제: 중복 취소 요청

**예시:** 홍길동이 취소 버튼을 두 번 눌렀다. 또는 취소 완료 후 페이지를 새로고침했다. 이때 에러를 보여주면 "취소가 안 된 건가?"라고 혼란스러워한다.

---

## 2. 해결: 이미 처리된 상태면 성공 반환

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
