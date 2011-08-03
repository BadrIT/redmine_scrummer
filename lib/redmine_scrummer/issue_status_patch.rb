module RedmineScrummer
	module IssueStatusPatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
				
			  serialize :scrummer_caption   
			  
			  def self.method_missing(m, *args, &block)
          # check status methods (status_defined?, status_accepted?, completed?, ..etc)
          # method name can be (status_status_name?) OR (status_name?) directly
          # we had to add status_ in some cases like (defined?) because defined? is a ruby keywork
          if m.to_s =~ /^(status_)?(defined|in_progress|completed|accepted|failed|succeeded|finished)$/
            IssueStatus.find_by_scrummer_caption($2.to_sym)
          else
            super
          end
        end
      end
      
    end
  end
end