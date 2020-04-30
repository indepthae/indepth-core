# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class TcTemplateFieldStudentDetail < TcTemplateField
  validate :check_uniqueness_of_field
  named_scope :parent_fields,:conditions => "parent_field_id IS NULL", :order=> "priority ASC"
  named_scope :child_fields,:conditions => "parent_field_id IS NOT NULL", :order=> "priority ASC"
 
  def validate
    errors.add_to_base("#{t('field_name_cant_be_blank')}") if self.field_name.blank?
    if self.field_info.additional_field.present?
      if self.field_info.additional_field.map{|o| o.value.strip.blank?}.include?(true)
        errors.add_to_base(:additional_field_cant_be_blank)
      end
    end
  end
  def check_uniqueness_of_field
    TcTemplateVersion.current.tc_template_field_student_details_main_fields.each do |field|
      if self.field_name == field.field_name
        record_field = TcTemplateFieldRecord.new
        flag = record_field.compare_student_details(field,self.field_info)
        if flag == 1
          unless self.new_record?
            errors.add_to_base(:field_exists)
          end
        end
      end
    end
  end

  class<< self
    def create_new_field(settings)
      status = false
      errors=[]
      error_string={}
      field_format,field_format_value,parent_field_id,value = check_type(settings)
      priority = check_priority_value(parent_field_id)
      priority=priority+1
      data,error_status = create_hash(settings,field_format,field_format_value,priority,parent_field_id,error_string,value)
      if error_status
        return data
      end
      field,flag= find_field(data)
      if field.new_record?
        if field.update_attributes(data)
          unless parent_field_id.to_i == 0
            parent_field = TcTemplateField.find(parent_field_id.to_i)
            status = template_version_count(parent_field)
          end
          if current_version_records or status
            update_version(field.id) 
          else
            current_template.tc_template_field_student_detail_ids <<= field.id
          end
        else
          errors.push(field) 
        end
      else
        if flag == 0
          new_field = TcTemplateFieldStudentDetail.new(data)
          if new_field.save
            unless parent_field_id.to_i == 0
              parent_field = TcTemplateField.find(parent_field_id.to_i)
              status = template_version_count(parent_field)
            end
            if current_version_records or status
              update_version(new_field.id) 
            else
              current_template.tc_template_field_student_detail_ids <<= new_field.id
            end
          else
            errors.push(new_field)
          end
        else
          if field.update_attributes(data)
          else
            errors.push(field)
          end
        end
      end
      return errors
    end
    
    def edit_field(settings)
      status = false
      errors= []
      error_string = {}
      edited_field = TcTemplateFieldStudentDetail.find(settings[:id].to_i)
      field_format,field_format_value,parent_field_id,value = check_type(settings)
      priority = settings[:priority].to_i
      data,error_status = create_hash(settings,field_format,field_format_value,priority,parent_field_id,error_string,value)
      if error_status
        return data
      end
      field,flag= find_or_initialize_field(data)
      if current_version_records
        if field.new_record?
          if field.update_attributes(data)
            update_edit_version(field.id,edited_field.id) 
          else
            errors.push(field) 
          end
        else
          if flag == 0
            new_field = TcTemplateFieldStudentDetail.new(data)
            if new_field.save
              update_edit_version(new_field.id,edited_field.id)
            else
              errors.push(new_field) 
            end
          else
            field.update_attribute('field_info',data[:field_info])
          end
        end
      else
        if field.new_record? or flag == 0
          field = TcTemplateFieldStudentDetail.find(settings[:id].to_i)
          edited_field = TcTemplateFieldStudentDetail.find(settings[:id].to_i)
          unless parent_field_id.to_i == 0
            parent_field = TcTemplateField.find(edited_field.parent_field_id.to_i)
            status = template_version_count(parent_field)
          end
          unless field.update_attributes(data)
            errors.push(field)
          end
          edit_status = template_version_count(edited_field)
          if edit_status or status
            update_edit_version(field.id,edited_field.id) 
          end
        else
          field.update_attribute('field_info',data[:field_info])
        end       
      end 
      return errors
    end
    
    def change_priority(settings)
      field_ids = []
      flags = false
      settings.each_pair do |key,value|
        id= value['id'].to_i
        priority = value['priority'].to_i
        field = TcTemplateFieldStudentDetail.find(id)
        if current_template.tc_template_field_student_details.child_fields.collect(&:parent_field_id).include? field.id 
          ids = id.to_s
          field_ids,flags=sub_field_priority(value[ids],field_ids,flags)
        end
        field_ids,flags = validate_priority(field,priority,id,field_ids,flags)
      end         
      if current_version_records
        update_priority_version(field_ids,flags)
      end   
    end
    
    def sub_field_priority(settings,field_ids,flags)
      settings.each_pair do |key, value|
        id= value['id'].to_i
        priority = value['priority'].to_i
        field = TcTemplateFieldStudentDetail.find(id)
        field_ids,flags = validate_priority(field,priority,id,field_ids,flags)      
      end
      return field_ids,flags
    end
    
    def validate_priority(field,priority,id,field_ids,flags)
      priority_field= current_template.tc_template_field_student_details.find_or_initialize_by_field_name_and_priority_and_parent_field_id(:field_name=>field.field_name,:field_info=>field.field_info,:priority=>priority,:parent_field_id=> field.parent_field_id)
      if current_version_records
        if priority_field.new_record?
          if field.parent_field_id == nil
            new_field = TcTemplateFieldStudentDetail.new(:field_name=>field.field_name,:field_info=>field.field_info,:priority=> priority,:parent_field_id=> field.parent_field_id)
            new_field.save
            if field.child_fields.present?
              field_ids.each do |sub_field_id|
                sub_field = TcTemplateFieldStudentDetail.find(sub_field_id)
                if sub_field.parent_field_id == field.id
                  new_sub_field = TcTemplateFieldStudentDetail.new(:field_name=>sub_field.field_name,:field_info=>sub_field.field_info,:priority=> sub_field.priority,:parent_field_id=> new_field.id)
                  new_sub_field.save
                  field_ids <<= new_sub_field.id
                  field_ids = field_ids-[sub_field.id]
                  flags = true
                end
              end
            end
            field_ids <<= new_field.id
            flags = true
          else
            new_field = TcTemplateFieldStudentDetail.new(:field_name=>field.field_name,:field_info=>field.field_info,:priority=> priority,:parent_field_id=> field.parent_field_id)
            new_field.save
            field_ids <<= new_field.id
            flags = true
          end 
        else
          field_ids <<= field.id       
        end      
      else
        if priority_field.new_record?
          status = template_version_count(field)
          if status
            if field.parent_field_id == nil
              new_field = TcTemplateFieldStudentDetail.new(:field_name=>field.field_name,:field_info=>field.field_info,:priority=> priority,:parent_field_id=> field.parent_field_id)
              new_field.save
              if field.child_fields.present?
                current_template.tc_template_field_student_detail_ids.each do |sub_field_id|
                  sub_field = TcTemplateFieldStudentDetail.find(sub_field_id)
                  if sub_field.parent_field_id == field.id
                    new_sub_field = TcTemplateFieldStudentDetail.new(:field_name=>sub_field.field_name,:field_info=>sub_field.field_info,:priority=> sub_field.priority,:parent_field_id=> new_field.id)
                    new_sub_field.save
                    current_template.tc_template_field_student_detail_ids=current_template.tc_template_field_student_detail_ids-[sub_field.id]
                    current_template.tc_template_field_student_detail_ids <<= new_sub_field.id
                  end
                end
              end
              current_template.tc_template_field_student_detail_ids=current_template.tc_template_field_student_detail_ids-[field.id]
              current_template.tc_template_field_student_detail_ids <<= new_field.id
            else
              new_field = TcTemplateFieldStudentDetail.new(:field_name=>field.field_name,:field_info=>field.field_info,:priority=> priority,:parent_field_id=> field.parent_field_id)
              new_field.save
              current_template.tc_template_field_student_detail_ids=current_template.tc_template_field_student_detail_ids-[field.id]
              current_template.tc_template_field_student_detail_ids <<= new_field.id
            end
          else
            field.update_attribute('priority', priority)
          end
        end
      end
      return field_ids,flags
    end
    
    def delete_field(delete_field)
      delete_field_id=delete_field[:id].to_i
      delete_exi_field = []
      if current_version_records
        current_template.tc_template_field_ids.each do |k|
          delete_exi_field << k          
        end
        define_new_version 
        delete_exi_field.each do |field_id|
          current_template.tc_template_field_ids <<= field_id
        end
        priority_up(delete_field_id)
      else 
        priority_up(delete_field_id)
      end
    end
     
    def priority_up(id)
      del_field=current_template.tc_template_field_student_details.find(id)
      del_priority=del_field.priority
      del_parent = del_field.parent_field_id
      status = template_version_count(del_field)
      if status
        child_fields_destroy(del_field)
        current_template.tc_template_field_student_detail_ids=current_template.tc_template_field_student_detail_ids-[id.to_i]
      else
        child_fields_destroy(del_field)
        current_template.tc_template_field_student_details.find(id).destroy
      end
      if del_parent == nil
        remaining_fields=current_template.tc_template_field_student_details_main_fields.find(:all,:conditions=>"priority > #{del_priority}")
        remaining_fields.each do |remain|
          prio=remain.priority
          up_status= template_version_count(remain)
          if up_status
            new_field = TcTemplateFieldStudentDetail.new(:field_name=>remain.field_name,:field_info=>remain.field_info,:priority=> prio-1)
            new_field.save
            current_template.tc_template_field_ids <<= new_field.id
            if remain.child_fields.present?
              current_template.tc_template_field_student_detail_ids.each do |sub_field_id|
                sub_field = TcTemplateFieldStudentDetail.find(sub_field_id)
                if sub_field.parent_field_id == remain.id
                  new_sub_field = TcTemplateFieldStudentDetail.new(:field_name=>sub_field.field_name,:field_info=>sub_field.field_info,:priority=> sub_field.priority,:parent_field_id=> new_field.id)
                  new_sub_field.save
                  current_template.tc_template_field_ids <<= new_sub_field.id
                  current_template.tc_template_field_student_detail_ids=current_template.tc_template_field_student_detail_ids-[sub_field_id.to_i]
                end
              end
            end
            current_template.tc_template_field_student_details_main_field_ids=current_template.tc_template_field_student_details_main_field_ids-[remain.id]
          else  
            remain.update_attribute('priority', prio-1)
          end
        end
      else
        parent =current_template.tc_template_field_student_details.find(del_parent)
        parent_status = template_version_count(parent)
        if parent_status
          new_parent_field = TcTemplateFieldStudentDetail.new(:field_name=>parent.field_name,:field_info=>parent.field_info,:priority=> parent.priority)
          new_parent_field.save
          current_template.tc_template_field_ids <<= new_parent_field.id
          current_template.tc_template_field_student_detail_ids=current_template.tc_template_field_student_detail_ids-[parent.id]
          remaining_fields=parent.child_fields
          remaining_fields.each do |remain|
            if remain.priority > del_priority 
              prio=remain.priority
              up_status= template_version_count(remain)
              if up_status
                current_template.tc_template_field_student_detail_ids=current_template.tc_template_field_student_detail_ids-[remain.id]
                new_field = TcTemplateFieldStudentDetail.new(:field_name=>remain.field_name,:field_info=>remain.field_info,:priority=> prio-1,:parent_field_id=> new_parent_field.id)
                new_field.save
                current_template.tc_template_field_ids <<= new_field.id
              else  
                remain.update_attribute('priority', prio-1)
                remain.update_attribute('parent_field_id', new_parent_field.id)
              end
            end
          end
        end
      end
    end
    
    def get_current_student_details
      student_details = {}
      fields = current_template.tc_template_field_student_details_main_fields.all
      fields.each do |h|
        sub_field_hash = {}
        h.child_fields.each do |s|
          tmp_hash = {s.id=>{:field_name=>s.field_name,:field_type=>s.field_info.field_type,:field_format_value=>s.field_info.field_format_value,:field_format=>s.field_info.field_format,:additional_field=>s.field_info.additional_field,:is_mandatory=>s.field_info.is_mandatory,:field_value=>nil,:is_in_words_enabled => s.field_info.is_in_words_enabled,:is_in_figures_enabled=>s.field_info.is_in_figures_enabled,:sub_fields=>nil,:value=>s.field_info.value}}
          sub_field_hash.merge! tmp_hash
        end
        tmp_hash = {h.id=>{:field_name=>h.field_name,:field_type=>h.field_info.field_type,:field_format_value=>h.field_info.field_format_value,:field_format=>h.field_info.field_format,:additional_field=>h.field_info.additional_field,:is_mandatory=>h.field_info.is_mandatory,:field_value=>nil,:is_in_words_enabled => h.field_info.is_in_words_enabled,:is_in_figures_enabled=>h.field_info.is_in_figures_enabled, :sub_fields=>sub_field_hash,:value=>h.field_info.value}}
        student_details.merge! tmp_hash
      end
      return student_details
    end
    
    def submitted_values_to_hash(hash)
      student_details = {}
      hash.each_pair do |id, value|
        sub_field_hash = {}
        if value['sub_field']
          value['sub_field'].each_pair do |sub_id, sub_value|
            s = get_objects(sub_id)
            tmp_hash = {s.id=>{:field_name=>s.field_name,:field_type=>s.field_info.field_type,:field_format_value=>s.field_info.field_format_value,:field_format=>s.field_info.field_format,:additional_field=>s.field_info.additional_field,:is_mandatory=>s.field_info.is_mandatory, :field_value=>sub_value,:is_in_words_enabled => s.field_info.is_in_words_enabled,:is_in_figures_enabled=>s.field_info.is_in_figures_enabled, :sub_fields=>nil,:value=>s.field_info.value}}
            sub_field_hash.merge! tmp_hash
          end
        end
        h = get_objects(id)
        tmp_hash = {h.id=>{:field_name=>h.field_name,:field_type=>h.field_info.field_type,:field_format_value=>h.field_info.field_format_value,:field_format=>h.field_info.field_format,:additional_field=>h.field_info.additional_field,:is_mandatory=>h.field_info.is_mandatory, :field_value=>value,:is_in_words_enabled => h.field_info.is_in_words_enabled,:is_in_figures_enabled=>h.field_info.is_in_figures_enabled, :sub_fields=>sub_field_hash,:value=>h.field_info.value}}
        student_details.merge! tmp_hash
      end
      return student_details
    end
    
    def get_objects(id)
      TcTemplateFieldStudentDetail.find(id.to_i)
    end
   
    private
    def child_fields_destroy(del_field)
      child_fields=del_field.child_fields
      child_fields.each do |child|
        child_status = template_version_count(child)
        if child_status
          current_template.tc_template_field_student_detail_ids=current_template.tc_template_field_student_detail_ids-[child.id.to_i]
        else
          current_template.tc_template_field_student_details.find(child.id).destroy
        end
      end
    end
    
    def create_hash(settings,field_format,field_format_value,priority,parent_field_id,error_string,value)
      error_status = false
      if field_format == "select_box"
        if settings[:field_info][:additional_field].present?
          data=modify_hash_with_additional_field(settings[:field_name],settings[:field_info][:type],field_format,field_format_value,priority,settings[:field_info][:additional_field],settings[:field_info][:is_mandatory],parent_field_id)
        else
          error_status = true
          error_string = {:error1=> t('create_atleast_one_option')}
          if settings[:field_name].blank?
            error_string.merge!(:error2=> t('field_name_cant_be_blank'))
          end
          return error_string,error_status
        end   
      else
        in_figures,in_words = check_date_of_birth(settings[:field_info],field_format_value)
        data=modify_hash(settings[:field_name],settings[:field_info][:type],field_format,field_format_value,priority,settings[:field_info][:is_mandatory],in_figures,in_words,parent_field_id,value)
      end 
      return data,error_status
    end
     
    def check_type(settings)
      if settings[:field_info][:type] == "system"
        keys=TcTemplateVersion::SYSTEM_FIELDS.select{|key,value| key == settings[:field_info][:system_field_type_name].to_i}
      else
        keys=TcTemplateVersion::CUSTOM_FIELDS.select{|key,value| key == settings[:field_info][:custom_field_type_name].to_i}
      end
      unless keys.present?
        field_type = "additional_field"
        field_type_name,value = get_additional_field_values(settings[:field_info][:system_field_type_name])
      else
        field_type=keys[0][1][:type] if keys[0][1][:type] != "date"
        field_type= "multiple_type" if keys[0][1][:type] == "date"
        field_type= "admission_date" if keys[0][1][:type] == "admission_date"
        field_type_name = keys[0][1][:field]
        value = nil
      end
      parent_field_id = settings[:field_info][:parent_id] || nil
      return field_type,field_type_name,parent_field_id,value
    end
    
    def check_date_of_birth(field_info,value)   
      if value == "date_of_birth" or value == "date" or value == "admission_date"
        if field_info[:in_words].present? or field_info[:in_words_custom].present?
          in_figures = field_info[:in_figures] || field_info[:in_figures_custom]  || 0
          in_words = field_info[:in_words] || field_info[:in_words_custom] || 0
        else
          in_figures =  1
          in_words =  0
        end
      else
        in_figures = nil
        in_words = nil
      end
      return in_figures,in_words
    end
    
    def modify_hash(field_name,field_type,field_format,field_format_value,priority,is_mandatory,in_figures,in_words,parent_field_id,value)
      object = get_object(field_type,field_format,field_format_value,is_mandatory,in_figures,in_words,value)
      hash = {:field_name=> field_name, :field_info=> object, :priority=> priority, :parent_field_id => parent_field_id  } 
      return hash
    end
    
    def modify_hash_with_additional_field(field_name,field_type,field_format,field_format_value,priority,additional_fields,is_mandatory,parent_field_id)
      field = TcTemplateFieldRecord.new
      field.multiple_field_update(field_type,field_format,field_format_value,additional_fields,is_mandatory)
      hash = {:field_name=> field_name, :field_info=> field, :priority=> priority, :parent_field_id => parent_field_id } 
      return hash
    end
    
    def get_object(field_type,field_format,field_format_value,is_mandatory,in_figures,in_words,value)
      TcTemplateFieldRecord.new(:field_type=>field_type,:field_format_value=>field_format_value,:field_format=>field_format,:is_mandatory=> is_mandatory,:is_in_figures_enabled=> s_to_bool(in_figures.to_s), :is_in_words_enabled=> s_to_bool(in_words.to_s), :value=> value)
    end
    
    def find_field(hash)
      field= current_template.tc_template_field_student_details.find_or_initialize_by_field_name_and_parent_field_id(hash)
      if field.new_record?
        flag = 0
        return field,flag
      else
        record_field = TcTemplateFieldRecord.new
        flag = record_field.compare_student_details(field,hash[:field_info])
        return field,flag
      end
      
    end
    
    def find_or_initialize_field(hash)
      field= current_template.tc_template_field_student_details_main_fields.find_or_initialize_by_field_name_and_priority_and_parent_field_id(hash)   
      if field.new_record?
        flag = 0
        return field,flag
      else
        record_field = TcTemplateFieldRecord.new
        flag = record_field.compare_student_details(field,hash[:field_info])
        return field,flag
      end
    end
    
    def template_version_count(field)
      field.tc_template_versions.count > 1
    end  
    
    def update_version(id)
      field_ids = []
      field_ids << id
      current_template.tc_template_field_ids.each do |ids|
        field_ids << ids
      end 
      define_new_version  
      field_ids.each do|field_id|
        current_template.tc_template_field_ids <<= field_id
      end
      field = current_template.tc_template_field_student_details.find(id)
      unless field.parent_field_id == nil
        parent_field = current_template.tc_template_field_student_details.find(field.parent_field_id)
        new_parent_field = TcTemplateFieldStudentDetail.new(:field_name=>parent_field.field_name,:field_info=>parent_field.field_info,:priority=> parent_field.priority,:parent_field_id=> parent_field.parent_field_id)
        new_parent_field.save
        current_template.tc_template_field_ids <<= new_parent_field.id
        if parent_field.child_fields.present?
          current_template.tc_template_field_student_detail_ids.each do |sub_field_id|
            sub_field = TcTemplateFieldStudentDetail.find(sub_field_id)
            if sub_field.parent_field_id == parent_field.id
              new_sub_field = TcTemplateFieldStudentDetail.new(:field_name=>sub_field.field_name,:field_info=>sub_field.field_info,:priority=> sub_field.priority,:parent_field_id=> new_parent_field.id)
              new_sub_field.save
              current_template.tc_template_field_ids <<= new_sub_field.id
              status = template_version_count(sub_field)
              if status
                current_template.tc_template_field_student_detail_ids=current_template.tc_template_field_student_detail_ids-[sub_field_id.to_i]
              else
                current_template.tc_template_field_student_details.find(sub_field_id.to_i).destroy
              end
            end
          end
        end
        current_template.tc_template_field_student_detail_ids=current_template.tc_template_field_student_detail_ids-[parent_field.id.to_i]
      end
    end
     
    def update_edit_version(id,edited_id)
      field_ids = []
      field_ids << id
      current_template.tc_template_field_ids.each do |ids|
        if ids != edited_id
          field_ids << ids
        end
      end 
      define_new_version  
      field_ids.each do|field_id|
        current_template.tc_template_field_ids <<= field_id
      end
      field = current_template.tc_template_field_student_details.find(id)
      unless field.parent_field_id == nil
        parent_field = current_template.tc_template_field_student_details.find(field.parent_field_id)
        new_parent_field = TcTemplateFieldStudentDetail.new(:field_name=>parent_field.field_name,:field_info=>parent_field.field_info,:priority=> parent_field.priority,:parent_field_id=> parent_field.parent_field_id)
        new_parent_field.save
        current_template.tc_template_field_ids <<= new_parent_field.id
        if parent_field.child_fields.present?
          current_template.tc_template_field_student_detail_ids.each do |sub_field_id|
            sub_field = TcTemplateFieldStudentDetail.find(sub_field_id)
            if sub_field.parent_field_id == parent_field.id
              new_sub_field = TcTemplateFieldStudentDetail.new(:field_name=>sub_field.field_name,:field_info=>sub_field.field_info,:priority=> sub_field.priority,:parent_field_id=> new_parent_field.id)
              new_sub_field.save
              current_template.tc_template_field_ids <<= new_sub_field.id
              status = template_version_count(sub_field)
              if status
                current_template.tc_template_field_student_detail_ids=current_template.tc_template_field_student_detail_ids-[sub_field_id.to_i]
              else
                current_template.tc_template_field_student_details.find(sub_field_id.to_i).destroy
              end
            end
          end
        end
        current_template.tc_template_field_student_detail_ids=current_template.tc_template_field_student_detail_ids-[parent_field.id.to_i]
      end
    end
    
    def update_priority_version(field_ids,flag)  
      if flag != false
        current_template.tc_template_field_header_ids.each do |ids|
          field_ids << ids
        end 
        current_template.tc_template_field_footer_ids.each do |ids|
          field_ids << ids
        end          
        define_new_version 
        field_ids.each do|field_id|
          current_template.tc_template_field_ids <<= field_id
        end  
      end     
    end
   
    def check_priority_value(parent_id)
      if parent_id == nil
        if current_template.tc_template_field_student_details_main_fields.last.present?
          return current_template.tc_template_field_student_details_main_fields.last.priority.to_i
        else
          return 0
        end
      else
        parent=current_template.tc_template_field_student_details_main_fields.find(parent_id)
        if parent.child_fields.last.present?
          return parent.child_fields.last.priority.to_i
        else
          return 0
        end
      end
      
    end
    
    def get_additional_field_values(text)
      unless text.nil? or text == ""
        field_format_value = text.split('.').first 
        id = text.split('.').last.to_i
      else
        field_format_value = nil
        id = nil
      end
      return field_format_value, id
    end
  end
end

