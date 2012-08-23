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
				
			  def add_custom_fields_filters(custom_fields)
			    @available_filters ||= {}

			    custom_fields.select(&:is_filter?).each do |field|
			      case field.field_format
			      when "text"
			        options = { :type => :text, :order => 20 }
			      when "list"
			        options = { :type => :list_optional, :values => field.possible_values, :order => 20}
			      when "date"
			        options = { :type => :date, :order => 20 }
			      when "bool"
			        options = { :type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]], :order => 20 }
			      when "user", "version", "release"
			        next unless project
			        options = { :type => :list_optional, :values => field.possible_values_options(project), :order => 20}
			      else
			        options = { :type => :string, :order => 20 }
			      end
			      @available_filters["cf_#{field.id}"] = options.merge({ :name => field.name })
			    end
			  end

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