# Rails normalizes vs before_validation

콜백 없이 선언적으로 입력값을 정규화하여 DB에 저장하는 방법.

---

## 1. 문제: 정규화 시점과 범위

**예시:** 사용자가 이름을 "홍 길 동"으로 입력하면 DB에는 "홍길동"으로 저장되어야 한다. 조회 시에도 "홍 길 동"으로 검색하면 "홍길동"으로 매칭되어야 한다.

`before_validation` 콜백으로 구현하면:
- `valid?`나 `save` 호출 시에만 변환 — 대입 직후에는 원본값이 남아 있음
- `find_by`에 적용되지 않음 — 검색 시 수동으로 정규화해야 함
- 콜백 순서에 따라 다른 validation과 충돌할 수 있음

```ruby
before_validation :normalize_name
def normalize_name
  self.name = name.gsub(/\s+/, "")
end
```

---

## 2. 해결: normalizes (Rails 7.1+)

```ruby
normalizes :name, with: ->(name) { name.gsub(/\s+/, "") }
normalizes :phone_number, with: ->(phone) { phone.gsub(/\D/, "") }
```

- 속성이 **대입되는 즉시** 변환됨 (`registration.name = "홍 길 동"` → 바로 `"홍길동"`)
- `find_by`에도 정규화가 적용됨 (`Registration.find_by(name: "홍 길 동")` → `"홍길동"`으로 검색)
- 선언적이라 의도가 명확하고, 콜백 순서에 의존하지 않음

이름과 전화번호에 `normalizes`를 사용하여, 저장뿐 아니라 조회 시에도 일관된 정규화를 보장한다. 특히 조회 기능(`find_by(name:)`)에서 사용자가 공백을 포함해 입력해도 정확히 매칭된다.
