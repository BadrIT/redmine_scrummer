module RedmineScrummer
  module ProjectPatch
    
    def self.included(base)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        include InstanceMethods 
        
        after_create :set_weekly_non_working_days
        #TODO Refactoring CF
        after_initialize :initiate_custom_fields
        
        has_many :releases,
                 :dependent => :destroy
        
        has_one :weekly_vacation, :dependent => :destroy
        has_many :vacations, :dependent => :destroy
      end
      
    end
    
    module InstanceMethods
      # This method returns the current sprint of the project if any else returns nil
      def current_or_latest_sprint
        sprints = self.versions.find(:all, :conditions => ['effective_date >= ?', Date.today])
        current_sprint = sprints.find{|sprint| sprint.start_date_custom_value <= Date.today}
        current_sprint || self.versions.all(:order => "effective_date DESC").first
      end
      
      def weekly_vacation_days
        weekly_vacation = []
        if vacation = self.weekly_vacation
          Date::DAYNAMES.each do |day|
            weekly_vacation << day if vacation.send("#{day.downcase}?")
          end
        end
        weekly_vacation
      end
      
      # This method checks if the given date is a non working day or not
      def non_working_day?(date)
        # Checks if the given date is a weekly non working day or a general non working day
        self.weekly_vacation_days.include?(date.strftime("%a")) || self.weekly_vacation_days.include?(date.strftime("%A")) || self.general_non_working_day?(date)
      end
      
      # This method checks if the given date is a general non working day
      def general_non_working_day?(date)
        # Iterating over the project's vacations
        # return if the date lies the start and the end date of the project's non working days
        !self.vacations.all.find{|vacation| (vacation.start_at.to_date..vacation.end_at.to_date) === date}.nil?
      end
      
      # This method sets the default non working days of a project according to the admin's configuration
      def set_weekly_non_working_days
        scrum_weekly_non_working_days = ScrumWeeklyNonWorkingDay.first
        self.weekly_vacation = WeeklyVacation.new
        Date::DAYNAMES.map(&:downcase).each do |day|
          self.weekly_vacation.send("#{day}=", scrum_weekly_non_working_days.send("#{day}?"))
        end
        self.weekly_vacation.save
      end
      
      # This method sets the default scrummer project attributes. By default, the Scrummer option will be 
      # selected on creating a new project as well as the scrummer custom fields (stroy size, remaining hours and the business value)
      def initiate_custom_fields
        if self.new_record?
          Setting.default_projects_modules << "scrummer"
          
          self.issue_custom_fields << CustomField.find_by_scrummer_caption(:story_size)
          self.issue_custom_fields << CustomField.find_by_scrummer_caption(:remaining_hours)
          self.issue_custom_fields << CustomField.find_by_scrummer_caption(:business_value)
        end
      end
    end
  end
end
