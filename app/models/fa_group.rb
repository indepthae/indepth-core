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
class FaGroup < ActiveRecord::Base
  has_many :fa_criterias
  has_and_belongs_to_many :subjects
  belongs_to :cce_exam_category
  has_many :cce_reports , :as=>:observable
  validates_numericality_of :max_marks, :greater_than_or_equal_to => 0.0
  #  has_many :cce_reports, :through=>:fa_criterias
  validate :formula_validate

  named_scope :active,:conditions=>{:is_deleted=>false}

  def validate
    errors.add_to_base("Name can't be blank") unless self.name.present?
    errors.add_to_base("CCE exam category can't be blank") if self.cce_exam_category_id.blank?
    errors.add_to_base("Description can't be blank") if self.desc.blank?
    errors.add_to_base("CCE exam category can't be modified since dependencies exist") if assessment_scores_entries_present and self.cce_exam_category_id_changed?
  end
  
  def formula_validate
    fa_setting = Configuration.find_or_create_by_config_key("CceFaType")
    if criteria_formula.present?
      valid_formula = ExamFormula.formula_validate(criteria_formula,fa_setting.config_value)
      if valid_formula == false
        errors.add_to_base('Invalid Formula')
        return false
      else
        return true
      end
    else
      return true
    end
  end

  def assessment_scores_entries_present
    fa_criterias.active.each do |fa_criteria|
      return true if fa_criteria.assessment_scores.present?
    end
    return false
  end
    
end
