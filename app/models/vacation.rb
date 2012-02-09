class Vacation < ActiveRecord::Base
  has_event_calendar
  belongs_to :project
  
  validates_presence_of :name, :start_at, :end_at
  validate :start_before_end
  
  def start_before_end
    errors.add("start_at", "must be before end at!") if (!self.start_at.blank? && !self.end_at.blank?) && (self.start_at > self.end_at)
  end
end