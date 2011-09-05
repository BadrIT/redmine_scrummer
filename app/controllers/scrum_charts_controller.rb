class ScrumChartsController < IssuesController
  unloadable
  include ScrumUserstoriesController::SharedScrumConstrollers

  prepend_before_filter :find_scrum_project, :only => [:index, :update_chart]
  before_filter :get_sprint, :only => [:index, :update_chart]
  
  
  def index
    @start_date = @sprint.effective_date
    @sprints = @project.versions
    
    gather_information
  end
  
  def update_chart
    @start_date = @sprint.effective_date
    gather_information
    
    render :update do |page|
      page.replace_html 'chart', ''
      page << "draw(#{@lower.inspect}, #{@upper.inspect});"
    end
  end

  protected 

  def get_sprint
    if params[:sprint]
      @sprint = Version.find params[:sprint]
    else
      @sprint = @project.versions.find(:first, :order => 'effective_date DESC')
    end
  end
  
  def gather_information
    @lower = []
    @upper = []

    (1..10).each do |day|
      @p1 = @p2 = 0
      
      @project.issues.each do |issue|
        if issue.time_trackable?
          history_entry = issue.history.find(:first, :conditions => ['date <= ?', @start_date + day])
          
          if history_entry
            @p1 += history_entry.actual
            @p2 += (history_entry.remaining + history_entry.actual)
          end
        end
      end
      @lower << [day, @p1]
      @upper << [day, @p2]
    end
  end
  

end
