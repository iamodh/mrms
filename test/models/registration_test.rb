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
end
