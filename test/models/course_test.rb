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

  test "remaining_slots returns capacity minus applied registrations" do
    course = courses(:five_km)
    assert_equal course.capacity - 1, course.remaining_slots
  end

  test "full? returns true when applied count >= capacity" do
    course = courses(:full)
    assert course.full?
  end

  test "full? returns false when applied count < capacity" do
    course = courses(:five_km)
    assert_not course.full?
  end

  test "available? returns true when not full and before deadline" do
    course = courses(:five_km)
    assert course.available?
  end

  test "available? returns false when full" do
    course = courses(:full)
    assert_not course.available?
  end

  test "available? returns false when registration deadline has passed" do
    course = courses(:closed_five_km)
    assert_not course.available?
  end
end
