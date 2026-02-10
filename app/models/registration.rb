class Registration < ApplicationRecord
  belongs_to :race
  belongs_to :course

  enum :gender, { male: "male", female: "female" }

  validates :name, :phone_number, :birth_date, :gender, :address, presence: true
end
