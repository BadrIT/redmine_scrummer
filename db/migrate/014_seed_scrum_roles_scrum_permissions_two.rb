class SeedScrumRolesScrumPermissionsTwo < ActiveRecord::Migration
	def self.up		
	
		all_scrum_permissions = [:scrum_user_stories,
														 :scrum_user_stories_add_inline,
														 :scrum_user_stories_manipulate_inline,
														 :scrum_sprint_planing,
														 :scrum_release_planing,
														 :scrum_charts]
		
		Role.find_all_by_is_scrum(true).each do |role|
		
			if(role.name == 'Scrum-ProjectMember')
				project_member_permissions = all_scrum_permissions
				role.permissions += project_member_permissions
				role.save!
			elsif(role.name == 'Scrum-ScrumMaster')
				role.permissions += all_scrum_permissions
				role.save!
			elsif(role.name == 'Scrum-ProductOwner')
				role.permissions += all_scrum_permissions
				role.save!				
			end
		end		
	end
	
	def self.down		
	end
end