class AddProjectIssueNumberToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :project_issue_number, :integer
  end

  def self.down
    remove_column :issues, :project_issue_number
  end
end
