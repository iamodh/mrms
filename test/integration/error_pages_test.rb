require "test_helper"

class ErrorPagesTest < ActionDispatch::IntegrationTest
  test "accessing non-existent course returns 404 with Korean message" do
    get new_course_registration_path(course_id: 999999)

    assert_response :not_found
    assert_select "h1", "페이지를 찾을 수 없습니다"
  end

  test "accessing non-existent admin course returns 404 with link to dashboard" do
    admin_login

    get edit_admin_course_path(id: 999999)

    assert_response :not_found
    assert_select "h1", "페이지를 찾을 수 없습니다"
    assert_select "a[href='/admin']", "대시보드"
  end
end
