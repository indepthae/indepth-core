module RemarksHelper

  def generate_remark_section(target_name,student_id,object_id,load_object_id,params_hash)
    @ret_val= RemarkMod.generate_remark_form(target_name, student_id, object_id, params_hash)
    @target_name=target_name
    @student_id=student_id
    @stud=Student.find_by_id(@student_id)
    @object_id=object_id||(@ret_val.id unless @ret_val.nil?)
    @params_hash=params_hash
    @target=RemarkSetting.find_by_target(@target_name)
    @load_object_id = load_object_id
    @load_model=@target.load_model.camelize.constantize
    if @target.table_name.present?
      @field_name=@target.field_name
      @remark=@ret_val.send(@field_name) if @ret_val.present?
      if @ret_val.present? and @remark.present?
        render :partial=>"remarks/show_remarks"
      else
        if @current_user.employee? and @load_model.find(load_object_id).has_employee_privilege
          render :partial=>"remarks/adding_remark"
        end
      end
    else
      @remark=@ret_val
      if @remark.present?
        render :partial=>"remarks/show_remarks"
      else
        if @current_user.employee? and @load_model.find(load_object_id).has_employee_privilege
          render :partial=>"remarks/adding_remark1"
        end
      end
    end
  end

  def generate_common_remark_section(target_name,student_id,object_id,load_object_id,params_hash)
    @page=1
    @ret_val= RemarkMod.generate_common_remark_form(target_name, student_id,@page,object_id,params_hash)
    @target_name=target_name
    @target=RemarkSetting.find_by_target(@target_name)
    @student_id=student_id
    @stud=Student.find_by_id(@student_id)
    @params_hash=params_hash
    @load_object_id=load_object_id
    @load_model=@target.load_model.camelize.constantize
    @target=RemarkSetting.find_by_target(@target_name)
    @field_name="remark"
    render :partial=>"remarks/add_and_show_remarks"
  end
  
end
