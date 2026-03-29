# 사용자 입력 기반 정렬의 SQL Injection 방지

사용자 입력을 정렬 쿼리에 직접 사용하지 않고 화이트리스트로 방어하는 패턴.

---

## 1. 문제: params를 order()에 직접 전달

**예시:** 신청자 목록을 이름순으로 정렬할 때 `params[:sort]`를 그대로 쿼리에 넣으면 악의적인 SQL을 삽입할 수 있다.

```ruby
# 위험: 사용자 입력을 그대로 쿼리에 사용
@registrations = @race.registrations.order(params[:sort])
```

`params[:sort]`에 `"name; DROP TABLE registrations"` 같은 값이 들어오면 의도치 않은 SQL이 실행된다.

---

## 2. 해결: 화이트리스트 패턴

허용된 정렬 옵션만 해시로 정의하고, `fetch`로 매칭되지 않으면 기본값을 반환한다.

```ruby
SORT_OPTIONS = {
  "name_asc" => { name: :asc },
  "name_desc" => { name: :desc }
}.freeze

def index
  order = SORT_OPTIONS.fetch(params[:sort], { created_at: :desc })
  @registrations = @race.registrations.order(order)
end
```

- 사용자 입력(`params[:sort]`)은 해시의 **키 조회**에만 사용되고, SQL에는 절대 들어가지 않음
- 허용되지 않은 값은 기본 정렬(최신순)로 폴백
- 정렬 옵션 추가 시 해시에 항목만 추가하면 됨
