class ScrumAdminsController < ApplicationController
  unloadable
  
  include ScrumUserstoriesController::SharedScrumConstrollers
  
  before_filter :require_admin
  before_filter :current_page_setter
  
  # GET /scrum_admins
  # GET /scrum_admins.xml
  def index
    @trackers = Tracker.find(:all, :conditions => ["is_scrum = ?", true])
    @tracker_statuses = IssueStatus.find(:all, :conditions => ["is_scrum = ?", true])
    @weekly_vacation = ScrumWeeklyNonWorkingDay.first || ScrumWeeklyNonWorkingDay.new
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @scrum_admins }
    end
  end

  def update_scrum_trackers
    params[:trackers].each do |tracker_attributes|
      tracker = Tracker.find(tracker_attributes[0])
      tracker.name = tracker_attributes[1][:name]
      tracker.short_name = tracker_attributes[1][:short_name]
      tracker.position = tracker_attributes[1][:position]
      tracker.save
    end

    flash[:notice] = "Trackers successfuly update!"

    respond_to do |format|
      format.html { redirect_to(scrum_admins_path(:project_id => @project)) }
    end
  end

  def update_scrum_tracker_statuses
    params[:tracker_statuses].each do |status_attributes|
      status = IssueStatus.find(status_attributes[0])
      status.name = status_attributes[1][:name]
      status.short_name = status_attributes[1][:short_name]
      status.position = status_attributes[1][:position]
      status.save
    end

    flash[:notice] = "Tracker Statuses successfuly update!"

    respond_to do |format|
      format.html { redirect_to(scrum_admins_path(:project_id => @project)) }
    end
  end
  
  def update_weekly_vacation
    @weekly_vacation = ScrumWeeklyNonWorkingDay.first || ScrumWeeklyNonWorkingDay.new
    
    respond_to do |format|
      if @weekly_vacation.update_attributes(params[:scrum_weekly_non_working_day])
        format.html { redirect_to(scrum_admins_path, :notice => 'Weekly Vacation was successfully set!') }
        format.xml  { render :xml => @weekly_vacation, :status => :created, :location => @weekly_vacation }
      else
        format.html { render :action => "index" }
        format.xml  { render :xml => @weekly_vacation.errors, :status => :unprocessable_entity }
      end
    end
  end

  private
  
  def current_page_setter
    @current_page = :scrum_admin
  end
end
