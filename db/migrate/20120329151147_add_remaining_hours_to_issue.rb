class AddRemainingHoursToIssue < ActiveRecord::Migration
  def self.up
    add_column :issues, :remaining_hours, :float
  end

  def self.down
    remove_column :issues, :remaining_hours
  end
end
