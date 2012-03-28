module RedmineScrummer
	module QueryPatch
		
		def self.included(base)
			base.class_eval do				
				unloadable # Send unloadable so it will not be unloaded in development
				
				add_available_column QueryColumn.new(:spent_hours)	
				add_available_column QueryColumn.new(:story_size)	
				add_available_column QueryColumn.new(:position, :sortable => "#{Issue.table_name}.position")
				
				include InstanceMethods		
				
			end
			
		end
		
		module InstanceMethods
			
			def column_with_name column_name
				columns.detect{|c| c.name == column_name}
			end
			
			# This method sets the default columns displayed in the scrum views 
			def default_scrummer_columns
			  #TODO Refactoring CF
        self.column_names = [:subject, :fixed_version, :assigned_to, :story_size, :status, :estimated_hours, :spent_hours, :cf_2]
			end
		end
		
	end
end