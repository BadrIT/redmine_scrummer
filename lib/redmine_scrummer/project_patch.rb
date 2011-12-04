module RedmineScrummer
  module ProjectPatch
    
    def self.included(base)
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development
        
        has_many :releases,
                 :dependent => :destroy
      end
      
    end
  end
end
