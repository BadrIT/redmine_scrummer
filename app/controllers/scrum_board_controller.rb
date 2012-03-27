class ScrumBoardController < ApplicationController
  unloadable

  include ScrumUserstoriesController::SharedScrumConstrollers

  prepend_before_filter :find_scrum_project
  before_filter :current_page_setter
  
  def index
    initialize_board
  end
  
  def sprint_board
    initialize_board
    
    render :update do |page|
      page.replace_html "board", :partial => "scrum_board"
    end
  end
  
  def update_status
     status = params[:status]
     issue = @project.issues.find(params[:issue_id])
     case status
     when "backlog"
       issue.update_attribute(:status_id, IssueStatus.find_by_scrummer_caption(:defined).id) 
     when "inprogress"
       issue.update_attribute(:status_id, IssueStatus.find_by_scrummer_caption(:in_progress).id)
     when "completed"
       issue.task? ? issue.update_attribute(:status_id, IssueStatus.find_by_scrummer_caption(:finished).id): issue.update_attribute(:status_id, IssueStatus.find_by_scrummer_caption(:completed).id)
     when "accepted"
       issue.update_attribute(:status_id, IssueStatus.find_by_scrummer_caption(:accepted).id)
     end
     
     render :nothing => true
  end
  
  private
  
  def initialize_board
    @issues = []
    @sprint = params[:sprint_id] ? @project.versions.find(params[:sprint_id]) : @project.current_or_latest_sprint
    
    @sprint.user_stories.each do |user_story|
      @issues << [user_story] + user_story.issue_tasks 
    end
    
    @sprint.defects do |defect|
      @issues << [defect] + defect.children
    end  
  end
  
  def current_page_setter
    @current_page = :board
  end
end
