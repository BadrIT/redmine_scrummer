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
	  custom_field = CustomField.find(custom_value.custom_field_id)
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

  	if value.class == IssueStatus && issue.status.is_scrum
  	  content = case value.scrummer_caption
    	  when :defined
    	    IssueStatus.find_by_scrummer_caption(:defined).short_name.upcase
    	  when :in_progress
    	    IssueStatus.find_by_scrummer_caption(:in_progress).short_name.upcase
    	  when :completed
    	    IssueStatus.find_by_scrummer_caption(:completed).short_name.upcase
    	  when :accepted
    	    IssueStatus.find_by_scrummer_caption(:accepted).short_name.upcase
        when :succeeded
          IssueStatus.find_by_scrummer_caption(:succeeded).short_name.upcase
        when :failed 
          IssueStatus.find_by_scrummer_caption(:failed).short_name.upcase
        when :finished 
          IssueStatus.find_by_scrummer_caption(:finished).short_name.upcase
  	  end
  	  "<div align='center' class='status #{value.scrummer_caption}' id='issue-#{issue.id}-status'>" + content.to_s + "</div>"
  	elsif column.name == :subject
  	  prefix = if issue.direct_children.blank? 
  	    "<span>&nbsp;&nbsp;</span>"
      else
        "<span class=\"expander\" onclick=\"toggleScrumRowGroup(this); return false;\" onmouseover=\"$j(this).addClass('hover')\" onmouseout=\"$j(this).removeClass('hover')\">&nbsp;&nbsp;</span>"    
      end
      
      tracker_name = issue.tracker.short_name.empty? ?  issue.tracker.name : issue.tracker.short_name
  		"<div class='prefix'>#{prefix}<b><span class='issues-list-issue-id'>##{issue.id.to_s}</span>" +
  		"#{tracker_name}</b>:</div>" +
  		"<div >&nbsp;#{subject_content(column, issue)}</div>" 
  	elsif column.name == :spent_hours && issue.scrum_issue?
  		content = column_content(column, issue)
        		
  		output_value = value > 0 ? value.round(2).to_s : ""
  		if issue.time_trackable?
  		  content = "<div align='center' class='edit float addition' id='issue-#{issue.id}-spent_hours'>" + output_value + "</div>"
  		else
  		  output_value = "Σ" + output_value if !issue.direct_children.empty? && value > 0
  		  content = "<div align='center' class='float addition' id='issue-#{issue.id}-spent_hours'>" + output_value + "</div>"
  		end
  		
  		unless issue.direct_children.empty?
  			content = value > 0 ? "<span align='center' class='accumelated-result'>#{content}</span>" : content
  		end
  		
  		content
  	elsif column.respond_to?(:custom_field) && issue.scrum_issue?
			field_format = column.custom_field.field_format
			
			content = '' 
			if ["int", "float", "list"].include?(field_format)
			  if  column.custom_field.scrummer_caption == :story_size
			    value = issue.story_size
			  else
				  value = issue_accumelated_custom_values(issue, column.custom_field)
				end
				
				field_caption = column.custom_field.scrummer_caption
				
				# can be editable if doesn't have children
				# OR having children but all children custom field aren't set then value will equal zero
				# ex: US1 has children (US2, US3) and they don't have story size set then I can edit US1 story size
				if (issue.direct_children.blank? || value.to_f == 0.0) && issue.has_custom_field?(field_caption)
					content = value.to_f > 0 ? value : ''
					"<div align='center' class='edit #{field_format}' id='issue-#{issue.id}-custom-field-#{column.name}'>" + content.to_s + "</div>"
			  else
			    if field_caption == :remaining_hours
			      output_content = "Σ" + value.to_s
			    else
			      output_content = value.to_s
			    end
					content = value.to_f > 0 ? "<span align='center' class='accumelated-result'>#{output_content}</span>" : '&nbsp;';
				end
			else
				content = column_content(column, issue)
			end					
  	elsif column.name == :estimated_hours  		
  		if (issue.direct_children.blank? || value.to_f == 0.0) && issue.time_trackable?
				value ||= 0.0
				
				content = value > 0 ? value : ''
				"<div align='center' class='edit float' id='issue-#{issue.id}-field-#{column.name}'>" + content.to_s + "</div>"
			else
				content = (value.to_f > 0) ? "<span align='center' class='accumelated-result'>Σ#{value}</span>" : '&nbsp;';
			end			  	
  	else
  		column_content(column, issue)
  	end
  end
  
  def issue_accumelated_custom_values issue, custom_field
  	format = custom_field.field_format
    result = 0.0
  	
  	if issue.direct_children.any? #&& issue.children.any?{|c| c.tracker.custom_fields.include?(custom_field)}  
  		issue.direct_children.each do |child|
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
    
    remaining_hours_column_caption = IssueCustomField.find_by_scrummer_caption(:remaining_hours).name
    story_size_column_caption = IssueCustomField.find_by_scrummer_caption(:story_size).name
    
    story_column = query.columns.find{|c| c.caption == story_size_column_caption}
    remaining_hours_column = query.columns.find{|c| c.caption == remaining_hours_column_caption}
    
    issues.each do |issue|
      # don't add story size if an issue having children having story sizes
      unless issue.direct_children.sum(:story_size) > 0.0
        result[:total_story_size] += issue.story_size
      end
      
      # don't add estimate if an issue having children having estimated hours
      unless issue.direct_children.sum(:estimated_hours) > 0.0
        result[:total_estimate] += issue.estimated_hours.to_f 
      end
      
      result[:total_actual]    += issue.time_entries.sum(:hours) 
      result[:total_remaining] += remaining_hours_column ? remaining_hours_column.value(issue).to_f : 0; 
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
  
  def subject_content(column , issue)
    value = column.value(issue)
    description = textilizable(issue.description).gsub("'","\'")
    
    options = {:title=>"#{issue.subject}|#{description}", :class=>'subject-contents'}
    
    link_to(h(value), {:controller => 'issues', :action => 'show', :id => issue }, options)
  end
  
  def build_params_for_context_menu
    {:controller => params[:controller], :project_id => @project}
  end
  
  def issue_li_tag(issue)
    unit = issue.has_custom_field?(:story_size) ? "pt":"hr"
    
    if issue.has_custom_field?(:story_size)
      value = issue.story_size
    else 
      value = issue.remaining_hours
    end
    
    "<li class='issue' id='#{issue.id}'> 
      <a target='_blank' class='issue #{issue.tracker.try(:scrummer_caption).to_s.downcase}-issue' href='issues/#{issue.id}'> 
      <h2>##{issue.id}: #{issue.tracker.short_name}</h2>
      <p>#{truncate(issue.subject, :length => 30)}</p> 
      <p><span style='color: #444; float: right;'>#{pluralize(value, unit)}</span></p> 
      </a> 
     </li>"
  end
  
  def update_issue_and_parents(page)
    level = params[:hierarchy] == "true" ? @issue.level: 0
    page.replace 'issue-' + @issue.id.to_s, :partial => "issue_row", :locals => {:issue => @issue, :hierarchy => params[:hierarchy] == "true", :query => @query, :level => level, :list_id => params[:list_id], :from_sprint => params[:from_sprint]}
    @issue.ancestors.each do |parent|
      level = params[:hierarchy] == "true" ? parent.level: 0
      page.replace 'issue-' + parent.id.to_s, :partial => "issue_row", :locals => {:issue => parent, :hierarchy => params[:hierarchy] == "true", :query => @query, :level => level, :list_id => params[:list_id], :from_sprint => params[:from_sprint]}
    end
  end
  
  def update_issue_childrens
    level = params[:hierarchy] == "true" ? @issue.level: 0
    @issue.children.each do |children|
      level = params[:hierarchy] == "true" ? children.level: 0
      page.replace 'issue-' + children.id.to_s, :partial => "issue_row", :locals => {:issue => children, :hierarchy => params[:hierarchy] == "true", :query => @query, :level => level, :list_id => params[:list_id], :from_sprint => params[:from_sprint]}
    end
  end
  
  def issue_allowed_statuses(issue)
    statuses = "{"
    issue.new_statuses_allowed_to(User.current).each do |status|
      statuses += "'" + status.short_name + "':'" + status.name + "', "
    end
    statuses += "'selected':'" + issue.status.short_name + "'}"
    statuses
  end
end
