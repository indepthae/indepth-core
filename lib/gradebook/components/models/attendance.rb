# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

module Gradebook
  module Components
    module Models
      class Attendance < Base
        properties :type,:parent_name,:parent_type,:name,:total,:attended,:metric 
        
        def days_present_percentage
          return '' if fail_case
          total == "-"? "-" : (total == 0 ? "0%" : ((attended*100.0/total).round(2)).to_s+"%")
        end
        
        def days_present_by_working_days(round = nil)
          return '' if fail_case
          if round.present? and round == true
            "#{attended.to_f.ceil}/#{total.to_f.ceil}"
          else
            "#{attended}/#{total}"
          end
        end
        
        def no_of_days_absent(round = nil)
          return '' if fail_case
          if round.present? and round == true
            total == "-"? "-" : total.to_f.ceil - attended.to_f.ceil
          else
            total == "-"? "-" : total - attended
          end
        end
        
        private
        
        def fail_case
          attended.nil? or total.nil?
        end
        
      end
    end
  end
end
