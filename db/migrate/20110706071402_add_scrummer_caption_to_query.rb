class AddScrummerCaptionToQuery < ActiveRecord::Migration
  def self.up
    # add scrummer_caption to search by it in init.rb
    add_column :queries, :scrummer_caption, :string
  end

  def self.down
    remove_column :queries, :scrummer_caption
  end
end
