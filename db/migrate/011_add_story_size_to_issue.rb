class AddStorySizeToIssue < ActiveRecord::Migration
	def self.up
		# add short names
		add_column :issues, :story_size, :float, :default => 0
	end
	
	def self.down
		remove_column :issues, :story_size 
	end
end