module RedmineScrummer
  module VersionPatch
    
    def self.included(base)
      base.class_eval do        
        unloadable # Send unloadable so it will not be unloaded in development
        
        include InstanceMethods   
        
        # Each version (sprint) belongs to only one release
        belongs_to :release
        
        after_update :alter_issues_release
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
    
    end
    
  end
end