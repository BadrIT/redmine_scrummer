module RedmineScrummer
	module IssuePatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
				
				include InstanceMethods
				
				after_create :initiate_remaining_hours
				after_save :update_remaining_hours
				after_save :update_children_target_versions
				after_save :update_children_release
				
				after_save :update_parent_status
				after_destroy :update_parent_status
				
				after_save :update_story_size
				after_destroy :update_parent_story_size
				
				before_save :init_was_new
				
				after_save :check_history_entries
				after_save :check_points_history
				
				has_many :history,
				         :class_name => 'IssueHistory',
				         :table_name => 'issue_histories',
				         :order      => 'date DESC',
				         :dependent  => :destroy
        
        has_many :points_histories,
                 :order     => 'date DESC',
                 :dependent => :destroy
				
				acts_as_list :scope => :fixed_version
				# the same as .children but it is an association
				# in order to be used in eager loading include
				has_many :direct_children, :foreign_key => :parent_id, :class_name => "Issue"
				belongs_to :direct_parent, :foreign_key => :parent_id, :class_name => "Issue"
				
				belongs_to :release
				
				# backlog issues
				named_scope :sprint_planing, lambda { |*args| {:conditions => ["tracker_id = ? OR tracker_id = ? OR tracker_id = ? OR tracker_id = ? OR tracker_id = ?",
                                                                Tracker.scrum_user_story_tracker.id,
                                                                Tracker.scrum_defect_tracker.id,
                                                                Tracker.scrum_defectsuite_tracker.id,
                                                                Tracker.scrum_refactor_tracker.id,
                                                                Tracker.scrum_spike_tracker.id]} }
                                                                
        named_scope :by_tracker, lambda { |*args| {:conditions => ['tracker_id = ?', args.first]} }
        
        named_scope :backlog, :conditions => {:fixed_version_id => nil}
        
        named_scope :active, lambda { |*args| {:conditions => ["status_id = ? OR status_id = ?",
                                                                IssueStatus.status_in_progress.id,
                                                                IssueStatus.status_defined.id]} }
                                                                
        named_scope :trackable, lambda { |*args| {:conditions => ["tracker_id = ? OR tracker_id = ? OR tracker_id = ? OR tracker_id = ?",
                                                                Tracker.scrum_task_tracker.id,
                                                                Tracker.scrum_defect_tracker.id,
                                                                Tracker.scrum_refactor_tracker.id,
                                                                Tracker.scrum_spike_tracker.id]} }
			end
			
		end
		
		module InstanceMethods
		  def is_test?
		    tracker.try(:is_test?)
		  end
		  
			def scrum_issue?
				tracker.try(:is_scrum?)
			end
			
			def is_user_story?
				tracker.try(:is_user_story?)
			end
			
			def is_epic?
				tracker.try(:is_epic?)
			end
			
			def is_theme?
				tracker.try(:is_theme?)
			end
			
			def is_task?
				tracker.try(:is_task?)
			end
			
			def is_spike?
        tracker.try(:is_spike?)
      end
			
			def defect?
			  tracker.try(:defect?)
			end
			
			def is_refactor?
			  tracker.try(:refactor?)
			end
			
			def time_trackable?
			 self.is_task? || self.defect? || self.is_refactor? || self.is_spike?
		  end
			 
			def remaining_hours
			  self.custom_field_values.find{|c| c.custom_field.scrummer_caption == :remaining_hours}.try(:value).try(:to_f)
			end
			
			def remaining_hours=(value)
        (self.custom_field_values.find{|c| c.custom_field.scrummer_caption == :remaining_hours}).value = value
      end
      
      def level
        parent = self
        level = 0
        while (parent.direct_parent) do
          parent = parent.direct_parent
          level += 1
        end
        
        level
      end
      
      def has_custom_field?(field_name)
        self.tracker.custom_fields.any?{|field| field.scrummer_caption == field_name.to_sym}
      end
			
			def method_missing(m, *args, &block)
			  # check status methods (status_defined?, status_accepted?, completed?, ..etc)
			  # method name can be (status_status_name?) OR (status_name?) directly
			  # we had to add status_ in some cases like (defined?) because defined? is a ruby keywork
			  if m.to_s =~ /^(status_)?(defined|in_progress|completed|accepted|failed|succeeded|finished)\?$/
			    self.status.scrummer_caption == $2.to_sym
			  else
			    super
			  end
			end
			
			def update_status
			  # Defined if all children are defined
			  self.status = if self.children.all?(&:status_defined?)
			    IssueStatus.status_defined 
			  # In-Progress if at least one child is in progress OR defined
			  elsif self.children.any?{|c| c.in_progress? || c.status_defined?} && !self.is_test?
          IssueStatus.in_progress
			  # Completed if all children are completed, accepted OR finished
			  # if user story is accepted don't move to completed, keep it accepted
			  elsif !self.accepted? && self.children.all?{|c| c.completed? || c.accepted? || c.status_finished?} && !self.is_test?
          self.is_task? || self.is_spike? ? IssueStatus.finished : IssueStatus.completed
			  end
			  
			  self.save
			end
			
			def update_story_size(custom_field=nil)
        # if the issue has children having the story size custom field
        # then sum children
        # else take issue story size custom field value
        if self.direct_children.any?
          value = direct_children.sum(:story_size)
        end
        
        if value.to_f == 0.0
          custom_field ||= CustomField.find_by_scrummer_caption(:story_size)
          value = (self.custom_value_for(custom_field).try(:value) || '').to_f
        end
      
        if self.story_size.to_f != value.to_f
          self.update_attribute(:story_size, value)
          self.update_parent_story_size(custom_field)
        end
      end
      
      
			protected
      
      def update_parent_story_size(custom_field=nil)
        self.parent.update_story_size(custom_field) if self.parent
      end
      
			def initiate_remaining_hours
        if self.remaining_hours == 0.0
          self.remaining_hours = self.estimated_hours
          self.save
        end
      end
      
      def update_remaining_hours
        # reset todo hours if completed, accepted or finished
        if status_id_changed? && (self.status_completed? ||self.status_finished? || self.status_accepted?) && self.remaining_hours.to_f > 0.0
         self.remaining_hours = 0.0
         self.save
        end
      end
      
			def update_parent_status
			  if self.status_id_changed? || @was_a_new_record
			    # when a story goes to completed OR accepted, all its children should be completed
			    if self.completed? || self.accepted?
			      self.children.each do |child|
			        if (child.is_task? || child.is_spike?) && (child.status_defined? || child.in_progress?)
			          child.status = IssueStatus.finished
			          child.save
			        elsif child.is_user_story? && (child.status_defined? || child.in_progress? || child.completed?)
                # if moved to completed, move children to completed
                # if moved to accepted, move children to accepted
                child.status = self.status
                child.save
			        end
			      end
			    end
           # update parent status
			    self.parent.update_status if self.parent
			  end
			end
			
			def update_children_target_versions
			  if fixed_version_id_changed? && !self.fixed_version.nil?
			    children.each do |child|
			      if child.fixed_version.nil?
			       child.fixed_version = self.fixed_version
			       child.save
			      end
			    end
			  end
			end
			
      def update_children_release
        if release_id_changed? && !self.release.nil?
          children.each do |child|
            if child.release.nil?
             child.release_id = self.release_id
             child.save
            end
          end
        end
      end
			
			def init_was_new
        @was_a_new_record = self.new_record? if @was_a_new_record.nil?
        return true
      end
			
			public
			
			def check_history_entries
        # Time-Untrackable issues have no history entry
        return unless self.time_trackable?
        
        # get the newest history entry
        history_entry = self.history.first
        
        # there is no history entries for this issue
        if history_entry.nil?
          self.build_history_entry.save
        # it was today's entry just update it
        elsif history_entry.date == Time.now.to_date
          history_entry.update_attributes :actual => self.spent_hours,
                                          :remaining => self.remaining_hours
        # create a new one just in case of new changes occurred
        elsif history_entry.actual != self.spent_hours && history_entry.remaining != self.remaining_hours
          self.build_history_entry.save
        end
      end
      
			def build_history_entry
			  IssueHistory.new :issue_id => self.id,
			                   :actual => self.spent_hours,
		                     :remaining => self.remaining_hours
			end

      def check_points_history
        # User_Stories issues only have points_histories
        return unless self.is_user_story?
        
        # get the newest points_history entry
        points_entry = self.points_histories.first
        
        # there is no history entries for this issue
        if points_entry.nil?
          self.build_points_history_entry.save
        # it was today's entry just update it
        elsif points_entry.date == Time.now.to_date
          points_entry.update_attributes :points => self.story_size
        # create a new one just in case of new changes occurred
        elsif points_entry.points != self.story_size
          self.build_points_history_entry.save
        end
      end
      
      def build_points_history_entry
        PointsHistory.new :issue_id => self.id,
                          :points   => self.story_size || 0.0
      end      
			
		end
	end
end