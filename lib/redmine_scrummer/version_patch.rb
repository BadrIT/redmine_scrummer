module RedmineScrummer
  module VersionPatch
    
    def self.included(base)
      base.class_eval do        
        unloadable # Send unloadable so it will not be unloaded in development
        
        include InstanceMethods   
        
      end
      
    end
    
    module InstanceMethods
      
      # returns the value of the buffer_size custom field
      def buffer_size
        buffer_size_field_id = VersionCustomField.find_by_scrummer_caption(:buffer_size).id
        
        buffer_size_field = self.custom_field_values.find {|field| field.custom_field_id = buffer_size_field_id}
        
        buffer_size_field.value.to_i
      end
      
    end
    
  end
end