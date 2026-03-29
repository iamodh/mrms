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
