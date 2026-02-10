class Course < ApplicationRecord
  belongs_to :race
  has_many :registrations, dependent: :destroy
end
