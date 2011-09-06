class IssueHistory < ActiveRecord::Base
  unloadable
  
  belongs_to :issue
  before_save :check_nil_attributes
  
  def after_initialize
    self.date ||= Time.now
  end
  
  def check_nil_attributes
    self.actual ||= 0
    self.remaining ||= 0
  end
  
end
