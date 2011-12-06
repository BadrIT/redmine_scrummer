ActionController::Routing::Routes.draw do |map|
  map.project_stories 'project', :controller => 'timelog', :action => 'bulk_edit', :conditions => { :method => :get }
  
  map.resources 'releases'
  
  # By Mohamed Magdy
  
  # This is just for adjusting the url to generate PDFs 
  map.scrum_charts '/projects/:project_id/scrum_charts.:format', :controller => 'scrum_charts', :action => 'index'
end