class ScrumUserstoriesController < IssuesController
  unloadable

	include ScrumUserstoriesHelper
	
	prepend_before_filter :check_for_default_scrum_issue_status_for_inline, :only => [:inline_add]
	prepend_before_filter :check_for_default_scrum_issue_priority_for_inline, :only => [:inline_add]
	
	prepend_before_filter :check_for_default_issue_status, :only => [:index]
	prepend_before_filter :check_for_default_issue_priority, :only => [:index]
	
	prepend_before_filter :find_query, :only => [:index, :refresh_inline_add_form, :inline_add, :update_single_field, :get_inline_issue_form, :issues_list]						# must be called after find_scrum_project
	prepend_before_filter :find_scrum_project, :only => [:index, :refresh_inline_add_form, :inline_add, :update_single_field, :get_inline_issue_form, :issues_list]
	
	before_filter :build_new_issue_from_params, :only => [:index, :refresh_inline_add_form, :inline_add, :get_inline_issue_form]
	before_filter :find_parent_issue, :only => [:get_inline_issue_form, :refresh_inline_add_form]	
	before_filter :set_default_values_from_parent, :only => [:get_inline_issue_form, :refresh_inline_add_form]
	
	def update_single_field
		new_value = params[:value]

    # custom field for todo
		if params[:id] =~ /custom/
			matched_groups = params[:id].match(/issue-(\d+)-custom-field-(.+)/)
			issue_id = matched_groups[1]
			column_name = matched_groups[2].to_sym
			
			query_column = @query.column_with_name column_name
			custom_field = query_column.custom_field			
			
			@issue = Issue.find(issue_id)
			@issue.custom_field_values = {custom_field.id => new_value}
	  
	    if @issue.save
        render :text => new_value
      else
        render :text => 'Errors in saving'
      end
      
	  elsif params[:id] =~ /spent_hours/ && params[:value] =~ /^\+(.*)/
	    # virtual fields like actual 
      matched_groups = params[:id].match(/issue-(\d+)-spent_hours/)
      issue_id = matched_groups[1]
      value = params[:value].match(/^\+(.*)/)[1]
      
      @issue = Issue.find(issue_id)
      @time_entry = TimeEntry.new(:project => @issue.project, :issue => @issue, :user => User.current, :spent_on => User.current.today)
      @time_entry.hours = value
      
      if @time_entry.hours > 0 && @time_entry.save
        render :text => @issue.spent_hours.to_s
      else
        render :text => 'Errors in saving'
      end
      
		elsif params[:id] =~ /-field-/
		  # fields like estimated hours
			matched_groups = params[:id].match(/issue-(\d+)-field-(.+)/)
			issue_id = matched_groups[1]
			column_name = matched_groups[2].to_sym
			
			@issue = Issue.find(issue_id)
			@issue.update_attributes(column_name => new_value)
			
			if @issue.save
        render :text => new_value
      else
        render :text => 'Errors in saving'
      end
    
    elsif params[:id] =~ /-status/
      matched_groups = params[:id].match(/issue-(\d+)-status/)
      issue_id = matched_groups[1]
      @issue = Issue.find(issue_id)

      status = if ["f", "F"].include? params[:value].to_s 
        @issue.is_test? ? IssueStatus.failed : IssueStatus.finished
      else
        IssueStatus.find_by_short_name(params[:value])
      end
      @issue.status = status
      
      allowed_statuses = @issue.new_statuses_allowed_to(User.current)
      
      if !status
        render :text => 'Status invalid'
      elsif  !allowed_statuses.include?(status)
        render :text => 'Status Not Allowed'
      elsif !@issue.save
        render :text => 'Errors in saving'
      else
        render :text => params[:value].upcase
      end 
      
    else
      render :text => 'Errors in saving'
		end
		
	rescue Exception => e
		render :text => 'Exception Occured'
	end
	
	def get_inline_issue_form
		issue_id = params[:issue_id] if params[:issue_id]
		@issue = Issue.find(issue_id) if issue_id
		
		respond_to do |format|
			format.js { render :partial => 'inline_add' }
		end
	end

  def index
  	initialize_sort
    
    if @query.valid?
 			load_issues_for_query
 			
      respond_to do |format|
        format.html 
        format.api
        format.atom { render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}") }
        format.csv  { send_data(issues_to_csv(@issues, @project), :type => 'text/csv; header=present', :filename => 'export.csv') }
        format.pdf  { send_data(issues_to_pdf(@issues, @project, @query), :type => 'application/pdf', :filename => 'export.pdf') }
      end
    else
      # Send html if the query is not valid
      return
    end
  rescue ActiveRecord::RecordNotFound
    render_404    
  end
  
  def issues_list
  	initialize_sort
  	
    load_issues_for_query
    
  	render :partial => 'list'
  end

	def refresh_inline_add_form
    @issue.description = @issue.is_user_story? ? "As a <role> I want to <goal> so that <reason>\nVerification Points:\n<Point1>\n<Point2>":""
    
	  respond_to do |format|
			format.js {render :partial => 'inline_add'}
		end
	end

  def inline_add
  	initialize_sort  	  	
  	
  	call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
    if @query.valid? && @issue.save
    	load_issues_for_query 	
      
      flash[:notice] = l(:notice_successful_create)
   
      call_hook(:controller_issues_new_after_save, { :params => params, :issue => @issue})   		
 			
 			if @issues.length > 0
	 			render :update do |page|
				  page.replace_html "issues_list", :partial => "list", :locals => {:issues => @issues, :query => @query}
				end
			end
 		else
 			render_error_html_for_inline_add(error_messages_for 'issue')			
 		end
 	rescue ActiveRecord::RecordNotFound
    render_404 
  end
        
  protected
		
	def find_parent_issue 
		parent_issue_id = params[:parent_issue_id] if params[:parent_issue_id]
		parent_issue_id ||= params[:issue][:parent_issue_id] if params[:issue] and params[:issue][:parent_issue_id]
		
		@parent_issue = (parent_issue_id and !parent_issue_id.empty?) ? Issue.find(parent_issue_id) : nil 
	end

	def find_query
	  if params[:query_id].blank? && (session[:query].nil? || session[:query][:id].nil?)
	    query = Query.find_by_scrummer_caption('User-Stories')
	    params[:query_id] = query.id
	  end
		retrieve_query
	end
	
	def load_issues_ancestors
	  @issues.each do |issue|
	    if !issue.parent.nil? && !@issues.include?(issue.parent)
	      @issues << issue.parent
	    end
	  end
	end
	
	def load_issues_for_query
		  
		case params[:format]
    when 'csv', 'pdf'
      @limit = Setting.issues_export_limit.to_i
    when 'atom'
      @limit = Setting.feeds_limit.to_i
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    @issue_count = @query.issue_count
    @issue_pages = Paginator.new self, @issue_count, @limit, params['page']
    @offset ||= @issue_pages.current.offset
    
    # all issues is used for statistics
    @all_issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                            :order => sort_clause)
    @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                            :order => sort_clause)
    
    load_issues_ancestors
    
    #build tree heirarachy
    @issues = scrum_issues_list(@issues)
    
    # pagination
    @issues = @issues[(@offst.to_i)..(@offset.to_i+@limit.to_i-1)]
    
    @issue_count_by_group = @query.issue_count_by_group
	end
	
  def set_default_values_from_parent
    if @parent_issue
      @issue.parent_issue_id ||= @parent_issue.id
      @issue.fixed_version ||= @parent_issue.fixed_version
      @issue.assigned_to ||= @parent_issue.assigned_to
     
      # can't user ||= because there is before filter set issue default tracker
      if params[:issue].blank? || params[:issue][:tracker_id].blank?
        @issue.tracker = case @parent_issue.tracker.scrummer_caption
        when :epic
          Tracker.scrum_user_story_tracker
        when :userstory
          Tracker.scrum_task_tracker
        when :defectsuite
          Tracker.scrum_defect_tracker
        when :defect
          Tracker.scrum_defect_tracker
        else
          Tracker.scrum_user_story_tracker
        end
      end
    end
  end 

	def initialize_sort
		sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)
	end
	 
	def find_scrum_project
    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def check_for_default_scrum_issue_priority_for_inline
    if IssueStatus.default.nil?
     	render_error_html_for_inline_add content_tag('p', l(:error_no_default_scrum_issue_priority)) 	
      return false
    end
  end	  	 
  
  def check_for_default_scrum_issue_status_for_inline
    if IssuePriority.default.nil?
      render_error_html_for_inline_add content_tag('p', l(:error_no_default_scrum_issue_status))
      return false
    end
  end
  
  def render_error_html_for_inline_add error_html
  	render :update do |page|
	  	page.replace_html "inline_new_issue_errors", error_html
		end
  end
  
  def check_for_default_issue_status	  
    if IssueStatus.default.nil?
      render_error l(:error_no_default_scrum_issue_status)
      return false
    end
  end
  
  def check_for_default_issue_priority
    if IssuePriority.default.nil?
      render_error l(:error_no_default_scrum_issue_priority)
      return false
    end
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
        level = issue.level
        
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
    result
  end
  
  
end
