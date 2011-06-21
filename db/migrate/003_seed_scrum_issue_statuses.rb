class SeedScrumIssueStatuses < ActiveRecord::Migration
	def self.up
		add_column :issue_statuses, :is_scrum, :boolean, :default => false
		
		IssueStatus.create(:is_scrum => true, :name => 'Scrum-Defined', :position => 1, :is_default => true)
		IssueStatus.create(:is_scrum => true, :name => 'Scrum-In-Progress', :position => 2)
		IssueStatus.create(:is_scrum => true, :name => 'Scrum-Completed', :position => 3)
		IssueStatus.create(:is_scrum => true, :name => 'Scrum-Accepted', :position => 4, :is_closed => true)
	
	end
	
	def self.down		
		remove_column :roles, :is_scrum
	end
end