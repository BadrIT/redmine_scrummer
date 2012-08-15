module RedmineScrummer
  module CustomValuePatch
    
    def self.included(base)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        
        include InstanceMethods
        
        after_save :sync_column_value
      end
      
    end
    
    module InstanceMethods
      
      def sync_column_value
        caption = self.custom_field.scrummer_caption.to_s

        if ['story_size', 'business_value'].include?(caption) &&
          self.customized.send(caption) != self.value.to_f
        
          self.customized.update_attributes(caption.to_sym => self.value.to_f)
        end
      end

    end
   
  end
end