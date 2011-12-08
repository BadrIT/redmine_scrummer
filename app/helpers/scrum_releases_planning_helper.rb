module ScrumReleasesPlanningHelper
  
  def issue_li_tag(issue)
      "<li class='issue' id='#{issue.id}'> 
        <a target='_blank' class='issue #{issue.tracker.short_name.downcase}-issue' href='issues/#{issue.id}'> 
          <h2>##{issue.project_issue_number}: #{issue.tracker.short_name}</h2>
          <p>#{issue.subject}</p> 
        </a> 
      </li>"
  end
  
end
