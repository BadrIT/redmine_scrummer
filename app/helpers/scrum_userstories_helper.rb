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
 	
 	
  
  def scrummy_column_content(column, issue)
  	
    if !issue[:tracker][:is_scrum]
      # fail back to old redmine logic
      return column_content(column, Issue.find(issue["id"]))
    end
      
    if column.name == :status
      content = issue[:status][:short_name].upcase 
  	  
      "<div title='#{issue[:status][:name]}' align='center' class='status #{issue[:status][:scrummer_caption]}' id='issue-#{issue["id"]}-status' data-statuses=\"#{issue_allowed_statuses(issue)}\"><b>" + content.to_s + "</b></div>"  	
    elsif (column.name == :subject)
  	  prefix = if issue[:children].empty?
  	    "<span>&nbsp;&nbsp;</span>"
      else
        "<span class=\"expander\" onclick=\"toggleScrumRowGroup(this); return false;\" onmouseover=\"$(this).addClass('hover')\" onmouseout=\"$(this).removeClass('hover')\">&nbsp;&nbsp;</span>"    
      end
      
      tracker = issue[:tracker]
      
  		"<div class='prefix'>#{prefix}<b><span class='issues-list-issue-id'>##{issue["id"].to_s}</span>" +
  		"<span class='tracker'>#{tracker[:name]}</span></b>:</div>" +
  		"<div >&nbsp;#{subject_content(issue)}</div>" 
    elsif [:story_size, :business_value].include?(column.name) 
      issue_has_children = issue[:children].any?  
      
      
      
      if (accept_field = issue[column.name.to_s] || issue_has_children )
        value = issue[column.name.to_s]
        
        if accept_field && (column.name == :business_value || !issue_has_children || (value != nil && value.to_f == 0.0) )
          content = value.to_f > 0 ? value : ' '*3
          content = format_story_size(content) if column.name == :story_size && content.is_a?(Float)
          css_class = 'edit' unless column.name == :story_size
          format = 'float'  unless column.name == :story_size
          content = "<div align='center' class='#{css_class} #{format} #{column.name}-container' id='issue-#{issue["id"]}-field-#{column.name}'>" + content.to_s + "</div>"
        else
          if column.name == :remaining_hours
            output_content = "&Sigma;" + value.to_s
          else
            output_content = format_story_size value.to_f
          end
          content = value.to_f > 0 ? "<span align='center' class='accumelated-result'>#{output_content}</span>" : '&nbsp;';
        end
      else
        # tasks, defects etc shouldn't display story size
        content = ''
      end
      
      content.to_s
      
    elsif [:actual_hours, :remaining_hours].include?(column.name)
      value = issue[column.name.to_s]
      value ||= 0
      
      elem_id = if column.name == :actual_hours
        issue["id"].to_s+"-"+column.name.to_s
      else
        "issue-" + issue["id"].to_s + "-field-" + column.name.to_s
      end      
      
      edit_method = column.name == :actual_hours ? "addition" : ""
                     
      output_value = value > 0 ? value.round(2).to_s : ""
      if issue[:time_trackable]
        content = "<div align='center' class='edit float #{edit_method}' id='issue-#{elem_id}'>" + output_value + "</div>"
      else
  		  output_value = "&Sigma;" + output_value if value > 0
        content = "<div align='center' class='accumelated-result' id='issue-#{elem_id}'>" + output_value + "</div>"
      end
      
  		content
    elsif column.name == :fixed_version

      if(issue["fixed_version_id"])
        version = issue[:fixed_version]
        link_to(h(version), {:controller => 'versions', :action => 'show', :id => issue["fixed_version_id"] })	     
      else
        ""
      end
    else
      issue[column.name] ? issue[column.name] : ""
    end
    
  end
  
  def issue_accumelated_custom_values issue, custom_field
  	format = custom_field.field_format
    result = 0.0
  	
  	if issue[:children].any? #&& issue.children.any?{|c| c.tracker.custom_fields.include?(custom_field)}  
  		issue[:children].each do |child|
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
    inline_issue_div_id = @issue.new_record? ? "inline_edit_for_#{@issue["id"]}" : "new_issue_inline_div"
    inline_issue_div_id = @parent_issue ? "inline_add_child_for_#{@parent_issue["id"]}" : inline_issue_div_id
  end
  
  def subject_content(issue)
    subject = issue["subject"]
    
    description = issue["description"].gsub("'","\'")
    
    options = {:title=>"#{h(subject)}|#{h(description)}", :class=>'subject-contents'}
    
    link_to(h(subject), {:controller => 'issues', :action => 'show', :id => issue["id"] }, options)
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
    
    "<li class='issue' id='#{issue["id"]}'> 
      <a target='_blank' class='issue #{issue.tracker.try(:scrummer_caption).to_s.downcase}-issue' href='issues/#{issue["id"]}'> 
      <h2>##{issue["id"]}: #{issue.tracker.short_name}</h2>
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
  
  def issue_allowed_statuses(issue)
    statuses = issue[:tracker][:issue_statuses].inject("{") do |memo, status|
      unless status.scrummer_caption.blank?
        memo += "'" + status.short_name + "':'" + status.name + "', "
      end
      
      memo
    end

    statuses += "'selected':'" + issue[:status][:short_name] + "'}"
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
