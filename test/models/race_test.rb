require "test_helper"

class RaceTest < ActiveSupport::TestCase
  test "race can be created" do
    race = Race.create!(
      name: "Test Race",
      event_date: 1.month.from_now,
      location: "Seoul",
      registration_deadline: 2.weeks.from_now
    )
    assert race.persisted?
  end
end
