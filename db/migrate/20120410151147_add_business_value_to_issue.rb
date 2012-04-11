class AddBusinessValueToIssue < ActiveRecord::Migration
  def self.up
    add_column :issues, :business_value, :float
  end

  def self.down
    remove_column :issues, :business_value
  end
end
