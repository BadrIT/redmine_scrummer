class VacationsController < ApplicationController
  unloadable
  
  include ScrumUserstoriesController::SharedScrumConstrollers
  prepend_before_filter :find_scrum_project
  before_filter :require_admin
  
  # GET /weekly_vacations
  # GET /weekly_vacations.xml
  def index
    @weekly_vacation = @project.weekly_vacation ? @project.weekly_vacation: WeeklyVacation.new

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @weekly_vacations }
    end
  end

  def weekly_vacation
    @weekly_vacation = WeeklyVacation.find_or_initialize_by_project_id(@project)
    @weekly_vacation.update_attributes(params[:weekly_vacation])
    @weekly_vacation.project = @project
    
    respond_to do |format|
      if @weekly_vacation.save
        format.html { redirect_to(vacations_path(:project_id => @project.identifier), :notice => 'Weekly Vacation was successfully set!') }
        format.xml  { render :xml => @weekly_vacation, :status => :created, :location => @weekly_vacation }
      else
        format.html { render :action => "index" }
        format.xml  { render :xml => @weekly_vacation.errors, :status => :unprocessable_entity }
      end
    end
  end
end
