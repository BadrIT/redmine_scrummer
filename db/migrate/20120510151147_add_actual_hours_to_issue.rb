class AddActualHoursToIssue < ActiveRecord::Migration
  def self.up
    add_column :issues, :actual_hours, :float, :default => 0
  end

  def self.down
    remove_column :issues, :actual_hours
  end
end
