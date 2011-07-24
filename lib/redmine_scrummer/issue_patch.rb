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
			
			def defect?
			  self.tracker.defect?
			end
			
			def time_trackable?
			 self.is_scrum_task? || self.defect?
		  end
			 
			def todo
			  self.custom_field_values.find{|c| c.custom_field.scrummer_caption == :remaining_hours}.try(:value).try(:to_f)
			end
			
			def todo=(value)
        (self.custom_field_values.find{|c| c.custom_field.scrummer_caption == :remaining_hours}).value = value
      end
			
			def after_create
			  if self.todo == 0.0
			    self.todo = self.estimated_hours
			    self.save
			  end
			end
		end
	end
end