# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class TcTemplateFieldFooter < TcTemplateField
  class << self
    def get_footer_settings(template)
      config = {}
      template.tc_template_field_footers.each do |f|
        tmp_hash = {f.field_name=>f.field_info}
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
      TcTemplateVersion.current.check_footer_changes(enable_status[:value])
      if enable_status[:value] == "true" 
        data = modify_form_data(settings)
        data.each do |hash|
          field = find_or_initialize_footer(hash)
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
      else
        return []
      end
    end
    
    def modify_form_data(settings)
      data = []
      settings.each_pair do |key, value|
        if key.camelize == "Signature"
          value.values.each do |field|
            field.each_pair do |prio, val| 
              field.delete(prio) if val['is_deleted']
            end
          end
        end
        object = get_object(key.camelize, value)
        data << {:type=>"TcTemplateFieldFooter",:field_name=>key.camelize, :field_info=>object}
      end
      return data
    end
    
    def get_object(key, hash)
      if key == "Signature"
        field = TcTemplateFieldRecord.new
        field.signature_field_update(hash['value'])
        return field
      else
        TcTemplateFieldRecord.new(:value=>hash['value']['text'].strip, :text_size=>hash['value']['text_size'].strip, :text_color=>hash['value']['text_color'].strip)
      end
    end
    
    def find_or_initialize_footer(field)
      template_field = TcTemplateVersion.current.tc_template_field_footers.find_by_field_name(field[:field_name])
      if template_field
        presence = check_presence_in_versions(template_field)
        equivalence = compare_fields(template_field, field)
        if equivalence
          new_field = template_field
        else
          new_field = if current_version_records or presence
            TcTemplateFieldFooter.new(field)
          else
            template_field
          end
        end
      else
        new_field = TcTemplateFieldFooter.new(field)
      end
      return new_field
    end
    
    def check_presence_in_versions(template_field)
      template_field.tc_template_versions.count > 1
    end
    
    def compare_fields(template_field, field)
      if field[:field_name] == "Signature"
        compare_additional_field(template_field, field)
      else
        template_field.field_info == field[:field_info]
      end
    end
    
    def compare_additional_field(template_field, field)
      status = true
      status  = false if template_field.field_info.additional_field.count != field[:field_info].additional_field.count
      template_field.field_info.additional_field.each do |signature|
        obj = field[:field_info].additional_field.find{ |f| (f.value == signature.value) && (f.priority == signature.priority) && (f.field_type == signature.field_type) }
        status = false unless obj
        break unless obj
      end
      return status
    end
    
    def get_remaining_fields
      version = TcTemplateVersion.current
      version.tc_template_field_student_detail_ids + version.tc_template_field_header_ids
    end
    
    def submitted_values(settings)
      config = {}
      settings.each_pair do |key, value|
        object = get_object(key.camelize, value)
        tmp_hash = {key.camelize=>object}
        config.merge! tmp_hash
      end
      return config
    end
  end
end
