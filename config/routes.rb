ActionController::Routing::Routes.draw do |map|
  map.project_stories 'project', :controller => 'timelog', :action => 'bulk_edit', :conditions => { :method => :get }
  
  map.resources 'releases'
  
  # By Mohamed Magdy
  # Lits of Scrummer Plugin Paths
  
  # Scrum Releases Planning path
  map.scrum_release_planing '/scrum_releases_planning', :controller => 'scrum_releases_planning', :action => 'index'
  
  # Sprint Planning path
  map.scrum_sprint_planing '/scrum_sprints_planning', :controller => 'scrum_sprints_planning', :action => 'index'
  
  # User Stories path
  map.scrum_user_stories '/scrum_userstories', :controller => 'scrum_userstories', :action => 'index'
  
  # This is just for adjusting the url to generate PDFs 
  map.scrum_charts '/projects/:project_id/scrum_charts.:format', :controller => 'scrum_charts', :action => 'index'
  
end