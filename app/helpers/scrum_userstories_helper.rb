require 'scrummer_constants'

module ScrumUserstoriesHelper
	def create_story_sizes_combo form
  	form.select :story_size, Scrummer::Constants::StorySizes.collect{|s| [s, s]}
 	end
 	
 	def scrum_issues_list(issues, &block)
 		issues = issues.reverse
 		
 		last_processed_level = 0
 		
 		result = []
 		result_set = {}
 		
 		# build the hierarchy
 		while issues.length > 0

 			processed_issues = []
 			
 			issues.each do |issue|
 				level = get_issue_level issue
 				
 				# get parent location, and insert right after it
 				if level == last_processed_level
 					parent_index = result.index issue.parent
 					
 					# if the this issue has no parent, then it's a root element just add it
 					if parent_index and parent_index >= 0
 						result.insert parent_index + 1, issue
 					else
 						result.insert 0, issue
 					end
 					
 					processed_issues << issue
 				end
 			end
 			
 			issues = issues - processed_issues
 			
	    last_processed_level += 1
   	end
   	
   	# return result
   	result.each do |issue|
      yield issue, get_issue_level(issue)
    end
    
  end
  
  def scrum_column_content(column, issue)
  	value = column.value(issue)
  	
  	if value.class == IssueStatus and issue.status.is_scrum
  		'<b>' + value.short_name + '</b>'
  	elsif column.name == :subject and issue.is_scrum_issue
  		'<b>' + '#' + issue.id.to_s + ' ' + issue.tracker.short_name + ' : ' + column_content(column, issue) 
  	else
  		column_content(column, issue)
  	end
  end
  
  def get_issue_level issue
  	parent = issue
  	level = 0
    while (parent.parent) do
    	parent = parent.parent
    	level += 1
    end
    
    level
  end

end
