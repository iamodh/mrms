class AddUniqueIndexOnRegistrationsRaceNamePhone < ActiveRecord::Migration[8.0]
  def change
    add_index :registrations, [ :race_id, :name, :phone_number ], unique: true
  end
end
