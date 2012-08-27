module RedmineScrummer
  module CustomValuePatch
    
    def self.included(base)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        
        validate :validate_retrospective_url

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
        return if self.custom_field.scrummer_caption != :release ||
                  self.value.to_s == self.customized.release.try(:name)

        puts "relase will be synced from CF with value: #{self.value}"
        issue = self.customized
        issue.release_id = issue.project.releases.find_by_name(self.value).try(:id)

        issue.send(:update_without_callbacks)
      end

      protected
      
      def validate_retrospective_url
        if self.custom_field.scrummer_caption == :retrospective_url &&
           !self.value.blank? &&
           (self.value.to_s =~ URI::regexp(%w(http https))).nil?

           errors.add(:value, :invalid)
        end
      end

    end
   
  end
end