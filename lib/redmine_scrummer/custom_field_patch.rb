module RedmineScrummer
  module CustomFieldPatch
    
    def self.included(base)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        
        scope :scrummer, :conditions => "scrummer_caption is not null" 
      end
      
      base.scrummer.all.each do |cf|
        caption = cf.scrummer_caption
        unless caption.blank?
          base.instance_eval %Q{
            def scrum_#{caption}
              CustomField.find_by_scrummer_caption("#{caption}")
            end
          } 
        end
      end if base.column_names.include?("scrummer_caption")
      

      def scrummer_caption
        read_attribute(:scrummer_caption).try(:to_sym)
      end
    end
    
  end
end