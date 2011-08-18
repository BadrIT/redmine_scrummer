module RedmineScrummer
  module VersionPatch
    
    def self.included(base)
      base.class_eval do        
        unloadable # Send unloadable so it will not be unloaded in development
        
        include InstanceMethods   
        
      end
      
    end
    
    module InstanceMethods
      
      def buffer_status
        children_size = self.fixed_issues.count(&:story_size)
      end
      
    end
    
  end
end