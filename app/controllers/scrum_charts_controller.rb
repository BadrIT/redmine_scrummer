class ScrumChartsController < IssuesController
  unloadable
  
  include ScrumUserstoriesController::SharedScrumConstrollers

  prepend_before_filter :find_scrum_project, :only => [:index, :update_chart]
  before_filter :get_sprint, :only => [:index]
  before_filter :get_release, :only => [:index]
  
  # By Mohamed Magdy
  # Filter before entering the index action to highlight the scrummer
  # menu tab
  before_filter :current_page_setter, :only => [:index]
  
  def index    
    @sprints  = @project.versions
    @releases = @project.releases
    
    @release = @releases.find(params[:release_id]) if params[:release_id]
    @sprint = @sprints.find(params[:sprint_id]) if params[:sprint_id]
    
    # @axes_release = {'accepted_pts' => [], 'total_pts' => []}
    # @axes_sprint = {'actual_hrs' => [], 'actual_and_remaining_hrs' => [], 'remaining_hrs' => []}
    
    gather_sprint_data
    gather_release_data
  end
  
  def update_chart
    @axes = {}
    
    if params[:chart] == 'sprint'
      get_sprint
      gather_sprint_data
    else
      get_release
      gather_release_data
    end
  end

  protected 

  def get_sprint
    @sprint = if params[:id]
      @project.versions.find(params[:id])
    else
      @project.versions.find(:first, :order => 'effective_date DESC')
    end
  end
  
  def get_release
    @release = if params[:id]
      @project.releases.find(params[:id])
    else
      @project.releases.first
    end
  end
  
  def gather_sprint_data
    @sprint ||= @sprints.last
    return unless @sprint

    @start_date = @sprint.start_date_custom_value
    @end_date   = @sprint.effective_date

    # validation for the range
    return false if @start_date.blank? || @end_date.blank? || @start_date >= @end_date

    @issues = @project.issues.trackable.find :all, :conditions => ['fixed_version_id = ?', @sprint.id]
    
    curves = [l(:actual_hrs), l(:actual_and_remaining_hrs), l(:remaining_hrs)]

    @axes_sprint = curves.inject({}) do |memo, curve|
      memo[curve] = []
      memo
    end

    # building dates map
    dates_map = (@start_date..@end_date).inject({}) do |memo, date| 
      unless @project.non_working_day?(date) 
        memo[date] = (date.to_time + Time.now.utc_offset).to_i * 1000
      end
      memo
    end

    gather_information(@axes_sprint, curves, dates_map) do |issue, date|
      # history will selects the issues in date descending order
      # steps: sort descendingly and get the first history.
      # if an issue has no history in this day, then the history will be the nearest history of this issue
      # before the given date 
      sprint_hrs = issue.history.find(:first, :conditions => ['date <= ?', date])
      
      actual    = sprint_hrs.try(:actual).to_f
      remaining = sprint_hrs.try(:remaining).to_f

      # filling an array that will contain the value for each curve
      [actual,
       actual + remaining,
       remaining]
    end

    # manually add ideal burn down, by interpolation
    actual_and_remaining_hrs = @axes_sprint[l(:actual_and_remaining_hrs)]
    xa = 0
    ya = actual_and_remaining_hrs[0][1]
    xb = actual_and_remaining_hrs.size
    yb = 0

    if xb > xa
      ar = []
      actual_and_remaining_hrs.each_with_index do |entry, index|
        x = index
        y = ya + (yb-ya)*(x-xa)/(xb-xa)
        ar << [x,y]
      end

      @axes_sprint[(:ideal_burn)] = ar
    else
      @axes_sprint[(:ideal_burn)] = actual_and_remaining_hrs.dup
    end

    @sprint_x_labels = dates_map.values.sort.map(&:to_s)
    true
  end

  def gather_release_data
    return if @release.nil?

    @start_date = @release.start_date
    @end_date   = @release.release_date

    # building dates array
    @dates_map = {}
    @dates_map[@start_date] = l(:start_date)

    @release.sprints.each do |sprint| 
      @dates_map[sprint.effective_date] = sprint.name
    end
    
    @dates_map[@end_date] = l(:end_date)

    @issues  = @release.issues.find :all, :conditions => ['tracker_id = ?', Tracker.scrum_userstory_tracker.id]
    
    curves = [l(:accepted_pts), l(:total_pts)]
    
    @axes_release = {}
    curves.each do |curve|
        @axes_release[curve] = []
    end
    
    accepted_id =  IssueStatus.find_by_scrummer_caption('accepted').id  
    gather_information(@axes_release, curves, @dates_map) do |issue, date|
      # point histories will selects the issues in date descending order
      # steps: sort descendingly and get the first point history.
      # if an issue has no point history in this day, then the history will be the nearest point history of this issue
      # before the given date 
      release_points = issue.points_histories.find(:first, :conditions => ['date <= ?', date])
      
      [release_points.try(:issue).try(:status_id) == accepted_id ? release_points.points : 0.0,
       release_points.try(:points).to_f]
    end

    # manually adding remaing points curve
    ar = []
    accepted_points = @axes_release[l(:accepted_pts)]
    total_points = @axes_release[l(:total_pts)]
    accepted_points.each_with_index do |element, i|
      ar << [element[0], (total_points[i][1] - accepted_points[i][1])]
    end
    @axes_release[l(:remaining_pts)] = ar

    # manually add ideal burn down
    xa = 0
    ya = total_points[0][1]
    xb = total_points.size
    yb = 0

    if xb > xa
      ar = []
      total_points.each_with_index do |entry, index|
        x = index
        y = ya + (yb-ya)*(x-xa)/(xb-xa)
        ar << [x,y]
      end

      @axes_release[(:ideal_burn)] = ar
    else
      @axes_release[(:ideal_burn)] = total_points.dup
    end

  end
  
  # attributes:
  # - dates_map is a map between the date and the data that will be displayed in the X axix
  #   e.g. dates_map = {Date.to_date => "Sprints - 12"}
  def gather_information(axes, curves, dates_map, &block)
    dates_array = dates_map.keys.sort
    start_date = dates_array.first
    end_date   = dates_array.last
    issues     = @issues
    
    # loops over the days of the sprint or the release
    dates_array.each do |date|
      points = Array.new(curves.count, 0)
      
      # looping over all the issues every day to calculate it points (release) or the hours (sprint)
      issues.each do |issue|
        issue_points = block.call(issue, date.end_of_day)
        
        issue_points.each_with_index do |issue_point, i|
          points[i] += issue_point
        end
      end
      
      # Checking if the date is a vacation or the start or the end date
      if !@project.non_working_day?(date) || date == start_date || date == end_date
        curves.each_with_index do |curve, i|
          axes[curve] << [dates_map[date] , points[i]]
        end
      end
    end
  end
  
  # By Mohamed Magdy
  # This methods sets the curret_page attribute to be used in the view 
  # and mark the current page in the scrummer menu
  def current_page_setter
    @current_page = :charts
  end
end
