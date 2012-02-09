class AddProjectIdToVacations < ActiveRecord::Migration
  def self.up
    add_column :vacations, :project_id, :integer
  end

  def self.down
    remove_column :vacations, :project_id
  end
end
