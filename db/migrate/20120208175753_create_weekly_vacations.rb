class CreateWeeklyVacations < ActiveRecord::Migration
  def self.up
    create_table :weekly_vacations do |t|
      t.text :comment
      t.integer :project_id
      t.boolean :sunday
      t.boolean :monday
      t.boolean :tuesday
      t.boolean :wednesday
      t.boolean :thursday
      t.boolean :friday
      t.boolean :saturday

      t.timestamps
    end
  end

  def self.down
    drop_table :weekly_vacations
  end
end
