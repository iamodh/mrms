class Course < ApplicationRecord
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
end
