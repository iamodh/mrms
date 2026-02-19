class Registration < ApplicationRecord
  belongs_to :race
  belongs_to :course

  enum :gender, { male: "male", female: "female" }

  normalizes :name, with: ->(name) { name.gsub(/\s+/, "") }
  normalizes :phone_number, with: ->(phone_number) { phone_number.gsub(/\D/, "") }

  validates :name, :phone_number, :birth_date, :gender, :address, presence: true
end
