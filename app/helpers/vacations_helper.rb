module VacationsHelper
  def month_link(month_date)
    link_to(I18n.localize(month_date, :format => "%B"), {:month => month_date.month, :year => month_date.year, :project_id => @project.identifier})
  end

  # custom options for this calendar
  def event_calendar_opts
    {
      :year => @year,
      :month => @month,
      :event_strips => @event_strips,
      :month_name_text => I18n.localize(@shown_month, :format => "%B %Y"),
      :previous_month_text => "<< " + month_link(@shown_month.advance(:month => -1)),
      :next_month_text => month_link(@shown_month.advance(:months => 1)) + " >>",
      :link_to_day_action => false 
    }
  end

  def event_calendar
    # args is an argument hash containing :event, :day, and :options
    calendar event_calendar_opts do |args|
      vacation = args[:event]
      if vacation.id
        link_to(vacation.name, delete_vacation_path(:id => vacation.id, :project_id => @project.identifier), :confirm => l(:non_working_delete_confirm), :method => :delete)
      else
        vacation.name  
      end
       
    end
  end
end
