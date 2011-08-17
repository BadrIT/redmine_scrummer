class UpdateStorySizeToFloat < ActiveRecord::Migration
  def self.up
    change_table :issues do |t|
      t.change :story_size, :float, :default => 0.0
    end
    Issue.all.each{|i| i.update_attribute(:story_size, 0.0) if i.story_size.nil?}
    
    custom_field = CustomField.find_by_scrummer_caption(:story_size)
    Issue.all.each{|i| i.update_story_size(custom_field)}
  end

  def self.down
    change_table :issues do |t|
      t.change :story_size, :integer, :default => 0
    end
  end
end
