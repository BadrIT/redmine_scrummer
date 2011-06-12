class SeedTrackerShortNames < ActiveRecord::Migration
	def self.up
		# correct name of Scrum-Task
		scrum_task = Tracker.find_by_name('Scrum-Taske')
		if scrum_task
			scrum_task.name = 'Scrum-Task'
			scrum_task.save!
		end
		
		# add short names
		name_to_short_name = {'Scrum-UserStory' => 'US',
													'Scrum-Task' => 'Task',
													'Scrum-Epic' => 'Epic',
													'Scrum-Feature' => 'Feature',
													'Scrum-Theme' => 'Theme'}
												
		name_to_short_name.each do |name, short_name|
			tracker = Tracker.find_by_name(name)
			tracker.short_name = short_name
			tracker.save!
		end
	end
	
	def self.down
	end
end