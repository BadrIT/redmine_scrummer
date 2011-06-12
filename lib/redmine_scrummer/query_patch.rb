module RedmineScrummer
	module QueryPatch
		
		def self.included(base)
			base.class_eval do				
				unloadable # Send unloadable so it will not be unloaded in development
				
				add_available_column QueryColumn.new(:story_size, :sortable => "#{Issue.table_name}.story_size", :groupable => true)				
			end
			
		end
		
	end
end