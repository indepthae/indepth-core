class StudentRecordsController < ApplicationController
  before_filter :login_required
  filter_access_to :all , :attribute_check=>true, :load_method => lambda { current_user }
  before_filter :protect_other_student_data, :only =>[:individual_student_records]

  def index
  end

  def create
    @student = Student.find(params[:student][:id])
    @batch=Batch.find(params[:batch_id])
    @record_group=RecordGroup.find(params[:record_group_id])
    student_attributes=params[:student]
    params[:student][:student_records_attributes].each_pair do |k, v|
      addl_info = v['additional_info']
      addl_field = Record.find(v['additional_field_id'])
      if addl_field.input_type == "multi_select"
        addl_info = addl_info.reject{|a| a.blank?}.join(", ")
        student_attributes[:student_records_attributes][k]['additional_info'] = addl_info
      end
    end
    if @student.update_attributes(params[:student])
      render :update do |page|
        @grouped_student_records=@record_group.student_records.all(:select=>"students.first_name,record_groups.name rg_name,records.*,student_records.*",:joins=>[:student,{:record=>:record_group}],:conditions=>{:batch_id=>@batch.id,:student_id=>@student.id}).group_by(&:rg_name)
        if params[:form_type] == 'specific'
          all_records_count=@record_group.records.count
          student_records_count=@student.student_records.count(:conditions=>["(raa.attachment_file_name is not null and r.input_type='attachment' and student_records.batch_id=? and student_records.additional_field_id IN (?)) or (r.input_type <> 'attachment' and student_records.additional_info != '' and student_records.batch_id=? and student_records.additional_field_id IN (?))",@batch.id,@record_group.records.collect(&:id),@batch.id,@record_group.records.collect(&:id)],:joins=>"inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id left outer join record_addl_attachments raa on raa.student_record_id=student_records.id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id inner join record_batch_assignments rba on rba.record_assignment_id=ra.id and rba.batch_id=b.id")
          @value=all_records_count == 0 ? 0 : ((student_records_count.to_f/all_records_count.to_f)*100)
        else
          @record_groups=@batch.record_groups.all(:joins=>[:courses,:record_assignments],:select=>"courses.course_name,record_groups.*,record_assignments.priority o_p,record_assignments.course_id",:order=>"o_p asc",:conditions=>["record_assignments.course_id=?",@batch.course_id],:group=>"record_groups.id")
          all_records_count=@batch.record_groups.count(:joins=>:records)
          r_ids=[]
          @record_groups.each do |rg|
            r_ids += rg.records.collect(&:id)
          end
          student_records_count=@student.student_records.count(:conditions=>["(raa.attachment_file_name is not null and r.input_type='attachment' and student_records.batch_id=?) or (r.input_type <> 'attachment' and student_records.additional_info != '' and student_records.batch_id=?)",@batch.id,@batch.id],:joins=>"inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id left outer join record_addl_attachments raa on raa.student_record_id=student_records.id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id inner join record_batch_assignments rba on rba.record_assignment_id=ra.id and rba.batch_id=b.id")
          @value=all_records_count == 0 ? 0 : ((student_records_count.to_f/all_records_count.to_f)*100)
        end
        page.replace_html "flash_box", :text => "<p class='flash-msg'>#{t('student_record_created')}</p>"
        page.replace_html "individual_student_#{params[:record_group_id]}", :partial=>'student_records_display'
        page.replace_html "student_details", :partial=>'student_information'
        page.replace_html "status_#{@record_group.id}", :partial=>'head_span',:object=>@record_group
      end
    else
      render :update do |page|
        @student_records=@student.student_records
        page.replace_html "form-errors_#{params[:record_group_id]}", :partial => 'errors', :object => @student
      end
    end
  end
  def new
    @student=Student.find(params[:id])
    @batch=Batch.find(params[:batch_id])
    if @batch.is_active == true
      @students=@batch.students.sort_by {|student| student.full_name.downcase.strip }
    else
      @students=@batch.graduated_students.sort_by {|student| student.full_name.downcase.strip }
    end
    if params[:rg_id].present?
      @record_groups=RecordGroup.find_all_by_id(params[:rg_id],:include=>{:records=>:record_field_options})
      if @record_groups.present?
        @rg=@record_groups.first
        all_records_count=@rg.records.count
        student_records_count=@student.student_records.count(:conditions=>["(raa.attachment_file_name is not null and r.input_type='attachment' and student_records.batch_id=? and student_records.additional_field_id IN (?)) or (r.input_type <> 'attachment' and student_records.additional_info != '' and student_records.batch_id=? and student_records.additional_field_id IN (?))",@batch.id,@rg.records.collect(&:id),@batch.id,@rg.records.collect(&:id)],:joins=>"inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id left outer join record_addl_attachments raa on raa.student_record_id=student_records.id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id inner join record_batch_assignments rba on rba.record_assignment_id=ra.id and rba.batch_id=b.id")
        @value=all_records_count == 0 ? 0 : ((student_records_count.to_f/all_records_count.to_f)*100)
      else
        @value=0
      end
    else
      @record_groups=@batch.record_groups.all(:joins=>[:courses,:record_assignments],:select=>"courses.course_name,record_groups.*,record_assignments.priority o_p,record_assignments.course_id",:order=>"o_p asc",:conditions=>["record_assignments.course_id=?",@batch.course_id],:group=>"record_groups.id")
      all_records_count=@batch.record_groups.count(:joins=>:records)
      r_ids=[]
      @record_groups.each do |rg|
        r_ids += rg.records.collect(&:id)
      end
      student_records_count=@student.student_records.count(:conditions=>["(raa.attachment_file_name is not null and r.input_type='attachment' and student_records.batch_id=?) or (r.input_type <> 'attachment' and student_records.additional_info != '' and student_records.batch_id=?)",@batch.id,@batch.id],:joins=>"inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id left outer join record_addl_attachments raa on raa.student_record_id=student_records.id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id inner join record_batch_assignments rba on rba.record_assignment_id=ra.id and rba.batch_id=b.id")
      @value=all_records_count == 0 ? 0 : ((student_records_count.to_f/all_records_count.to_f)*100)
    end
    @student_records = @student.student_records.all(:conditions=>{:student_records=>{:batch_id=>@batch.id}},:joins=>[:student,{:record=>:record_group}])
    @grouped_student_records=@student.student_records.all(:select=>"students.first_name,record_groups.name rg_name,records.*,student_records.*",:joins=>[:student,{:record=>:record_group}],:conditions=>{:batch_id=>@batch.id}).group_by(&:rg_name)
    @record_groups.each do |rg|
      rg.records.all(:order=>'records.priority').each do |r|
        unless @student_records.collect(&:additional_field_id).include?(r.id)
          sr=@student.student_records.build(:additional_field_id=>r.id)
          @student_records.push(sr)
          sr.record_addl_attachments.build
        end
      end
    end
    @all_student_records=@student_records.group_by{|rg| rg.record.record_group_id}
    if request.post?
      render(:update) do |page|
        page.replace_html   'entire_form_sec', :partial=>"all_parts"
      end
    end
  end

  def get_edit_form
    @student=Student.find(params[:student_id])
    @batch=Batch.find(params[:batch_id])
    @record_group=RecordGroup.find(params[:record_group_id])
    @student_records = @student.student_records.all(:conditions=>{:student_records=>{:batch_id=>@batch.id}},:joins=>[:student,{:record=>:record_group}])
    @grouped_student_records=@student.student_records.all(:select=>"students.first_name,record_groups.name rg_name,records.*,student_records.*",:joins=>[:student,{:record=>:record_group}],:conditions=>{:batch_id=>@batch.id}).group_by(&:rg_name)
    @record_group.records.all(:order=>'records.priority').each do |r|
      unless @student_records.collect(&:additional_field_id).include?(r.id)
        sr=@student.student_records.build(:additional_field_id=>r.id)
        @student_records.push(sr)
        sr.record_addl_attachments.build
      end
    end
    @all_student_records=@student_records.group_by{|rg| rg.record.record_group_id}
    render :partial=>'record_fields'
  end

  def student_records_for_batch
    @batch=Batch.find(params[:id]||params[:batch][:id])
    if @batch.is_active == true
      @students=@batch.students.all(:order=>'students.first_name asc')
    else
      @students=@batch.graduated_students.sort{|a,b| a[:first_name]<=>b[:first_name]}
    end
    unless params[:student_id].present?
      @student = @students.first
    else
      @student=Student.find(params[:student_id])
    end
    if @student.present?
      @previous_student = @students[@students.index(@student) - 1]
      @next_student = @students[@students.index(@student) + 1]
      if params[:rg_id].present?
        rg=RecordGroup.find(params[:rg_id])
        @batches=@batch.course.batches.usable.all(:select=>'distinct batches.id,name',:joins=>:record_batch_assignments,:conditions=>["record_batch_assignments.record_group_id=?",params[:rg_id]])
        @student_records=@student.student_records.all(:select=>"distinct s.first_name, rg.name rg_name,r.*,student_records.*,ra.priority o_p",:conditions=>["(raa.attachment_file_name is not null and r.input_type='attachment' and student_records.batch_id=? and student_records.additional_field_id IN (?)) or (r.input_type <> 'attachment' and student_records.additional_info != '' and student_records.batch_id=? and student_records.additional_field_id IN (?))",@batch.id,rg.records.collect(&:id),@batch.id,rg.records.collect(&:id)],:joins=>"inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id left outer join record_addl_attachments raa on raa.student_record_id=student_records.id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id",:order=>"o_p asc").group_by(&:rg_name)
      else
        @batches=Batch.usable.all(:select=>'distinct batches.id,name',:joins=>[:students,:record_batch_assignments])
        @student_records=@student.student_records.all(:select=>"distinct s.first_name, rg.name rg_name,r.*,student_records.*,ra.priority o_p",:conditions=>["(raa.attachment_file_name is not null and r.input_type='attachment' and student_records.batch_id=?) or (r.input_type <> 'attachment' and student_records.additional_info != '' and student_records.batch_id=?)",@batch.id,@batch.id],:joins=>"inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id left outer join record_addl_attachments raa on raa.student_record_id=student_records.id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id",:order=>"o_p asc").group_by(&:rg_name)
      end
    end
    if (params[:batch].present? and params[:batch][:id].present?) or request.post?
      render(:update) do |page|
        page.replace_html   'course_batches_section', :partial=>"links_for_change"
        page.replace_html   'batch_informer', :partial=>"batch_info"
        page.replace_html   'student_list', :partial=>"student_list" if ((params[:batch].present? and params[:batch][:id].present? and @students.present? and @student.present?) or (@students.present? and @student.present?))
        page.replace_html   'student_list', :text=>"" unless ((params[:batch].present? and params[:batch][:id].present? and @students.present? and @student.present?) or (@students.present? and @student.present?))
        page.replace_html   'student_record', :partial=>"individual_student_record" if @student.present?
        page.replace_html   'student_record', :text=>"" unless @student.present?
      end
    end
  end

  def handle_record_groups
    @record_group=RecordGroup.find(params[:id])
    @courses_list=Course.active.all(:select=>'courses.id,count(DISTINCT IF(batches.course_id=courses.id,batches.id,NULL)) bcount,courses.course_name cname,courses.grading_type',:joins=>{:record_groups=>:batches},:conditions=>["record_assignments.record_group_id = ? ",@record_group.id],:group=>'courses.id')
  end

  def manage_student_records
    if current_user.admin? or current_user.privileges.include?(Privilege.find_by_name('ManageStudentRecord'))
      if params[:course_batch].present? and params[:course_batch]=='no'
        @record_groups=RecordGroup.all(:joins=>{:record_assignments=>:record_batch_assignments},:group=>"id",:select=>'record_groups.id,name,count(distinct record_batch_assignments.batch_id) count')
      else
        @courses_list = Course.active.all(:select=>'courses.id,count(DISTINCT IF(batches.course_id=courses.id,batches.id,NULL)) bcount,courses.course_name cname,courses.grading_type',:joins=>"INNER JOIN `record_assignments` ON (`courses`.`id` = `record_assignments`.`course_id`) LEFT OUTER JOIN `record_groups` ON (`record_groups`.`id` = `record_assignments`.`record_group_id`) LEFT OUTER JOIN `record_batch_assignments` ON (`record_groups`.`id` = `record_batch_assignments`.`record_group_id`) LEFT OUTER JOIN `batches` ON (`batches`.`id` = `record_batch_assignments`.`batch_id`)",:group=>'courses.id')
      end
    elsif current_user.is_a_batch_tutor?
      @batches_list = current_user.employee_entry.batches.all(:select=>'DISTINCT batches.*,concat(courses.course_name," - ",batches.name) as full_name,courses.course_name cname',:joins=>[:record_batch_assignments,:course]).group_by{|b| b.is_active}
    end
    if request.post?
      if params[:course_batch].present? and params[:course_batch]=='no'
        render :update do |page|
          page.replace_html 'rg_desc',:text=>t('manage_student_records_rg_text_desc')
          page.replace_html 'student_items' ,:partial=>'manage_record_groups_for_students'
        end
      else
        render :update do |page|
          page.replace_html 'rg_desc' ,:text=>t('manage_student_records_text_desc')
          page.replace_html 'student_items' ,:partial=>'manage_student_records_course_batch_wise'
        end
      end
    end
  end

  def manage_student_records_for_course
    @course=Course.active.find_by_id(params[:id]||params[:course][:id])
    if @course.present?
      @record_groups=@course.record_groups
      if params[:rg_id].present?
        @record_group=RecordGroup.find(params[:rg_id])
        @batches_list = @course.batches.usable.all(:select=>"distinct batches.id,batches.name,batches.is_active status",:order=>'status desc',:joins=>"LEFT OUTER JOIN `batch_students` ON batch_students.batch_id = batches.id LEFT OUTER JOIN `students` ON `students`.id = `batch_students`.student_id INNER JOIN record_batch_assignments rba on rba.batch_id=batches.id",:conditions=>['rba.record_group_id=? and (batches.is_active=1 or students.id is not null)',@record_group.id]).group_by(&:status)
      else
        @batches_list = @course.batches.usable.all(:select=>"distinct batches.id,batches.name,batches.is_active status",:order=>'status desc',:joins=>"LEFT OUTER JOIN `batch_students` ON batch_students.batch_id = batches.id LEFT OUTER JOIN `students` ON `students`.id = `batch_students`.student_id",:conditions=>['batches.is_active=1 or students.id is not null']).group_by(&:status)
      end
      if request.post?
        render(:update) do |page|
          page.replace_html  'batches_list', :partial=>"batches_all_rgs"
        end
      end
    end
  end

  def list_students
    @batch = Batch.find(params[:id])
    @sort_order = params[:sort_order] || 'first_name ASC'
    if params[:rg_id].present?
      @record_group = RecordGroup.find(params[:rg_id])
    end
    if @batch.is_active == true
        @all_students = @batch.students.paginate(:per_page=>20,:page=>params[:page],:order=>@sort_order)
    else
        @all_students = @batch.graduated_students.paginate(:per_page=>20,:page=>params[:page], :order=>@sort_order)
    end
    if request.xhr?
      render :update do |page|
        page.replace_html "information", :partial => "list_students"
      end
    end
  end


  def get_courses_list
    if params[:rg_id].present?
      @courses_list=Course.active.all(:select=>'courses.id,count(distinct batches.id) bcount,courses.course_name cname',:joins=>[:batches,:record_assignments],:conditions=>{:record_assignments=>{:record_group_id=>params[:rg_id]}},:group=>'courses.course_name')
    else
      @courses_list=Course.active.all(:select=>'courses.id,count(distinct batches.id) bcount,courses.course_name cname',:joins=>[:batches,:record_assignments],:group=>'courses.course_name')
    end
    @current_course_id=params[:id]
    render :partial=>'get_courses_list'
  end

  def get_course_batch_selector
    @batch=Batch.find(params[:id])
    @course=@batch.course
    if params[:rg_id].present?
      @batches=@course.batches.usable.all(:select=>"distinct batches.id,batches.name,batches.is_active status",:order=>'status desc',:joins=>"LEFT OUTER JOIN `batch_students` ON batch_students.batch_id = batches.id LEFT OUTER JOIN `students` ON `students`.id = `batch_students`.student_id INNER JOIN record_batch_assignments rba on rba.batch_id=batches.id",:conditions=>['rba.record_group_id=? and (batches.is_active=1 or students.id is not null)',params[:rg_id]])
      @courses=Course.active.all(:select=>'distinct courses.id,courses.course_name cname',:joins=>[{:batches=>:students},:record_assignments],:conditions=>["record_assignments.record_group_id=?",params[:rg_id]])
    else
      @batches=@course.batches.usable.all(:select=>"distinct batches.id,batches.name,batches.is_active status",:order=>'status desc',:joins=>"LEFT OUTER JOIN `batch_students` ON batch_students.batch_id = batches.id LEFT OUTER JOIN `students` ON `students`.id = `batch_students`.student_id",:conditions=>['batches.is_active=1 or students.id is not null'])
      @courses=Course.active.all(:select=>'distinct courses.id,courses.course_name cname',:joins=>[{:batches=>:students},:record_assignments])
    end
    render :update do |page|
      page.replace_html 'course_batches_section',:partial=>'course_selector'
    end
  end
  
  def get_batches_list
    @course=Course.find(params[:id])
    if params[:rg_id].present?
      @batches=@course.batches.usable.all(:select=>"distinct batches.id,batches.name,batches.is_active status",:order=>'status desc',:joins=>"LEFT OUTER JOIN `batch_students` ON batch_students.batch_id = batches.id LEFT OUTER JOIN `students` ON `students`.id = `batch_students`.student_id INNER JOIN record_batch_assignments rba on rba.batch_id=batches.id",:conditions=>['rba.record_group_id=? and (batches.is_active=1 or students.id is not null)',params[:rg_id]])
    else
      @batches=@course.batches.usable.all(:select=>"distinct batches.id,batches.name,batches.is_active status",:order=>'status desc',:joins=>"LEFT OUTER JOIN `batch_students` ON batch_students.batch_id = batches.id LEFT OUTER JOIN `students` ON `students`.id = `batch_students`.student_id",:conditions=>['batches.is_active=1 or students.id is not null'])
    end
    render :update do |page|
      page.replace_html 'batches_list',:partial=>'batch_selector'
    end
  end

  def cancel
    @batch=Batch.find(params[:id])
    render(:update) do |page|
      page.replace_html   'course_batches_section', :partial=>"links_for_change"
    end
  end

  def destroy
    @student=Student.find(params[:student_id])
    @batch=Batch.find(params[:batch_id])
    @record_group=RecordGroup.find(params[:record_group_id])
    @record_groups=RecordGroup.find_all_by_id(@record_group.id,:include=>{:records=>:record_field_options})
    @record_group.student_records.all(:conditions=>{:student_records=>{:batch_id=>@batch.id,:student_id=>@student.id}}).each do |sr|
      sr.destroy
    end
    @student_records = @student.student_records.all(:conditions=>{:student_records=>{:batch_id=>@batch.id}},:joins=>[:student,{:record=>:record_group}])
    @grouped_student_records=@student.student_records.all(:select=>"students.first_name,record_groups.name rg_name,records.*,student_records.*",:joins=>[:student,{:record=>:record_group}],:conditions=>{:batch_id=>@batch.id}).group_by(&:rg_name)
    @record_groups.each do |rg|
      rg.records.all(:order=>'records.priority').each do |r|
        unless @student_records.collect(&:additional_field_id).include?(r.id)
          sr=@student.student_records.build(:additional_field_id=>r.id)
          @student_records.push(sr)
          sr.record_addl_attachments.build
        end
      end
    end
    @all_student_records=@student_records.group_by{|rg| rg.record.record_group_id}
    if params[:form_type] == 'specific'
      all_records_count=@record_group.records.count
      student_records_count=@student.student_records.count(:conditions=>["(raa.attachment_file_name is not null and r.input_type='attachment' and student_records.batch_id=? and student_records.additional_field_id IN (?)) or (r.input_type <> 'attachment' and student_records.additional_info != '' and student_records.batch_id=? and student_records.additional_field_id IN (?))",@batch.id,@record_group.records.collect(&:id),@batch.id,@record_group.records.collect(&:id)],:joins=>"inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id left outer join record_addl_attachments raa on raa.student_record_id=student_records.id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id inner join record_batch_assignments rba on rba.record_assignment_id=ra.id and rba.batch_id=b.id")
      @value=all_records_count == 0 ? 0 : ((student_records_count.to_f/all_records_count.to_f)*100)
    else
      @record_groups=@batch.record_groups.all(:joins=>[:courses,:record_assignments],:select=>"courses.course_name,record_groups.*,record_assignments.priority o_p,record_assignments.course_id",:order=>"o_p asc",:conditions=>["record_assignments.course_id=?",@batch.course_id],:group=>"record_groups.id")
      all_records_count=@batch.record_groups.count(:joins=>:records)
      r_ids=[]
      @record_groups.each do |rg|
        r_ids += rg.records.collect(&:id)
      end
      student_records_count=@student.student_records.count(:conditions=>["(raa.attachment_file_name is not null and r.input_type='attachment' and student_records.batch_id=?) or (r.input_type <> 'attachment' and student_records.additional_info != '' and student_records.batch_id=?)",@batch.id,@batch.id],:joins=>"inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id left outer join record_addl_attachments raa on raa.student_record_id=student_records.id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id inner join record_batch_assignments rba on rba.record_assignment_id=ra.id and rba.batch_id=b.id")
      @value=all_records_count == 0 ? 0 : ((student_records_count.to_f/all_records_count.to_f)*100)
    end
    render :update do |page|
      page.replace_html "flash_box", :text => "<p class='flash-msg'>#{t('student_record_deleted')}</p>"
      page.replace_html "individual_student_#{params[:record_group_id]}", :partial=>'record_fields'
      page.replace_html "student_details", :partial=>'student_information'
      page.replace_html "status_#{@record_group.id}", :partial=>'head_span',:object=>@record_group
    end
  end

  def individual_student_records
    @student=Student.find(params[:id])
    unless params[:batch_id].present?
      @batch=@student.batch
    else
      @batch=Batch.find(params[:batch_id])
    end
    @batches=[]
    @batches << @student.batch
    @batches += @student.graduated_batches.sort{|a,b| b[:id] <=> a[:id]}
    @batches.uniq!
    @previous_batch = @batches[@batches.index(@batch) - 1]
    @next_batch = @batches[@batches.index(@batch) + 1]
    #    @student_records=@student.student_records.all(:select=>"students.first_name,record_groups.name rg_name,records.*,student_records.*",:conditions=>["(record_addl_attachments.attachment_file_name is not null and records.input_type='attachment' and student_records.batch_id=?) or (records.input_type <> 'attachment' and student_records.additional_info != '' and student_records.batch_id=?)",@batch.id,@batch.id],:joins=>"INNER JOIN `students` ON `student_records`.student_id = `students`.id INNER JOIN `records` ON `records`.id = `student_records`.additional_field_id INNER JOIN `record_groups` ON `record_groups`.id = `records`.record_group_id LEFT OUTER JOIN `record_addl_attachments` ON record_addl_attachments.student_record_id = student_records.id INNER JOIN record_assignments on record_assignments.record_group_id=record_groups.id",:order=>"record_assignments.priority asc").group_by(&:rg_name)
    @student_records=@student.student_records.all(:select=>"distinct s.first_name, rg.name rg_name,r.*,student_records.*,ra.priority o_p",:conditions=>["(raa.attachment_file_name is not null and r.input_type='attachment' and student_records.batch_id=?) or (r.input_type <> 'attachment' and student_records.additional_info != '' and student_records.batch_id=?)",@batch.id,@batch.id],:joins=>"inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id left outer join record_addl_attachments raa on raa.student_record_id=student_records.id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id",:order=>"o_p asc").group_by(&:rg_name)
    if (params[:batch].present? and params[:batch][:id].present?) or request.post?
      render(:update) do |page|
        page.replace_html   'student_list', :partial=>"batches_list"
        page.replace_html   'student_record', :partial=>"individual_student_records"
      end
    end
  end


  def student_record_csv_export
    @batch=Batch.find(params[:id])
    if @batch.is_active == true
      @students=@batch.students.all(:order=>'students.first_name asc')
    else
      @students=@batch.graduated_students.sort{|a,b| a[:first_name]<=>b[:first_name]}
    end
    csv_records=StudentRecord.last.get_student_record_csv_report_details(@batch, @students, params[:rg_id])
    filename = "StudentRecordExport#{Time.now.to_date.to_s}.csv"
    send_data(csv_records, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end


end
