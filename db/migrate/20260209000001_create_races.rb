class CreateRaces < ActiveRecord::Migration[8.0]
  def change
    create_table :races do |t|
      t.string :name, null: false
      t.datetime :event_date, null: false
      t.string :location, null: false
      t.datetime :registration_deadline, null: false

      t.timestamps
    end
  end
end
