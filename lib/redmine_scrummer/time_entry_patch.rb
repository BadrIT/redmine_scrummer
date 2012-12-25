module RedmineScrummer
  module TimeEntryPatch
    
    def self.included(base)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        
        include InstanceMethods
        
        after_save :update_actual_hours
        after_destroy :update_actual_hours
        
      end
      
    end
    
    module InstanceMethods
      
      protected
      def update_actual_hours
        self.issue.update_actual_hours
      end
    end
  end
end