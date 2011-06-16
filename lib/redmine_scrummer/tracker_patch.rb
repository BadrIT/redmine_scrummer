module RedmineScrummer
	module TrackerPatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
				
				include InstanceMethods
	
				
				def self.scrum_task_tracker
					Tracker.find_by_name(Scrummer::Constants::ScrumTaskTrackerName)
				end		
			end
			
		end
		
		module InstanceMethods
			
			def is_user_story?
				name == Scrummer::Constants::ScrumUserStoryTrackerName
			end
			
			def is_epic?
				name == Scrummer::Constants::ScrumEpicTrackerName
			end
			
			def is_theme?
				name == Scrummer::Constants::ScrumThemeTrackerName
			end
			
			def is_scrum_task?
				name == Scrummer::Constants::ScrumTaskTrackerName
			end
		end
	end
end