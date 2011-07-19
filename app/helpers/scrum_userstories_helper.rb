module ScrumUserstoriesHelper
			
	#unloadable # prevent it from being unloaded in development mode
						 # other wise, a stack overflow exception will be 
						 # thrown due to the alias method chain being called twice
	
	include CustomFieldsHelper unless included_modules.include? CustomFieldsHelper
	
	def column_short_header(column)
	  todo_column_caption       = IssueCustomField.find_by_scrummer_caption(:remaining_hours).name
	  story_size_column_caption = IssueCustomField.find_by_scrummer_caption(:story_size).name
	  
	  caption = column.caption
	  
	  short_headers = {todo_column_caption        => "TODO",
	                   story_size_column_caption  => "Size",
	                   l("field_estimated_hours") => "Estimate"}
	                   
    caption = short_headers[caption] || caption
	  
    column.sortable ? sort_header_tag(column.name.to_s, :caption => caption,
                                                        :default_order => column.default_order) : 
                      content_tag('th', caption)
  end
  
	def custom_field_tag_with_add_class_to_float_inputs(name, custom_value)	
	  custom_field = IssueCustomField.find(custom_value.custom_field_id)
    field_name = "#{name}[custom_field_values][#{custom_field.id}]"
    field_id = "#{name}_custom_field_values_#{custom_field.id}"

    field_format = Redmine::CustomFieldFormat.find_by_name(custom_field.field_format)
    
    case field_format.try(:edit_as)
    when "float"    	    
    	text_field_tag(field_name, custom_value.value, :id => field_id, :class => 'custom_field_float_type')
    else
      custom_field_tag_without_add_class_to_float_inputs(name, custom_value)
    end
  end
	alias_method_chain :custom_field_tag, :add_class_to_float_inputs  unless method_defined?(:custom_field_tag_without_add_class_to_float_inputs)
 	
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
  	  case value.scrummer_caption
    	  when :defined
    	    '<b>D</b>'
    	  when :in_progress
    	    '<b>DP</b>'
    	  when :completed
    	    '<b>DPC</b>'
    	  when :accepted
    	    '<b>DPCA</b>'
  	  end
  	elsif column.name == :subject and issue.scrum_issue?
  	  prefix = if issue.children.blank? 
  	    if issue.is_scrum_task?
  	     "<span>&nbsp;&nbsp;</span>"
  	    else
  	     "<span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>"
  	    end
      else
        "<span class=\"expander\" onclick=\"toggleScrumRowGroup(this); return false;\" onmouseover=\"$j(this).addClass('hover')\" onmouseout=\"$j(this).removeClass('hover')\">&nbsp;&nbsp;</span>"    
      end   
      
  		"<div class='prefix'>#{prefix}<b><span class='issues-list-issue-id'>##{issue.id.to_s}</span>" +
  		"#{issue.tracker.short_name}</b>:</div>" +
  		"<div class='subject-contents' original-title='#{issue.description}'>&nbsp;#{column_content(column, issue)}</div>" 
  	elsif column.name == :spent_hours and issue.scrum_issue?
  		content = column_content(column, issue)
  		
  		output_value = value > 0 ? value.to_s : ""
  		content = "<div align='center' class='edit float addition' id='issue-#{issue.id}-spent_hours'>" + output_value + "</div>"
  		
  		unless issue.children.empty?
  			content = value > 0 ? "<span align='center' class='accumelated-result'>#{content}</span>" : content
  		end
  		
  		content
  	elsif column.respond_to? :custom_field and issue.scrum_issue?
			field_format = column.custom_field.field_format
			
			content = '' 
			if ["int", "float"].include? field_format 
				value = issue_accumelated_custom_values(issue, column.custom_field)
				if issue.children.length > 0 or !issue.is_scrum_task?
					content = value > 0 ? "<span align='center' class='accumelated-result'>#{value}</span>" : '&nbsp;';
				else
					content = value > 0 ? value : ''
					"<div align='center' class='edit #{field_format}' id='issue-#{issue.id}-custom-field-#{column.name}'>" + content.to_s + "</div>"
				end
			else
				content = column_content(column, issue)
			end					
  	elsif column.name == :estimated_hours  		
  		if issue.children.length > 0 or !issue.is_scrum_task?
				content = value and value > 0 ? "<span align='center' class='accumelated-result'>#{value}</span>" : '&nbsp;';
			else
				value ||= 0
				
				content = value > 0 ? value : ''
				"<div align='center' class='edit float' id='issue-#{issue.id}-field-#{column.name}'>" + content.to_s + "</div>"
			end			  	
  	else
  		column_content(column, issue)
  	end
  end
  
  def issue_accumelated_custom_values issue, custom_field
  	format = custom_field.field_format
  	unless issue.children.empty?  
  		result = 0
  		issue.children.each do |child|
  			result += issue_accumelated_custom_values child, custom_field
  		end
  		
  		result  		  		
  	else
  		custom_value = issue.custom_value_for custom_field
  		value = custom_value ? custom_value.value : '' 
  		
  		format == "float" ? value.to_f : value_to_i  		
  	end
  end
  
  def custom_column_exists_in_issue? custom_column, issue
  	issue.custom_values.collect{|value| value.custom_field_id}.include? custom_column.custom_field.id
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

  def calculate_statistics(issues, query)
    result = {:total_story_size => 0.0,
              :total_estimate => 0.0,
              :total_actual => 0.0,
              :total_remaining => 0.0}
    
    todo_column_caption       = IssueCustomField.find_by_scrummer_caption(:remaining_hours).name
    story_size_column_caption = IssueCustomField.find_by_scrummer_caption(:story_size).name
    
    story_column = query.columns.find{|c| c.caption == story_size_column_caption}
    to_do_column = query.columns.find{|c| c.caption == todo_column_caption}
    
    scrum_issues_list(issues) do |issue, level|
      if issue.parent.nil? || issues.exclude?(issue.parent)
        result[:total_estimate] += issue.estimated_hours.to_f
        result[:total_actual]   += issue.spent_hours.to_f
      end
      
      result[:total_story_size] += story_column.value(issue).to_f 
      result[:total_remaining]  += to_do_column.value(issue).to_f 
    end 
    
    result
  end
  
	def scrummer_image_path path
		'../plugin_assets/redmine_scrummer/images/' + path
	end
end
