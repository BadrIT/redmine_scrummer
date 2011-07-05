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
        
          true
        end
      end
    end
  end
end
