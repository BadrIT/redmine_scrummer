module ScrumReleasesPlanningHelper
  
  def issue_li_tag(issue)
    unit = issue.has_custom_field?(:story_size) ? "pt":"hr"
    "<li class='issue' id='#{issue.id}'> 
      <a target='_blank' class='issue #{issue.tracker.short_name.downcase}-issue' href='issues/#{issue.id}'> 
      <h2>##{issue.id}: #{issue.tracker.short_name}</h2>
      <p>#{truncate(issue.subject, 40, "...")}</p> 
      <p><span style='color: #444; float: right;'>#{issue.story_size} #{unit}</span></p> 
      </a> 
     </li>"
  end
  
end
