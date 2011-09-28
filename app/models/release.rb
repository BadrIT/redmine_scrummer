class Release < ActiveRecord::Base
  unloadable
  
  RELEASE_STATUSES = %w(Planning Committed Closed)
  
  validate :dates_overlapping
  validates_uniqueness_of :name
  validates_presence_of :name, :start_date, :release_date, :project_id
  validates_inclusion_of :state, :in => RELEASE_STATUSES
  
  belongs_to :project
  
  has_many   :issues,
             :dependent => :nullify
  protected

  def dates_overlapping
    if self.start_date and self.release_date and self.start_date > self.release_date
      errors.add :date, "Start date must be less than realse date"
      return false
    end
  end
  
end
