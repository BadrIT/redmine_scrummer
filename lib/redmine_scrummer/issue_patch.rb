module RedmineScrummer
	module IssuePatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
				
				include InstanceMethods
				
				validate :validate_status
				
				after_create :initiate_remaining_hours
				after_save :update_remaining_hours
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
			
			def is_task?
				tracker.is_task?
			end
			
			def defect?
			  self.tracker.defect?
			end
			
			def time_trackable?
			 self.is_task? || self.defect?
		  end
			 
			def remaining_hours
			  self.custom_field_values.find{|c| c.custom_field.scrummer_caption == :remaining_hours}.try(:value).try(:to_f)
			end
			
			def remaining_hours=(value)
        (self.custom_field_values.find{|c| c.custom_field.scrummer_caption == :remaining_hours}).value = value
      end
      
      def story_size
        # if the issue has children having the story size custom field
        # then sum children
        # else take issue story size custom field value
        
        if self.children.any?
          result = children.map(&:story_size).sum
        end
        
        if result.to_f == 0.0
          custom_field = CustomField.find_by_scrummer_caption(:story_size)
          format = custom_field.field_format
          custom_value = self.custom_value_for(custom_field)
          value = custom_value ? custom_value.value : '' 
          
          result = (format == "float" ? value.to_f : value.to_i)  
        end
        
        result
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
      
      def has_custom_field?(field_name)
        self.tracker.custom_fields.any?{|field| field.scrummer_caption == field_name.to_sym}
      end
			
			def initiate_remaining_hours
			  if self.remaining_hours == 0.0
			    self.remaining_hours = self.estimated_hours
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
			
			def update_remaining_hours
			  # reset todo hours if completed or accepted
			  if status_id_changed? && (self.status_completed? || self.status_accepted?) && self.remaining_hours.to_f > 0.0
			   self.remaining_hours = 0.0
			   self.save
			  end
			end
			
			def validate_status
			  if self.status_id_changed?
			    # test issues can allow only (defined, success, fail)
  			  if (self.is_test? && !(self.succeeded? || self.failed? || self.status_defined?)) ||
  			     # task allow only (defined, progress, completed)
  			     (self.is_task? && !(self.status_defined? || self.in_progress? || self.completed?)) ||
  			     # non test issues doesn't accept success and fail
    			   (!self.is_test? && (self.succeeded? || self.failed?))
    			   
    			  self.errors.add(:status_id, "invalid status")
    			  return false
  			  end
			  end
			end
		end
	end
end