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

class EmployeeAdditionalDetail < ActiveRecord::Base
  belongs_to :employee
  belongs_to :additional_field

  validates_presence_of :additional_field_id
  
  named_scope :active_details, :joins => :additional_field, :conditions => ["additional_fields.status = true"], :select => "name, additional_info, employee_id, additional_field_id"
  
  def archive_employee_additional_detail(archived_employee)
    additional_detail_attributes = self.attributes
    additional_detail_attributes.delete "id"
    additional_detail_attributes["employee_id"] = archived_employee
    if ArchivedEmployeeAdditionalDetail.create(additional_detail_attributes)
      self.delete
    else
      return false
    end
  end

  def validate
    unless self.additional_field.nil?
      if self.additional_field.status == true
        if self.additional_field.is_mandatory == true
          unless self.additional_info.present?
            errors.add("additional_info","can't be blank")
          end
        end
      else
        if self.additional_field.is_mandatory == true
          unless self.additional_info.present?
            errors.add("additional_info","can't be blank")
          end
        end
      end
    end
  end

  def before_validation
    unless self.additional_field.nil?
      if ["belongs_to","has_many"].include? self.additional_field.input_type and self.additional_info.present? and self.additional_info_changed?
        options = self.additional_field.additional_field_options.collect(&:field_option)
        self.additional_info.split(", ").each do |ad|
          unless options.include? ad
            self.additional_info = ""
          end
        end
      end
    end
  end

  def before_create
    if self.additional_info.present? and self.additional_field.status == true
      return true
    else
      return false
    end
  end

  def before_update
    if self.additional_info.present? and self.additional_field.status == true
      return true
    else
      self.destroy
    end
  end
end
