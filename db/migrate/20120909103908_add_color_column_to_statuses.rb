class AddColorColumnToStatuses < ActiveRecord::Migration
  def self.up
  	add_column :issue_statuses, :color, :string
  end

  def self.down
  end
end
