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
                                                   
          columns =  [:subject, :assigned_to, :cf_1, :status, :estimated_hours, :cf_3] 
          Query.find_or_create_by_scrummer_caption(:scrummer_caption => "Sprint-Planning", 
                                                   :sort_criteria    => [[:cf_3, 'desc']],
                                                   :column_names     => columns,                                                   
                                                   :name             => l(:label_scrum_sprint_planing),
                                                   :is_public        => true)
        
          #############################################################################################
          # Create/Update Trackers
          #############################################################################################
          scrum_tracker_options = {:is_scrum => true, :is_in_roadmap => true, :is_in_chlog => true}
  
          scrum_trackers = { :userstory   => { :name => l(:scrum_userStory),   :short_name => 'US'   },
                             :task        => { :name => l(:scrum_task),        :short_name => 'Task' },
                             :epic        => { :name => l(:scrum_epic),        :short_name => 'Epic' },
                             :theme       => { :name => l(:scrum_theme),       :short_name => 'Theme'},
                             :defect      => { :name => l(:scrum_defect),      :short_name => 'DE'   },
                             :defectsuite => { :name => l(:scrum_defectSuite), :short_name => 'DS'   },
                             :refactor    => { :name => l(:scrum_refactor),    :short_name => 'RE'   },
                             :test        => { :name => l(:scrum_test),        :short_name => 'Test' },
                             :spark       => { :name => l(:scrum_spark),       :short_name => 'Spark'}}
          
          scrum_trackers.each do |caption, options|
            options = options.merge(scrum_tracker_options)
            
            tracker = Tracker.find_or_create_by_scrummer_caption(caption)            
            tracker.update_attributes(options)
          end
    
          #############################################################################################
          # Create/Update Roles
          #############################################################################################
          scrum_roles = { :project_member => l(:scrum_projectMember),
                          :scrum_master   => l(:scrum_scrumMaster),
                          :product_owner  => l(:scrum_productOwner)}
                             
          scrum_roles.each do |caption, name|
            role = Role.find_or_create_by_scrummer_caption(caption);
            role.update_attributes(:is_scrum => true, :scrummer_caption => caption, :name => name)
          end
                                                   
          #############################################################################################
          # Create/Update Statuses
          #############################################################################################
          statuses = [{:scrummer_caption => :defined,     :is_scrum => true,     :name => l(:scrum_defined),     :short_name => 'D', :is_default => true},
                      {:scrummer_caption => :in_progress, :is_scrum => true,     :name => l(:scrum_inProgress),  :short_name => 'P'}, 
                      {:scrummer_caption => :completed,   :is_scrum => true,     :name => l(:scrum_completed),   :short_name => 'C'}, 
                      {:scrummer_caption => :accepted,    :is_scrum => true,     :name => l(:scrum_accepted),    :short_name => 'A', :is_closed => true},
                      {:scrummer_caption => :succeeded,   :is_scrum => true,     :name => l(:scrum_succeeded),   :short_name => 'S', :is_closed => true},
                      {:scrummer_caption => :failed,      :is_scrum => true,     :name => l(:scrum_failed),      :short_name => 'F'},
                      {:scrummer_caption => :finished,    :is_scrum => true,     :name => l(:scrum_finished),    :short_name => 'F', :is_closed => true}]
          
          statuses.each do |options|
            caption = options[:scrummer_caption]
            status = IssueStatus.find_or_create_by_scrummer_caption(caption)
            status.update_attributes(options)
          end
          
          # update all tasks from completed or accepted to finished
          # TEMP
          task_id = Tracker.find_by_scrummer_caption(:task).id
          tasks = Issue.find_all_by_tracker_id(task_id)
          
          tasks.select{|t| t.status == IssueStatus.accepted || t.status == IssueStatus.completed }.each do |task|
            task.status = IssueStatus.finished
            task.save            
          end
            
          #############################################################################################
          # Create/Update Workflow
          #############################################################################################                    
          Workflow.destroy_all
          
          # trackers
          test_id = Tracker.find_by_scrummer_caption(:test).id
          task_id = Tracker.find_by_scrummer_caption(:task).id
          spark_id = Tracker.find_by_scrummer_caption(:spark).id
          
          # statuses
          finished_id = IssueStatus.find_by_scrummer_caption(:finished).id
          failed_id = IssueStatus.find_by_scrummer_caption(:failed).id
          succeeded_id = IssueStatus.find_by_scrummer_caption(:succeeded).id
          
          limited_statuses = [failed_id,finished_id,succeeded_id]
          
          Tracker.find_all_by_is_scrum(true).each do |tracker|
            Role.find_all_by_is_scrum(true).each do |role|
              IssueStatus.find_all_by_is_scrum(true).each do |old_status|
                IssueStatus.find_all_by_is_scrum(true).each do |new_status|
                  # exclude test, task and spark trackers
                  # exclude failed, succeeded and finished statuses
                  if tracker.id != test_id && 
                      tracker.id != task_id && 
                      tracker.id != spark_id &&
                      !limited_statuses.include?(old_status.id) && 
                      !limited_statuses.include?(new_status.id)
                    
                    conditions = {:role_id         => role.id, 
                                    :tracker_id    => tracker.id, 
                                    :old_status_id => old_status.id, 
                                    :new_status_id => new_status.id}
                    
                    Workflow.find(:first, :conditions => conditions) || Workflow.create(conditions)
                  end
                end
              end
            end
          end
          
          # workflow for Scrum_Test
          Role.find_all_by_is_scrum(true).each do |role|
            [:defined,:succeeded,:failed].each do |old_status|
              [:defined,:succeeded,:failed].each do |new_status|
                conditions = {:role_id       => role.id, 
                              :tracker_id    => test_id, 
                              :old_status_id => IssueStatus.find_by_scrummer_caption(old_status).id, 
                              :new_status_id => IssueStatus.find_by_scrummer_caption(new_status).id}
                Workflow.find(:first, :conditions => conditions) || Workflow.create(conditions)
              end
            end
          end
          # workflow for Scrum_Task
          Role.find_all_by_is_scrum(true).each do |role|
            [:defined,:in_progress,:finished].each do |old_status|
              [:defined,:in_progress,:finished].each do |new_status|
                [task_id, spark_id].each do |tracker_id|
                  conditions = {:role_id         => role.id, 
                                  :tracker_id    => tracker_id, 
                                  :old_status_id => IssueStatus.find_by_scrummer_caption(old_status).id, 
                                  :new_status_id => IssueStatus.find_by_scrummer_caption(new_status).id}
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
            if(role.name == l(:scrum_projectMember))
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
            elsif(role.name == l(:scrum_scrumMaster))
              role.permissions = all_default_permissions
              role.save!
            elsif(role.name == l(:scrum_productOwner))
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
          
            if(role.name == l(:scrum_projectMember))
              project_member_permissions = all_scrum_permissions
              role.permissions += project_member_permissions
              role.save!
            elsif(role.name == l(:scrum_scrumMaster))
              role.permissions += all_scrum_permissions
              role.save!
            elsif(role.name == l(:scrum_productOwner))
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
                                    :name             => l(:story_size),
                                    :field_format     => 'list',
                                    :possible_values  => Scrummer::Constants::StorySizes.map{|size| size.to_s},
                                    :is_required      => false,
                                    :default_value    => "0")

          # add remaining time custom field
          remaining_hours_custom_field = IssueCustomField.find_or_create_by_scrummer_caption(:scrummer_caption => :remaining_hours)
          remaining_hours_custom_field.update_attributes(
                                    :name             => l(:remaining_hours),
                                    :field_format     => 'float',
                                    :default_value    => "0")
                                    
          # add business value custom field
          business_value_custom_field = IssueCustomField.find_or_create_by_scrummer_caption(:scrummer_caption => :business_value)
          business_value_custom_field.update_attributes(
                                    :name             => l(:business_value),
                                    :field_format     => 'float',
                                    :default_value    => "0")

          trackers_custom_fields = { :userstory => [:story_size, :business_value],
                                     :epic      => [:story_size, :business_value],
                                     :theme     => [:story_size, :business_value],
                                     :task      => [:remaining_hours],
                                     :defect    => [:remaining_hours],
                                     :refactor  => [:remaining_hours],
                                     :spark     => [:remaining_hours]}
                    
          # add connections between fields and trackers          
          trackers_custom_fields.each do |tracker_caption, fields_captions|
            tracker = Tracker.find_by_scrummer_caption(tracker_caption)
            tracker.custom_fields = []
            tracker.custom_fields << IssueCustomField.find_all_by_scrummer_caption(fields_captions)
          end
          
          # add buffer_size custom field to versions
          buffer_custom_field = VersionCustomField.find_or_create_by_scrummer_caption(:scrummer_caption => :buffer_size)
          buffer_custom_field.update_attributes(
                              :name          => l(:buffer_size),
                              :field_format  => 'float',
                              :default_value => "0")
          
          # add start_date custom field to versions
          start_date_custom_field = VersionCustomField.find_or_create_by_scrummer_caption(:scrummer_caption => :start_date)
          start_date_custom_field.update_attributes(
                              :name          => l(:start_date),
                              :field_format  => 'date')
                              
          true
        end
      end
    end
  end
end
