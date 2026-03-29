# render vs redirect: 에러 전달 방식의 차이

Rails에서 에러 발생 시 render와 redirect 중 어떤 것을 선택할지에 대한 컨벤션.

---

## 1. render — 같은 요청에서 뷰를 다시 그린다

**예시:** 신청 폼에서 필수 필드를 비워두고 제출했다. 입력값을 유지한 채 에러 메시지를 보여줘야 한다.

인스턴스 변수(`@registration.errors`)가 유지되므로 뷰에서 필드별 에러를 직접 표시할 수 있고, 폼 입력값이 보존된다.

```ruby
rescue ActiveRecord::RecordInvalid => e
  @registration = e.record
  render :new, status: :unprocessable_entity
```

용도: validation 실패 (필수 필드 누락, 형식 오류 등)

---

## 2. redirect — 새 요청을 보낸다

**예시:** 정원이 마감된 코스에 신청을 시도했다. 입력값을 보존할 필요 없이 에러 메시지만 전달하면 된다.

인스턴스 변수가 소멸하므로 `flash`로 메시지를 전달한다. 폼 입력값은 사라진다.

```ruby
redirect_to new_course_registration_path(@course), alert: "정원이 마감되었습니다."
```

용도: 권한 거부, 중복 신청, 마감 등 폼 보존이 불필요한 경우

---

## 3. 테스트에서의 차이

| 방식 | 응답 검증 | 메시지 검증 |
|------|-----------|-------------|
| render | `assert_response :unprocessable_entity` | `assert_select ".field-errors"` |
| redirect | `assert_redirected_to path` | `assert_equal "메시지", flash[:alert]` |

redirect 후에는 페이지 본문이 없으므로 `assert_select`를 쓸 수 없고, flash로 검증한다.
