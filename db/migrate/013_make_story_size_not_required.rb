require 'scrummer_constants'

class MakeStorySizeNotRequired < ActiveRecord::Migration
	def up
		story_size_field = IssueCustomField.find_by_name(Scrummer::Constants::CustomStorySizeFieldName)
		story_size_field.is_required = 0
		story_size_field.save!
		
		story_size_field.reload
		puts story_size_field.is_required
	end
	
	def down		
	end
end