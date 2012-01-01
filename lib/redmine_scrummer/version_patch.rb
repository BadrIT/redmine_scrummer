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
      
      # returns the value of the buffer_size custom field or zero if nil
      def buffer_size
        buffer_size_field = VersionCustomField.find_by_scrummer_caption(:buffer_size)
        self.custom_value_for(buffer_size_field).try(:value).try(:to_i) || 0
      end
      
      # returns the value of the start_date custom field
      # NOTE: Redmine defines 'start_date' function which return the least date of the all fixed issues
      def start_date_custom_value
        start_date_field = VersionCustomField.find_by_scrummer_caption(:start_date)
        self.custom_value_for(start_date_field).try(:value).try(:to_date)
      end
      
      protected
      # By Mohamed Magdy
      # This method is called after updating the the version (sprint).
      # The aim of this method is to alter the release id of the issues that belongs to
      # the updated version
      def alter_issues_release
        self.fixed_issues.each do |issue|
          issue.update_attribute(:release_id, self.release_id)
        end
      end
      
      def add_to_side_bar
        filters = {:fixed_version_id => {:operator => "=", :values=>[self.id.to_s]}}
        columns =  [:subject, :fixed_version, :assigned_to, :cf_1, :status, :estimated_hours, :spent_hours, :cf_2] 
        
        @query = Query.new(:name => self.name, :group_by =>"", :sort_criteria => ['id', 'asc'], :is_public => true, 
          :column_names => columns, :filters => filters)
        
        @query.user = User.current
        @query.project = @project
        
        @query.save
      end
    
    end
    
  end
end