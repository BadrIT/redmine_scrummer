class ScrumAdminsController < ApplicationController
  unloadable

  include ScrumUserstoriesController::SharedScrumConstrollers

  prepend_before_filter :find_scrum_project
  before_filter :current_page_setter
  # GET /scrum_admins
  # GET /scrum_admins.xml
  def index
    @trackers = Tracker.find(:all, :conditions => ["is_scrum = ?", true])
    @tracker_statuses = IssueStatus.find(:all, :conditions => ["is_scrum = ?", true])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @scrum_admins }
    end
  end

  def update_scrum_trackers
    params[:trackers].each do |tracker|
      Tracker.update_all(['name = ?, short_name = ?', tracker[1][:name], tracker[1][:short_name]], ["id = ?", tracker[0].to_i])
    end

    flash[:notice] = "Trackers successfuly update!"

    respond_to do |format|
      format.html { redirect_to(scrum_admins_path(:project_id => @project)) }
    end
  end

  def update_scrum_tracker_statuses
    params[:tracker_statuses].each do |tracker_status|
      IssueStatus.update_all(['name = ?, short_name = ?', tracker_status[1][:name], tracker_status[1][:short_name]], ["id = ?", tracker_status[0].to_i])
    end

    flash[:notice] = "Tracker Statuses successfuly update!"

    respond_to do |format|
      format.html { redirect_to(scrum_admins_path(:project_id => @project)) }
    end
  end

  def current_page_setter
    @current_page = :scrum_admin
  end

end
