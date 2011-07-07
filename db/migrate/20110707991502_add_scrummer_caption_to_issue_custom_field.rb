class AddScrummerCaptionToIssueCustomField < ActiveRecord::Migration
  def self.up
    # add scrummer_caption to search by it in init.rb
    add_column :custom_fields, :scrummer_caption, :string
  end

  def self.down
    remove_column :custom_fields, :scrummer_caption
  end
end
