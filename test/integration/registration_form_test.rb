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
end
