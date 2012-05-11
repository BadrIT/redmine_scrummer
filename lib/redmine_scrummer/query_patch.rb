module RedmineScrummer
	module QueryPatch
		
		def self.included(base)
			base.class_eval do				
				unloadable # Send unloadable so it will not be unloaded in development
				
				add_available_column QueryColumn.new(:actual_hours)	
				add_available_column QueryColumn.new(:story_size)	
				add_available_column QueryColumn.new(:remaining_hours)	
				add_available_column QueryColumn.new(:business_value)	
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
        self.column_names = [:subject, :fixed_version, :assigned_to, :story_size, :status, :estimated_hours, :actual_hours, :remaining_hours]
			end
		end
		
	end
end