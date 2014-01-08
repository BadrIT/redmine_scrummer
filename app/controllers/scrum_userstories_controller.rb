class ScrumUserstoriesController < IssuesController
  unloadable

  include ScrumUserstoriesHelper
  include ERB::Util

  prepend_before_filter :find_query, :only => [:index, :refresh_inline_add_form, :inline_add, :update_single_field, :get_inline_issue_form, :issues_list, :calculate_statistics]						# must be called after find_scrum_project
  prepend_before_filter :find_scrum_project, :only => [:index, :refresh_inline_add_form, :inline_add, :update_single_field, :get_inline_issue_form, :issues_list, :sprint_planing, :inline_add_version, :calculate_statistics]

  before_filter :build_new_issue_from_params, :only => [:index, :refresh_inline_add_form, :get_inline_issue_form]
  before_filter :build_new_issue_or_find_from_params, :only => [:inline_add]
  before_filter :find_parent_issue, :only => [:get_inline_issue_form, :refresh_inline_add_form ]
  before_filter :set_default_values_from_parent, :only => [:get_inline_issue_form, :refresh_inline_add_form]
  before_filter :set_default_values, :only => [:refresh_inline_add_form, :index]

  # By Mohamed Magdy
  # Filter before entering the index action to highlight the scrummer
  # menu tab
  before_filter :current_page_setter, :only => [:index]

  module SharedScrumConstrollers

    include ActionView::Helpers::TagHelper

    protected
    def find_scrum_project
      project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
      @project = Project.find_by_identifier(project_id)
      @project ||= Project.find(project_id)
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end

  include SharedScrumConstrollers

  def update_single_field
    new_value = params[:value]

    # custom field for todo
    if params[:id] =~ /custom/
      matched_groups = params[:id].match(/issue-(\d+)-custom-field-cf_(\d+)/)
      issue_id = matched_groups[1]

      custom_field_id = matched_groups[2]

      @issue = Issue.find(issue_id)
      @issue.init_journal(User.current)
      @issue.custom_field_values = {custom_field_id => new_value}

      if @issue.save
        update_issue_and_parents
      else
        render :text => 'Errors in saving'
      end

    elsif params[:id] =~ /actual_hours/ 
      if params[:value] =~ /^\+(.*)/
        # virtual fields like actual
        matched_groups = params[:id].match(/issue-(\d+)-actual_hours/)
        issue_id       = matched_groups[1]
        value          = params[:value].match(/^\+(.*)/)[1]

        @issue      = Issue.find(issue_id)
        @issue.init_journal(User.current)
        @time_entry = TimeEntry.new(:hours => value,
        :issue => @issue,
        :user => User.current,
        :project => @issue.project,
        :spent_on => User.current.today,
        :activity_id => TimeEntryActivity.find_by_name('Scrum').id )

        if @time_entry.hours > 0 && @time_entry.save
          update_issue_and_parents
        else
          render :text => 'Errors in saving'
        end
      else
        render :text => ''
      end

    elsif params[:id] =~ /-field-/
      # fields like estimated hours
      matched_groups = params[:id].match(/issue-(\d+)-field-(.+)/)
      issue_id       = matched_groups[1]
      column_name    = matched_groups[2].to_sym

      @issue = Issue.find(issue_id)
      @issue.init_journal(User.current)
      @issue.update_attributes(column_name => new_value)

      if @issue.save
        update_issue_and_parents
      else
        render :text => 'Errors in saving'
      end

    elsif params[:id] =~ /-status/
      matched_groups = params[:id].match(/issue-(\d+)-status/)
      issue_id       = matched_groups[1]
      @issue         = Issue.find(issue_id)
      @issue.init_journal(User.current)

      status = if ["f", "F"].include? params[:value].to_s
        @issue.test? ? IssueStatus.failed : IssueStatus.finished
      else
        IssueStatus.find_by_short_name(params[:value])
      end
      @issue.status = status if status

      allowed_statuses = @issue.new_statuses_allowed_to(User.current)

      if !status
        render :text => 'Status invalid'
      elsif  !allowed_statuses.include?(status)
        render :text => 'Status Not Allowed'
      elsif !@issue.save
        render :text => 'Errors in saving'
      else
        update_issue_and_parents
      end

    elsif params[:id] =~ /-version/
      matched_groups = params[:id].match(/issue-(\d+)-version/)
      issue_id       = matched_groups[1]
      @issue         = Issue.find(issue_id)
      @issue.init_journal(User.current)

      version_id = params[:value] == 'backlog' ? nil : params[:value].gsub('sprint-','').to_i

      @issue.fixed_version_id = version_id
      @issue.insert_at((params[:first_index].to_i - params[:index].to_i).abs || 0)
      @issue.save
      render :update do |page|
        page.call 'update_sprint_status'
      end

    else
      render :text => 'Errors in saving'
    end
    
  rescue Exception => e
    puts e.inspect
    puts e.backtrace.join "\n"
    render :text => "Exception occured"
  end

  def authorize(ctrl = params[:controller], action = params[:action], global = false)
    if params[:action] == "inline_add"
      true
    else
      super
    end
  end
  
  def get_inline_issue_form
    issue_id = params[:issue_id] if params[:issue_id]
    @issue = Issue.find(issue_id) if issue_id
    
    @issue_id = params[:issue_id] || params[:parent_issue_id]
    
    respond_to do |format|
      format.js
    end
  end

  def calculate_statistics
    @statistics = { :total_story_size => 0.0,
      :total_estimate => 0.0,
      :total_actual => 0.0,
      :total_remaining => 0.0 }

    load_issues_for_query

    @all_issues.each do |issue|
      # don't add story size if an issue having children having story sizes
      if issue.direct_children.sum(:story_size).to_f == 0.0
        @statistics[:total_story_size] += issue.story_size
      end
      
      if issue.direct_children.sum(:remaining_hours).to_f == 0.0
        @statistics[:total_remaining] += issue.remaining_hours.to_f
      end

      # don't add estimate if an issue having children having estimated hours
      unless issue.direct_children.sum(:estimated_hours) > 0.0
        @statistics[:total_estimate] += issue.estimated_hours.to_f
      end

      @statistics[:total_actual]    += issue.time_entries.sum(:hours)
    end
    
    render :partial => 'statistics'
  end

  def index
    
    if @query.valid?
      load_sidebar_query
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

    if params[:list_id] == 'issues_list'
      load_issues_for_query
    else
      set_issues_and_query_for_list
    end
  end

  def refresh_inline_add_form
    @div = params[:div]
    
    respond_to do |format|
      format.js
    end
  end

  # inline add action
  def inline_add   
    @div_name = get_inline_issue_div_id
    saved = if @issue.new_record?
      inline_add_issue
    else
      inline_edit_issue
    end
     
    if saved
      load_issues_for_query
      flash[:notice] = l(:notice_successful_create)
     
      if @issues.length > 0
        set_issues_and_query_for_list unless params[:list_id] == 'issues_list'
        @partial_list ||= "list"
      end      
           
    else
      render_error_html_for_inline_add(error_messages_for 'issue')
    end
     
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  protected

  def inline_add_issue
    call_hook(:controller_issues_new_before_save, { :params => params, :issue => @issue })
    @issue.release_id = params[:issue][:release_id] if params[:issue] && !params[:issue][:release_id].blank?
    @issue.save(:validate => false)      
  end

  def inline_edit_issue
    return unless update_issue_from_params
    begin
      saved = @issue.save_issue_with_child_records(params)
    rescue ActiveRecord::StaleObjectError
      @conflict = true
      if params[:last_journal_id]
        @conflict_journals = @issue.journals_after(params[:last_journal_id]).all
        @conflict_journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
      end
    end

    saved
  end

  def find_parent_issue
    parent_issue_id = params[:parent_issue_id] if params[:parent_issue_id]
    parent_issue_id ||= params[:issue][:parent_issue_id] if params[:issue] and params[:issue][:parent_issue_id]

    @parent_issue = (parent_issue_id and !parent_issue_id.empty? and Issue.exists?(parent_issue_id)) ? Issue.find(parent_issue_id) : nil
  end

  def find_query
    # setting up current user if this filter is called before user_setup filter
    user_setup if User.current

    if session[:query].nil? || params[:set_filter] == 'clear'
      if sprint = @project.current_or_latest_sprint 
        query = IssueQuery.find_by_project_id_and_name(@project.id, sprint.name)
      end 
      query ||= IssueQuery.find_by_scrummer_caption('User-Stories')
      params[:query_id] = query.id if query
    end
    retrieve_query

    @query.column_names = IssueQuery::SCRUMMER_COLUMNS if @query.new_record?
  end

  # Edited by Mohamed Magdy
  def load_issues_ancestors
    @issues.each do |issue|
      if !issue.direct_parent.nil? && !@issues.include?(issue.direct_parent)
      @issues << issue.direct_parent
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

    # all issues is used for statistics
    @all_issues = Issue.find(:all, :include => [:project, :status, :tracker, :fixed_version, :assigned_to], :conditions => @query.statement)    

    # clone all issues in a new array
    # but having the same objects in order not to calcluate statistics twice
    @issues = @all_issues.map{|i| i}

    #build tree heirarachy
    @issues = scrum_issues_list(@issues)  
    
    @issue_count = @issues.length
    @issue_pages = Paginator.new self, @issue_count, @limit, params['page']  
    
    @issues = @issues[(@offst.to_i)..(@offset.to_i+@limit.to_i-1)]
  end

  def set_default_values_from_parent
    if @parent_issue
      @issue.parent_issue_id ||= @parent_issue.id
      @issue.fixed_version ||= @parent_issue.fixed_version
      @issue.assigned_to ||= @parent_issue.assigned_to

      # can't user ||= because there is before filter set issue default tracker
      if params[:issue].blank? || params[:issue][:tracker_id].blank?
        @issue.tracker = case @parent_issue.tracker.scrummer_caption.to_sym
        when :epic
          Tracker.scrum_userstory_tracker
        when :userstory
          Tracker.scrum_task_tracker
        when :defectsuite
          Tracker.scrum_defect_tracker
        when :defect
          Tracker.scrum_defect_tracker
        else
        Tracker.scrum_userstory_tracker
        end
      end
    end
  end

  protected

  # By Mohamed Magdy
  # This methods sets the curret_page attribute to be used in the view
  # and mark the current page in the scrummer menu
  def current_page_setter
    @current_page = :user_stories
  end

  def update_issue_and_parents
    @issue = issue_to_hash @issue
    
    # load parents 
    height = 0
    issue = @issue
    while issue["parent_id"] do
      parent = Issue.find_by_id(issue["parent_id"], :include => [:project, :status, :tracker, :fixed_version, :assigned_to])
      issue[:parent] = issue_to_hash parent
      issue = issue[:parent]
      height += 1
    end
    
    # update levels
    issue = @issue
    while issue do
      issue[:level] = height      
      issue = issue[:parent]
      height -= 1
    end    
    
    render :update_issue_and_parents
  end
  
  def tracker_statuses tracker
    @tracker_statuses_hash ||= {}
    
    @tracker_statuses_hash[tracker.id] = tracker.issue_statuses unless @tracker_statuses_hash[tracker.id]
    
    @tracker_statuses_hash[tracker.id]
  end  
  
  def issue_to_hash issue
    issue.attributes.merge({
      :children => [], 
      :parent => nil, 
      :tracker => issue.tracker, 
      :tracker_issues_statuses => tracker_statuses(issue.tracker),
      :status => issue.status,
      :story_size => issue.accept_story_size? ? issue.story_size.to_f : nil ,  
      :remaining_hours => issue.accept_remaining_hours? ? issue.remaining_hours.to_f : nil, 
      :business_value => issue.accept_business_value? ? issue.business_value.to_f : nil,
      :time_trackable => issue.time_trackable?,
      :fixed_version => issue.fixed_version ? issue.fixed_version.name : "",
      :assigned_to => issue.assigned_to ? issue.assigned_to.name : ""
    }) 
  end

  def scrum_issues_list(issues, &block)
    # convert to hash to be able to add children
    issues = issues.map do |issue| 
      issue_to_hash issue
    end
    
    # convert to map to be able to build tree structure
    issues_map = Hash[ issues.collect{|issue| [issue["id"], issue] } ]    
    
    # tree with root level issues at top
    issues_tree = []
    
    issues.each do |issue|    
      parent = issue["parent_id"] && issues_map[ issue["parent_id"] ];  
      if(parent)  #should be added as child
        issue[:parent] = parent
        parent[:children] << issue        
      else # add as root level
        issues_tree << issue
      end      
    end
    
    # init levels
    issues.each do |issue|    
      level = 0
      parent = issue[:parent]
      while parent do
        level += 1
        parent = parent[:parent]
      end
      issue[:level] = level
    end     
        
    # flatten the list    
    sorted_flatten_issues = flatten issues_tree
    
    # return result
    sorted_flatten_issues
  end
  
  def flatten issues
    result = []
    issues.each do |issue|
      result << issue
      result << (flatten issue[:children])
    end    
    result.flatten
  end

  def set_default_values
    if @issue.fixed_version.nil? && !@query.filters['fixed_version_id'].nil? &&
    @query.filters['fixed_version_id'][:operator] == '='&&
    (params[:issue].nil? || params[:issue][:parent_issue_id].empty?)

      id = @query.filters['fixed_version_id'][:values][0].to_i
      @issue.fixed_version =  Version.find(id) if Version.exists?(id)
    end
  end

  def set_issues_and_query_for_list
    # set the query to sprint-planning query
    @query = IssueQuery.find_by_scrummer_caption("Sprint-Planning")

    if params[:from_sprint]
      sprint_id = params[:from_sprint].split("sprint-")[1]
      unless sprint_id
        @old_sprint_issues = @project.issues.backlog.sprint_planing.find(:all, :order => sort_clause)
      else
        @old_sprint_issues = @project.versions.find(sprint_id).fixed_issues.sprint_planing.find(:all, :order => sort_clause)
      end
    end

    if params[:selected_sprint]
      params[:list_id] = params[:selected_sprint]
    end

    if params[:list_id] == 'backlog'
      if params[:tracker_id]
        # if filtering by only userstories, defects, ..etc
        @issues = @project.issues.backlog.by_tracker(params[:tracker_id]).find(:all, :order => sort_clause)
      else
        @issues = @project.issues.backlog.sprint_planing.find(:all, :order => sort_clause)
      end
    elsif params[:list_id].to_s =~ /sprint-(\d*)/
      @issues = Version.find($1).fixed_issues.sprint_planing.find(:all, :order => sort_clause)
    elsif params[:list_id] == 'release-backlog'
      if @issue.release
        @issues = @issue.release.issues
        params[:list_id] = params[:from_sprint] = @issue.release_id.to_s
      else
        @issues = @project.issues.sprint_planing.find(:all, :conditions => ['release_id is NULL'])
      end
      @partial_list = 'scrum_releases_planning/release_backlog'
    end
  end
  
  # load the sidebar query. The query sorts the sprints by id not by name
  def load_sidebar_query
    # User can see public queries and his own queries
    conditions = ["(is_public = ? OR user_id = ?)", true, (User.current.logged? ? User.current.id : 0)]

    # Project specific queries and global queries
    if @project.nil? 
      conditions[0] = conditions[0] + " AND (project_id IS NULL)"
    else
      conditions[0] = conditions[0] + " AND (project_id IS NULL OR project_id = ?)"
      conditions << @project.id
    end

    @sidebar_queries = IssueQuery.find(:all,
                            :select => 'id, name, is_public',
                            :order => "id DESC",
                            :conditions => conditions)
  end

  def build_new_issue_or_find_from_params
    if params[:id].blank?
      @issue = Issue.new
      # optimization : not using assign_attributes because of slowness in aliased method in issue.rb
      params[:issue].each do |k, v|
          @issue[k] = v
      end
      @issue.author_id = User.current.id
    else
      find_issue
    end
  end
end
