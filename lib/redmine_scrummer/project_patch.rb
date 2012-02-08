module RedmineScrummer
  module ProjectPatch
    
    def self.included(base)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        include InstanceMethods 
        
        has_many :releases,
                 :dependent => :destroy
        
        has_one :weekly_vacation, :dependent => :destroy
      end
      
    end
    
    module InstanceMethods
      # This method returns the current sprint of the project if any else returns nil
      def current_sprint
        sprints = self.versions.find(:all, :conditions => ['effective_date >= ?', Date.today])
        sprints.each do |sprint|
          return sprint if sprint.start_date_custom_value <= Date.today
        end
        nil
      end
    end
  end
end
