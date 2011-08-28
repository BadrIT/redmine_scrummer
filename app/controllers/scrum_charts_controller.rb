class ScrumChartsController < ScrumUserstoriesController
  unloadable

  prepend_before_filter :find_scrum_project, :only => [:index]
  
  def index
  end

  def inline_add
  end
end
