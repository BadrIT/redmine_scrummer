module RedmineScrummer
  module DefaultData
    class DataAlreadyLoaded < Exception; end

    module Loader
      include Redmine::I18n
    
      class << self
        # Loads the default data
        def load(lang=nil)
          set_language_if_valid(lang)
          
          filters = {"status_id"=>{:values=>["1"], :operator=>"o"}} #TODO should have empty spaces
          columns =  [:subject, :fixed_version, :assigned_to, :cf_1, :status, :estimated_hours, :spent_hours, :cf_2] 
          Query.find_or_create_by_scrummer_caption(:scrummer_caption => "User-Stories", 
                                                   :sort_criteria    => [:id],
                                                   :column_names     => columns,                                                   
                                                   :name             => l(:label_scrum_user_stories),
                                                   :filters          => filters, 
                                                   :is_public        => true)
        
          #############################################################################################
          # Temp (for migration to use loader smoothly)
          #############################################################################################
          
          {Scrummer::Constants::CustomStorySizeFieldName      => :story_size,
           Scrummer::Constants::RemainingHoursCustomFieldName => :remaining_hours}.each do |name, caption|
              IssueCustomField.find_by_name(name).update_attributes(:scrummer_caption => caption) if IssueCustomField.find_by_name(name) 
          end
      
          
          {'Scrum-UserStory'   => :userstory,
          'Scrum-Task'        => :task,
          'Scrum-Epic'        => :epic,
          'Scrum-Theme'       => :theme,
          'Scrum-Defect'      => :defect,
          'Scrum-DefectSuite' => :defectsuite,
          'Scrum-Refactor'    => :refactor}.each do |name, caption|
            Tracker.find_by_name(name).update_attributes(:scrummer_caption => caption) if Tracker.find_by_name(name)
          end
          
          {'Scrum-ProjectMember' => :project_member,
          'Scrum-ScrumMaster'   => :scrum_master,
          'Scrum-ProductOwner'  => :product_owner}.each do |name, caption|
            Role.find_by_name(name).update_attributes(:scrummer_caption => caption) if Role.find_by_name(name)
          end
          
          {'Scrum-Defined' => :defined,
          'Scrum-In-Progress' => :in_progress,
          'Scrum-Completed' => :completed,
          'Scrum-Accepted' => :accepted}.each do |name, caption|
            IssueStatus.find_by_name(name).update_attributes(:scrummer_caption => caption) if IssueStatus.find_by_name(name)
          end
                    
          #############################################################################################
          # Create/Update Trackers
          #############################################################################################
          scrum_tracker_options = {:is_scrum => true, :is_in_roadmap => true, :is_in_chlog => true}
  
          scrum_trackers = { :userstory   => { :name => 'Scrum-UserStory',   :short_name => 'US'},
                             :task        => { :name => 'Scrum-Task',        :short_name => 'Task'},
                             :epic        => { :name => 'Scrum-Epic',        :short_name => 'Epic'},
                             :theme       => { :name => 'Scrum-Theme',       :short_name => 'Theme'},
                             :defect      => { :name => 'Scrum-Defect',      :short_name => 'DE'},
                             :defectsuite => { :name => 'Scrum-DefectSuite', :short_name => 'DS'},
                             :refactor    => { :name => 'Scrum-Refactor',    :short_name => 'RE'} }
          
          scrum_trackers.each do |caption, options|
            options = options.merge(scrum_tracker_options)
            
            tracker = Tracker.find_or_create_by_scrummer_caption(caption)            
            tracker.update_attributes(options)
          end
    
          #############################################################################################
          # Create/Update Roles
          #############################################################################################
          scrum_roles = { :project_member => 'Scrum-ProjectMember',
                          :scrum_master   => 'Scrum-ScrumMaster',
                          :product_owner  => 'Scrum-ProductOwner'}
                             
          scrum_roles.each do |caption, name|
            role = Role.find_or_create_by_scrummer_caption(caption);
            role.update_attributes(:is_scrum => true, :scrummer_caption => caption, :name => name)
          end
                                                   
          #############################################################################################
          # Create/Update Statuses
          #############################################################################################
          statuses = [{:scrummer_caption => :defined,     :name => 'Scrum-Defined',     :short_name => 'D', :is_default => true},
                      {:scrummer_caption => :in_progress, :name => 'Scrum-In-Progress', :short_name => 'P'}, 
                      {:scrummer_caption => :completed,   :name => 'Scrum-Completed',   :short_name => 'C'}, 
                      {:scrummer_caption => :accepted,    :name => 'Scrum-Accepted',    :short_name => 'A', :is_closed => true}]
          
          statuses.each do |options|
            caption = options[:scrummer_caption]
            status = IssueStatus.find_or_create_by_scrummer_caption(caption)
            status.update_attributes(options)
          end
            
          #############################################################################################
          # Create/Update Workflow
          #############################################################################################                    
          Tracker.find_all_by_is_scrum(true).each do |tracker|
            Role.find_all_by_is_scrum(true).each do |role|
              IssueStatus.find_all_by_is_scrum(true).each do |old_status|
                IssueStatus.find_all_by_is_scrum(true).each do |new_status|
                  conditions = {:role_id => role.id, 
                                  :tracker_id => tracker.id, 
                                  :old_status_id => old_status.id, 
                                  :new_status_id => new_status.id}
                  Workflow.find(:first, :conditions => conditions) || Workflow.create(conditions)
                end
              end
            end
          end   
    
          #############################################################################################  
          # seed scrum roles permissions
          #############################################################################################  
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
    
          #############################################################################################  
          # Seed Scrum Permissions
          #############################################################################################        
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
          
          #############################################################################################  
          # Create/Update custom fields
          #############################################################################################  
  
          # add story size custom field
          story_size_custom_field = IssueCustomField.find_or_create_by_scrummer_caption(:scrummer_caption => :story_size)
          story_size_custom_field.update_attributes(
                                    :name             => 'Story-Size',
                                    :field_format     => 'list',
                                    :possible_values  => Scrummer::Constants::StorySizes.map{|size| size.to_s},
                                    :is_required      => false,
                                    :default_value    => "0")

          # add remaining time custom field
          remaining_hours_custom_field = IssueCustomField.find_or_create_by_scrummer_caption(:scrummer_caption => :remaining_hours)
          remaining_hours_custom_field.update_attributes(
                                    :name             => 'TODO(hrs)',
                                    :field_format     => 'float',
                                    :default_value    => "0")

          trackers_custom_fields = { :userstory => [:story_size],
                                     :epic      => [:story_size],
                                     :theme     => [:story_size],
                                     :task      => [:remaining_hours],
                                     :defect    => [:remaining_hours],
                                     :refactor  => [:remaining_hours]}
                    
          # add connections between fields and trackers          
          trackers_custom_fields.each do |tracker_caption, fields_captions|
            tracker = Tracker.find_by_scrummer_caption(tracker_caption)
            tracker.custom_fields << IssueCustomField.find_all_by_scrummer_caption(fields_captions)
          end
      
          true
        end
      end
    end
  end
end
