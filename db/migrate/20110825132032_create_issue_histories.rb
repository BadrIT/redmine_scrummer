class CreateIssueHistories < ActiveRecord::Migration
  def self.up
    create_table :issue_histories do |t|
        t.date    :date
        t.float   :actual
        t.float   :remaining
        t.integer :issue_id
    end
  end

  def self.down
    drop_table :issue_histories
  end
end
