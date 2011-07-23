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
			
			def todo
			  #TODO(MK): shouldn't we introduce caption to custom_field, instead of checking name?
			  self.custom_field_values.find{|c| c.custom_field.name == "TODO(hrs)"}.try(:value).try(:to_f)
			end
			
			def todo=(value)
			  #TODO(MK): shouldn't we introduce caption to custom_field, instead of checking name?
        (self.custom_field_values.find{|c| c.custom_field.name == "TODO(hrs)"}).value = value
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