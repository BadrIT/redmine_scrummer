module RedmineScrummer
	module IssuePatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
				
				include InstanceMethods
				
			end
			
		end
		
		module InstanceMethods
			
			def scrum_issue?
				tracker.is_scrum
			end
			
			def is_user_story?
				tracker.is_user_story?
			end
			
			def is_epic?
				tracker.is_epic?
			end
			
			def is_theme?
				tracker.is_theme?
			end
			
			def is_scrum_task?
				tracker.is_scrum_task?
			end
		end
	end
end