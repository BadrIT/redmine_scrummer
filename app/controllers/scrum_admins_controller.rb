class ScrumAdminsController < ApplicationController
  unloadable

  include ScrumUserstoriesController::SharedScrumConstrollers

  prepend_before_filter :find_scrum_project
  before_filter :current_page_setter
  # GET /scrum_admins
  # GET /scrum_admins.xml
  def index
    @custom_fields = CustomField.find(:all, :conditions => ["scrummer_caption IS NOT NULL"])
    @trackers = Tracker.find(:all, :conditions => ["is_scrum = ?", true])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @scrum_admins }
    end
  end

  def update_custom_fields
    params[:custom_fields].each do |custom_field|
      CustomField.update_all(['name = ?', custom_field[1]], ["id = ?", custom_field[0].to_i])
    end

    flash[:notice] = "Custom Fields successfuly update!"

    respond_to do |format|
      format.html { redirect_to(scrum_admins_path(:project_id => @project)) }
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

  def current_page_setter
    @current_page = :scrum_admin
  end

end
