module RedmineScrummer
	module TrackerPatch
		
		def self.included(base)
			base.class_eval do
				unloadable # Send unloadable so it will not be unloaded in development
				
				include InstanceMethods
	
	      serialize :scrummer_caption
				
				def self.method_missing(m, *args, &block)
				  # retreive a specific tracker
				  # ex: Tracker.scrum_task_tracker
				  # ex: Tracker.scrum_userstory_tracker
				  # ex: Tracker.scrum_user_story_tracker
				  if m.to_s =~ /^scrum_(.*)_tracker$/
				    Tracker.find_by_scrummer_caption($1.gsub("_", "").to_sym)
				  else
				    super
				  end
				end
			end
			
		end
		
		module InstanceMethods
			
			def is_user_story?
			  scrummer_caption == :userstory
			end
			
			def is_epic?
			  scrummer_caption == :epic
			end
			
			def is_test?
			  scrummer_caption == :test
			end
			
			def is_theme?
				scrummer_caption == :theme
			end
			
			def is_task?
				scrummer_caption == :task
			end
			
			def defect?
			  scrummer_caption == :defect			 
			end
			
			def defectsuite?
        scrummer_caption == :defectsuite       
      end
      
      def refactor?
        scrummer_caption == :refactor       
      end
      
      def is_spike?
        scrummer_caption == :spike
      end
		end
	end
end