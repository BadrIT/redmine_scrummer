class SeedScrumRoles < ActiveRecord::Migration
	def self.up
		add_column :roles, :is_scrum, :boolean, :default => false
		
		Role.create(:is_scrum => true, :name => 'Scrum-ProjectMember', :position => 1)
		Role.create(:is_scrum => true, :name => 'Scrum-ScrumMaster', :position => 2)
		Role.create(:is_scrum => true, :name => 'Scrum-ProductOwner', :position => 3)		
		
	end
	
	def self.down		
		remove_column :roles, :is_scrum
	end
end