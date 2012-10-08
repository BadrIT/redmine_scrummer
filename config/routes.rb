RedmineApp::Application.routes.draw do
  match 'project' => 'timelog#bulk_edit', :as => :project_stories, :via => [:get]
  
  # Lists of Scrummer Plugin Paths
    
  # Scrum Releases Planning path
  match '/scrum_releases_planning' => 'scrum_releases_planning#index', :as => :scrum_release_planing
  match '/scrum_releases_planning/show_release/:id' => 'scrum_releases_planning#show_release', :as => :show_scrum_release
  match '/scrum_releases_planning/:id/edit_release' => 'scrum_releases_planning#edit_release', :as => :edit_scrum_release
  match '/scrum_releases_planning/create' => 'scrum_releases_planning#create', :as => :create_scrum_release, :via => :post
  match '/scrum_releases_planning/set_issue_release' => 'scrum_releases_planning#set_issue_release', :as => :set_issue_release
  match '/scrum_releases_planning/:id' => 'scrum_releases_planning#update_release', :as => :update_scrum_release, :via => :put
  match '/scrum_releases_planning/:id/destroy_release' => 'scrum_releases_planning#destroy_release', :as => :destroy_scrum_release, :via => :delete
  
  # Sprint Planning path
  match '/scrum_sprints_planning' => 'scrum_sprints_planning#index', :as => :scrum_sprint_planing
  match '/scrum_sprints_planning/:id/edit_version' => 'scrum_sprints_planning#edit_version', :as => :edit_scrum_sprint
  match '/scrum_sprints_planning/add_version' => 'scrum_sprints_planning#add_version', :as => :add_scrum_sprint, :via => :post
  match '/scrum_sprints_planning/:id/destroy_version' => 'scrum_sprints_planning#destroy_version', :as => :destroy_scrum_sprint
  
  # User Stories path
  match '/scrum_userstories' => 'scrum_userstories#index', :as => :scrum_user_stories
  match '/scrum_userstories/statistics' => 'scrum_userstories#calculate_statistics', :as => :scrum_statistics
  match '/scrum_userstories/inline_add' => 'scrum_userstories#inline_add', :as => :inline_add, :via => [:post, :put]
  match '/scrum_userstories/issues_list' => 'scrum_userstories#issues_list', :as => :issues_list, :via => :post
  match '/scrum_userstories/update_single_field' => 'scrum_userstories#update_single_field', :as => :update_single_field
  match '/scrum_userstories/get_inline_issue_form' => 'scrum_userstories#get_inline_issue_form', :as => :get_inline_issue_form
  
  # Scrum Admin path
  match '/scrum_admin' => 'scrum_admins#index', :as => :scrum_admins
  match '/scrum_admin/update_custom_fields' => "scrum_admins#update_scrum_tracker_statuses", :as => :update_scrum_tracker_statuses, :via => :post
  match '/scrum_admin/update_scrum_trackers' => "scrum_admins#update_scrum_trackers", :as => :update_scrum_trackers, :via => :post
  match '/scrum_admin/update_weekly_vacations' => "scrum_admins#update_weekly_vacation", :as => :admin_weekly_vacation
  
  # This is just for adjusting the url to generate PDFs 
  match '/projects/:project_id/scrum_charts.:format' => 'scrum_charts#index', :as => :scrum_charts
  
  # Vacations
  match '/vacations' => 'vacations#index', :as => :vacations
  match '/vacations/add_weekly_vacation' => 'vacations#weekly_vacation', :as => :weekly_vacation
  match '/calendar(/:year(/:month))' => 'calendar#index', :as => :calendar, :constraints => {:year => /\d{4}/, :month => /\d{1,2}/}
  match '/vacations/add_vacation' => 'vacations#add_vacation', :as => :add_vacation
  match '/vacations/:id/delete_vacation' => 'vacations#delete_vacation', :as => :delete_vacation, :via => :delete
end
