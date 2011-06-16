require 'scrummer_constants'

class AddStorySizeToIssue < ActiveRecord::Migration
	def self.up
		# add story size custom field
		story_size_custom_field = IssueCustomField.find_by_name(Scrummer::Constants::CustomStorySizeFieldName)
		story_size_custom_field ||= IssueCustomField.create(:name => Scrummer::Constants::CustomStorySizeFieldName,
																											:field_format => 'list',
																											:possible_values => Scrummer::Constants::StorySizes.map{|size| size.to_s},
																											:is_required => true,
																											:default_value => "0")
		story_size_custom_field.save!
		
		# add connections between fields and trackers
		tracker_names = [ Scrummer::Constants::ScrumUserStoryTrackerName,
											Scrummer::Constants::ScrumEpicTrackerName,
											Scrummer::Constants::ScrumThemeTrackerName	]

		tracker_names.each do |tracker_name|
			tracker = Tracker.find_by_name(tracker_name)
			tracker.custom_fields << story_size_custom_field
			tracker.save!
		end												
		
	end
	
	def self.down 
	end
end