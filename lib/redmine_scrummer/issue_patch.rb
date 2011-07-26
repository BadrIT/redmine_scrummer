module RedmineScrummer
	module IssuePatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
				
				include InstanceMethods
				
				after_create :initiate_todo
				after_save :update_todo
				validate :validate_status
			end
			
		end
		
		module InstanceMethods
		  def is_test?
		    tracker.is_test?
		  end
		  
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
      
      def story_size
        # if the issue has children having the story size custom field
        # then sum children
        # else take issue story size custom field value
        children_has_custom_field = self.children.any? do |c| 
          c.tracker.custom_fields.any?{|field| field.scrummer_caption == :story_size}
        end  
        
        if children_has_custom_field
          children.map(&:story_size).sum
        else
          custom_field = CustomField.find_by_scrummer_caption(:story_size)
          format = custom_field.field_format
          custom_value = self.custom_value_for(custom_field)
          value = custom_value ? custom_value.value : '' 
          
          format == "float" ? value.to_f : value.to_i  
        end
      end
      
      def level
        parent = self
        level = 0
        while (parent.parent) do
          parent = parent.parent
          level += 1
        end
        
        level
      end
			
			def initiate_todo
			  if self.todo == 0.0
			    self.todo = self.estimated_hours
			    self.save
			  end
			end
			
			def method_missing(m, *args, &block)
			  # check status methods (status_defined?, status_accepted?, completed?, ..etc)
			  # method name can be (status_status_name?) OR (status_name?) directly
			  # we had to add status_ in some cases like (defined?) because defined? is a ruby keywork
			  if m.to_s =~ /^(status_)?(defined|in_progress|completed|accepted|failed|succeeded)\?$/
			    self.status.scrummer_caption == $2.to_sym
			  else
			    super
			  end
			end
			
			def update_todo
			  # reset todo hours if completed or accepted
			  if status_id_changed? && (self.status_completed? || self.status_accepted?) && self.todo.to_f > 0.0
			   self.todo = 0.0
			   self.save
			  end
			end
			
			def validate_status
			  if self.status_id_changed?
			    # test issues can allow only (defined, success, fail)
  			  if self.is_test? && !(self.succeeded? || self.failed? || self.status_defined?)
  			    self.errors.add(:status_id, "invalid status")
  			    return false
  			  # non test issues doesn't accept success and fail
    			elsif !self.is_test? && (self.succeeded? || self.failed?)
    			  self.errors.add(:status_id, "invalid status")
    			  return false
  			  end
			  end
			end
		end
	end
end