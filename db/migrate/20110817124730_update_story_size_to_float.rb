class UpdateStorySizeToFloat < ActiveRecord::Migration
  def self.up
    change_table :issues do |t|
      t.change :story_size, :float, :default => 0.0
    end
  end

  def self.down
    change_table :issues do |t|
      t.change :story_size, :integer, :default => 0
    end
  end
end
