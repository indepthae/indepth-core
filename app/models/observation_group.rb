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
class ObservationGroup < ActiveRecord::Base
  has_many                  :observations
  has_many                  :descriptive_indicators, :through=>:observations
  belongs_to                :cce_grade_set
  has_and_belongs_to_many   :courses

  named_scope :active,:conditions=>{:is_deleted=>false}
  
  OBSERVATION_KINDS={'2'=>'Scholastic','3'=>'Co-Scholastic Activity','1'=>'Co-Scholastic Area'}

  validates_presence_of :name
  validates_presence_of :header_name
  validates_presence_of :observation_kind
  validates_presence_of :di_count_in_report
  validates_numericality_of :di_count_in_report,:greater_than_or_equal_to=>0 
 def validate
    errors.add_to_base("CCE grade set can't be blank") if self.cce_grade_set_id.blank?
    errors.add_to_base("Description can't be blank") if self.desc.blank?
  end

  def max_grade
    if self.cce_grade_set.cce_grades.present?
      self.cce_grade_set.cce_grades.first(:order=>'grade_point DESC').grade_point.to_f
    else
      5.0
    end
  end
  
end
