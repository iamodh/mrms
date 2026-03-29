class ReplaceUniqueIndexOnRegistrationsWithPartial < ActiveRecord::Migration[8.1]
  def change
    remove_index :registrations, [ :race_id, :name, :phone_number ]
    add_index :registrations, [ :race_id, :name, :phone_number ],
      unique: true, where: "status = 'applied'"
  end
end
