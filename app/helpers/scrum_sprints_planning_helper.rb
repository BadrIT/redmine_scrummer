module ScrumSprintsPlanningHelper
  
  include ScrumUserstoriesHelper
  
  def backlog_filter(tracker_id, icon, label)
      link_to_remote image_tag( scrummer_image_path(icon), :class => 'filter-icon'),
                    {:url => {:controller => 'scrum_userstories', :action => 'issues_list', :list_id => 'backlog', :from_sprint => 'backlog', :project_id =>@project, :tracker_id => tracker_id},
                    :update => { :success => 'backlog'},
                    :method => 'GET'},
                    :title  => label
  end
  
  # By Mohamed Magdy
  # Collects all releases to populate them in a combobox
  def available_releases(project)
    project.releases.collect {|release| [release.name, release.id]}
  end
  
  def link_to_wiki_page(page, options={})
    link_to(h(page.pretty_title), {:controller => 'wiki', :action => 'show', :project_id => page.project, :id => page.title},
                           :title => (options[:timestamp] && page.updated_on ? l(:label_updated_time, distance_of_time_in_words(Time.now, page.updated_on)) : nil))
  end
end
