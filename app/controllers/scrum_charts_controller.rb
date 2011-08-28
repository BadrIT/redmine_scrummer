class ScrumChartsController < ScrumUserstoriesController
  unloadable

  prepend_before_filter :find_scrum_project, :only => [:index]
  
  def index
    @ll_verions = @project.versions
    @sprint = @project.versions.first
    @issues = @sprint.issues
    
  end

  def inline_add
  end
end
