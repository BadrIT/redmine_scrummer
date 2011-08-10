module ScrumUserstoriesHelper
			
	#unloadable # prevent it from being unloaded in development mode
						 # other wise, a stack overflow exception will be 
						 # thrown due to the alias method chain being called twice
	
	include CustomFieldsHelper unless included_modules.include? CustomFieldsHelper
	
	def column_short_header(column)
	  todo_column_caption       = IssueCustomField.find_by_scrummer_caption(:remaining_hours).name
	  story_size_column_caption = IssueCustomField.find_by_scrummer_caption(:story_size).name
	  
	  caption = column.caption
	  
	  short_headers = {todo_column_caption        => l("short_field_remaining_hours"),
	                   story_size_column_caption  => l("short_field_story_size"),
	                   l("field_estimated_hours") => l("short_field_estimated_hours")}
	                   
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
 	
 	
  
  def scrum_column_content(column, issue)
  	value = column.value(issue)
  	if value.class == IssueStatus and issue.status.is_scrum
  	  content = case value.scrummer_caption
    	  when :defined
    	    'D'
    	  when :in_progress
    	    'P'
    	  when :completed
    	    'C'
    	  when :accepted
    	    'A'
        when :succeeded
          'S'
        when :failed 
          'F'
        when :finished 
          'F'
  	  end
  	  "<div align='center' class='edit status #{value.scrummer_caption}' id='issue-#{issue.id}-status'>" + content.to_s + "</div>"
  	elsif column.name == :subject and issue.scrum_issue?
  	  prefix = if issue.children.blank? 
  	    "<span>&nbsp;&nbsp;</span>"
      else
        "<span class=\"expander\" onclick=\"toggleScrumRowGroup(this); return false;\" onmouseover=\"$j(this).addClass('hover')\" onmouseout=\"$j(this).removeClass('hover')\">&nbsp;&nbsp;</span>"    
      end   
      
  		"<div class='prefix'>#{prefix}<b><span class='issues-list-issue-id'>##{issue.id.to_s}</span>" +
  		"#{issue.tracker.short_name}</b>:</div>" +
  		"<div class='subject-contents' original-title='#{textilizable issue.description}'>&nbsp;#{column_content(column, issue)}</div>" 
  	elsif column.name == :spent_hours and issue.scrum_issue?
  		content = column_content(column, issue)
  		
  		output_value = value > 0 ? value.round(2).to_s : ""
  		content = "<div align='center' class='edit float addition' id='issue-#{issue.id}-spent_hours'>" + output_value + "</div>"
  		
  		unless issue.children.empty?
  			content = value > 0 ? "<span align='center' class='accumelated-result'>#{content}</span>" : content
  		end
  		
  		content
  	elsif column.respond_to? :custom_field and issue.scrum_issue?
			field_format = column.custom_field.field_format
			
			content = '' 
			if ["int", "float", "list"].include?(field_format)
			  if  column.custom_field.scrummer_caption == :story_size
			    value = issue.story_size
			  else
				  value = issue_accumelated_custom_values(issue, column.custom_field)
				end
				
				field_caption = column.custom_field.scrummer_caption
				
				if (issue.children.blank? || value.to_f == 0.0) && issue.has_custom_field?(field_caption)
				# if issue.children.blank? && issue.has_custom_field?(column.custom_field.scrummer_caption)
					content = value > 0 ? value : ''
					"<div align='center' class='edit #{field_format}' id='issue-#{issue.id}-custom-field-#{column.name}'>" + content.to_s + "</div>"
			  else
					content = value > 0 ? "<span align='center' class='accumelated-result'>#{value}</span>" : '&nbsp;';
				end
			else
				content = column_content(column, issue)
			end					
  	elsif column.name == :estimated_hours  		
  		if (issue.children.blank? || value.to_f == 0.0) && issue.time_trackable?
				value ||= 0.0
				
				content = value > 0 ? value : ''
				"<div align='center' class='edit float' id='issue-#{issue.id}-field-#{column.name}'>" + content.to_s + "</div>"
			else
				content = (value.to_f > 0) ? "<span align='center' class='accumelated-result'>#{value}</span>" : '&nbsp;';
			end			  	
  	else
  		column_content(column, issue)
  	end
  end
  
  def issue_accumelated_custom_values issue, custom_field
  	format = custom_field.field_format
    result = 0.0
  	
  	if issue.children.any? #&& issue.children.any?{|c| c.tracker.custom_fields.include?(custom_field)}  
  		issue.children.each do |child|
  			result += issue_accumelated_custom_values(child, custom_field)
  		end
    end
      		
  	if result == 0.0
  		custom_value = issue.custom_value_for custom_field
  		value = custom_value ? custom_value.value : '' 
  		
  		result=(format == "float" ? value.to_f : value.to_i)  		
  	end
  	
  	result
  end
  
  def custom_column_exists_in_issue? custom_column, issue
  	issue.custom_values.collect{|value| value.custom_field_id}.include? custom_column.custom_field.id
  end
  
  def calculate_statistics(issues, query)
    result = {:total_story_size => 0.0,
              :total_estimate => 0.0,
              :total_actual => 0.0,
              :total_remaining => 0.0}
    
    remaining_hours_column_caption       = IssueCustomField.find_by_scrummer_caption(:remaining_hours).name
    story_size_column_caption = IssueCustomField.find_by_scrummer_caption(:story_size).name
    
    story_column = query.columns.find{|c| c.caption == story_size_column_caption}
    remaining_hours_column = query.columns.find{|c| c.caption == remaining_hours_column_caption}
    
    issues.each do |issue|
      if issue.parent.nil? || issues.exclude?(issue.parent)
        result[:total_estimate] += issue.estimated_hours.to_f
        result[:total_actual]   += issue.spent_hours.to_f
        result[:total_story_size] += issue.story_size 
      end

      result[:total_remaining]  += remaining_hours_column ? remaining_hours_column.value(issue).to_f : 0; 
    end 
    
    result
  end
  
	def scrummer_image_path path
		'../plugin_assets/redmine_scrummer/images/' + path
	end
	
  def to_jss(string)
    string.gsub("\n","\\n")
  end
  
  def get_inline_issue_div_id
    inline_issue_div_id = @issue.new_record? ? "inline_edit_for_#{@issue.id}" : "new_issue_inline_div"
    inline_issue_div_id = @parent_issue ? "inline_add_child_for_#{@parent_issue.id}" : inline_issue_div_id
  end

end
