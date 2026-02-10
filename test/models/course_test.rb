require "test_helper"

class CourseTest < ActiveSupport::TestCase
  test "belongs to race" do
    course = courses(:five_km)
    assert_equal races(:marathon_2026), course.race
  end

  test "has many registrations" do
    course = courses(:five_km)
    assert_includes course.registrations, registrations(:hong_5km)
  end
end
