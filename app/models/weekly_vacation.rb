class WeeklyVacation < ActiveRecord::Base
  belongs_to :project
  has_event_calendar
end
