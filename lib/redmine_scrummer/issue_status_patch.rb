module RedmineScrummer
	module IssueStatusPatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
				
			  serialize :scrummer_caption   
			  
			  base.all.each do |status|
          base.instance_eval %Q{
            def #{'status_' if status.scrummer_caption==:defined}#{status.scrummer_caption}
              IssueStatus.find_by_scrummer_caption(:#{status.scrummer_caption})
            end
          } unless status.scrummer_caption.blank?
          
        end
      end
      
    end
  end
end