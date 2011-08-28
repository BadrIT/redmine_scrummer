class IssueHistory < ActiveRecord::Base
  unloadable
  
  belongs_to :issue
  
  def after_initialize
    self.date ||= Time.now
  end
  
end
