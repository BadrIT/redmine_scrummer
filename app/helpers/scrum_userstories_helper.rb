module ScrumUserstoriesHelper
			
	#unloadable # prevent it from being unloaded in development mode
						 # other wise, a stack overflow exception will be 
						 # thrown due to the alias method chain being called twice
	
	include CustomFieldsHelper unless included_modules.include? CustomFieldsHelper
	
	def column_short_header(column)
	  caption = column.caption
	  
	  short_headers = {l("field_remaining_hours")        => l("short_field_remaining_hours"),
	                   l("field_story_size")  => l("short_field_story_size"),
	                   l("field_estimated_hours") => l("short_field_estimated_hours"),
                     l("field_business_value") => l("short_field_business_value")}

    title = {l("short_field_remaining_hours")        => l("remaining_hours"),
             l("short_field_story_size")  => l("story_size"),
             l("short_field_estimated_hours") => l("estimated_hours")}
	                   
    caption = short_headers[caption] || caption
    
    column.sortable ? sort_header_tag(column.name.to_s, :caption => caption,
                                                        :default_order => column.default_order) : 
                      content_tag('th', caption, :title => title[caption])
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

  	if value.is_a?(IssueStatus) && issue.status.is_scrum
  	  #TODO refactoring cache IssueStatus please :(
  	  content = IssueStatus.find_by_scrummer_caption(value.scrummer_caption).short_name.upcase
  	  
      "<div align='center' class='status #{value.scrummer_caption}' id='issue-#{issue.id}-status' data-statuses=\"#{issue_allowed_statuses(issue)}\"><b>" + content.to_s + "</b></div>"
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
  	elsif column.name == :actual_hours && issue.scrum_issue?
  		content = column_content(column, issue)
        		
  		output_value = value > 0 ? value.round(2).to_s : "&nbsp;"*4
  		if issue.time_trackable?
  		  content = "<div align='center' class='edit float addition' id='issue-#{issue.id}-actual_hours'>" + output_value + "</div>"
  		else
  		  output_value = "Σ" + output_value if !issue.direct_children.empty? && value > 0
  		  content = "<div align='center' class='float addition' id='issue-#{issue.id}-actual_hours'>" + output_value + "</div>"
  		end
  		
  		unless issue.direct_children.empty?
  			content = value > 0 ? "<span align='center' class='accumelated-result'>#{content}</span>" : content
  		end
  		
  		content
  		
    elsif [:story_size, :remaining_hours, :business_value].include?(column.name) && issue.scrum_issue?
      issue_has_children = issue.direct_children.any?  
      
      if (accept_field = issue.send("accept_#{column.name}?")) || issue_has_children
        value = issue.send(column.name)
        
        if accept_field && (column.name == :business_value || !issue_has_children || value.to_f == 0.0)
          content = value.to_f > 0 ? value : ' '*3
          content = format_story_size(content) if column.name == :story_size && content.is_a?(Float)
          css_class = 'edit' unless column.name == :story_size
          format = 'float'  unless column.name == :story_size
          "<div align='center' class='#{css_class} #{format} #{column.name}-container' id='issue-#{issue.id}-field-#{column.name}'>" + content.to_s + "</div>"
        else
          if column.name == :remaining_hours
            output_content = "Σ" + value.to_s
          else
            output_content = format_story_size value.to_f
          end
          content = value.to_f > 0 ? "<span align='center' class='accumelated-result'>#{output_content}</span>" : '&nbsp;';
        end
      else
        # tasks, defects etc shouldn't display story size
        content = ''
      end
      
  	elsif column.respond_to?(:custom_field) && issue.scrum_issue?
			field_format = column.custom_field.field_format
			
			content = '' 
			if ["int", "float", "list"].include?(field_format)
			  value = issue_accumelated_custom_values(issue, column.custom_field)
				
				field_caption = column.custom_field.scrummer_caption
				
				# can be editable if doesn't have children
				# OR having children but all children custom field aren't set then value will equal zero
				# ex: US1 has children (US2, US3) and they don't have story size set then I can edit US1 story size
				if (issue.direct_children.blank? || value.to_f == 0.0) && issue.has_custom_field?(field_caption)
					content = value.to_f > 0 ? value : '&nbsp;'*4
					"<div align='center' class='edit #{field_format}' id='issue-#{issue.id}-custom-field-#{column.name}'>" + content.to_s + "</div>"
			  else
					content = value.to_f > 0 ? "<span align='center' class='accumelated-result'>#{value}</span>" : '&nbsp;';
				end
			else
				content = column_content(column, issue)
			end					
  	elsif column.name == :estimated_hours  		
  		if (issue.direct_children.blank? || value.to_f == 0.0) && issue.time_trackable?
				value ||= 0.0
				
				content = value > 0 ? value : ' '*4
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
    
    options = {:title=>"#{h(issue.subject)}|#{h(description)}", :class=>'subject-contents'}
    
    link_to(h(value), {:controller => 'issues', :action => 'show', :id => issue }, options)
  end
  
  def build_params_for_context_menu
    {:controller => params[:controller], :project_id => @project}
  end
  
  def issue_li_tag(issue)
    unit = issue.userstory? ? "pt":"hr"
    
    if issue.userstory?
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
  
  def scrum_user_stories_manipulate_inline
    @scrum_user_stories_manipulate_inline ||= User.current.allowed_to?(:scrum_user_stories_manipulate_inline, @project)
  end

  def scrum_user_stories_add_inline
    @scrum_user_stories_add_inline ||= User.current.allowed_to?(:scrum_user_stories_add_inline, @project)
  end

  def update_issue_and_parents(page)
    level = params[:hierarchy] == "true" ? @issue.level: 0
    page.replace 'issue-' + @issue.id.to_s, :partial => "issue_row", :locals => {:issue => @issue, :hierarchy => params[:hierarchy] == "true", :query => @query, :level => level, :list_id => params[:list_id], :from_sprint => params[:from_sprint]}
    @issue.ancestors.each do |parent|
      level = params[:hierarchy] == "true" ? parent.level: 0
      page.replace 'issue-' + parent.id.to_s, :partial => "issue_row", :locals => {:issue => parent, :hierarchy => params[:hierarchy] == "true", :query => @query, :level => level, :list_id => params[:list_id], :from_sprint => params[:from_sprint]}
    end
    
    page << "enableInlineEdit();"
  end
  
  def issue_allowed_statuses(issue)
    statuses = "{"
    # issue.new_statuses_allowed_to(User.current).each do |status|
    issue.tracker.issue_statuses.each do |status|
      statuses += "'" + status.short_name + "':'" + status.name + "', "
    end
    statuses += "'selected':'" + issue.status.short_name + "'}"
    statuses
  end
  
  def storysize_possible_values
    possible_sizes = ""
    Scrummer::Constants::StorySizes.each do |value|
      possible_sizes += "'" + value.to_f.to_s + "':'" + value.to_s + "', "
    end
    possible_sizes
  end

  def format_story_size(value)
    if ((value - value.to_i) == 0) 
      value.to_i
    else
      value
    end
  end
end
