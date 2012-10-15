class AddStorySizeToIssue < ActiveRecord::Migration
  def self.up
    add_column :issues, :story_size, :integer, :default => 0
  end

  def self.down
    remove_column :issues, :story_size
  end
end
