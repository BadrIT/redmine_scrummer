desc 'Run Scrummer scheduled tasks'

namespace :redmine_scrummer do

  # send daily notification for sprints started today
  task :scheduler => :environment do
    versions = Version.all.select do |v| 
      start_date = v.try(:start_date_custom_value)

      start_date && start_date == Date.today
    end

    versions.each do |sprint|
      Mailer.sprint_start(sprint).deliver
    end

  end
end