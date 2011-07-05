class AddIsScrumRoles < ActiveRecord::Migration
	def self.up
		add_column :roles, :is_scrum, :boolean, :default => false
	end
	
	def self.down		
		remove_column :roles, :is_scrum
	end
end