class SeedScrumRolesPermissions < ActiveRecord::Migration
	def self.up
		
		all_default_permissions = [:add_issue_notes,
														:add_issue_watchers,
														:add_issues,
														:add_messages,
														:add_project,
														:add_subprojects,
														:browse_repository,
														:comment_news,
														:commit_access,
														:delete_issue_watchers,
														:delete_issues,
														:delete_messages,
														:delete_own_messages,
														:delete_wiki_pages,
														:delete_wiki_pages_attachments,
														:edit_issue_notes,
														:edit_issues,
														:edit_messages,
														:edit_own_issue_notes,
														:edit_own_messages,
														:edit_own_time_entries,
														:edit_project,
														:edit_time_entries,
														:edit_wiki_pages,
														:export_wiki_pages,
														:log_time,
														:manage_boards,
														:manage_categories,
														:manage_documents,
														:manage_files,
														:manage_issue_relations,
														:manage_members,
														:manage_news,
														:manage_project_activities,
														:manage_public_queries,
														:manage_repository,
														:manage_subtasks,
														:manage_versions,
														:manage_wiki,
														:move_issues,
														:protect_wiki_pages,
														:rename_wiki_pages,
														:save_queries,
														:search_project,
														:select_project_modules,
														:set_issues_private,
														:set_own_issues_private,
														:view_calendar,
														:view_changesets,
														:view_documents,
														:view_files,
														:view_gantt,
														:view_issue_watchers,
														:view_issues,
														:view_messages,
														:view_news,
														:view_project,
														:view_time_entries,
														:view_wiki_edits,
														:view_wiki_pages]
														
		Role.find_all_by_is_scrum(true).each do |role|
			
			if(role.name == 'Scrum-ProjectMember')
				project_member_permissions = all_default_permissions - [:add_project,
																																:add_subprojects,
																																:add_issues,													
																																:delete_issue_watchers,
																																:delete_issues,
																																:delete_messages,
																																:delete_wiki_pages,
																																:delete_wiki_pages_attachments,														
																																:edit_issues,														
																																:manage_boards,
																																:manage_categories,
																																:manage_documents,
																																:manage_files,
																																:manage_issue_relations,
																																:manage_members,
																																:manage_news,
																																:manage_project_activities,
																																:manage_public_queries,
																																:manage_repository,
																																:manage_subtasks,
																																:manage_versions,
																																:manage_wiki,
																																:move_issues,														
																																:set_issues_private]
				role.permissions = project_member_permissions
				role.save!
			elsif(role.name == 'Scrum-ScrumMaster')
				role.permissions = all_default_permissions
				role.save!
			elsif(role.name == 'Scrum-ProductOwner')
				product_owner_permissions = all_default_permissions - [:add_project,
																															:add_subprojects,
																															:delete_issue_watchers,
																															:delete_wiki_pages,
																															:delete_wiki_pages_attachments,														
																															:manage_boards,
																															:manage_categories,
																															:manage_members,
																															:manage_news,
																															:manage_project_activities,
																															:manage_public_queries,
																															:manage_repository,
																															:manage_subtasks,
																															:manage_versions,
																															:manage_wiki,
																															:move_issues,														
																															:set_issues_private];
				role.permissions = product_owner_permissions
				role.save!				
			end
		end		
	end
	
	def self.down		
	end
end