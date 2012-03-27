class PointsHistory < ActiveRecord::Base
  unloadable
  
  belongs_to :issue,
             :class_name => 'Issue',
             :conditions => ['tracker_id = ?',Tracker.scrum_userstory_tracker.id]
             
  before_save :check_nil_attributes
             
  
  def nil_attributes?
    self.points.nil?
  end

  protected
  def after_initialize
    self.date ||= Time.now
  end
  
  def check_nil_attributes
    self.points ||= 0.0
  end
end
