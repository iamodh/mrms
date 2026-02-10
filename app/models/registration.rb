class Registration < ApplicationRecord
  belongs_to :race
  belongs_to :course

  validates :name, :phone_number, :birth_date, :gender, presence: true
end
