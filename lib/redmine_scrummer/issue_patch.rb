module RedmineScrummer
	module IssuePatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
				
				validates_numericality_of :story_size
				include InstanceMethods
		
				safe_attributes 'story_size',
			    :if => lambda {|issue, user| issue.new_record? || user.allowed_to?(:edit_issues, issue.project) }
			end
			
		end
		
		module InstanceMethods
			
			def is_scrum_issue
				tracker.is_scrum
			end
		end
	end
end