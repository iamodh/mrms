require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  test "flash alert is rendered in layout" do
    course = courses(:full)

    post course_registrations_path(course), params: {
      registration: {
        name: "테스트",
        phone_number: "01099999999",
        birth_date: "1990-01-01",
        gender: "male",
        address: "서울시 강남구"
      }
    }

    follow_redirect!
    assert_select ".flash-alert", "선택하신 코스의 정원이 마감되었습니다."
  end
end
