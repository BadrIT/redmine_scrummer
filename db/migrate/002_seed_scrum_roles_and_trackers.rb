class SeedScrumRolesAndTrackers < ActiveRecord::Migration
	def self.up
		# Add trackers
		Tracker.reset_column_information	# hack, to solve the problem of :is_scrum, being not loaded correctly

		Tracker.create(:is_scrum => true, :name => 'Scrum-UserStory', :is_in_roadmap => true, :is_in_chlog => true, :position => 1)
		Tracker.create(:is_scrum => true, :name => 'Scrum-Task', :is_in_roadmap => true, :is_in_chlog => true, :position => 2)
		Tracker.create(:is_scrum => true, :name => 'Scrum-Epic', :is_in_roadmap => true, :is_in_chlog => true, :position => 3)
		Tracker.create(:is_scrum => true, :name => 'Scrum-Theme', :is_in_roadmap => true, :is_in_chlog => true, :position => 5)
		
		# Add Roles
		Role.reset_column_information	# hack, to solve the problem of :is_scrum, being not loaded correctly
		
		Role.create(:is_scrum => true, :name => 'Scrum-ProjectMember', :position => 1)
		Role.create(:is_scrum => true, :name => 'Scrum-ScrumMaster', :position => 2)
		Role.create(:is_scrum => true, :name => 'Scrum-ProductOwner', :position => 3)		
		
	end
	
	def self.down				
	end
end