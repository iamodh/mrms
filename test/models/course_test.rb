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

  test "create_registration! allows re-registration after cancellation" do
    canceled = registrations(:lee_5km_canceled)
    course = canceled.course

    new_registration = course.create_registration!(
      name: canceled.name,
      phone_number: canceled.phone_number,
      birth_date: "1992-07-20",
      gender: "female",
      address: "경기도 성남시"
    )

    assert_not_equal canceled.id, new_registration.id
    assert_equal "applied", new_registration.status
    assert_equal "canceled", canceled.reload.status
  end

  test "create_registration! raises RegistrationClosedError when deadline has passed" do
    course = courses(:closed_five_km)

    assert_raises(Course::RegistrationClosedError) do
      course.create_registration!(
        name: "테스트",
        phone_number: "01099999999",
        birth_date: "1990-01-01",
        gender: "male",
        address: "서울시 강남구"
      )
    end
  end
end
