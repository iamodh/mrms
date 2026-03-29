# 사용자 입력 기반 정렬의 SQL Injection 방지

## 문제

정렬 기능에서 `params[:sort]`를 `order()`에 직접 전달하면 SQL injection이 가능하다.

```ruby
# 위험: 사용자 입력을 그대로 쿼리에 사용
@registrations = @race.registrations.order(params[:sort])
```

## 해결: 화이트리스트 패턴

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
