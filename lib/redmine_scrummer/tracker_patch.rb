module RedmineScrummer
	module TrackerPatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
				
	      serialize :scrummer_caption
        validate :color, :format => { :with => /^#([A-Fa-f0-9]{6})$/}

         scope :scrummer, :conditions => {:is_scrum => true}
			end
			
      base.all.each do |tracker|
        caption = tracker.scrummer_caption
        unless caption.blank?
          base.instance_eval %Q{
            def scrum_#{caption}_tracker
              Tracker.find_by_scrummer_caption(:#{caption})
            end
          } 
          
          base.class_eval %Q{
            def #{caption}?
              scrummer_caption == :#{caption}
            end
          } 
        end
      end if base.column_names.include?("scrummer_caption")
      
		end
		
	end
end