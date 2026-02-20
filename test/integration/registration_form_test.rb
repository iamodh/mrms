require "test_helper"

class RegistrationFormTest < ActionDispatch::IntegrationTest
  test "home page shows available courses with registration links" do
    get root_path

    assert_response :success

    [ courses(:five_km), courses(:ten_km), courses(:half) ].each do |course|
      assert_select "[data-course-id='#{course.id}'] a[href=?]", new_course_registration_path(course)
    end
  end

  test "home page hides courses with zero capacity" do
    get root_path

    assert_select "[data-course-id='#{courses(:full).id}']", count: 0
  end

  test "home page displays remaining slots for each available course" do
    get root_path

    five_km = courses(:five_km)

    assert_select "[data-course-id='#{five_km.id}'] .remaining-slots",
      text: /#{five_km.remaining_slots}/
  end

  test "registration form renders input fields for the selected course" do
    course = courses(:five_km)

    get new_course_registration_path(course)

    assert_response :success
    assert_select "form[action=?]", course_registrations_path(course)
    assert_select "input[name='registration[name]']"
    assert_select "input[name='registration[phone_number]']"
    assert_select "input[name='registration[birth_date]']"
    assert_select "select[name='registration[gender]']"
    assert_select "textarea[name='registration[address]']"
  end

  test "registration fails with error when course is full" do
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

    assert_redirected_to new_course_registration_path(course)
    assert_equal "선택하신 코스의 정원이 마감되었습니다.", flash[:alert]
  end

  test "submitting with missing fields re-renders form with validation errors and preserves input" do
    course = courses(:five_km)
    kept_name = "김철수"

    assert_no_difference "Registration.count" do
      post course_registrations_path(course), params: {
        registration: { name: kept_name, phone_number: "", birth_date: "", gender: "", address: "" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "input[name='registration[name]'][value=?]", kept_name
    assert_select ".field-errors"
  end
end
