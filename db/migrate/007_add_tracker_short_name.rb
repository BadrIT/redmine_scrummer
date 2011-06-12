class AddTrackerShortName < ActiveRecord::Migration
	def self.up
		add_column :trackers, :short_name, :string, :default => ''
	end
	
	def self.down
		remove_column :trackers, :short_name		
	end
end