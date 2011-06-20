module RedmineScrummer
	module QueryPatch
		
		def self.included(base)
			base.class_eval do				
				unloadable # Send unloadable so it will not be unloaded in development
				
				add_available_column QueryColumn.new(:spent_hours)	
				
				include InstanceMethods			
			end
			
		end
		
		module InstanceMethods
			
			def column_with_name column_name
				columns.detect{|c| c.name == column_name}
			end
			
		end
		
	end
end