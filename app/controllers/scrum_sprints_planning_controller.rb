class ScrumSprintsPlanningController < IssuesController
  unloadable
  
  include ScrumUserstoriesHelper

  include ScrumUserstoriesController::SharedScrumConstrollers  
  
  prepend_before_filter :find_scrum_project, :only => [:index, :inline_add_version]
  
  def index
    @query = Query.find_by_scrummer_caption("Sprint-Planning")
    initialize_sort
    # retrive the sprints ordered by its date
    @sprints = @project.versions.find(:all,:order => 'effective_date DESC')
    @backlog_issues = @project.issues.backlog.sprint_planing.find(:all, :order => sort_clause)
    
  end
  
  def inline_add_version
    @sprint = Version.new(params[:version])
    @sprint.project = @project
    
    if @sprint.save
      flash[:notice] = l(:notice_successful_create)
      
      @query = Query.find_by_scrummer_caption("Sprint-Planning")
      initialize_sort
      @sprints = @project.versions.find(:all,:order => 'effective_date DESC')
      
      render :update do |page|
        page.replace_html 'sprints', :partial => "sprint", :collection => @sprints
        page.replace_html 'inline_add_container', :partial => 'inline_add_version'
        page.replace_html 'version_errors', ""
        page.call 'init_planning'
        page.call 'update_sprint_status'
      end
      
    else
      errors = error_messages_for 'sprint'
      render :update do |page|
        page.replace_html 'version_errors', errors 
      end
    end
  end
  
end
