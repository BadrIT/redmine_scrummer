module RedmineScrummer
  module DefaultData
    class DataAlreadyLoaded < Exception; end
    
    module Loader
      include Redmine::I18n
      
      class << self
        # Loads the default data
        def load(lang=nil)
          set_language_if_valid(lang)
          
          filters = {"status_id"=>{:operator=>"*", :values=>[""]}} #TODO should have empty spaces
          columns =  [:subject, :fixed_version, :assigned_to, :story_size, :status, :estimated_hours, :actual_hours, :remaining_hours] 
          options = {:scrummer_caption => "User-Stories", 
                                                   :sort_criteria    => [:id],
                                                   :column_names     => columns,                                                   
                                                   :name             => I18n.translate(:label_scrum_user_stories),
                                                   :filters          => filters, 
                                                   :is_public        => true}
          q = Query.find_or_create_by_scrummer_caption(options)
          q.update_attributes(options)
          
          columns =  [:subject, :assigned_to, :story_size, :status, :estimated_hours, :business_value] 
          sprint_query = Query.find_or_create_by_scrummer_caption(:scrummer_caption => "Sprint-Planning", 
                                                   :sort_criteria    => [],
                                                   :column_names     => columns,                                                   
                                                   :name             => I18n.translate(:label_scrum_sprint_planing),
                                                   :is_public        => true)

          sprint_query.sort_criteria = []
          sprint_query.save
          
          #############################################################################################
          # Create/Update Trackers
          #############################################################################################
          # removing Scrum-Spark as it's now deprecated
          spark_tracker = Tracker.find_by_name('Scrum-Spark')
          spark_tracker.update_attributes({:scrummer_caption => :spike}) if spark_tracker
          
          scrum_tracker_options = {:is_scrum => true, :is_in_roadmap => true, :is_in_chlog => true}
          
          scrum_trackers = { :userstory   => { :name => I18n.translate(:scrum_userStory),   :short_name => 'US'   ,:color => '#C2D3E8', :position => 0},
                             :task        => { :name => I18n.translate(:scrum_task),        :short_name => 'Task' ,:color => '#FFFFFF'},
                             :epic        => { :name => I18n.translate(:scrum_epic),        :short_name => 'Epic' ,:color => '#CCC0D9'},
                             :defect      => { :name => I18n.translate(:scrum_defect),      :short_name => 'DE'   ,:color => '#E5B8B7'},
                             :defectsuite => { :name => I18n.translate(:scrum_defectSuite), :short_name => 'DS'   ,:color => '#D99594'},
                             :refactor    => { :name => I18n.translate(:scrum_refactor),    :short_name => 'RE'   ,:color => '#FBD4B4'},
                             :test        => { :name => I18n.translate(:scrum_test),        :short_name => 'Test' ,:color => '#D9D9D9'},
                             :spike       => { :name => I18n.translate(:scrum_spike),       :short_name => 'Spike',:color => '#FFEC8B'}}
          
          scrum_trackers.each do |caption, options|
            options = options.merge(scrum_tracker_options)
            
            tracker = Tracker.find_or_create_by_scrummer_caption(caption)            
            tracker.update_attributes(options)
          end
          
          #############################################################################################
          # Create/Update Roles
          #############################################################################################
          scrum_roles = { :project_member => I18n.translate(:scrum_projectMember),
                          :scrum_master   => I18n.translate(:scrum_scrumMaster),
                          :product_owner  => I18n.translate(:scrum_productOwner)}
          
          scrum_roles.each do |caption, name|
            role = Role.find_or_create_by_scrummer_caption(caption);
            role.update_attributes(:is_scrum => true, :scrummer_caption => caption, :name => name)
          end
          
          #############################################################################################
          # Create/Update Statuses
          #############################################################################################
          statuses = [
          {:scrummer_caption => :defined,     :position => 1, :is_scrum => true, :width => 20, :name => I18n.translate(:scrum_defined),     :short_name => 'D', :is_default => true, :color => '#FFFFFF'},
          {:scrummer_caption => :in_progress, :position => 2, :is_scrum => true, :width => 30, :name => I18n.translate(:scrum_inProgress),  :short_name => 'P', :color => '#D6E3BC'}, 
          {:scrummer_caption => :completed,   :position => 3, :is_scrum => true, :width => 50, :name => I18n.translate(:scrum_completed),   :short_name => 'C', :color => '#C2D69B'}, 
          {:scrummer_caption => :accepted,    :position => 4, :is_scrum => true, :width => 60, :name => I18n.translate(:scrum_accepted),    :short_name => 'A', :is_closed => true, :color => '#76A03C'},
          {:scrummer_caption => :succeeded,   :position => 5, :is_scrum => true, :width => 50, :name => I18n.translate(:scrum_succeeded),   :short_name => 'S', :is_closed => true, :color => '#10BA00'},
          {:scrummer_caption => :failed,      :position => 6, :is_scrum => true, :width => 60, :name => I18n.translate(:scrum_failed),      :short_name => 'F', :color => '#FF7066'},
          {:scrummer_caption => :finished,    :position => 7, :is_scrum => true, :width => 60, :name => I18n.translate(:scrum_finished),    :short_name => 'F', :is_closed => true, :color => '#B8D050'}]
          
          statuses.each do |options|
            caption = options[:scrummer_caption]
            status = IssueStatus.find_or_create_by_scrummer_caption(caption)
            status.update_attributes(options)
          end

          # remove 'In-Progress' status and user 'In Progress' instead
          old_status = IssueStatus.find_by_name('Scrum-In-Progress')
          new_status = IssueStatus.find_by_name(I18n.translate(:scrum_inProgress))
          if old_status
            Issue.update_all("status_id = #{new_status.id}", "status_id = #{old_status.id}")
            old_status.destroy
          end
          new_status.update_attributes({:scrummer_caption => :in_progress, :position => 2, :is_scrum => true, :name => I18n.translate(:scrum_inProgress), :short_name => 'P'})

          #############################################################################################
          # Create/Update WorkflowTransition
          #############################################################################################                    
          # WorkflowRule.destroy_all
          
          # trackers
          test_id = Tracker.find_by_scrummer_caption(:test).id
          task_id = Tracker.find_by_scrummer_caption(:task).id
          spike_id = Tracker.find_by_scrummer_caption(:spike).id
          
          # statuses
          finished_id = IssueStatus.find_by_scrummer_caption(:finished).id
          failed_id = IssueStatus.find_by_scrummer_caption(:failed).id
          succeeded_id = IssueStatus.find_by_scrummer_caption(:succeeded).id
          
          limited_statuses = [failed_id,finished_id,succeeded_id]
          
          Tracker.find_all_by_is_scrum(true).each do |tracker|
            Role.find_all_by_is_scrum(true).each do |role|
              IssueStatus.find_all_by_is_scrum(true).each do |old_status|
                IssueStatus.find_all_by_is_scrum(true).each do |new_status|
                  # exclude test, task and spike trackers
                  # exclude failed, succeeded and finished statuses
                  if tracker.id != test_id && 
                    tracker.id != task_id && 
                    tracker.id != spike_id &&
                    !limited_statuses.include?(old_status.id) && 
                    !limited_statuses.include?(new_status.id)
                    
                    conditions = {:role_id         => role.id, 
                                    :tracker_id    => tracker.id, 
                                    :old_status_id => old_status.id, 
                                    :new_status_id => new_status.id}
                    
                    WorkflowTransition.find(:first, :conditions => conditions) || WorkflowTransition.create(conditions)
                  end
                end
              end
            end
          end
          
          # WorkflowRule for Scrum_Test
          Role.find_all_by_is_scrum(true).each do |role|
            [:defined,:succeeded,:failed].each do |old_status|
              [:defined,:succeeded,:failed].each do |new_status|
                conditions = {:role_id       => role.id, 
                              :tracker_id    => test_id, 
                              :old_status_id => IssueStatus.find_by_scrummer_caption(old_status).id, 
                              :new_status_id => IssueStatus.find_by_scrummer_caption(new_status).id}
                WorkflowTransition.find(:first, :conditions => conditions) || WorkflowTransition.create(conditions)
              end
            end
          end
          # workflow for Scrum_Task
          Role.find_all_by_is_scrum(true).each do |role|
            [:defined,:in_progress,:finished].each do |old_status|
              [:defined,:in_progress,:finished].each do |new_status|
                [task_id, spike_id].each do |tracker_id|
                  conditions = {:role_id         => role.id, 
                                  :tracker_id    => tracker_id, 
                                  :old_status_id => IssueStatus.find_by_scrummer_caption(old_status).id, 
                                  :new_status_id => IssueStatus.find_by_scrummer_caption(new_status).id}
                  WorkflowTransition.find(:first, :conditions => conditions) || WorkflowTransition.create(conditions)
                end
              end
            end
          end
          
          #############################################################################################  
          # seed scrum roles permissions
          #############################################################################################  
          #TODO (MA): seems like all roles have the same permissions ??
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
            if(role.name == I18n.translate(:scrum_projectMember))
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
            elsif(role.name == I18n.translate(:scrum_scrumMaster))
              role.permissions = all_default_permissions
              role.save!
            elsif(role.name == I18n.translate(:scrum_productOwner))
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
            
            if(role.name == I18n.translate(:scrum_projectMember))
              project_member_permissions = all_scrum_permissions
              role.permissions += project_member_permissions
              role.save!
            elsif(role.name == I18n.translate(:scrum_scrumMaster))
              role.permissions += all_scrum_permissions
              role.save!
            elsif(role.name == I18n.translate(:scrum_productOwner))
              role.permissions += all_scrum_permissions
              role.save!        
            end
          end   
          
          #############################################################################################  
          # Create/Update custom fields
          #############################################################################################  
          
          if ScrumWeeklyNonWorkingDay.first.nil?
            ScrumWeeklyNonWorkingDay.create(:sunday => 0,
              :monday => 0,
              :tuesday => 0,
              :wednesday => 0,
              :thursday => 0,
              :friday => 1,
              :saturday => 1)
          end
          
          # add start_date custom field to versions
          start_date_custom_field = VersionCustomField.find_or_create_by_scrummer_caption(:scrummer_caption => :start_date)
          start_date_custom_field.update_attributes(
                              :name          => I18n.translate(:start_date),
                              :field_format  => 'date')

          # add retrospective custom field to versions
          retrospective_url_custom_field = VersionCustomField.find_or_create_by_scrummer_caption(:scrummer_caption => :retrospective_url)
          retrospective_url_custom_field.update_attributes(
                              :name          => I18n.translate(:retrospective_url),
                              :field_format  => 'string',
                              :is_required   => false)
          
          
          # add story size custom field
          story_size_custom_field = IssueCustomField.find_or_create_by_scrummer_caption(:scrummer_caption => :story_size)
          story_size_custom_field.update_attributes(
                                    :name             => I18n.translate(:story_size),
                                    :field_format     => 'list',
                                    :possible_values  => Scrummer::Constants::StorySizes.map{|size| size.to_f.to_s},
                                    :is_required      => false,
                                    :default_value    => "0.0")
           # add business value custom field
          business_value_custom_field = IssueCustomField.find_or_create_by_scrummer_caption(:scrummer_caption => :business_value)
          business_value_custom_field.update_attributes(
                                    :name             => I18n.translate(:business_value),
                                    :field_format     => 'float',
                                    :default_value    => "0")

          # adding release_id value custom field
          release_custom_field = IssueCustomField.find_or_create_by_scrummer_caption(:scrummer_caption => :release)
          release_custom_field.update_attributes(
                                    :name             => I18n.translate(:release),
                                    :field_format     => 'list',
                                    :possible_values  => ["0"],
                                    :is_required      => false,
                                    :default_value    => "0")

          release_custom_field.update_attribute(:field_format, 'release')

          
          # add remaining time custom field
          remaining_hours_custom_field = IssueCustomField.find_or_create_by_scrummer_caption(:scrummer_caption => :remaining_hours)
          remaining_hours_custom_field.update_attributes(
                                    :name             => I18n.translate(:remaining_hours),
                                    :field_format     => 'float',
                                    :default_value    => "0")
            
          trackers_custom_fields = {:userstory => [:story_size, :business_value, :release],
                                   :epic      => [:story_size, :business_value, :release],
                                   :defectsuite => [:story_size, :business_value, :release],
                                   :task      => [:remaining_hours, :release],
                                   :defect    => [:remaining_hours, :release],
                                   :refactor  => [:remaining_hours, :release],
                                   :spike     => [:remaining_hours, :release]}
          
                                   
          # add connections between fields and trackers          
          trackers_custom_fields.each do |tracker_caption, fields_captions|
            tracker = Tracker.find_by_scrummer_caption(tracker_caption)
            tracker.custom_fields = []
            tracker.custom_fields << IssueCustomField.find_all_by_scrummer_caption(fields_captions)
          end
          
          # set the defualt method for calculation done ratio for issues.
          Setting.issue_done_ratio = 'automatic_calculation'
          TimeEntryActivity.create(:name => 'Scrum')

          true
        end
        
      end
    end
  end
end
