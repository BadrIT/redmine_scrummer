class AddRetrospectiveUrlToVersion < ActiveRecord::Migration
  def self.up
  	add_column :versions, :retrospective_url, :string
  end

  def self.down
  end
end
