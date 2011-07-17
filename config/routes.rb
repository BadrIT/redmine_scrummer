ActionController::Routing::Routes.draw do |map|
  map.project_stories 'project',
                   :controller => 'timelog', :action => 'bulk_edit', :conditions => { :method => :get }
end