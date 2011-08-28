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
        buffer_size_field = VersionCustomField.find_by_scrummer_caption(:buffer_size)
        self.custom_value.for(buffer_size_field).value.try(:to_i)
      end
      
      # returns the value of the start_date custom field
      def start_date
        start_date_field = VersionCustomField.find_by_scrummer_caption(:start_date)
        self.custom_value.for(start_date_field).value.try(:to_date)
      end
      
    end
    
  end
end