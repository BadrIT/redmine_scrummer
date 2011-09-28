class ScrumReleasesPlanningController < IssuesController
  unloadable
  # layout 'base'
  
  include ScrumUserstoriesController::SharedScrumConstrollers
  
  before_filter :find_scrum_project, :only => [:index, :destroy_release]
  prepend_before_filter :find_project, :only => [:create, :destroy_release,:edit, :show, :update_release, :set_issue_release]
  
  # GET /releases
  # GET /releases.xml
  def index
    @release  = Release.new
    @releases = @project.releases
    @issues   = @project.issues.sprint_planing.find(:all, :conditions => ['release_id is NULL'])
    @planning_releases = @project.releases.find_all_by_state('Planning') 
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @releases }
    end
  end

  # GET /releases/1
  # GET /releases/1.xml
  def show
    @release = Release.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @release }
    end
  end

  # GET /releases/1/edit
  def edit
    @release = Release.find(params[:id])
  end

  # POST /releases
  # POST /releases.xml
  def create
    @release = Release.new(params[:release])
    @release.project_id = @project.id
    
    if @release.save
      render :update do |page|
        page.insert_html :bottom, 'releases', :partial => 'release', :object => @release
        page.visual_effect :highlight, "release-#{@release.id}", :duration => 2
        if @release.state == 'Planning'
          page.insert_html :bottom, 'accordion', :partial => 'release_as_list', :object => @release
          page.visual_effect :highlight, "header-#{@release.id}", :duration => 2
          page.call 'init_release_planning'
          page.call 'add_last_element_to_accordion'
        end
      end
    else
      render :update do |page|
        page.remove 'release_errors', error_messages_for('release')
      end
    end
  end

  # PUT /releases/1
  # PUT /releases/1.xml
  def update_release
    @release = Release.find(params[:id])

    respond_to do |format|
      if @release.update_attributes(params[:release])
        format.html { redirect_to(:action => 'index', :project_id => @project, :notice => 'Release was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @release.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def set_issue_release
    @issue = Issue.find params[:issue_id]
    release_id = params[:release_id] != 'backlog' ? params[:release_id] : nil
    @issue.release_id = release_id
    @issue.save
    
    render :update do |page|
      page.visual_effect :highlight, "header-#{release_id}", :duration => 3
    end
    
  end

  # DELETE /releases/1
  # DELETE /releases/1.xml
  def destroy_release
    @release = Release.find(params[:id])
    @release.destroy

    render :update do |page|
      page.remove "release-#{params[:id]}"
      page.remove "header-#{params[:id]}"
      page.remove "#{params[:id]}"
    end
  end
end
