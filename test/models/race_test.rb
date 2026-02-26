require "test_helper"

class RaceTest < ActiveSupport::TestCase
  test "has many courses" do
    race = races(:marathon_2026)
    assert_includes race.courses, courses(:five_km)
    assert_includes race.courses, courses(:ten_km)
  end

  test "has many registrations" do
    race = races(:marathon_2026)
    assert_includes race.registrations, registrations(:hong_5km)
  end

  test "registration_closed? returns true when deadline has passed" do
    assert races(:closed_race).registration_closed?
  end

  test "registration_closed? returns false when deadline is in the future" do
    assert_not races(:marathon_2026).registration_closed?
  end
end
