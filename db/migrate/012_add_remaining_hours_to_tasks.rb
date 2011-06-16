require 'scrummer_constants'

class AddRemainingHoursToTasks < ActiveRecord::Migration
	def self.up
		# add remaining time custom field
		remaining_hours_custom_field = IssueCustomField.find_by_name(Scrummer::Constants::RemainingHoursCustomFieldName)																											
		remaining_hours_custom_field ||= IssueCustomField.create(:name => Scrummer::Constants::RemainingHoursCustomFieldName,
																											:field_format => 'float',
																											:default_value => "0")
		remaining_hours_custom_field.save!
		
		# add connections between fields and trackers
		tracker = Tracker.find_by_name(Scrummer::Constants::ScrumTaskTrackerName)
		tracker.custom_fields << remaining_hours_custom_field
		tracker.save!
		
	end
	
	def self.down 
	end
end