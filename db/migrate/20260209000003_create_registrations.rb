class CreateRegistrations < ActiveRecord::Migration[8.0]
  def change
    create_table :registrations do |t|
      t.references :race, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string :name, null: false
      t.date :birth_date, null: false
      t.string :gender, null: false
      t.string :phone_number, null: false
      t.string :address, null: false
      t.string :confirmation_code
      t.string :status, null: false, default: "applied"
      t.datetime :canceled_at

      t.timestamps
    end
  end
end
