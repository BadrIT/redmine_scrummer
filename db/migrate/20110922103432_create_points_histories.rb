class CreatePointsHistories < ActiveRecord::Migration
  def self.up
    
    create_table :points_histories do |t|
      t.column :issue_id, :integer, :null => false
      t.column :date    , :date   , :null => false
      t.column :points  , :float  , :null => false, :default => 0.0
    end

  end

  def self.down
    drop_table :points_histories
  end
end
