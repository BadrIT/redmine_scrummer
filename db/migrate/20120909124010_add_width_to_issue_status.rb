class AddWidthToIssueStatus < ActiveRecord::Migration
  def self.up
  	add_column :issue_statuses, :width, :integer
  end

  def self.down
  end
end
