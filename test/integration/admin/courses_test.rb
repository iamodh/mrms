require "test_helper"

class Admin::CoursesTest < ActionDispatch::IntegrationTest
  test "update course capacity persists to DB" do
    admin_login
    course = courses(:five_km)

    patch admin_course_path(course), params: { course: { capacity: 500 } }

    assert_redirected_to admin_root_path
    assert_equal 500, course.reload.capacity
  end
end
