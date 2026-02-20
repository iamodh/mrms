class Course < ApplicationRecord
  class CapacityExceededError < StandardError; end

  belongs_to :race
  has_many :registrations, dependent: :destroy

  def remaining_slots
    capacity - registrations.where(status: "applied").count
  end

  def full?
    remaining_slots <= 0
  end

  def available?
    !full? && race.registration_deadline > Time.current
  end

  def create_registration!(params)
    Course.transaction do
      lock!

      if full?
        raise CapacityExceededError, "선택하신 코스의 정원이 마감되었습니다."
      end

      registrations.create!(params)
    end
  end
end
