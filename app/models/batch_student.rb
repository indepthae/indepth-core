#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
class BatchStudent < ActiveRecord::Base
  belongs_to :batch
  belongs_to :student
  belongs_to :school
  validates_presence_of :student_id,:batch_id
  
  
  
  def name_with_suffix
    value = Fedena.sort_order_config
    if value == "admission_no"
      return "#{self.full_name} (#{self.admission_no})&#x200E;" 
    elsif value == "roll_number" 
      if self.roll_number.present? 
        return "#{self.full_name} (#{self.roll_number})&#x200E;" 
      else
        return "#{self.full_name} (-)&#x200E;"
      end
    else
      if Configuration.enabled_roll_number?
        return "#{self.full_name} (#{self.roll_number})&#x200E;" if self.roll_number.present? 
        return "#{self.full_name} (-)&#x200E;" unless self.roll_number.present? 
      else
        return "#{self.full_name} (#{self.admission_no})&#x200E;"
      end
    end
  end
  
  #GradeBook batch effective batch students associations
  
  def assessment_marks
    AssessmentMark.all(:conditions => {:student_id => self.id})
  end
  
  def converted_assessment_marks
    ConvertedAssessmentMark.all(:conditions => {:student_id => self.id})
  end
  
  def individual_reports
    IndividualReport.all(:conditions => {:student_id => self.id})
  end
  
  #-------------------------------------------------------#
  
  def self.check_and_sort
    if roll_number_config_value == "1"
      return "soundex(roll_number),length(roll_number),roll_number ASC"
    else
      return "first_name ASC"
    end
  end
  
  def self.roll_number_config_value
    Configuration.find_by_config_key('EnableRollNumber').config_value
  end
end
