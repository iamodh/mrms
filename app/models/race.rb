class Race < ApplicationRecord
  has_many :courses, dependent: :destroy
  has_many :registrations, dependent: :destroy

  scope :upcoming, -> { where("registration_deadline > ?", Time.current).order(:event_date) }

  def self.latest
    order(event_date: :desc).first
  end

  def registration_closed?
    Time.current > registration_deadline
  end
end
