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
			  :scrummer_caption == :userstory
			end
			
			def is_epic?
			  :scrummer_caption == :epic
			end
			
			def is_theme?
				:scrummer_caption == :theme
			end
			
			def is_scrum_task?
				:scrummer_caption == :task
			end
			
			def defect?
			  :scrummer_caption == :defect			 
			end
			
			def defectsuite?
        :scrummer_caption == :defectsuite       
      end
      
      def refactor?
        :scrummer_caption == :refactor       
      end
		end
	end
end