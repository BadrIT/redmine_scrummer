class SeedScrumTrackers < ActiveRecord::Migration
	def self.up
		add_column :trackers, :is_scrum, :boolean, :default => false
		
		Tracker.create(:is_scrum => true, :name => 'Scrum-UserStory', :is_in_roadmap => true, :is_in_chlog => true, :position => 1)
		Tracker.create(:is_scrum => true, :name => 'Scrum-Task', :is_in_roadmap => true, :is_in_chlog => true, :position => 2)
		Tracker.create(:is_scrum => true, :name => 'Scrum-Epic', :is_in_roadmap => true, :is_in_chlog => true, :position => 3)
		Tracker.create(:is_scrum => true, :name => 'Scrum-Feature', :is_in_roadmap => true, :is_in_chlog => true, :position => 4)
		Tracker.create(:is_scrum => true, :name => 'Scrum-Theme', :is_in_roadmap => true, :is_in_chlog => true, :position => 5)
		
	end
	
	def self.down
		remove_column :trackers, :is_scrum		
	end
end