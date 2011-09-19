class ScrumReleasesPlanningController < ReleasesController
  unloadable
  # layout 'base'
  
  include ScrumUserstoriesController::SharedScrumConstrollers
  
  before_filter :find_scrum_project, :only => [:index, :destroy_release]
  prepend_before_filter :find_project, :only => [:create, :destroy_release,:edit, :show, :update_release]
  
  # GET /releases
  # GET /releases.xml
  def index
    @release  = Release.new
    @releases = @project.releases
    @issues   = @project.issues.sprint_planing
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
        page.toggle('#inline-add');
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

  # DELETE /releases/1
  # DELETE /releases/1.xml
  def destroy_release
    @release = Release.find(params[:id])
    @release.destroy

    render :update do |page|
      page.remove "release-#{params[:id]}"
    end
  end
end
