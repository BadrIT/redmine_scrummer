module RedmineScrummer
  module IssuePatch
    
    def self.included(base)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        
        include InstanceMethods
        
        # adding automatic_calculation to done ratio calculation options
        const_set "DONE_RATIO_OPTIONS", %w(issue_field issue_status automatic_calculation)

        ActiveRecord::Base.lock_optimistically = false
        safe_attributes 'story_size', 'remaining_hours', 'business_value'
        before_create :init_custom_fields_values
        before_create :set_release_CF_value

        before_save :update_remaining_by_estimate
        before_save :update_remaining_hours_by_status

        before_save :update_children_target_versions
        before_save :update_children_release
          
        # set issue release by sprint release
        # set issue sprint to nil if release changed
        before_save :set_issue_release
        before_save :set_done_ratio_value

        # for unknow reason field_changed? doesn't work in after_save callbacks
        # ONLY when using init_journal
        # so that we can them before save and destroy
        # and read the cached changed in the after_save callbacks
        before_save :cache_changes
        before_destroy :cache_changes

        def cache_changes
          @cached_changes = self.changes
        end

        after_save :update_parent_status
        after_save :update_accumulated_fields
        
        after_save :check_history_entries
        after_save :check_points_history

        after_destroy :update_parent_accumulated_fields
        after_destroy :update_parent_status

        has_many :history,
				         :class_name => 'IssueHistory',
				         :table_name => 'issue_histories',
				         :order      => 'date DESC',
				         :dependent  => :delete_all
        
        has_many :points_histories,
                 :order     => 'date DESC',
                 :dependent => :delete_all
        
        acts_as_list :scope => :fixed_version
        # the same as .children but it is an association
        # in order to be used in eager loading include
        has_many :direct_children, :foreign_key => :parent_id, :class_name => "Issue"
        belongs_to :direct_parent, :foreign_key => :parent_id, :class_name => "Issue"
        
        belongs_to :release
        
        # backlog issues
        scope :sprint_planing, lambda { |*args| {:conditions => ["tracker_id = ? OR tracker_id = ? OR tracker_id = ? OR tracker_id = ? OR tracker_id = ?",
            Tracker.scrum_userstory_tracker.id,
            Tracker.scrum_defect_tracker.id,
            Tracker.scrum_defectsuite_tracker.id,
            Tracker.scrum_refactor_tracker.id,
            Tracker.scrum_spike_tracker.id]} }
        
        scope :by_tracker, lambda { |*args| {:conditions => ['tracker_id = ?', args.first]} }
        
        scope :backlog, :conditions => {:fixed_version_id => nil}
        
        scope :active, lambda { |*args| {:conditions => ["status_id in (?)",
            IssueStatus.where('is_closed = ?', false)]} }
        
        scope :trackable, lambda { |*args| {:conditions => ["tracker_id = ? OR tracker_id = ? OR tracker_id = ? OR tracker_id = ? OR tracker_id = ?",
            Tracker.scrum_task_tracker.id,
            Tracker.scrum_defect_tracker.id,
            Tracker.scrum_refactor_tracker.id,
            Tracker.scrum_spike_tracker.id,
            Tracker.scrum_test_tracker.id]} }
      end
      
    end
    
    module InstanceMethods
      def test?
        tracker.try(:test?)
      end
      
      def scrum_issue?
        tracker.try(:is_scrum?)
      end
      
      def userstory?
        tracker.try(:userstory?)
      end
      
      def epic?
        tracker.try(:epic?)
      end
      
      def theme?
        tracker.try(:theme?)
      end
      
      def task?
        tracker.try(:task?)
      end
      
      def spike?
        tracker.try(:spike?)
      end
      
      def defect?
        tracker.try(:defect?)
      end
      
      def is_refactor?
        tracker.try(:refactor?)
      end
      
      def is_defectsuite?
        tracker.try(:defectsuite?)
      end
      
      def time_trackable?
        self.task? || self.defect? || self.is_refactor? || self.spike?
      end
      
      def childrenless?
        !self.children.any?  
      end
      
      def with_task_children?
        self.children.map(&:tracker).map(&:id).include?(Tracker.find_by_scrummer_caption('task').id)
      end
      
      def issue_tasks
        self.children.map{|child| child if child.task?}.delete_if{|child| child.nil?}  
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
      
      def accept_story_size?
        [:userstory, :epic, :theme, :defectsuite].include?(self.tracker.scrummer_caption)
      end

      def accept_business_value?
        [:userstory, :epic, :theme, :defectsuite].include?(self.tracker.scrummer_caption)
      end
      
      def accept_remaining_hours?
        [:task, :defect, :refactor, :spike].include?(self.tracker.scrummer_caption)
      end
      
      def has_custom_field?(field_name)
        self.tracker.custom_fields.any?{|field| field.scrummer_caption == field_name.to_sym}
      end
      
      def status_in?(statuses)
        statuses.include?(self.status.scrummer_caption)
      end
      
      def tracker_in?(trackers)
        trackers.include?(self.tracker.scrummer_caption)
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
        elsif self.children.any?{|x| x.in_progress? || x.status_defined?} && !self.test?
          IssueStatus.in_progress
          # Completed if all children are completed, accepted OR finished
          # if user story is accepted don't move to completed, keep it accepted
        elsif !self.accepted? && self.children.all?{|c| c.completed? || c.accepted? || c.status_finished?} && !self.test?
          self.task? || self.spike? ? IssueStatus.finished : IssueStatus.completed
        end
        
        self.save
      end
      
      def update_accumulated_fields
        # if the issue has children having the story size custom field
        # then sum children
        # else take issue story size custom field value
        [:story_size, :remaining_hours, :actual_hours].each do |field|
          if !@cached_changes["#{field}"].blank?
            if self.direct_children.any?
              update_accumulated_field(field)
            else
              update_parent_accumulated_field(field)
            end
          end
        end
      end
      
      def update_accumulated_field(field)
        value = self.direct_children.sum(field)
            
        if self.send(field).to_f != value.to_f
          self.update_attribute(field, value)
          self.update_parent_accumulated_field(field) 
        end
      end

      def unduplicated_custom_values
        duplicated_fields = [:story_size, :remaining_hours, :business_value, :release]
        self.custom_field_values.delete_if {|cfv| duplicated_fields.include?(cfv.custom_field.scrummer_caption)}
      end

      def story_size=(value)
        write_attribute(:story_size, value)
        self.custom_field_values = {CustomField.scrum_story_size.id.to_s => value.to_f.to_s}
      end

      def remaining_hours=(value)
        write_attribute(:remaining_hours, value)
        self.custom_field_values = {CustomField.scrum_remaining_hours.id.to_s => value.to_s}
      end

      def business_value=(value)
        write_attribute(:business_value, value)
        self.custom_field_values = {CustomField.scrum_business_value.id.to_s => value.to_s}
      end

      def release_id=(value)
        write_attribute(:release_id, value)
        self.custom_field_values = {CustomField.scrum_release.id.to_s => project.releases.find_by_id(value).try(:name)}
      end
      
      protected
      def update_parent_accumulated_fields
        [:story_size, :remaining_hours, :actual_hours].each do |field|
          update_parent_accumulated_field(field)
        end
      end
      
      def update_parent_accumulated_field(field)
        self.parent.update_accumulated_field(field) if self.parent
      end
      
      def update_parent_status
        # check for id_changed to handle after_create
        if !@cached_changes['status_id'].blank? || !@cached_changes['id'].blank?
          # when a story goes to completed OR accepted, all its children should be completed
          if self.status_in?([:completed, :accepted])
            self.children.each do |child|
              child_tracker = child.tracker
              
              if (child_tracker.task? || child_tracker.spike?) && child.status_in?([:defined, :in_progress]) && child.status != IssueStatus.finished
                child.status = IssueStatus.finished
                child.save
              elsif child_tracker.userstory? && child.status_in?([:defined, :in_progress, :completed]) && child.status != self.status
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
        if self.fixed_version_id_changed? && !self.fixed_version.nil?
          self.children.each do |child|
            child.fixed_version = self.fixed_version
            child.save
          end
        end
      end
      
      def update_children_release
        if self.release_id_changed? && !self.release.nil?
          self.children.each do |child|
            child.release_id = self.release_id
            child.save
          end
        end
      end
      
      def update_remaining_hours_by_status
        # reset todo hours if completed, accepted or finished
        if self.accept_remaining_hours? && status_id_changed? && 
          self.remaining_hours.to_f > 0.0 && self.status_in?([:completed, :finished, :accepted]) 

          self.remaining_hours = 0.0
        end
      end

      def update_remaining_by_estimate
        if self.accept_remaining_hours? && 
          self.estimated_hours_changed? && self.status_defined? && !self.remaining_hours_changed?

          self.remaining_hours = self.estimated_hours
        end
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
          history_entry.update_attributes :actual => self.actual_hours,
                                          :remaining => self.remaining_hours
          # create a new one just in case of new changes occurred
        elsif history_entry.actual != self.actual_hours || history_entry.remaining != self.remaining_hours
          self.build_history_entry.save
        end
      end
      
      def build_history_entry
        IssueHistory.new :issue_id => self.id,
                         :date => Time.now.to_date,
			                   :actual => self.actual_hours,
		                     :remaining => self.remaining_hours
      end
      
      def check_points_history
        # User_Stories issues only have points_histories
        return if self.time_trackable?
        
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
                          :date => Time.now.to_date,
                          :points   => self.story_size || 0.0
      end      
      
      # By Mohamed Magdy
      # Called after creating an issue
      def set_issue_release
        unless @blocked
          @blocked = true
          
          if self.fixed_version && self.fixed_version_id_changed?
            # The case that the sprint ID is changed,
            # change the issue release ID to match 
            # the sprint release 
            self.release = self.fixed_version.release
          end
          
          if self.release
            # The case that the release ID is changed
            # and the issue sprint is not included in the release
            # set the release ID to nill
            if self.release_id_changed? && !self.release.versions.include?(self.fixed_version)
              self.fixed_version = nil
            end
          end
        end
      end

      def set_release_CF_value
        if self.new_record?
          field = IssueCustomField.find_by_scrummer_caption('release')
          field_value = self.custom_values.select{|cv| cv.custom_field_id == field.id}.try(:first)

          field_value.value = self.release.try(:name) if field_value
        end
      end

      # set the values of the custom values in the memory before creation to stop race from custom values
      def init_custom_fields_values
        ['story_size', 'business_value', 'remaining_hours'].each do |caption|
          if self.send("accept_#{caption}?")
            next unless (field = IssueCustomField.find_by_scrummer_caption(caption))
            
            field_value = self.custom_values.select{|cv| cv.custom_field_id == field.id}.try(:first)
            field_value.value = self.send(caption).to_s if (field_value && field_value.value == field.default_value)
          end
        end
      end

      def set_done_ratio_value
        return if Setting.issue_done_ratio != "automatic_calculation"
        
        if !done_ratio_changed? && (actual_hours_changed? || remaining_hours_changed?) 

          self.done_ratio = if actual_hours.to_f == 0.0 
            0.0
          else
            ((actual_hours / (actual_hours + remaining_hours.to_f)) * 10).round * 10
          end
        end
      end

      def update_actual_hours
        self.actual_hours = self.time_entries.sum(:hours)
        self.save
      end
    end
  end
end