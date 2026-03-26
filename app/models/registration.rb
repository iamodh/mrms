class Registration < ApplicationRecord
  class NotCancelableError < StandardError; end

  belongs_to :race
  belongs_to :course

  before_validation :set_race_from_course
  before_create :generate_confirmation_code

  enum :status, { applied: "applied", canceled: "canceled", refunded: "refunded" }
  enum :gender, { male: "male", female: "female" }

  normalizes :name, with: ->(name) { name.gsub(/\s+/, "") }
  normalizes :phone_number, with: ->(phone_number) { phone_number.gsub(/\D/, "") }

  validates :name, presence: true, length: { maximum: 10 }, uniqueness: {
    scope: [ :race_id, :phone_number ],
    conditions: -> { where(status: :applied) }
  }
  validates :phone_number, presence: true, length: { is: 11 }
  validates :birth_date, presence: true, comparison: { less_than_or_equal_to: -> { Date.today } }
  validates :gender, presence: true
  validates :address, presence: true, length: { maximum: 30 }

  STATUS_LABELS = { "applied" => "신청", "canceled" => "취소", "refunded" => "환불" }.freeze
  GENDER_LABELS = { "male" => "남", "female" => "여" }.freeze

  def status_label
    STATUS_LABELS[status]
  end

  def gender_label
    GENDER_LABELS[gender]
  end

  def formatted_phone_number
    phone_number.gsub(/(\d{3})(\d{4})(\d{4})/, '\1-\2-\3')
  end

  def cancelable?
    applied? && !race.registration_closed?
  end

  def cancel!
    return true if canceled?

    raise NotCancelableError, "취소 가능 기간이 지났습니다." unless cancelable?

    update!(status: :canceled, canceled_at: Time.current)
  end

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
