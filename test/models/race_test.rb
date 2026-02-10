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
end
