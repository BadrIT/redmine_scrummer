module RedmineScrummer
  module CustomValuePatch
    
    def self.included(base)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        
        include InstanceMethods
        
        after_save :sync_column_value
        after_save :sync_release_custome_field_value
        before_validation :add_releases_list_custom_field
      end
      
    end
    
    module InstanceMethods
      
      def sync_column_value
        caption = self.custom_field.scrummer_caption.to_s

        if ['story_size', 'business_value', 'remaining_hours'].include?(caption) &&
          self.customized.send(caption) != self.value.to_f
        
          self.customized.update_attributes(caption.to_sym => self.value.to_f)
        end
      end

      def add_releases_list_custom_field
        if self.customized && custom_field.scrummer_caption == :release
          custom_field.possible_values = self.customized.project.releases.map(&:name)
        end
      end

      def sync_release_custome_field_value
        if self.custom_field.scrummer_caption == :release && self.customized.release &&
           self.customized.release.name != self.value.to_s

          self.customized.update_attributes(:release_id => Release.find_by_name(self.value.to_s).id)
        end
      end

    end
   
  end
end