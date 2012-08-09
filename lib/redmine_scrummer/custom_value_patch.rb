module RedmineScrummer
  module CustomValuePatch
    
    def self.included(base)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        
        include InstanceMethods
        
        after_save :sync_story_size
      end
      
    end
    
    module InstanceMethods
      def sync_story_size
        if self.custom_field.scrummer_caption == :story_size &&
          self.customized.story_size.to_s != self.value
          
          self.customized.update_attributes(:story_size => self.value.to_f)
        end
      end
    end
   
  end
end