require 'scrummer_constants'

module ScrumUserstoriesHelper
	def create_story_sizes_combo form
  	form.select :size, Scrummer::Constants::StorySizes.collect{|s| [s, s]}
 	end
end
