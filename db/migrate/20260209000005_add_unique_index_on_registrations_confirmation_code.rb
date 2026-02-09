class AddUniqueIndexOnRegistrationsConfirmationCode < ActiveRecord::Migration[8.0]
  def change
    add_index :registrations, :confirmation_code, unique: true
  end
end
