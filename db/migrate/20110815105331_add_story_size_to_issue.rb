class AddStorySizeToIssue < ActiveRecord::Migration
  def self.up
    add_column :issues, :story_size, :integer, :default => 0
    Issue.all.each{|i| i.update_attribute(:story_size, 0)}
    
    custom_field = CustomField.find_by_scrummer_caption(:story_size)
    Issue.all.each{|i| i.update_story_size(custom_field)}
  end

  def self.down
    remove_column :issues, :story_size
  end
end
