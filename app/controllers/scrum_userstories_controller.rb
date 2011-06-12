class ScrumUserstoriesController < IssuesController
  unloadable

	prepend_before_filter :check_for_default_scrum_issue_status_for_inline, :only => [:inline_add]
	prepend_before_filter :check_for_default_scrum_issue_priority_for_inline, :only => [:inline_add]
	
	prepend_before_filter :check_for_default_issue_status, :only => [:index]
	prepend_before_filter :check_for_default_issue_priority, :only => [:index]
	
	prepend_before_filter :find_query, :only => [:index, :inline_add]						# must be called after find_scrum_project
	prepend_before_filter :find_scrum_project, :only => [:index, :inline_add]	
	
	
	before_filter :build_new_issue_from_params, :only => [:inline_add]

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
  
  	def find_query
  		retrieve_query
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
      @issues = @query.issues(:include => [:assigned_to, :tracker, :priority, :category, :fixed_version],
                              :order => sort_clause,
                              :offset => @offset,
                              :limit => @limit)
      @issue_count_by_group = @query.issue_count_by_group
  	end
  	
  	def initialize_sort
  		sort_init(@query.sort_criteria.empty? ? [['id', 'desc']] : @query.sort_criteria)
	    sort_update(@query.sortable_columns)
  	end
  	 
  	def find_scrum_project  	 
	    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
	    @project = Project.find(project_id)
	    logger.info 'project.id : ' + @project.id.to_s		   
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
end
