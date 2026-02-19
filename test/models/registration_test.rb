require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
  test "belongs to race" do
    registration = registrations(:hong_5km)
    assert_equal races(:marathon_2026), registration.race
  end

  test "belongs to course" do
    registration = registrations(:hong_5km)
    assert_equal courses(:five_km), registration.course
  end

  test "normalizes name by removing spaces" do
    registration = registrations(:hong_5km)
    registration.name = "홍 길 동"
    assert_equal "홍길동", registration.name
  end

  test "normalizes phone_number by removing non-digits" do
    registration = registrations(:hong_5km)
    registration.phone_number = "010-1234-5678"
    assert_equal "01012345678", registration.phone_number
  end

  test "requires name, phone_number, birth_date, gender, and address" do
    registration = registrations(:hong_5km)
    registration.name = nil
    registration.phone_number = nil
    registration.birth_date = nil
    registration.gender = nil
    registration.address = nil
    assert_not registration.valid?
    assert_includes registration.errors[:name], "can't be blank"
    assert_includes registration.errors[:phone_number], "can't be blank"
    assert_includes registration.errors[:birth_date], "can't be blank"
    assert_includes registration.errors[:gender], "can't be blank"
    assert_includes registration.errors[:address], "can't be blank"
  end
end
