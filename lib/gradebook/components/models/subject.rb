module Gradebook
  module Components
    module Models
      class Subject < Base
        properties :name, :teacher_name, :parent_name, :parent_type,:parent_id, :is_activity, :type, :children, :obj_id, :code, :exclude_from_total, :parent_subject_id
        
        def parent(report)
          report.subjects.find_by(:name => parent_name, :type => parent_type, :obj_id => parent_id)
        end
        
        def children(report, subject_id = nil)
          report.subjects.find_all_by(:parent_name => name, :parent_type => type, :parent_id => obj_id, :parent_subject_id => subject_id)
        end
        
        
      end
    end
  end
end
