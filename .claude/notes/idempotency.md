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
