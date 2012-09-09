class AddColumnColorToTrackers < ActiveRecord::Migration
  def self.up
  	add_column :trackers, :color, :string
  end

  def self.down
  end
end
