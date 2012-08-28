module RedmineScrummer
	module IssueCustomFieldPatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development

				include InstanceMethods
	      serialize :scrummer_caption
			end	
			
		end
	end

	module InstanceMethods
		def possible_values_options(obj=nil)
			if self.scrummer_caption == :release
				# obj can be one of two classes; Issue or Project
				# obj is issue when comming fom Issue default view
				# obj is project whtn comming from building filters partial
				project = obj.is_a?(Issue) ? obj.project : obj
				project.releases.map(&:name)
			else
				super
			end
		end
	end
end

  