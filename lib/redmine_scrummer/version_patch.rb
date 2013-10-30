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

        after_destroy :destroy_custom_query
      end
      
    end
    
    module InstanceMethods
      
      def method_missing(m, *args, &block)
        # providing speed access to issues that have specfic tracker e.g. defined_issues will return all defined issues
        if m.to_s =~ /(defined|in_progress|completed|accepted|failed|succeeded|finished)_issues$/
          self.fixed_issues.find(:all, :conditions => ['status_id = ?', IssueStatus.find_by_scrummer_caption($1)])
        else
          super
        end
      end
      
      def user_stories
        fixed_issues.find(:all, :conditions => ['tracker_id = ?', Tracker.find_by_scrummer_caption('userstory').id]).delete_if do |user_story|
          !user_story.with_task_children? && !user_story.childrenless?
        end
      end
      
      # returns the value of the buffer_size custom field or zero if nil
      def buffer_size
        buffer_size_field = VersionCustomField.find_by_scrummer_caption('buffer_size')
        self.custom_value_for(buffer_size_field).try(:value).try(:to_i) || 0
      end
      
      # returns the value of the start_date custom field
      # NOTE: Redmine defines 'start_date' function which return the least date of the all fixed issues
      def start_date_custom_value
        start_date_field = VersionCustomField.find_by_scrummer_caption('start_date')
        value = self.custom_value_for(start_date_field).try(:value)
        value = value.try(:to_date) unless value.blank?
        value
      end

      def version_custom_value
        version_field = VersionCustomField.find_by_scrummer_caption('start_date')
        self.custom_value_for(version_field).try(:value)
      end

      def remaining_working_days(date=Date.today)
        (date..effective_date).to_a.delete_if do |d|
          self.project.non_working_day?(d)
        end
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
        columns =  IssueQuery::SCRUMMER_COLUMNS

        @query = IssueQuery.new(:name => self.name, :group_by =>"", :sort_criteria => ['id asc'], :is_public => true, 
          :column_names => columns, :filters => filters)
        
        @query.user = User.current
        @query.project = project
        
        @query.save
      end

      def destroy_custom_query
        query = project.queries.find_by_name(self.name)
        query.try(:destroy)
      end

      # This method create a retrospective after creating the sprint,
      # this retrospective is represented as a wikipage with default content.
      public
      def build_wiki_page
        wiki_page = self.project.wiki.pages.new(:title => self.name)
        self.wiki_page_title = wiki_page.title
        wiki_page.build_content(:text => I18n.translate('retrospective_default_content'),
                                :author_id => User.current.id)
        wiki_page
      end

    end
    
  end
end