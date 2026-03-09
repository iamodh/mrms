require "test_helper"

class Admin::CoursesTest < ActionDispatch::IntegrationTest
  test "update course capacity persists to DB" do
    admin_login
    course = courses(:five_km)

    patch admin_course_path(course), params: { course: { capacity: 500 } }

    assert_redirected_to admin_root_path
    assert_equal 500, course.reload.capacity
  end

  test "edit form displays current capacity" do
    admin_login
    course = courses(:five_km)

    get edit_admin_course_path(course)

    assert_response :success
    assert_select "input[name='course[capacity]'][value='200']"
  end

  test "dashboard has edit links for each course" do
    admin_login

    get admin_root_path

    courses = Course.where(race: races(:marathon_2026))
    courses.each do |course|
      assert_select "a[href='#{edit_admin_course_path(course)}']"
    end
  end
end
