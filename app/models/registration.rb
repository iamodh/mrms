class Registration < ApplicationRecord
  belongs_to :race
  belongs_to :course

  before_validation :set_race_from_course
  before_create :generate_confirmation_code

  enum :gender, { male: "male", female: "female" }

  normalizes :name, with: ->(name) { name.gsub(/\s+/, "") }
  normalizes :phone_number, with: ->(phone_number) { phone_number.gsub(/\D/, "") }

  validates :name, presence: true, length: { maximum: 10 }, uniqueness: {
    scope: [ :race_id, :phone_number ],
    message: "이미 동일한 이름과 전화번호로 신청된 내역이 있습니다."
  }
  validates :phone_number, presence: true, length: { is: 11 }
  validates :birth_date, :gender, presence: true
  validates :address, presence: true, length: { maximum: 30 }

  private

  def set_race_from_course
    self.race = course.race if course.present? && race.blank?
  end

  def generate_confirmation_code
    loop do
      self.confirmation_code = SecureRandom.alphanumeric(8).upcase
      break unless Registration.exists?(confirmation_code: confirmation_code)
    end
  end
end
