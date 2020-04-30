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

class ExamReportsController < ApplicationController
  helper_method :valid_mark?
  before_filter :login_required
  before_filter :protect_other_student_data
  #  before_filter :restrict_employees_from_exam
  before_filter :has_required_params
  #before_filter :load_archived_exam_prerequsites, :only=>[:archived_batches_exam_report,:archived_batches_exam_report_pdf]
  before_filter :load_consolidated_exam_prerequsites,:only=>[:consolidated_exam_report,:consolidated_exam_report_pdf]
  filter_access_to :all, :except=>[:archived_exam_wise_report,:list_inactivated_batches,:final_archived_report_type,:consolidated_exam_report,
    :consolidated_exam_report_pdf,:archived_batches_exam_report,:archived_batches_exam_report_pdf,:graph_for_archived_batches_exam_report]

  filter_access_to [:archived_exam_wise_report], :attribute_check=>true, :load_method => lambda { current_user }
  filter_access_to [:list_inactivated_batches], :attribute_check=>true, :load_method => lambda { Course.find(params[:course_id]) }
  filter_access_to [:final_archived_report_type,:archived_batches_exam_report_pdf,], :attribute_check=>true, :load_method => lambda { Batch.find(params[:batch_id]) }
  filter_access_to [:archived_batches_exam_report], :attribute_check=>true, :load_method => lambda { Batch.find(params[:exam_report][:batch_id]) }
  
  def archived_exam_wise_report
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))  or @current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
      @courses=Course.has_inactive_batches.uniq
    elsif @current_user.is_a_batch_tutor
      @courses=[]
      @courses+=Course.all(:joins=>{:batches=>:employees},:conditions=>{:is_deleted=>false,:batches=>{:is_active=>false,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
      @courses+=Course.all(:joins=>{:batches=>{:subjects=>:employees}},:conditions=>{:is_deleted=>false,:batches=>{:is_active=>false,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
      @courses.uniq!
    elsif @current_user.is_a_subject_teacher
      @courses=Course.all(:joins=>{:batches=>{:subjects=>:employees}},:conditions=>{:is_deleted=>false,:batches=>{:is_active=>false,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
    else
      @courses=[]
    end
    @batches=[]
  end

  def list_inactivated_batches
    unless params[:course_id]==""
      @course = Course.find(params[:course_id])
      @batches = Batch.find(:all,:conditions=>{:course_id=>@course.id,:is_active=>false,:is_deleted=>false})
    else
      @batches = []
    end
    render(:update) do|page|
      page.replace_html "inactive_batches", :partial=>"inactive_batches"
    end
  end

  def final_archived_report_type
    batch = Batch.find(params[:batch_id])
    @grouped_exams = GroupedExam.find_all_by_batch_id(batch.id)
    render(:update) do |page|
      page.replace_html 'archived_report_type',:partial=>'report_type'
    end
  end

  def archived_batches_exam_report
    #grouped-exam-report-for-batch
    if params[:student].nil?
      @type = params[:type]
      @batch = Batch.find(params[:exam_report][:batch_id])
      #        @students_all = BatchStudent.find_by_sql("select s.id sid,CONCAT_WS('',s.first_name,' ',s.last_name) full_name,s.admission_no,s.roll_number,s.first_name,s.last_name,bs.roll_number roll_number from students s inner join batch_students bs on bs.student_id=s.id where bs.batch_id=#{@batch.id} UNION ALL select ars.former_id sid,CONCAT_WS('',ars.first_name,' ',ars.last_name) full_name,ars.admission_no,ars.roll_number,ars.first_name,ars.last_name from archived_students ars inner join batch_students bs on bs.student_id=ars.former_id where bs.batch_id=#{@batch.id}  order by #{Student.sort_order("batch_students")}")
      @students_all = BatchStudent.find_by_sql("select s.id sid,CONCAT_WS('',s.first_name,' ',s.middle_name,' ',s.last_name) full_name,s.admission_no,s.first_name,s.last_name,bs.roll_number roll_number from students s inner join batch_students bs on bs.student_id=s.id where bs.batch_id=#{@batch.id} UNION ALL select ars.former_id sid,CONCAT_WS('',ars.first_name,' ',ars.middle_name,' ',ars.last_name) full_name,ars.admission_no,ars.first_name,ars.last_name,ars.roll_number roll_number from archived_students ars where ars.batch_id=#{@batch.id} UNION ALL select ars1.former_id sid,CONCAT_WS('',ars1.first_name,' ',ars1.middle_name,' ',ars1.last_name) full_name,ars1.admission_no,ars1.first_name,ars1.last_name,bs.roll_number roll_number from archived_students ars1 inner join batch_students bs on bs.student_id=ars1.former_id where bs.batch_id=#{@batch.id} order by #{Student.sort_order}")
      @students=[]
      @students_all.each do |s|
        st = Student.find_by_id(s.sid)
        st.roll_number = st.batch_students.last.roll_number unless st.nil?
        if st.nil?
          st = ArchivedStudent.find_by_former_id(s.sid)
          st.id = st.former_id
          batch_student = BatchStudent.find(:all,:conditions=> "student_id=#{st.id}").last unless st.nil?
          if batch_student.nil?
            st.roll_number =  nil 
          else
            st.roll_number =  batch_student.roll_number
          end
        end
        @students.push st
      end
      #@students=@batch.students.all(:order=>"first_name ASC")
      @student = @students.first  unless @students.empty?
      if @student.blank?
        flash[:notice] = "#{t('flash1')}"
        redirect_to :action=>'archived_exam_wise_report' and return
      end
      if @type == 'grouped'
        @grouped_exams = GroupedExam.find_all_by_batch_id(@batch.id)
        @exam_groups = []
        @grouped_exams.each do |x|
          @exam_groups.push ExamGroup.find(x.exam_group_id)
        end
      else
        @exam_groups = ExamGroup.find_all_by_batch_id(@batch.id)
      end
      general_subjects = Subject.find_all_by_batch_id(@batch.id, :conditions=>"elective_group_id IS NULL AND is_deleted=false")
      student_electives = StudentsSubject.find_all_by_student_id(@student.id,:conditions=>"batch_id = #{@batch.id}")
      elective_subjects = []
      student_electives.each do |elect|
        elective_subjects.push Subject.find(elect.subject_id)
      end
      @subjects = general_subjects + elective_subjects
      @subjects.reject!{|s| (s.no_exams==true or s.exam_not_created(@exam_groups.collect(&:id)))}
    else
      @student = Student.find_by_id(params[:student])
      @student.roll_number = @student.batch_students.last.roll_number unless @student.nil?
      if @student.nil?
        @student = ArchivedStudent.find_by_former_id(params[:student])
        unless @student.nil?
          @student.id = @student.former_id
          @student.roll_number = BatchStudent.find(:all,:conditions=> "student_id=#{@student.id}").last.roll_number
        end
      end
      @batch = Batch.find(params[:exam_report][:batch_id])
      @type  = params[:type]
      if params[:type] == 'grouped'
        @grouped_exams = GroupedExam.find_all_by_batch_id(@batch.id)
        @exam_groups = []
        @grouped_exams.each do |x|
          @exam_groups.push ExamGroup.find(x.exam_group_id)
        end
      else
        @exam_groups = ExamGroup.find_all_by_batch_id(@batch.id)
      end
      general_subjects = Subject.find_all_by_batch_id(@batch.id, :conditions=>"elective_group_id IS NULL AND is_deleted=false")
      student_electives = StudentsSubject.find_all_by_student_id(@student.id,:conditions=>"batch_id = #{@batch.id}")
      elective_subjects = []
      student_electives.each do |elect|
        elective_subjects.push Subject.find(elect.subject_id)
      end
      @subjects = general_subjects + elective_subjects
      @subjects.reject!{|s| (s.no_exams==true or s.exam_not_created(@exam_groups.collect(&:id)))}
      render(:update) do |page|
        page.replace_html   'grouped_exam_report', :partial=>"grouped_exam_report"
      end
    end
  end

  def archived_batches_exam_report_pdf
    #grouped-exam-report-for-batch
    if params[:student].nil?
      @type = params[:type]
      @batch = Batch.find(params[:exam_report][:batch_id])
      batch_students = BatchStudent.find_all_by_batch_id(@batch.id)
      @students = []
      unless batch_students.empty?
        batch_students.each do|bs|
          st = Student.find_by_id(bs.student_id)
          if st.nil?
            st = ArchivedStudent.find_by_former_id(bs.student_id)
            unless st.nil?
              st.id=bs.student_id
            end
          end
          unless st.nil?
            @students.push st
          end
        end
      end
      @student = @students.first
      if @type == 'grouped'
        @grouped_exams = GroupedExam.find_all_by_batch_id(@batch.id)
        @exam_groups = []
        @grouped_exams.each do |x|
          @exam_groups.push ExamGroup.find(x.exam_group_id)
        end
      else
        @exam_groups = ExamGroup.find_all_by_batch_id(@batch.id)
      end
      general_subjects = Subject.find_all_by_batch_id(@batch.id, :conditions=>"elective_group_id IS NULL and is_deleted=false")
      student_electives = StudentsSubject.find_all_by_student_id(@student.id,:conditions=>"batch_id = #{@batch.id}")
      elective_subjects = []
      student_electives.each do |elect|
        elective_subjects.push Subject.find(elect.subject_id,:conditions => {:is_deleted => false})
      end
      @subjects = general_subjects + elective_subjects
      @subjects.reject!{|s| (s.no_exams==true or s.exam_not_created(@exam_groups.collect(&:id)))}
    else
      @student = Student.find_by_id(params[:student])
      if @student.nil?
        @student = ArchivedStudent.find_by_former_id(params[:student])
        unless @student.nil?
          @student.id = @student.former_id
        end
      end
      @batch = Batch.find(params[:batch_id])
      @type  = params[:type]
      if params[:type] == 'grouped'
        @grouped_exams = GroupedExam.find_all_by_batch_id(@batch.id)
        @exam_groups = []
        @grouped_exams.each do |x|
          @exam_groups.push ExamGroup.find(x.exam_group_id)
        end
      else
        @exam_groups = ExamGroup.find_all_by_batch_id(@batch.id)
      end
      general_subjects = Subject.find_all_by_batch_id(@batch.id, :conditions=>"elective_group_id IS NULL")
      student_electives = StudentsSubject.find_all_by_student_id(@student.id,:conditions=>"batch_id = #{@batch.id}")
      elective_subjects = []
      student_electives.each do |elect|
        elective_subjects.push Subject.find(elect.subject_id)
      end
      @subjects = general_subjects + elective_subjects
      @subjects.reject!{|s| (s.no_exams==true or s.exam_not_created(@exam_groups.collect(&:id)))}
    end
    @general_records=ReportSetting.result_as_hash
    render :pdf => 'archived_batches_exam_report_pdf',:orientation => 'Landscape',:margin=>{:left=>10,:right=>10,:top=>8,:bottom=>8},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
  end

  def consolidated_exam_report

  end

  def consolidated_exam_report_pdf

    render :pdf => 'consolidated_exam_report_pdf',
      :page_size=> 'A3'
  end

  

  private

  def load_archived_exam_prerequsites
    exam_group_id = params[:exam_report] ? params[:exam_report][:exam_group_id] : params[:exam_group_id] ? params[:exam_group_id] : ""
    batch_id = params[:exam_report] ? params[:exam_report][:batch_id] : params[:batch_id] ? params[:batch_id] : ""
    if exam_group_id and batch_id
      @batch = Batch.find(batch_id)
      @exam_group = ExamGroup.find(exam_group_id)
      active_students = @batch.students + @batch.graduated_students
      archived_students = @batch.archived_students
      @students = active_students + archived_students
      if params[:student]
        find_student = active_students.select{|s| s.id==params[:student].to_i}
        @student = find_student.first unless find_student.blank?
        if @student.blank?
          find_student = archived_students.select{|s| s.former_id==params[:student].to_i}
          @student = find_student.first unless  find_student.blank?
        end
      else
        @student = active_students.first
      end
      if @student
        general_subjects = Subject.find_all_by_batch_id(@student.batch_id, :conditions=>"elective_group_id IS NULL")
        student_electives = StudentsSubject.find_all_by_student_id(@student.id,:conditions=>"batch_id = #{@student.batch.id}")
        elective_subjects = []
        student_electives.each do |elect|
          elective_subjects.push Subject.find(elect.subject_id)
        end
        @subjects = general_subjects + elective_subjects
        @exams = []
        @subjects.each do |sub|
          exam = Exam.find_by_exam_group_id_and_subject_id(@exam_group.id,sub.id)
          @exams.push exam unless exam.nil?
        end
      else
        flash[:notice]="#{t('flash2')}"
        redirect_to :controller=>"exam_reports", :action=>"archived_exam_wise_report"
      end
    else
      flash[:notice]="#{t('flash2')}"
      redirect_to :controller=>"exam_reports", :action=>"archived_exam_wise_report"
    end
  end

  def load_consolidated_exam_prerequsites
    @exam_group = ExamGroup.find(params[:exam_group])
    @active_students = @exam_group.batch.students + @exam_group.batch.graduated_students
    @archvied_students = @exam_group.batch.archived_students
  end
  def valid_mark?(score)
    score.to_f==0? false : true
  end

  def has_required_params
    case params[:action]
    when 'list_inactivated_batches'
      handle_params_failure(params[:course_id],[:@batches],[['inactive_batches',{:partial=>'inactive_batches'}]])
    when 'archived_batches_exam_report'
      if params[:exam_report][:course_id].present?
        handle_params_failure(params[:exam_report][:course_id],[],[{:controller => "exam_reports",:action => "archived_exam_wise_report" }],"#{t('select_course_batch')}",true) and return
      end
      handle_params_failure(params[:exam_report][:batch_id],[],[{:controller => "exam_reports",:action => "archived_exam_wise_report" }],"#{t('select_a_batch')}",true) and return
    end
  end
end
