class ScrumSprintsPlanningController < IssuesController
  unloadable
  
  include ScrumUserstoriesHelper
  
  include ScrumUserstoriesController::SharedScrumConstrollers  
  
  prepend_before_filter :find_scrum_project, :only => [:index, :inline_add_version, :sprint_info]
  # By Mohamed Magdy
  # Filter before entering the index action to highlight the scrummer
  # menu tab
  before_filter :current_page_setter, :only => :index
  before_filter :build_new_issue_from_params, :only => :index
  
  def index
    @query = Query.find_by_scrummer_caption("Sprint-Planning")
    initialize_sort
    # retrive the sprints ordered by its date
    @sprints = @project.versions.find(:all,:order => 'effective_date DESC')
    @backlog_issues = @project.issues.backlog.sprint_planing.find(:all, :order => sort_clause)
  end
  
  def inline_add_version
    @sprint = Version.find(:first, :conditions => ['id = ?', params[:version_id]])
    
    if @sprint
      @success = update_sprint
    else
      @success = create_sprint
    end
    
    if @success
      @query = Query.find_by_scrummer_caption("Sprint-Planning")
      initialize_sort
      @sprints = @project.versions.find(:all,:order => 'effective_date DESC')
      @list_id = "backlog"
      @from_sprint = "backlog" 
      render :update do |page|
        page.replace_html 'sprints', :partial => "sprint", :collection => @sprints
        page.replace_html 'version_errors', ""
        page.call 'init_planning'
        page.call 'update_sprint_status'
      end
    else
      errors = error_messages_for 'sprint'
      render :update, :status => :unprocessable_entity do |page|
        page.replace_html 'version_errors', errors
      end
    end
  end
  
  def sprint_info
    @version = Version.find(params[:id])
    
    respond_to do |format|
      format.js { render :partial => 'inline_add_version' }
    end
  end
  
  protected
  # By Mohamed Magdy
  # This methods sets the curret_page attribute to be used in the view 
  # and mark the current page in the scrummer menu
  def current_page_setter
    @current_page = :sprint_planning
  end
  
  def set_default_values
    @issue.description = @issue.is_user_story? ? l(:default_description):""
    @issue.project_id = @project
    if @issue.fixed_version.nil? && !@query.filters['fixed_version_id'].nil? && 
      @query.filters['fixed_version_id'][:operator] == '='&& 
       (params[:issue].nil? || params[:issue][:parent_issue_id].empty?)
      
      @issue.fixed_version =  Version.find(@query.filters['fixed_version_id'][:values][0].to_i)
    end
  end
  
  # By Mohamed Magdy
  private
  
  # By Mohamed Magdy
  # Creating a new sprint with the passed parameters
  def create_sprint
    @sprint = Version.new(params[:version])
    @sprint.project = @project
    
    if @sprint.save
      flash[:notice] = l(:notice_successful_create)
      true
    else
      false
    end
  end
  
  # By Mohamed Magdy
  # Updating an existing sprint with passed parameters
  def update_sprint
    if @sprint.update_attributes(params[:version])
      flash[:notice] = l(:notice_successful_create)
      true
    else
      flash[:notice] = l(:error_sprint_update)
      false
    end
  end
end
