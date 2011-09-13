class ScrumChartsController < IssuesController
  unloadable
  
  include ScrumUserstoriesController::SharedScrumConstrollers

  prepend_before_filter :find_scrum_project, :only => [:index, :update_chart]
  before_filter :get_sprint, :only => [:index, :update_chart]
  
  
  def index    
    @sprints = @project.versions
    
    gather_information
  end
  
  def update_chart
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
    @start_date = @sprint.start_date_custom_value
    @end_date   = @sprint.effective_date
    
    @lower = []
    @upper = []
    
    return unless @start_date && @end_date
    
    @issues = @project.issues.find :all, :conditions => ['fixed_version_id = ?', @sprint.id]
    
    day = 0
    (@start_date..@end_date).each do |date|
      @upperPoint = 0 # remaining + actual 
      @lowerPoint = 0 # actual
      
      @issues.each do |issue|
        if issue.time_trackable?
          history_entry = issue.history.find(:first, :conditions => ['date >= ? and date <= ?', @start_date, date])
          
          if history_entry && history_entry.actual && history_entry.remaining
            @lowerPoint += history_entry.actual
            @upperPoint += history_entry.remaining + history_entry.actual
          end
        end
      end
      @lower << [day, @lowerPoint]
      @upper << [day, @upperPoint]
      day += 1
    end
  end
  

end
