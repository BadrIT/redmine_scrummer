module RedmineScrummer
  module DefaultData
    class DataAlreadyLoaded < Exception; end

    module Loader
      include Redmine::I18n
    
      class << self
        # Loads the default data
        def load(lang=nil)
          set_language_if_valid(lang)
          
          filters = {"status_id"=>{:values=>["1"], :operator=>"o"}}
          columns =  [:subject, :fixed_version, :assigned_to, :cf_1, :status, :estimated_hours, :spent_hours, :cf_2] 
          Query.find_or_create_by_name(:name => l(:label_scrum_user_stories), :filters => filters, :is_public => true, :column_names => columns)
        
          Tracker.find_or_create_by_name(:is_scrum => true, :name => 'Scrum-UserStory', :is_in_roadmap => true, :is_in_chlog => true, :position => 1)
          Tracker.find_or_create_by_name(:is_scrum => true, :name => 'Scrum-Task', :is_in_roadmap => true, :is_in_chlog => true, :position => 2)
          Tracker.find_or_create_by_name(:is_scrum => true, :name => 'Scrum-Epic', :is_in_roadmap => true, :is_in_chlog => true, :position => 3)
          Tracker.find_or_create_by_name(:is_scrum => true, :name => 'Scrum-Theme', :is_in_roadmap => true, :is_in_chlog => true, :position => 5)
    
          Role.find_or_create_by_name(:is_scrum => true, :name => 'Scrum-ProjectMember', :position => 1)
          Role.find_or_create_by_name(:is_scrum => true, :name => 'Scrum-ScrumMaster', :position => 2)
          Role.find_or_create_by_name(:is_scrum => true, :name => 'Scrum-ProductOwner', :position => 3)   
          
          IssueStatus.find_or_create_by_name(:is_scrum => true, :name => 'Scrum-Defined', :position => 1, :is_default => true)
          IssueStatus.find_or_create_by_name(:is_scrum => true, :name => 'Scrum-In-Progress', :position => 2)
          IssueStatus.find_or_create_by_name(:is_scrum => true, :name => 'Scrum-Completed', :position => 3)
          IssueStatus.find_or_create_by_name(:is_scrum => true, :name => 'Scrum-Accepted', :position => 4, :is_closed => true)
  
          Tracker.find_all_by_is_scrum(true).each do |tracker|
            Role.find_all_by_is_scrum(true).each do |role|
              IssueStatus.find_all_by_is_scrum(true).each do |old_status|
                IssueStatus.find_all_by_is_scrum(true).each do |new_status|
                  Workflow.create(:role_id => role.id, 
                                  :tracker_id => tracker.id, 
                                  :old_status_id => old_status.id, 
                                  :new_status_id => new_status.id)
                end
              end
            end
          end   
    
    
          # seed scrum roles permissions
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
          
          all_scrum_permissions = [:scrum_user_stories,
                             :scrum_user_stories_add_inline,
                             :scrum_user_stories_manipulate_inline,
                             :scrum_sprint_planing,
                             :scrum_release_planing,
                             :scrum_charts]
    
    
    
          # seed scrum roles scrum perissions
          Role.find_all_by_is_scrum(true).each do |role|
          
            if(role.name == 'Scrum-ProjectMember')
              project_member_permissions = all_scrum_permissions
              role.permissions += project_member_permissions
              role.save!
            elsif(role.name == 'Scrum-ScrumMaster')
              role.permissions += all_scrum_permissions
              role.save!
            elsif(role.name == 'Scrum-ProductOwner')
              role.permissions += all_scrum_permissions
              role.save!        
            end
          end   
          
          # seed trackers short names
          name_to_short_name = {'Scrum-UserStory' => 'US',
                                'Scrum-Task' => 'Task',
                                'Scrum-Epic' => 'Epic',
                                'Scrum-Theme' => 'Theme'}
                              
          name_to_short_name.each do |name, short_name|
            tracker = Tracker.find_by_name(name)
            tracker.short_name = short_name
            tracker.save!
          end
          
          # seed status short names
          name_to_short_name = {'Scrum-Defined' => 'D',
                                'Scrum-In-Progress' => 'P',
                                'Scrum-Completed' => 'C',
                                'Scrum-Accepted' => 'A'}
                              
          name_to_short_name.each do |name, short_name|
            status = IssueStatus.find_by_name(name)
            status.short_name = short_name
            status.save!
          end
    
    
          # add story size custom field
          require "scrummer_constants"
          story_size_custom_field = IssueCustomField.find_by_name(Scrummer::Constants::CustomStorySizeFieldName)
          story_size_custom_field ||= IssueCustomField.create(:name => Scrummer::Constants::CustomStorySizeFieldName,
                                                            :field_format => 'list',
                                                            :possible_values => Scrummer::Constants::StorySizes.map{|size| size.to_s},
                                                            :is_required => true,
                                                            :default_value => "0")
          story_size_custom_field.save!
          
          # add connections between fields and trackers
          tracker_names = [ Scrummer::Constants::ScrumUserStoryTrackerName,
                            Scrummer::Constants::ScrumEpicTrackerName,
                            Scrummer::Constants::ScrumThemeTrackerName  ]
      
          tracker_names.each do |tracker_name|
            tracker = Tracker.find_by_name(tracker_name)
            tracker.custom_fields << story_size_custom_field
            tracker.save!
          end 
    
          
          # add remaining time custom field
          remaining_hours_custom_field = IssueCustomField.find_by_name(Scrummer::Constants::RemainingHoursCustomFieldName)                                                      
          remaining_hours_custom_field ||= IssueCustomField.create(:name => Scrummer::Constants::RemainingHoursCustomFieldName,
                                                            :field_format => 'float',
                                                            :default_value => "0")
          remaining_hours_custom_field.save!
          
          # add connections between fields and trackers
          tracker = Tracker.find_by_name(Scrummer::Constants::ScrumTaskTrackerName)
          tracker.custom_fields << remaining_hours_custom_field
          tracker.save!
          
          # make story size optional
          story_size_field = IssueCustomField.find_by_name(Scrummer::Constants::CustomStorySizeFieldName)
          story_size_field.is_required = 0
          story_size_field.save!
          
          story_size_field.reload
      
          
          # change status short names
          name_to_short_name = {'Scrum-Defined' => 'D',
                                'Scrum-In-Progress' => 'DP',
                                'Scrum-Completed' => 'DPC',
                                'Scrum-Accepted' => 'DPCA'}
                              
          name_to_short_name.each do |name, short_name|
            status = IssueStatus.find_by_name(name)
            status.short_name = short_name
            status.save!
          end
    
          true
        end
      end
    end
  end
end
