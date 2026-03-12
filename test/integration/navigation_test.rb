require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  test "admin registrations page has back link to dashboard" do
    admin_login
    get admin_registrations_path

    assert_select "a[href='#{admin_root_path}']", "대시보드로 돌아가기"
  end

  test "admin course edit page has back link to dashboard" do
    admin_login
    get edit_admin_course_path(courses(:five_km))

    assert_select "a[href='#{admin_root_path}']", "대시보드로 돌아가기"
  end

  test "admin race edit page has back link to dashboard" do
    admin_login
    get edit_admin_race_path

    assert_select "a[href='#{admin_root_path}']", "대시보드로 돌아가기"
  end

  test "registration complete page has link to lookup page" do
    course = courses(:five_km)
    registration = registrations(:hong_5km)

    get course_registration_path(course, registration)

    assert_select "a[href='#{lookup_path}']", "신청 조회하기"
  end

  test "lookup result page has link to home" do
    registration = registrations(:hong_5km)
    post lookup_path, params: { confirmation_code: registration.confirmation_code, name: registration.name }

    assert_select "a[href='#{root_path}']", "홈으로 돌아가기"
  end

  test "lookup form page has link to home" do
    get lookup_path

    assert_select "a[href='#{root_path}']", "홈으로 돌아가기"
  end
end
