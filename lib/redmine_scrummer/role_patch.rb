module RedmineScrummer
	module RolePatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
				
        serialize :scrummer_caption   
      end
      
    end
  end
end