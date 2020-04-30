# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Gradebook
  module Components
    module Models
      class Remark < Base
        
        # :type => general or subject depending on the remark type
        # :type_id => id of the RemarkSet or Subject
        # :parent_name => name of the reportable(name of Assessment Group, Term or Plan)
        # :parent_type => values may be AssessmentGroup or AssessmentTerm or AssessmentPlan
        # :name => Remark Set name if general remark else Subject name
        # :remark => remark of that reportable for that student
        # :is_inherited => whether the remark is inherited or not
        properties :type, :type_id, :parent_name, :parent_type, :name, :remark, :is_inherited
        
      end
    end
  end
end
