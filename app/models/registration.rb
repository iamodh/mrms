class Registration < ApplicationRecord
  belongs_to :race
  belongs_to :course

  before_validation :set_race_from_course

  enum :gender, { male: "male", female: "female" }

  normalizes :name, with: ->(name) { name.gsub(/\s+/, "") }
  normalizes :phone_number, with: ->(phone_number) { phone_number.gsub(/\D/, "") }

  validates :name, presence: true, length: { maximum: 10 }
  validates :phone_number, :birth_date, :gender, presence: true
  validates :address, presence: true, length: { maximum: 30 }

  private

  def set_race_from_course
    self.race = course.race if course.present? && race.blank?
  end
end
