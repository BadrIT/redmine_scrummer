module RedmineScrummer
  module VersionPatch
    
    def self.included(base)
      base.class_eval do        
        unloadable # Send unloadable so it will not be unloaded in development

        include InstanceMethods

        # Each version (sprint) belongs to only one release
        belongs_to :release
        
        after_update :alter_issues_release
        
        after_create :add_to_side_bar
      end
      
    end
    
    module InstanceMethods
      
      def defined_issues
        self.fixed_issues.find(:all, :conditions => ['status_id = ?', 1])
      end
      
      def in_progress_issues
        self.fixed_issues.find(:all, :conditions => ['status_id = ?', 2])
      end
      
      def to_be_verified_issues
        self.fixed_issues.find(:all, :conditions => ['status_id = ?', 3])
      end
      
      def done_issues
        self.fixed_issues.find(:all, :conditions => ['status_id = ?', 4])
      end
      
      def user_stories
        self.fixed_issues.find(:all, :conditions => ['tracker_id = ?', Tracker.find_by_scrummer_caption(:userstory).id]).map{|user_story| user_story if user_story.with_task_children? || user_story.childrenless?}.delete_if{|user_story| user_story.nil?}
      end
      
      def defects
        self.fixed_issues.find(:all, :conditions => ['tracker_id = ?', Tracker.find_by_scrummer_caption(:defect).id])
      end
            
      # returns the value of the buffer_size custom field or zero if nil
      def buffer_size
        buffer_size_field = VersionCustomField.find_by_scrummer_caption(:buffer_size)
        self.custom_value_for(buffer_size_field).try(:value).try(:to_i) || 0
      end
      
      # returns the value of the start_date custom field
      # NOTE: Redmine defines 'start_date' function which return the least date of the all fixed issues
      def start_date_custom_value
        start_date_field = VersionCustomField.find_by_scrummer_caption(:start_date)
        value = self.custom_value_for(start_date_field).try(:value)
        value = value.try(:to_date) unless value.blank?
        value
      end

      def version_custom_value
        version_field = VersionCustomField.find_by_scrummer_caption(:start_date)
        self.custom_value_for(version_field).try(:value)
      end
      
      protected
      # By Mohamed Magdy
      # This method is called after updating the the version (sprint).
      # The aim of this method is to alter the release id of the issues that belongs to
      # the updated version
      def alter_issues_release
        self.fixed_issues.update_all(:release_id => self.release_id)
      end

      def add_to_side_bar
        filters = {"fixed_version_id" => {:operator => "=", :values => [self.id.to_s]}, "status_id" => {:values => ["1"], :operator => "*"}}
        columns =  [:subject, :fixed_version, :assigned_to, :story_size, :status, :estimated_hours, :actual_hours, :remaining_hours] 
        
        @query = Query.new(:name => self.name, :group_by =>"", :sort_criteria => ['id asc'], :is_public => true, 
          :column_names => columns, :filters => filters)
        
        @query.user = User.current
        @query.project = @project
        
        @query.save
      end
      
      # This method create a retrospective after creating the sprint,
      # this retrospective is represented as a wikipage with default content.
      public
      def build_wiki_page
        wikiPage = self.project.wiki.pages.new(:title => self.name)
        self.wiki_page_title = wikiPage.title
        wikiPage.build_content(:text => I18n.translate('retrospective_default_content'),
                                :author_id => User.current)
        wikiPage
      end

    end
    
  end
end