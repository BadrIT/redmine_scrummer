class AddIsScrumTrackers < ActiveRecord::Migration
	def self.up
		add_column :trackers, :is_scrum, :boolean, :default => false
	end
	
	def self.down
		remove_column :trackers, :is_scrum		
	end
end