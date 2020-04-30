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

class TcTemplateFieldHeader < TcTemplateField
  class << self
    def set_config_values(current_version)
      field_ids = []
      school = MultiSchool.current_school
      if current_version_records
        current_version.tc_template_field_ids.each do |k|
          field_ids << k          
        end
        define_new_version 
        field_ids.each do |field_id|
          current_template.tc_template_field_ids <<= field_id
        end
        field = current_version.tc_template_field_headers.find_by_field_name("InstitutionName")
        new_field = TcTemplateFieldHeader.new(:field_name=>field.field_name,:field_info => TcTemplateFieldRecord.new(:value=>"#{school.configurations.get_config_value("InstitutionName")}", :is_enabled=>field.field_info.is_enabled),:priority=> field.priority,:parent_field_id=> field.parent_field_id)
        new_field.save
        current_template.tc_template_field_ids <<= new_field.id
        current_template.tc_template_field_ids=current_template.tc_template_field_ids-[field.id.to_i]
        field = current_version.tc_template_field_headers.find_by_field_name("Phone")
        new_field = TcTemplateFieldHeader.new(:field_name=>field.field_name,:field_info => TcTemplateFieldRecord.new(:value=>"#{school.configurations.get_config_value("InstitutionPhoneNo")}", :is_enabled=>field.field_info.is_enabled),:priority=> field.priority,:parent_field_id=> field.parent_field_id)
        new_field.save
        current_template.tc_template_field_ids <<= new_field.id
        current_template.tc_template_field_ids=current_template.tc_template_field_ids-[field.id.to_i]
        hash= ['Address','Email','Website']
        hash.each do |item|
          field = current_version.tc_template_field_headers.find_by_field_name(item)
          new_field = TcTemplateFieldHeader.new(:field_name=>field.field_name,:field_info => TcTemplateFieldRecord.new(:value=>"#{school.configurations.get_config_value("Institution#{item}")}", :is_enabled=>field.field_info.is_enabled),:priority=> field.priority,:parent_field_id=> field.parent_field_id)
          new_field.save
          current_template.tc_template_field_ids <<= new_field.id
          current_template.tc_template_field_ids=current_template.tc_template_field_ids-[field.id.to_i]
        end
      else
        field = current_version.tc_template_field_headers.find_by_field_name("InstitutionName")
        field.update_attributes(:field_info => TcTemplateFieldRecord.new(:value=>"#{school.configurations.get_config_value("InstitutionName")}", :is_enabled=>field.field_info.is_enabled))
        field = current_version.tc_template_field_headers.find_by_field_name("Phone")
        field.update_attributes(:field_info => TcTemplateFieldRecord.new(:value=>"#{school.configurations.get_config_value("InstitutionPhoneNo")}", :is_enabled=>field.field_info.is_enabled))
        hash= ['Address','Email','Website']
        hash.each do |item|
          field = current_version.tc_template_field_headers.find_by_field_name(item)
          field.update_attributes(:field_info => TcTemplateFieldRecord.new(:value=>"#{school.configurations.get_config_value("Institution#{item}")}", :is_enabled=>field.field_info.is_enabled))
        end
      end
    end
    
    
    
    def get_header_settings(template)
      config = {}
      template.tc_template_field_headers.each do |h|
        tmp_hash = {h.field_name=>h.field_info}
        config.merge! tmp_hash
      end
      return config
    end

    def check_and_save(settings)
      require_new_version_flag = false
      errors = []
      data = []
      field_ids = []
      enable_status = settings.delete("enabled")
      space = settings.delete("space_instead")
      result = current_template.check_header_changes(enable_status[:value], space[:value])
      unless result.errors.present?
#        if enable_status[:value] == "true"
          data = modify_form_data(settings)
          data.each do |hash|
            field = find_or_initialize_header(hash)
            status = require_new_version(field.new_record?)
            require_new_version_flag = true if status
            field.update_attributes(hash)
            field_ids << field.id 
            errors.push(field) if field.errors.present?
          end
          field_ids += get_remaining_fields
          check_version_update(field_ids , require_new_version_flag)
          if errors.length > 0
            return errors
          else
            return []
          end
#        else
#          return []
#        end
      else
        errors.push(result)
        return errors
      end
      
    end
    
    def modify_form_data(settings)
      data = []
      settings.each_pair do |key, value|
        if key.camelize == "AdditionalField"
          value.values.each do |field|
            field.each_pair do |rand, val| 
              field.delete(rand) if val['is_deleted']
            end
          end
        end
        if key.camelize == "DateOfIssue"
          if value.has_key?("is_deleted")
            value["value"] = ""
          end
        end
        object = get_object(key.camelize, value)
        data << {:type=>"TcTemplateFieldHeader",:field_name=>key.camelize, :field_info=>object}
      end
      return data
    end
    
    def get_object(key, hash)
      if key == "AdditionalField"
        field = TcTemplateFieldRecord.new
        field.additional_field_update(hash['value'])
        return field
      else
        if hash['value'].present?
          TcTemplateFieldRecord.new(:value=>hash['value'].strip, :is_enabled=>s_to_bool(hash['is_enabled'] || "nil"))
        else
          if key == "InstitutionLogo"
            TcTemplateFieldRecord.new(:value=>"left", :is_enabled=>s_to_bool(hash['is_enabled'] || "nil"))
          else
            TcTemplateFieldRecord.new(:value=>hash['value'].strip, :is_enabled=>s_to_bool(hash['is_enabled'] || "nil"))
          end
        end
      end
    end
    
    def find_or_initialize_header(field)
      template_field = current_template.tc_template_field_headers.find_by_field_name(field[:field_name])
      if template_field
        presence = check_presence_in_versions(template_field)
        equivalence = compare_fields(template_field, field)
        if equivalence
          new_field = template_field
        else
          new_field = if current_version_records or presence
            TcTemplateFieldHeader.new(field)
          else
            template_field
          end
        end
      else
        new_field = TcTemplateFieldHeader.new(field)
      end
      return new_field
    end
    
    def compare_fields(template_field, field)
      if field[:field_name] == "AdditionalField"
        compare_additional_field(template_field, field)
      else
        record_field = TcTemplateFieldRecord.new
        flag = record_field.compare_header_details(template_field,field[:field_info])
        return flag
      end
    end
    
    def check_presence_in_versions(template_field)
      template_field.tc_template_versions.count > 1
    end
    
    def compare_additional_field(template_field, field)
      status = true
      status  = false if template_field.field_info.additional_field.count != field[:field_info].additional_field.count
      template_field.field_info.additional_field.each do |additional_field|
        obj = field[:field_info].additional_field.find{ |f| (f.value == additional_field.value) && (f.text_size == additional_field.text_size) && (f.text_color == additional_field.text_color) }
        status = false unless obj
        break unless obj
      end
      return status
    end
    
    def compare_additonal_field_objects(object, additional_field)
      (object.value == additional_field.value)&&
        (object.text_color == additional_field.text_color)&&
        (object.text_size == additional_field.text_size)
    end
    
    def get_remaining_fields
      current_template.tc_template_field_student_detail_ids + current_template.tc_template_field_footer_ids
    end
    
    def submitted_values(settings)
      hsh = {}
      settings.each_pair do |key, value|
        object = get_object(key.camelize, value)
        tmp_hsh = {key.camelize=>object}
        hsh.merge! tmp_hsh
      end
      return hsh
    end
  end
end
