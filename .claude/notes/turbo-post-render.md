# Turbo Drive와 POST → render 충돌

Turbo Drive의 POST 응답 제약으로 인해 검색 폼에서 render를 사용할 수 없는 문제와 해결 방법.

---

## 1. 문제: POST 응답이 200이면 Turbo가 에러 발생

**예시:** 조회 폼에서 확인코드와 이름을 입력하고 제출하면 결과를 그 자리에서 보여줘야 한다. 일반적인 Rails 방식대로 render하면 Turbo가 거부한다.

일반적인 Rails POST 흐름은 "데이터 생성 → redirect → 새 페이지"다. Turbo Drive는 이를 전제로 설계되어 POST 응답이 200(render)이면 에러를 발생시킨다. redirect(303) 또는 4xx/5xx만 허용한다.

redirect(303)로 우회하려면 다음 URL에 confirmation_code와 이름을 쿼리스트링으로 실어야 하는데(`?code=AB12CD34&name=홍길동`), 주소창에 그대로 노출되므로 안 된다.

---

## 2. 해결: 해당 폼에서만 Turbo 비활성화

```erb
<%= form_with url: lookup_path, method: :post, data: { turbo: false } do |f| %>
```

Turbo를 비활성화하면 일반 폼 제출로 동작하여 POST → render 흐름이 정상적으로 처리된다.
