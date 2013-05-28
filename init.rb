require 'redmine'
require 'scrummer_constants'

Rails.configuration.to_prepare do
	require_dependency 'issue'
	require_dependency 'query'
  require_dependency 'tracker'
	require_dependency 'mailer'
	
  unless Mailer.included_modules.include? RedmineScrummer::MailerPatch
    Mailer.send :include, RedmineScrummer::MailerPatch
  end

	unless Issue.included_modules.include? RedmineScrummer::IssuePatch
		Issue.send :include, RedmineScrummer::IssuePatch
	end
	
  # IssueQuery is introduced in redmine 2.2
  # unless defined?(IssueQuery)
  #   class IssueQuery < Query
  #   end
  # end

	unless IssueQuery.included_modules.include? RedmineScrummer::IssueQueryPatch
		IssueQuery.send :include, RedmineScrummer::IssueQueryPatch
	end
	
	unless Tracker.included_modules.include? RedmineScrummer::TrackerPatch
		Tracker.send :include, RedmineScrummer::TrackerPatch
	end
	
	unless IssueStatus.included_modules.include? RedmineScrummer::IssueStatusPatch
    IssueStatus.send :include, RedmineScrummer::IssueStatusPatch
  end
  
  unless IssueCustomField.included_modules.include? RedmineScrummer::IssueCustomFieldPatch
    IssueCustomField.send :include, RedmineScrummer::IssueCustomFieldPatch
  end
  
  unless Role.included_modules.include? RedmineScrummer::RolePatch
    Role.send :include, RedmineScrummer::RolePatch
  end
  
  unless Version.included_modules.include? RedmineScrummer::VersionPatch
    Version.send :include, RedmineScrummer::VersionPatch
  end
  
  unless Project.included_modules.include? RedmineScrummer::ProjectPatch
    Project.send :include, RedmineScrummer::ProjectPatch
  end
  
  unless TimeEntry.included_modules.include? RedmineScrummer::TimeEntryPatch
    TimeEntry.send :include, RedmineScrummer::TimeEntryPatch
  end
  
  unless CustomValue.included_modules.include? RedmineScrummer::CustomValuePatch
    CustomValue.send :include, RedmineScrummer::CustomValuePatch
  end

  unless CustomField.included_modules.include? RedmineScrummer::CustomFieldPatch
    CustomField.send :include, RedmineScrummer::CustomFieldPatch
  end

  unless VersionCustomField.included_modules.include? RedmineScrummer::VersionCustomFieldPatch
    VersionCustomField.send :include, RedmineScrummer::VersionCustomFieldPatch
  end
end

Redmine::Plugin.register :redmine_scrummer do
  name 'Redmine Scrummer plugin'
  author 'BadrIT'
  description 'This plugin goal is to help you to run a SCRUM process in you project '
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://www.badrit.com'
  
  requires_redmine :version_or_higher => '1.2.0' 
  
  project_module :scrummer do
  	permission :scrum_user_stories, 										{ :scrum_userstories => [:index, :issues_list, :calculate_statistics] }
  	permission :scrum_user_stories_add_inline, 					{ :scrum_userstories => [:inline_add, :get_inline_issue_form], :scrum_sprints_planning =>  [:inline_add_version, :add_version, :destroy_version] }
  	permission :scrum_user_stories_manipulate_inline, 	{ :scrum_userstories => [:get_inline_issue_form, :refresh_inline_add_form, :update_single_field, :inline_add_version, :add_version, :destroy_version] }
  	
  	permission :scrum_sprint_planing, 									{ :scrum_sprints_planning  => [:index, :sprint_info, :add_version, :destroy_version, :edit_version]}
  	
  	permission :scrum_release_planing, 									{ :scrum_releases_planning => [:index, :create, :destroy_release, :show_release, :edit_release, :update_release, :set_issue_release]}
  	
  	permission :scrum_charts, 													{ :scrum_charts => [:index, :update_chart]}
  	permission :scrum_admins,                           { :scrum_admins => [:index, :update_scrum_trackers, :update_scrum_tracker_statuses] }, :require => :member
    permission :vacations,                              { :vacations => [:index] }, :public => true
  end
  
  # Adjusting the Scrummer Menu "Scrummer Tab"
  menu :project_menu, :scrummer, {:controller => 'scrum_userstories', :action => 'index' }, :after => :activity, :param => :project_id
  menu :project_menu, :non_working_days, {:controller => 'vacations', :action => 'index' }, :after => :scrummer, :param => :project_id
  # The scrum admin menu
  menu :top_menu, :scrum_admin, {:controller => 'scrum_admins', :action => 'index' }, :caption => 'Scrum Admin', :if => Proc.new { User.current.admin? }
#  menu :project_menu, :scrum_user_stories, { :controller => 'scrum_userstories', :action => 'index' }, :after => :activity, :param => :project_id 
#  menu :project_menu, :scrum_sprint_planing, { :controller => 'scrum_sprints_planning', :action => 'index' }, :after => :activity, :param => :project_id 
#  menu :project_menu, :scrum_release_planing, { :controller => 'scrum_releases_planning', :action => 'index' }, :after => :scrum_charts, :param => :project_id 
end

Float.class_eval do
  def empty?
  end
end

Redmine::CustomFieldFormat.class_eval do
  def format_as_release(value)
    value
  end
end
release_field_format = Redmine::CustomFieldFormat.new("release", :edit_as => "list", :label => "release")
Redmine::CustomFieldFormat.register(release_field_format)