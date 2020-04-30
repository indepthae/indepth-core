class RemarkMod
  attr_accessor :target_name, :student_id, :object_id, :params_hash,:pno
  
  class << self
    def generate_remark_form(target_name,student_id,object_id,*params_hash)
      remark_setting = RemarkSetting.find_by_target target_name
      if remark_setting.table_name.present?
        model_name=remark_setting.table_name.singularize.titleize.delete(' ').constantize
      end
      if object_id.present? and model_name.present?
        table=model_name.find(object_id)
        remark=table if table.present?
      else
        optn = params_hash.extract_options!.stringify_keys
        remark_setting = RemarkSetting.find_by_target(target_name)
        remark = remark_setting.remarks.first(:select => "remarks.*",:joins => "INNER JOIN `remark_settings` ON `remark_settings`.id = `remarks`.target_id #{remark_setting.params_join_string(optn)}",:conditions =>"(#{remark_setting.params_query_string(optn)}) AND (remarks.student_id = #{student_id})",:group=>"remarks.id",:order=>"updated_at DESC")
      end
      remark
    end

    def generate_common_remark_form(target_name,student_id,pno,object_id,*params_hash)
      optn = params_hash.extract_options!.stringify_keys
      remark_setting = RemarkSetting.find_by_target(target_name)
      if object_id.present? and object_id==1
        student_remarks = remark_setting.remarks.all(:select => "remarks.*",:joins => "INNER JOIN `remark_settings` ON `remark_settings`.id = `remarks`.target_id #{remark_setting.params_join_string(optn)}",:conditions =>"(#{remark_setting.params_query_string(optn)}) AND (remarks.student_id = #{student_id})",:group=>"remarks.id",:order=>"updated_at DESC")
      else
        student_remarks = remark_setting.remarks.paginate(:select => "remarks.*",:joins => "INNER JOIN `remark_settings` ON `remark_settings`.id = `remarks`.target_id #{remark_setting.params_join_string(optn)}",:conditions =>"(#{remark_setting.params_query_string(optn)}) AND (remarks.student_id = #{student_id})",:group=>"remarks.id",:per_page=>5,:page=>pno,:order=>"updated_at DESC")
      end
      student_remarks
    end
  end
end