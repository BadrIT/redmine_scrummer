class RemoveRetrospectiveUrlColumn < ActiveRecord::Migration
  def self.up
  	remove_column :versions, :retrospective_url
  end

  def self.down
  end
end
