class CreateScrumWeeklyNonWorkingDays < ActiveRecord::Migration
  def self.up
    create_table :scrum_weekly_non_working_days do |t|
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
    drop_table :scrum_weekly_non_working_days
  end
end
