require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
  test "registration can be created" do
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
    registration = Registration.create!(
      race_id: race.id,
      course_id: course.id,
      name: "홍길동",
      birth_date: Date.new(1990, 1, 1),
      gender: "male",
      phone_number: "01012345678",
      address: "서울시 강남구"
    )
    assert registration.persisted?
  end
end
