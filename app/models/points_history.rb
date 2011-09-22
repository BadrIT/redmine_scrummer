class PointsHistory < ActiveRecord::Base
  unloadable
  
  belongs_to :issue,
             :class_name => 'Issue',
             :conditions => ['tracker_id = ?',Tracker.scrum_user_story_tracker.id]
             
  before_save :check_nil_attributes
             
  
  def lower_point
    self.points
  end
  
  def upper_point
    accepted_id =  IssueStatus.find_by_scrummer_caption(:accepted).id
    self.issue.status_id == accepted_id ? self.points : 0.0
  end 
  
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
