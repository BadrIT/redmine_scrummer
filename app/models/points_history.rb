class PointsHistory < ActiveRecord::Base
  unloadable
  
  belongs_to :issue,
             :class_name => 'Issue',
             :conditions => ['tracker_id = ?',Tracker.scrum_userstory_tracker.id]
             
  before_save :check_nil_attributes
             
  
  def nil_attributes?
    self.points.nil?
    self.date.nil?
  end

  protected
  def after_initialize
    self.date ||= Time.now
  end
  
  def check_nil_attributes
    self.points ||= 0.0
    # It was throwing ActiveRecord::StatementInvalid (Mysql2::Error: Column 'date' cannot be null
    self.date ||= Date.today
  end
end
