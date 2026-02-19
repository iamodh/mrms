class Course < ApplicationRecord
  belongs_to :race
  has_many :registrations, dependent: :destroy

  def remaining_slots
    capacity - registrations.where(status: "applied").count
  end
end
