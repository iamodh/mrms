class Race < ApplicationRecord
  has_many :courses, dependent: :destroy
  has_many :registrations, dependent: :destroy
end
