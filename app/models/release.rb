class Release < ActiveRecord::Base
  unloadable
  
  RELEASE_STATUSES = %w(Planning Committed Closed)
  
  validate :dates_overlapping
  validates_uniqueness_of :name, :scope => :project_id
  validates_presence_of :name, :start_date, :release_date, :project_id
  validates_inclusion_of :state, :in => RELEASE_STATUSES
  
  belongs_to :project
  
  has_many   :issues,
             :dependent => :nullify
  
  # By Mohamed Magdy
  # Each release has many versions (sprints)
  has_many :versions, :dependent => :nullify
  
  def number_of_points
    self.issues.inject(0){ |points, issue| points + issue.points_histories.sum(:points) } 
  end

  def sprints
    # get all sprsints that have effective_date (end date) within the time of the release
    project.versions.find(:all,
                          :conditions => ['effective_date >= ? and effective_date <= ?', start_date, release_date],
                          :order => 'effective_date')
  end

  protected
  
  def dates_overlapping
    if self.start_date and self.release_date and self.start_date > self.release_date
      errors.add :date, "Start date must be less than realse date"
      return false
    end
  end

  
end
