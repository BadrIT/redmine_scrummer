module RedmineScrummer
	module IssuePatch
		
		def self.included(base)
		  base.extend(ClassMethods) 
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
				
				include InstanceMethods
			end
			
		end
		
		module ClassMethods
		  def default_description
		    "As a <role> I want to <goal> so that <reason>\\nVerification Points:\\n<Point1>\\n<Point2>"
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