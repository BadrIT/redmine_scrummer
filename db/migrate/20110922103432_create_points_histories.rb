class CreatePointsHistories < ActiveRecord::Migration
  def self.up
    create_table :points_histories do |t|
      t.column :issue_id, :integer, :null => false
      t.column :date    , :date   , :null => false
      t.column :points  , :float  , :null => false, :default => 0.0
    end
    
    # Create points history entry for all the issues as a strat point
    Issue.find(:all, :conditions => ['tracker_id = ?', Tracker.scrum_user_story_tracker.id]).each do |issue|
      issue.build_points_history_entry.save
    end
    
  end

  def self.down
    drop_table :points_histories
  end
end
