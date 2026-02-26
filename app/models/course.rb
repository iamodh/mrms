class Course < ApplicationRecord
  class CapacityExceededError < StandardError; end
  class RegistrationClosedError < StandardError; end

  belongs_to :race
  has_many :registrations, dependent: :destroy

  def remaining_slots
    capacity - registrations.where(status: "applied").count
  end

  def full?
    remaining_slots <= 0
  end

  def available?
    !race.registration_closed? && !full?
  end

  def create_registration!(params)
    Course.transaction do
      lock!

      raise RegistrationClosedError, "신청 기간이 종료되었습니다." if race.registration_closed?
      raise CapacityExceededError, "선택하신 코스의 정원이 마감되었습니다." if full?

      registrations.create!(params.merge(race: race))
    end
  end
end
