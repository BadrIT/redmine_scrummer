module ScrumSprintsPlanningHelper
  
  include ScrumUserstoriesHelper
  
  def backlog_filter(tracker_id, icon, label)
      link_to_remote image_tag( scrummer_image_path(icon), :class => 'filter-icon', :alt => label),
                    :url => {:controller => 'scrum_userstories', :action => 'issues_list', :list_id => 'backlog', :project_id =>@project, :tracker_id => tracker_id},
                    :update => { :success => 'backlog'},
                    :method => 'GET'
  end
end
