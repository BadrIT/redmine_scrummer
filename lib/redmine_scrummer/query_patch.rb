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
				
				const_set "SCRUMMER_COLUMNS", [:subject, :fixed_version, :assigned_to, :story_size, :business_value, :status, :actual_hours, :remaining_hours]
				include InstanceMethods		

				# this is the way for overriding methods from modules
				# Ref: http://erniemiller.org/2011/02/03/when-to-use-alias_method_chain/
				# def alias_method_chain(target, feature)
				# 	alias_method "#{target}without#{feature}", target
				# 	alias_method target, "#{target}with#{feature}"
				# end
				alias_method_chain  :available_filters, :scrum_filters 
				
			end
			
		end
		
		module InstanceMethods
		  # adding new field to the available filters to make it available in the query filters
		  def add_to_available_filters(field, type, options={})
		    @available_filters_patcheds ||= {}
		    @available_filters[field] = {:type => type,
		    														 :format => type.to_s,
		                                 :order => (options[:order] || 21),
		                                 :values => options[:values],
		                                 :name => I18n.translate("field_#{field}")}       
		  end

		  def add_scrum_columns_available_filters
		    add_to_available_filters("remaining_hours", :integer)
		    add_to_available_filters("business_value", :integer)
		    add_to_available_filters("story_size", :integer)
		    add_to_available_filters("release_id", :list_optional, :values => self.project.releases.collect{|r| [r.name, r.id]}) if self.project
		  end

		  def available_filters_with_scrum_filters
		  	available_filters_without_scrum_filters
		  	add_scrum_columns_available_filters
		  	@available_filters
		  end

			def column_with_name column_name
				columns.detect{|c| c.name == column_name}
			end
			
			# This method sets the default columns displayed in the scrum views 
			def default_scrummer_columns
        self.column_names = Query::SCRUMMER_COLUMNS
			end

		end
		
	end
end