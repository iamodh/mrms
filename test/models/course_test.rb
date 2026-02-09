require "test_helper"

class CourseTest < ActiveSupport::TestCase
  test "course can be created" do
    race = Race.create!(
      name: "Test Race",
      event_date: 1.month.from_now,
      location: "Seoul",
      registration_deadline: 2.weeks.from_now
    )
    course = Course.create!(
      race_id: race.id,
      name: "10km",
      capacity: 100,
      fee: 30_000,
      start_time: Time.parse("09:00")
    )
    assert course.persisted?
  end
end
