class CreateReleases < ActiveRecord::Migration
  def self.up
    create_table :releases do |t|
      t.string  :name,        :null => false
      t.integer :project_id,  :null => false
      t.date    :start_date,  :null => false
      t.date    :release_date,:null => false
      t.string  :state,       :null => false
      t.text    :description
    end
  end

  def self.down
    drop_table :releases
  end
end
  