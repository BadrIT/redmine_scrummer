class VacationsController < ApplicationController
  unloadable
  
  include ScrumUserstoriesController::SharedScrumConstrollers
  prepend_before_filter :find_scrum_project
  # GET /weekly_vacations
  # GET /weekly_vacations.xml
  def index
    # Weekly vacations
    @weekly_vacation = @project.weekly_vacation || WeeklyVacation.new
    
    # General vacations
    initialize_general_vacations

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @weekly_vacations }
    end
  end

  def weekly_vacation
    @weekly_vacation = WeeklyVacation.find_or_initialize_by_project_id(@project)

    respond_to do |format|
      if @weekly_vacation.update_attributes(params[:weekly_vacation])
        format.html { redirect_to(vacations_path(:project_id => @project.identifier), :notice => 'Weekly Vacation was successfully set!') }
        format.xml  { render :xml => @weekly_vacation, :status => :created, :location => @weekly_vacation }
      else
        format.html { render :action => "index" }
        format.xml  { render :xml => @weekly_vacation.errors, :status => :unprocessable_entity }
      end
    end
  end

  def add_vacation
    params[:vacation][:color] = "#" + params[:vacation][:color]
    @vacation = Vacation.new(params[:vacation])
    @vacation.project = @project

    respond_to do |format|
      if @vacation.save
        format.html { redirect_to(vacations_path(:project_id => @project.identifier), :notice => 'Vacation was successfully set!') }
      else
        # Weekly vacations
        @weekly_vacation = @project.weekly_vacation || WeeklyVacation.new
        # General vacations
        initialize_general_vacations
        format.html { render :action => "index" }
      end
    end
  end

  def delete_vacation
    Vacation.find(params[:id]).destroy
    @vacation = Vacation.new
    redirect_to(vacations_path(:project_id => @project.identifier), :notice => 'Vacation was removed!')
  end
  
  private
  def initialize_general_vacations
    # General vacations
    @month = (params[:month] || (Time.zone || Time).now.month).to_i
    @year = (params[:year] || (Time.zone || Time).now.year).to_i

    @shown_month = Date.civil(@year, @month)

    @event_strips = Vacation.event_strips_for_month(@shown_month, @project.weekly_vacation_days)
  end
end
