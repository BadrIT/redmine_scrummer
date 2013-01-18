module RedmineScrummer
  module MailerPatch
    
    def self.included(base)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        
        include InstanceMethods
      end
    end

    module InstanceMethods
      def sprint_start(sprint) 
        redmine_headers 'Project' => sprint.project.identifier,
                    'Version-Id' => sprint.id
        message_id sprint
        @sprint = sprint
        @project = @sprint.project
        @members = @project.members.map{|m| m.user.mail}

        cc = @project.recipients - @members
        mail :to => @members,
          :cc => cc,
          :subject => "[#{@project.name}] #{@sprint.name} has Started"

      end

    end  
  end
end