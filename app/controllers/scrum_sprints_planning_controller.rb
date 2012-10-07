class ScrumSprintsPlanningController < IssuesController
  unloadable
  
  include ScrumUserstoriesHelper
  
  include ScrumUserstoriesController::SharedScrumConstrollers  
  
  prepend_before_filter :find_scrum_project
  # By Mohamed Magdy
  # Filter before entering the index action to highlight the scrummer
  # menu tab
  before_filter :current_page_setter
  before_filter :build_new_issue_from_params, :only => :index
  
  def index
    # retrive the sprints ordered by its date
    @sprints = @project.versions.find(:all,:order => 'effective_date DESC')
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
      # initialize_sort
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

  # GET /sprints/1/edit
  def edit_version
    @version = @project.versions.find(params[:id])
  end
  
  def sprint_info
    @version = Version.find(params[:id])
    
    respond_to do |format|
      format.js { render :partial => 'inline_add_version' }
    end
  end

  def add_version
     @sprint = Version.find(:first, :conditions => ['id = ?', params[:version_id]])
    
    if @sprint
      @success = update_sprint
    else
      @success = create_sprint
    end
    
    @sprints = @project.versions.find(:all,:order => 'effective_date DESC')
    render :index
  end

  def destroy_version
    @version = @project.versions.find params[:id]
    @version.destroy

    if Version.exists?(params[:id])
      flash[:error] = l(:notice_unable_delete_version)
    else  
      flash[:notice] = l(:notice_successful_delete)
    end

    @sprints = @project.versions.find(:all,:order => 'effective_date DESC')
    
    redirect_to scrum_sprint_planing_path(:project_id => @project.identifier)
  end

  protected
  # By Mohamed Magdy
  # This methods sets the curret_page attribute to be used in the view 
  # and mark the current page in the scrummer menu
  def current_page_setter
    @current_page = :sprint_planning
  end
  
  def set_default_values
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

    # adding retrospective_url form the creating wiki_page
    wiki_disabled = @sprint.project.wiki.nil?
    unless wiki_disabled
      page = @sprint.build_wiki_page
    end

    if @sprint.save && (wiki_disabled || page.save)
      field = VersionCustomField.find_by_scrummer_caption(:retrospective_url)
      field_value = @sprint.custom_values.find_or_create_by_custom_field_id(field.id)
      
      field_value.value = url_for(:controller => 'wiki', :action => 'show', :project_id => page.project,
                                :id => page.title, :only_path => false, :protocol => 'http')
      field_value.save

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
      flash[:notice] = l(:notice_successful_update)
      true
    else
      flash[:notice] = l(:error_sprint_update)
      false
    end
  end
end
