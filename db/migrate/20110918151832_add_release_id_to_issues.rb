class AddReleaseIdToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :release_id, :integer
  end

  def self.down
    add_remove :issues, :release_id, :integer
  end
end
