class RemarksController < ApplicationController
  filter_access_to :all, :except => [:add_remarks,:create_remarks,:edit_remarks,:update_remarks,:destroy,:edit_common_remarks,:update_common_remarks,:destroy_common_remarks,:index,:add_employee_custom_remarks,:employee_list_custom_remarks,:list_students,:list_custom_remarks,:list_student_with_remark_subject,:employee_custom_remark_update,:edit_custom_remarks,:destroy_custom_remarks,:update_custom_remarks]
  filter_access_to [:add_remarks,:create_remarks,:edit_remarks,:update_remarks,:destroy], :attribute_check=>true,
    :load_method => lambda { RemarkSetting.find_by_target(params[:target_name]).load_model.camelize.constantize.find(params[:load_object_id]) }
  filter_access_to [:edit_common_remarks,:update_common_remarks,:destroy_common_remarks], :attribute_check=>true, :load_method => lambda { RemarkSetting.find_by_target(params[:target_name]).load_model.camelize.constantize.find(params[:load_object_id]) }
  filter_access_to [:index,:add_employee_custom_remarks,:employee_list_custom_remarks,:list_students,:list_custom_remarks,:list_student_with_remark_subject,:employee_custom_remark_update,:edit_custom_remarks,:destroy_custom_remarks,:update_custom_remarks], :attribute_check=>true, :load_method => lambda {current_user}
  filter_access_to [:custom_remark_list, :remarks_history, :remarks_pdf, :remarks_csv], :attribute_check=>true, :load_method => lambda { (current_user.admin? ? current_user : (current_user.employee? ? (params[:archived_id].present? ? ArchivedStudent.find(params[:archived_id]).user : Student.find(params[:id]||params[:student_id]).user) : (params[:archived_id].present? ? ArchivedStudent.find(params[:archived_id]) : Student.find(params[:id]||params[:student_id])))) }
  def index
    
  end
  ####################################################################################################
  #target based remark operations start
  ####################################################################################################
  def add_remarks
    @page=params[:page]
    @target_name=params[:target_name]
    @target=RemarkSetting.find_by_target(@target_name)
    @student_id=params[:student_id]
    @stud=Student.find_by_id(@student_id)
    @params_hash=JSON.parse(params[:params_hash])
    @object_id=params[:object_id]
    @load_object_id = params[:load_object_id]
    @remark=Remark.new
    @remark.remark_parameters.build
    render :partial => "add_remarks"
  end

  def create_remarks
    @page=params[:page]
    @target_name=params[:target_name]
    @target=RemarkSetting.find_by_target(@target_name)
    @student_id=params[:student_id]
    @stud=Student.find_by_id(@student_id)
    @params_hash=params[:params_hash]
    @load_object_id = params[:load_object_id]
    @load_model=@target.load_model.camelize.constantize
    @params_hash.each { |key,val| @params_hash[key]=@params_hash[key].to_i }
    @remark=Remark.new(params[:remark])
    if @remark.save
      @object_id=@remark.id
      @submitted_by=@remark.submitted_by
      @remarked_by=@remark.remarked_by
      if @target.general
        @ret_val=RemarkMod.generate_common_remark_form(@target_name, @student_id,@page.to_i,nil,@params_hash)
        render :partial=>"add_and_show_remarks"
      else
        @ret_val= RemarkMod.generate_remark_form(@target_name, @student_id, @object_id,@params_hash)
        render :partial => "show_remarks"
      end
    end
  end

  def edit_remarks
    @object_id=params[:object_id]
    @target_name=params[:target_name]
    @target=RemarkSetting.find_by_target(params[:target_name])
    @student_id=params[:student_id]
    @stud=Student.find_by_id(@student_id)
    @load_object_id = params[:load_object_id]
    @load_model=@target.load_model.camelize.constantize
    @target=RemarkSetting.find_by_target(params[:target_name])
    if @target.table_name.present?
      model_name=@target.table_name.singularize.titleize.delete(' ').constantize
      @remark=model_name.find(@object_id)
      field_name=@target.field_name
      @symbolized_field_name=field_name.to_sym
    else
      @remark = Remark.find @object_id
      @symbolized_field_name = 'remark_body'.to_sym
    end
    @params_hash=JSON.parse(params[:params_hash])
    render :partial=>"edit_remarks"
  end

  def update_remarks
    @object_id=params[:object_id]
    @target_name=params[:target_name]
    @student_id=params[:student_id]
    @stud=Student.find_by_id(@student_id)
    @target=RemarkSetting.find_by_target(params[:target_name])
    @params_hash=JSON.parse(params[:params_hash])
    @load_object_id = params[:load_object_id].to_i
    @load_model=@target.load_model.camelize.constantize
    if @target.table_name.present?
      model_name=@target.table_name.singularize.titleize.delete(' ').constantize
      @remark=model_name.find(@object_id)
      field_name=@target.field_name
      @symbolized_field_name=field_name.to_sym
    else
      @remark = Remark.find(@object_id,:conditions => {:submitted_by => current_user.id})
      @symbolized_field_name = 'remark_body'.to_sym
    end
    @updated_remark=params[:remark][@symbolized_field_name].present? ? params[:remark][@symbolized_field_name] : "-"
    @remark.update_attribute(@symbolized_field_name,@updated_remark) unless @remark.nil?
    render :partial=>"show_remarks"
  end

  def destroy
    @object_id=params[:object_id]
    @target_name=params[:target_name]
    @target=RemarkSetting.find_by_target(params[:target_name])
    @student_id=params[:student_id]
    @stud=Student.find_by_id(@student_id)
    @params_hash=JSON.parse(params[:params_hash])
    @load_object_id = params[:load_object_id].to_i
    @load_model=@target.load_model.camelize.constantize
    @target=RemarkSetting.find_by_target(params[:target_name])
    if @target.table_name.present?
      model_name=@target.table_name.singularize.titleize.delete(' ').constantize
      @remark=model_name.find(@object_id)
      @field_name=@target.field_name
      @symbolized_field_name=@field_name.to_sym
      @remark.update_attribute(@symbolized_field_name,@updated_remark)
      render :partial=>"adding_remark"
    else
      @remark=Remark.find(@object_id,:conditions => {:submitted_by => current_user.id})
      @remark.destroy unless @remark.nil?
      render :partial=>"adding_remark1"
    end
  end

  ####################################################################################################
  #target based remark operations stop
  ####################################################################################################



  
  ####################################################################################################
  #common remark operations start
  ####################################################################################################

  def edit_common_remarks
    @object_id=params[:object_id]
    @target_name=params[:target_name]
    @student_id=params[:student_id]
    @stud=Student.find_by_id(@student_id)
    @load_object_id=params[:load_object_id]
    @remark=Remark.find(@object_id,:include => :remark_setting,:conditions => {:submitted_by => current_user.id})
    field_name="remark"
    @symbolized_field_name=field_name.to_sym
    @params_hash=JSON.parse(params[:params_hash])
    render :partial=>"edit_common_remarks"
  end

  def update_common_remarks
    @object_id=params[:object_id]
    @target_name=params[:target_name]
    @target=RemarkSetting.find_by_target(@target_name)
    @student_id=params[:student_id]
    @stud=Student.find_by_id(@student_id)
    @remark=Remark.find(@object_id,:conditions => {:submitted_by => current_user.id})
    @params_hash=JSON.parse(params[:params_hash])
    @load_object_id=params[:load_object_id].to_i
    @load_model=@target.load_model.camelize.constantize
    field_name="remark"
    @symbolized_field_name=field_name.to_sym
    @remark.update_attributes(:remark_subject=>params[:remark][:remark_subject],:remark_body=>params[:remark][:remark_body],:remarked_by=>params[:remark][:remarked_by]) unless @remark.nil?
    @submitted_by=@remark.submitted_by
    @remarked_by=@remark.remarked_by
    @ret_val=RemarkMod.generate_common_remark_form(@target_name, @student_id,nil,nil, @params_hash)
    render :partial=>"show_common_remark"
  end

  def show_common_remarks
    @target_name=params[:target_name]
    @student_id=params[:student_id]
    @stud=Student.find_by_id(@student_id)
    @target=RemarkSetting.find_by_target(@target_name)
    @params_hash=params[:params_hash]
    @load_object_id=params[:load_object_id].to_i
    @load_model=@target.load_model.camelize.constantize
    @page=params[:page]
    @ret_val=RemarkMod.generate_common_remark_form(@target_name, @student_id,@page.to_i,nil, @params_hash)
    @submitted_by=
      render(:update) do |page|
      page.replace_html "remarks_list", :partial=>"remarks/show_common_remarks"
    end
  end

  def destroy_common_remarks
    
    @object_id=params[:object_id]
    @target_name=params[:target_name]
    @target=RemarkSetting.find_by_target(@target_name)
    @student_id=params[:student_id]
    @stud=Student.find_by_id(@student_id)
    @params_hash=params[:params_hash]
    @load_object_id=params[:load_object_id].to_i
    @load_model=@target.load_model.camelize.constantize
    @remark=Remark.find(@object_id,:conditions => {:submitted_by => current_user.id})
    @remark.destroy unless @remark.nil?
    @params_hash.each { |key,val| @params_hash[key]=@params_hash[key].to_i }
    @ret_val=RemarkMod.generate_common_remark_form(@target_name, @student_id,nil,nil, @params_hash)
    render(:update) do |page|
      page.replace_html "remarks_list", :partial=>"show_common_remarks"
    end
  end

  ####################################################################################################
  #common remark operations stop
  ####################################################################################################




  ####################################################################################################
  #custom remark operations start
  ####################################################################################################

  def add_employee_custom_remarks
    if current_user.has_required_custom_remarks_privileges?
      @courses = Course.active
    else
      course_ids=current_user.employee_record.batches.collect(&:course_id).uniq
      @courses=Course.find_all_by_id(course_ids)
    end
  end

  def list_batches
    
    if params[:course_id].present?
      if current_user.has_required_custom_remarks_privileges?
        @course=Course.find(params[:course_id])
        @batches=@course.batches.active
      else
        @batches=current_user.employee_record.batches.all(:conditions => { :is_deleted => false, :is_active => true,:course_id=>params[:course_id] })
      end
      render(:update) do |page|
        page.replace_html "batch_space", :partial=>"list_batches"
        page.replace_html "new_form_section", :text=>""
      end
    else
      render(:update) do |page|
        page.replace_html "batch_space", :text=>""
        page.replace_html "new_form_section", :text=>""
      end
    end
  end

  def list_student_with_remark_subject
    @remarks=[]
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id],:include => :students)
      render(:update) do |page|
        page.replace_html "new_form_section", :partial=>"list_student_with_remark_subject"
      end
    else
      render(:update) do |page|
        page.replace_html "new_form_section", :text=>""
      end
    end
  end

  def employee_custom_remark_update
    target=RemarkSetting.find_by_target("custom_remark")
    batch=Batch.find(params[:batch][:batch_id])
    cnt=0
    params[:batch][:students_attributes].each do |k,v|
      v["remark"].merge!(params[:remark])
      if v["remark"]["remark_body"].present?
        cnt+=1
        Remark.create(:remark_subject=>v["remark"]["remark_subject"],:remark_body=>v["remark"]["remark_body"],:remarked_by=>v["remark"]["remarked_by"],:submitted_by=>current_user.id,:batch_id=>params[:batch][:batch_id],:student_id=>v["id"],:target_id=>target.id) if v["remark"]["remark_body"].present?
      end
    end
    render(:update) do |page|
      if cnt>0
        page.replace_html "new_form_section", :text=>"<p class='flash-msg fleft width_960'>#{t('remarks_added_succeessfully')}#{cnt}#{t('students_in_small_letters')}</p>"
      else
        page.replace_html "new_form_section", :text=>"<p class='flash-msg fleft width_960'>#{t('remarks_not_added')}</p>"
      end
    end
  end

  def employee_list_custom_remarks
    if current_user.has_required_custom_remarks_privileges?
      @courses=Course.active.all
    else
      course_ids=current_user.employee_record.batches.collect(&:course_id).uniq
      @courses=Course.find_all_by_id(course_ids)
    end
  end

  def list_specific_batches

    if params[:course_id].present?
      if current_user.has_required_custom_remarks_privileges?
        @course=Course.find(params[:course_id])
        @batches=@course.batches.active
      else
        @batches=current_user.employee_record.batches.all(:conditions => { :is_deleted => false, :is_active => true,:course_id=>params[:course_id] })
      end
      render(:update) do |page|
        page.replace_html "list_specific_batches", :partial=>"list_specific_batches"
        page.replace_html "list_students", :text=>""
        page.replace_html "remarks_list",:text=>""
      end
    else
      render(:update) do |page|
        page.replace_html "list_specific_batches", :text=>""
        page.replace_html "list_students", :text=>""
        page.replace_html "remarks_list",:text=>""
      end
    end
  end

  def list_students
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id])
      @students=@batch.students
      render(:update) do |page|
        page.replace_html "list_students", :partial=>"list_students"
      end
    else
      render(:update) do |page|
        page.replace_html "list_students", :text=>""
        page.replace_html "remarks_list",:text=>""
      end
    end
  end

  def list_student_custom_remarks
    @student=Student.find(params[:student_id])
    @target=RemarkSetting.find_by_target('custom_remark')
    @remarks=Remark.paginate(:conditions=>["student_id=? and target_id=? and batch_id=?",@student.id,@target.id,@student.batch_id],:per_page=>10,:page=>params[:page],:order=>"updated_at DESC")
  end

  def add_custom_remarks
    @remark=Remark.new
    @target=RemarkSetting.find_by_target('custom_remark')
    @student=Student.find(params[:student_id])
    render :partial=>"add_custom_remarks"
  end
  
  def create_custom_remarks
    @target=RemarkSetting.find(params[:remark][:target_id])
    @student=Student.find(params[:remark][:student_id])
    @remark=Remark.new(params[:remark])
    if @remark.save
      @remarks=Remark.paginate(:conditions=>["student_id=? and target_id=? and batch_id=?",@student.id,@target.id,@student.batch_id],:per_page=>10,:page=>params[:page],:order=>"updated_at DESC")
      render :partial=>"list_custom_remarks"
    end
  end

  def edit_custom_remarks
    @object_id=params[:object_id]
    @target_name=params[:target_name]
    @student=Student.find(params[:student_id])
    @remark=Remark.find(@object_id,:conditions => {:submitted_by => current_user.id})
    field_name="remark"
    @symbolized_field_name=field_name.to_sym
    render :partial=> "edit_custom_remarks"
  end

  def update_custom_remarks
    @object_id=params[:object_id]
    @remark=Remark.find(@object_id,:conditions => {:submitted_by => current_user.id})
    @student=Student.find(params[:remark][:student_id])
    @updated_remark_body=params[:remark][:remark_body]
    @updated_remark_subject=params[:remark][:remark_subject]
    @updated_remarked_by=params[:remark][:remarked_by]
    
    @remark.update_attributes(:remark_body=>@updated_remark_body,:remark_subject=>@updated_remark_subject,:remarked_by=>@updated_remarked_by) unless @remark.nil?
    render :partial=>"show_custom_remarks"
    
  end

  def custom_remark_list
    @student=current_user.student? ? current_user.student_record : Student.find(params[:student_id])
    @target=RemarkSetting.find_by_target('custom_remark')
    @remarks=Remark.paginate(:conditions=>["student_id=? and target_id=? and batch_id=?",@student.id,@target.id,@student.batch_id],:per_page=>10,:page=>params[:page],:order=>"updated_at DESC")
    @batches=Batch.all(:select=>"DISTINCT batches.*",:joins=>"LEFT OUTER JOIN `batch_students` ON batch_students.batch_id = batches.id",:conditions=>["batch_students.student_id = ?",@student.id],:order=>"batch_students.id")
  end
  def list_custom_remarks
    if params[:student_id].present?
      @student=Student.find(params[:student_id])
      @target=RemarkSetting.find_by_target('custom_remark')
      @remarks=Remark.paginate(:conditions=>["student_id=? and target_id=? and batch_id=?",@student.id,@target.id,@student.batch_id],:per_page=>10,:page=>params[:page],:order=>"updated_at DESC")
      render(:update) do |page|
        page.replace_html "remarks_list", :partial=>"list_custom_remarks"
      end
    else
      render(:update) do |page|
        page.replace_html "remarks_list", :text=>""
      end
    end
  end

  def destroy_custom_remarks
    @object_id=params[:object_id]
    remark=Remark.find(@object_id,:conditions => {:submitted_by => current_user.id})
    @student=Student.find(remark.student_id)
    target_id=remark.target_id
    @target=RemarkSetting.find(target_id)
    batch_id=remark.batch_id
    remark.destroy unless remark.nil?
    @remarks=Remark.paginate(:conditions=>["student_id=? and target_id=? and batch_id=?",@student.id,target_id,batch_id],:per_page=>10,:page=>params[:page],:order=>"updated_at DESC")
    render(:update) do |page|
      page.replace_html "remarks_list", :partial=>"list_custom_remarks"
    end
  end

  
  
  ####################################################################################################
  #custom remark operations stop
  ####################################################################################################
  


  
  ####################################################################################################
  #Remarks History Start
  ####################################################################################################

  def remarks_history
    @target=RemarkSetting.find_by_target('custom_remark')
    unless params[:archived_id].present?
      @student=Student.find(params[:id])
    else
      @archived_student = ArchivedStudent.find(params[:archived_id])
    end
    batches_ids = Batch.all(:select=>"DISTINCT batches.*",:joins=>"LEFT OUTER JOIN `batch_students` ON batch_students.batch_id = batches.id",:conditions=>["batch_students.student_id = ?",(@student.present? ? @student.id : @archived_student.former_id)],:order=>"batch_students.id DESC").collect(&:id)
    batches_ids.unshift(@student.present? ? @student.batch_id : @archived_student.batch_id)
    @batches=Batch.paginate(:conditions=>["id in (?)",batches_ids.uniq],:per_page=>4,:page=>params[:page], :order => "field(id, #{batches_ids.uniq.join(',')})")
    @remarks = Remark.find_all_by_batch_id_and_student_id_and_target_id(@batches.collect(&:id),@student.present? ? @student.id : @archived_student.former_id,@target.id,:order=>"updated_at desc").group_by(&:batch_id)
  end
  
  ####################################################################################################
  #Remark History Stop
  ####################################################################################################
  
  
  
  
  ####################################################################################################
  #Remark PDF and CSV Start
  ####################################################################################################
  
  def remarks_pdf
    @data_hash = Remark.fetch_student_remarks(params)
    render :pdf => 'remarks_pdf', :show_as_html => params[:d],:margin=>{:left=>10,:right=>10,:top=>8,:bottom=>8}, :header => {:html => nil},:footer => {:html => nil}# ,:zoom => 1,:margin =>{:bottom => 0,:left=>5,:right=>5, :top => 25}, :header => {:html => { :template=> 'employee_payslips/_payslip_pdf_header.html.erb'}}
  end
  
  def remarks_csv
    result = Remark.fetch_student_remarks(params)
    data_hash = result.last
    csv_string = result.first
    filename = (params[:history].present? ? "remarks_#{data_hash[:student].admission_no}.csv" : "remarks_#{data_hash[:student].admission_no}_#{data_hash[:student].batch.full_name}.csv")
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end
  
  
  ####################################################################################################
  #Remark PDF and CSV Stop
  ####################################################################################################
  #  (current_user.admin? ? current_user : (current_user.employee? ? (params[:archived_id].present? ? ArchivedStudent.find(params[:archived_id]).user : Student.find(params[:id]||params[:student_id]).user) : (params[:archived_id].present? ? ArchivedStudent.find(params[:archived_id]) : Student.find(params[:id]||params[:student_id]))))
  #  ((current_user.admin? or current_user.employee?) ? current_user : (params[:archived_id].present? ? ArchivedStudent.find(params[:archived_id]) : Student.find(params[:id]||params[:student_id])))
  
end
