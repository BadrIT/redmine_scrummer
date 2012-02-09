class CreateVacations < ActiveRecord::Migration
  def self.up
    create_table :vacations do |t|
      t.string :name
      t.datetime :start_at
      t.datetime :end_at
      t.text :comment
      t.string :color

      t.timestamps
    end
  end

  def self.down
    drop_table :vacations
  end
end
