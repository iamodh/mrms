class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses do |t|
      t.references :race, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :capacity, default: 0, null: false
      t.integer :fee, null: false
      t.time :start_time, null: false

      t.timestamps
    end
  end
end
