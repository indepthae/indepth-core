class JobResourceLocator < ActiveRecord::Base
  
  class << self
    def resources(context, args = {})
      all(:conditions => {:context => context, :locator => locator_string(context, args)}, :order => 'created_at desc')
    end
    
    def locator_string(context, args)
      case context
      when 'assessment_imports'
        "batch_id-#{args[:batch_id]}&assessment_group_id-#{args[:assessment_group_id]}"
      end
    end
    
  end
end
