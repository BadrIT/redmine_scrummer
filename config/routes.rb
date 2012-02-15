ActionController::Routing::Routes.draw do |map|
  map.project_stories 'project', :controller => 'timelog', :action => 'bulk_edit', :conditions => { :method => :get }
  
  # By Mohamed Magdy
  # Lits of Scrummer Plugin Paths
  
  # Scrum Releases Planning path
  map.scrum_release_planing '/scrum_releases_planning', :controller => 'scrum_releases_planning', :action => 'index'
  map.show_scrum_release '/scrum_releases_planning/show_release/:id', :controller => 'scrum_releases_planning', :action => 'show_release'
  map.edit_scrum_release '/scrum_releases_planning/:id/edit_release', :controller => 'scrum_releases_planning', :action => 'edit_release'
  map.create_scrum_release '/scrum_releases_planning/create', :controller => 'scrum_releases_planning', :action => 'create', :method => :post
  map.set_issue_release '/scrum_releases_planning/set_issue_release', :controller => 'scrum_releases_planning', :action => 'set_issue_release'
  map.update_scrum_release '/scrum_releases_planning/:id', :controller => 'scrum_releases_planning', :action => 'update_release', :method => :put
  
  # Sprint Planning path
  map.scrum_sprint_planing '/scrum_sprints_planning', :controller => 'scrum_sprints_planning', :action => 'index'
  
  # User Stories path
  map.scrum_user_stories '/scrum_userstories', :controller => 'scrum_userstories', :action => 'index'
  map.scrum_statistics '/scrum_userstories/statistics', :controller => 'scrum_userstories', :action => 'calculate_statistics'
  
  # Scrum Admin path
  map.scrum_admins '/scrum_admin', :controller => 'scrum_admins', :action => 'index'
  map.update_scrum_tracker_statuses '/scrum_admin/update_custom_fields', :controller => "scrum_admins", :action => "update_scrum_tracker_statuses", :method => :post
  map.update_scrum_trackers '/scrum_admin/update_scrum_trackers', :controller => "scrum_admins", :action => "update_scrum_trackers", :method => :post
  map.admin_weekly_vacation '/scrum_admin/update_weekly_vacations', :controller => "scrum_admins", :action => "update_weekly_vacation"
  
  # This is just for adjusting the url to generate PDFs 
  map.scrum_charts '/projects/:project_id/scrum_charts.:format', :controller => 'scrum_charts', :action => 'index'
  
  # Vacations
  map.vacations '/vacations', :controller => 'vacations', :action => 'index'
  map.weekly_vacation '/vacations/add_weekly_vacation', :controller => 'vacations', :action => 'weekly_vacation'
  map.calendar '/calendar/:year/:month', :controller => 'calendar', :action => 'index', :requirements => {:year => /\d{4}/, :month => /\d{1,2}/}, :year => nil, :month => nil
  map.add_vacation '/vacations/add_vacation', :controller => 'vacations', :action => 'add_vacation'
  map.delete_vacation '/vacations/:id/delete_vacation', :controller => 'vacations', :action => 'delete_vacation', :method => :delete
end