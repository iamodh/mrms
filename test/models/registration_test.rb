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

  test "requires name, phone_number, and birth_date" do
    registration = registrations(:hong_5km)
    registration.name = nil
    registration.phone_number = nil
    registration.birth_date = nil
    assert_not registration.valid?
    assert_includes registration.errors[:name], "can't be blank"
    assert_includes registration.errors[:phone_number], "can't be blank"
    assert_includes registration.errors[:birth_date], "can't be blank"
  end
end
