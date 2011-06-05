class SeedScrumWorkflow < ActiveRecord::Migration
	def self.up
		
		Tracker.find_all_by_is_scrum(true).each do |tracker|
			Role.find_all_by_is_scrum(true).each do |role|
				IssueStatus.find_all_by_is_scrum(true).each do |old_status|
					IssueStatus.find_all_by_is_scrum(true).each do |new_status|
						Workflow.create(:role_id => role.id, 
						  			 		    :tracker_id => tracker.id, 
						  			 		    :old_status_id => old_status.id, 
						  			 		    :new_status_id => new_status.id)
					end
				end
			end
		end		
		
	end
	
	def self.down		
	end
end