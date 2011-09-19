module ScrumReleasesPlanningHelper
  
  def issue_li_tag(issue)
      "<li class='issue'> 
        <a class='issue #{issue.tracker.short_name.downcase}-issue' href='issues/#{issue.id}'> 
          <h2>##{issue.id}:#{issue.subject}</h2> 
          <p>#{truncate(issue.description, 80, "...")}</p> 
        </a> 
      </li>"
  end
  
end
