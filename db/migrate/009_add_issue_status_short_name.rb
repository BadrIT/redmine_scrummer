class AddIssueStatusShortName < ActiveRecord::Migration
	def self.up
		add_column :issue_statuses, :short_name, :string, :default => ''
	end
	
	def self.down
		remove_column :issue_statuses, :short_name		
	end
end