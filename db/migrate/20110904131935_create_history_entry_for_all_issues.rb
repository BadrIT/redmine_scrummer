class CreateHistoryEntryForAllIssues < ActiveRecord::Migration
  def self.up
    # Create history entry for all time trackable issues
    Issue.all.each do |issue|
      issue.build_history_entry.save
    end
    
  end

  def self.down
  end
end
