require 'redmine'

Redmine::Plugin.register :redmine_scrummer do
  name 'Redmine Scrummer plugin'
  author 'BadrIT'
  description 'This plugin goal is to help you to run a SCRUM process in you project '
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://www.badrit.com'
  
  project_module :scrummer do
  	permission :scrum_index, {:scrum => [:index]}, :public => false
  	
  	permission :scrum_user_stories, {:scrum_userstories => [:index]}, :public => false
  	permission :scrum_user_stories_add_inline, {:scrum_userstories => [:inline_add]}, :public => false
  	
  	permission :scrum_sprint_planing, {:scrum_sprints_planning => [:index]}, :public => false
  	
  	permission :scrum_release_planing, {:scrum_releases_planning => [:index]}, :public => false
  	
  	permission :scrum_charts, {:scrum_charts => [:index]}, :public => false
  end
  
  menu :project_menu, :scrum_user_stories, { :controller => 'scrum_userstories', :action => 'index' }, :caption => 'User Stories', :after => :activity, :param => :project_id
  menu :project_menu, :scrum_sprint_planing, { :controller => 'scrum_sprints_planning', :action => 'index' }, :caption => 'Sprint Planning', :after => :activity, :param => :project_id
  menu :project_menu, :scrum_release_planing, { :controller => 'scrum_releases_planning', :action => 'index' }, :caption => 'Release Planning', :after => :activity, :param => :project_id
  menu :project_menu, :scrum_charts, { :controller => 'scrum_charts', :action => 'charts' }, :caption => 'index Charts', :after => :activity, :param => :project_id
end
