class ScrumChartsController < IssuesController
  unloadable
  
  include ScrumUserstoriesController::SharedScrumConstrollers

  prepend_before_filter :find_scrum_project, :only => [:index, :update_chart]
  before_filter :get_sprint, :only => [:index]
  before_filter :get_release, :only => [:index]
  
  def index    
    @sprints  = @project.versions
    @releases = @project.releases
    
    gather_sprint_data
    gather_release_data
    
  end
  
  def update_chart
    if params[:chart] == 'sprint'
      get_sprint
      gather_sprint_data
      
      render :update do |page|
        page.replace_html 'sprints-chart', ''
        page << "draw('#sprints-chart',#{@lower_sprint.inspect}, #{@upper_sprint.inspect}, sprint_chart_l1, sprint_chart_l2);"
      end
    else
      get_release
      gather_release_data
      
      render :update do |page|
        page.replace_html 'release-chart', ''
        page <<  "draw('#release-chart',#{@lower_release.inspect}, #{@upper_release.inspect}, release_chart_l1, release_chart_l2);"
      end
    end
  end

  protected 

  def get_sprint
    @sprint = if params[:id]
      Version.find params[:id]
    else
      @project.versions.find(:first, :order => 'effective_date DESC')
    end
  end
  
  def get_release
    @release = if params[:id]
      Release.find params[:id]
    else
      @project.releases.first
    end
  end
  
  def gather_sprint_data
    @start_date = @sprint.start_date_custom_value
    @end_date   = @sprint.effective_date
    @issues     = @project.issues.trackable.find :all, :conditions => ['fixed_version_id = ?', @sprint.id]  
    
    gather_information(@lower_sprint = [], @upper_sprint = []) do |issue, date|
      issue.history.find(:first, :conditions => ['date >= ? and date <= ?', @start_date, date])
    end
  end

  def gather_release_data
    @start_date = @release.start_date
    @end_date   = @release.release_date
    @issues     = @release.issues.find :all, :conditions => ['tracker_id = ?', Tracker.scrum_user_story_tracker.id]
    
    gather_information(@lower_release = [], @upper_release = []) do |issue, date|
      issue.points_histories.find(:first, :conditions => ['date <= ?', date])
    end
  end
  
  def gather_information(lower, upper, &block)
    start_date = @start_date
    end_date   = @end_date
    issues     = @issues
    
    return unless start_date && end_date
    
    day = 0
    (start_date..end_date).each do |date|
      upperPoint = 0.0 # remaining + actual 
      lowerPoint = 0.0 # actual
      
      issues.each do |issue|
        history_entry = block.call(issue, date)
        
        if history_entry && !history_entry.nil_attributes?
          lowerPoint += history_entry.lower_point
          upperPoint += history_entry.upper_point
        end
      end
      
      lower << [(date.to_time + Time.now.utc_offset).to_i * 1000 , lowerPoint]
      upper << [(date.to_time + Time.now.utc_offset).to_i * 1000 , upperPoint]
      day += 1
    end
  end
  
end
