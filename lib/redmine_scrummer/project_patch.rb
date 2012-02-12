module RedmineScrummer
  module ProjectPatch
    
    def self.included(base)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        include InstanceMethods 
        
        has_many :releases,
                 :dependent => :destroy
        
        has_one :weekly_vacation, :dependent => :destroy
        has_many :vacations, :dependent => :destroy
      end
      
    end
    
    module InstanceMethods
      # This method returns the current sprint of the project if any else returns nil
      def current_sprint
        sprints = self.versions.find(:all, :conditions => ['effective_date >= ?', Date.today])
        sprints.each do |sprint|
          return sprint if sprint.start_date_custom_value <= Date.today
        end
        nil
      end
      
      def weekly_vacation_days
        weekly_vacation = []
        weekly_vacation << "Sunday" if self.weekly_vacation.sunday?
        weekly_vacation << "Monday" if self.weekly_vacation.monday?
        weekly_vacation << "Tuesday" if self.weekly_vacation.tuesday?
        weekly_vacation << "Wednesday" if self.weekly_vacation.wednesday?
        weekly_vacation << "Thursday" if self.weekly_vacation.thursday?
        weekly_vacation << "Friday" if self.weekly_vacation.friday?
        weekly_vacation << "Saturday" if self.weekly_vacation.saturday?
        weekly_vacation
      end
      
      # This method checks if the given date is a non working day or not
      def non_working_day?(date)
        # Checks if the given date is a weekly non working day or a general non working day
        self.weekly_vacation_days.include?(date.strftime("%a")) || self.weekly_vacation_days.include?(date.strftime("%A")) || self.general_non_working_day(date)
      end
      
      # This method checks if the given date is a general non working day
      def general_non_working_day(date)
        # Iterating over the project's vacations
        self.vacations.each do |vacation|
          # return if the date lies the start and the end date of the project's non working days
          return true if (vacation.start_at.to_date..vacation.end_at.to_date) === date
        end
        false
      end
    end
  end
end
