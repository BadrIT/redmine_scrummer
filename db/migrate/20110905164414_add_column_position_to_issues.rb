class AddColumnPositionToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :position, :integer, :default => 0
  end

  def self.down
    remove_column :issues, :position
  end
end
