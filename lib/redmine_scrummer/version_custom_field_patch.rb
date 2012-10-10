module RedmineScrummer
	module VersionCustomFieldPatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
			end	
			
      def scrummer_caption
        read_attribute(:scrummer_caption).try(:to_sym)
      end
		end
	end

end