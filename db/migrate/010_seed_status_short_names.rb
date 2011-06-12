class SeedStatusShortNames < ActiveRecord::Migration
	def self.up
		# add short names
		name_to_short_name = {'Scrum-Defined' => 'D',
													'Scrum-In-Progress' => 'P',
													'Scrum-Completed' => 'C',
													'Scrum-Accepted' => 'A'}
												
		name_to_short_name.each do |name, short_name|
			status = IssueStatus.find_by_name(name)
			status.short_name = short_name
			status.save!
		end
	end
	
	def self.down
	end
end