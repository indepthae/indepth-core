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

class StudentAdditionalDetail < ActiveRecord::Base
  belongs_to :student
  belongs_to :student_additional_field, :foreign_key=>'additional_field_id'
  validates_presence_of :additional_field_id
  
  named_scope :active_details, :joins => :student_additional_field, :conditions => ["student_additional_fields.status = true"], :select => "name, additional_info, student_id, additional_field_id"

  def validate
    unless self.student_additional_field.nil?
      if self.student_additional_field.status == true
        if self.student_additional_field.is_mandatory == true
          unless self.additional_info.present?
            errors.add("additional_info","can't be blank")
          end
        end
      else
        if self.student_additional_field.is_mandatory == true
          unless self.additional_info.present?
            errors.add("additional_info","can't be blank")
          end
        end
      end
    end
  end

  def before_validation
    unless self.student_additional_field.nil?
      if ["belongs_to","has_many"].include? self.student_additional_field.input_type and self.additional_info.present? and self.additional_info_changed?
        options = self.student_additional_field.student_additional_field_options.collect(&:field_option)
        self.additional_info.split(", ").each do |ad|
          unless options.include? ad
            errors.add(student_additional_field.name.to_sym)
            return false
            # self.additional_info = ""
          end
        end
      end
    end
  end

  def before_create
    if self.additional_info.present? and self.student_additional_field.status == true
      return true
    else
      return false
    end
  end

  def before_update
    if self.additional_info.present? and self.student_additional_field.status == true
      return true
    else
      self.destroy
    end
  end
end
