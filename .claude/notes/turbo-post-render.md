# Turbo Drive와 POST → render 충돌

일반적인 Rails POST 흐름은 "데이터 생성 → redirect → 새 페이지"이다. Turbo Drive는 이를 전제로 설계되어, POST 응답이 200(render)이면 에러를 발생시킨다. redirect(303) 또는 4xx/5xx만 허용한다.

**문제:** lookup은 POST가 "생성"이 아니라 "검색"이다. 결과를 그 자리에서 render하고 싶지만, Turbo가 이를 거부한다. redirect하려면 URL에 confirmation_code와 이름을 실어야 하는데, 이는 개인정보 노출이므로 안 된다.

**해결:** 해당 폼에서만 Turbo를 비활성화한다.

```erb
<%= form_with url: lookup_path, method: :post, data: { turbo: false } do |f| %>
```
