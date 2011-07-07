require File.dirname(__FILE__) + '/../test_helper'

require 'scrum_userstories_controller'

# Re-raise errors caught by the controller.
class ScrumUserstoriesController; def rescue_action(e) raise e end; end


class ScrumUserstoriesControllerTest < ActionController::TestCase
	
		
	# US40
	def test_changing_inline_issue_tracker_requests_inline_form
		
	end
	
	# US40
	def test_hours_aggregated_at_parent
		
	end
	
	# US38
	def test_story_size_exists_as_custom_column
		
	end
	
	# US42
	def test_custom_queries_exist_to_show_backlog
		
	end
	
	# US42
	def test_custom_queries_exist_to_show_all_user_stories
		
	end
	
	# US42
	def test_subject_is_shown_on_hover_on_story_subject
		
	end
	
	# US42
	def test_can_collapse_expand_all_by_one_button
		
	end
	
	# US42
	def test_can_edit_story_inline
		
	end

	# US42
	def test_can_delete_stories_inline
		
	end

	# US42
	def test_inline_est_hours_only_shown_for_scrum_tasks
		
	end
	
	# US42
	def test_inline_remaining_hours_only_shown_for_scrum_tasks
		
	end

	# US42
	def test_inline_size_only_shown_for_scrum_stories
		
	end
	
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
