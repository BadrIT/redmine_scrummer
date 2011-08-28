require 'redmine'
require 'dispatcher'
require "scrummer_constants"

Dispatcher.to_prepare :redmine_scrummer do
	require_dependency 'issue'
	require_dependency 'query'
	require_dependency 'tracker'
	
	unless Issue.included_modules.include? RedmineScrummer::IssuePatch
		Issue.send :include, RedmineScrummer::IssuePatch
	end
	
	unless Query.included_modules.include? RedmineScrummer::QueryPatch
		Query.send :include, RedmineScrummer::QueryPatch
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
  	permission :scrum_user_stories, 										{ :scrum_userstories => [:index, :issues_list] }
  	permission :scrum_user_stories_add_inline, 					{ :scrum_userstories => [:inline_add, :get_inline_issue_form, :inline_add_version] }
  	permission :scrum_user_stories_manipulate_inline, 	{ :scrum_userstories => [:refresh_inline_add_form, :update_single_field, :inline_add_version] }
  	
  	permission :scrum_sprint_planing, 									{ :scrum_userstories  => [:sprint_planing]}
  	
  	permission :scrum_release_planing, 									{ :scrum_releases_planning => [:index]}
  	
  	permission :scrum_charts, 													{ :scrum_charts => [:index]}
  end
  
  menu :project_menu, :scrum_charts, { :controller => 'scrum_charts', :action => 'index' }, :after => :activity, :param => :project_id
  menu :project_menu, :scrum_user_stories, { :controller => 'scrum_userstories', :action => 'index' }, :after => :activity, :param => :project_id 
  menu :project_menu, :scrum_sprint_planing, { :controller => 'scrum_userstories', :action => 'sprint_planing' }, :after => :activity, :param => :project_id 
end
