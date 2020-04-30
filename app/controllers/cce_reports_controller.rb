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

class CceReportsController < ApplicationController
  lock_with_feature :cce_enhancement
  before_filter :login_required
  #  before_filter :load_cce_report, :only=>[:show_student_wise_report]
  #  before_filter :protect_other_student_data, :only =>[:student_report_pdf]
  before_filter :has_required_params
  filter_access_to :all, :except=>[:index,:student_wise_report,:student_report_pdf,:student_transcript,:student_report,
    :assessment_wise_report,:list_batches,:generated_report,:generated_report_csv,:generated_report_pdf,:subject_wise_report,
    :subject_wise_batches,:list_subjects,:subject_wise_generated_report,:subject_wise_generated_report_csv,
    :subject_wise_generated_report_pdf,:get_batches,:cce_full_exam_report,:generate_student_wise_report,:list_exam_groups,:generate_cbse_scholastic_report,:generate_cbse_scholastic_report_csv,:list_observation_groups,
    :generate_cbse_co_scholastic_report,:generate_cbse_co_scholastic_report_csv,:list_asl_groups,:generate_asl_report,:asl_report_csv,:new_batch_wise_student_report,:get_students_list,:previous_batch_exam_reports,:list_previous_batches,:upscale_report,:generate_previous_batch_exam_reports,:student_fa_report_pdf,:detailed_fa_report]

  filter_access_to [:index,:subject_wise_report,:student_wise_report,:consolidated_report,:batch_student_report,:cbse_report,
    :asl_report,:cbse_scholastic_report,:cbse_co_scholastic_report,:new_batch_wise_student_report,:create_reports,:get_batches,:get_students_list,:previous_batch_exam_reports,:upscale_report,:detailed_fa_report,:batch_wise_student_report_download], :attribute_check=>true, :load_method => lambda { current_user }
  filter_access_to [:subject_wise_batches,:list_batches,:list_previous_batches], :attribute_check=>true, :load_method => lambda { Course.find(params[:course_id])}
  filter_access_to [:list_subjects], :attribute_check=>true, :load_method => lambda { params[:exam_group_id].present? ? ExamGroup.find(params[:exam_group_id]).batch : Batch.find(params[:batch_id])}
  filter_access_to [:generate_student_wise_report,:generated_report_csv,:generated_report_pdf,:list_exam_groups,
    :list_observation_groups,:list_asl_groups,:asl_report_csv], :attribute_check=>true, :load_method => lambda { Batch.find(params[:batch_id])}
  filter_access_to [:student_report], :attribute_check=>true, :load_method => lambda { Student.find(params[:student_id]).batch}
  filter_access_to [:student_report_pdf,:cce_full_exam_report,:student_transcript,:student_fa_report_pdf], :attribute_check=>true, :load_method => lambda { (params[:type].present? and params[:type] == 'former') ? (ars=ArchivedStudent.find_by_former_id(params[:id]);ars.user.student_record.batch_in_context_id=params[:batch_id];ars.user) : (s=Student.find_by_id(params[:id]);(s.user.student_record.batch_in_context_id=params[:batch_id];s.user))}
  filter_access_to [:generated_report,:generate_cbse_co_scholastic_report,:generate_asl_report,:generate_cbse_co_scholastic_report_csv], :attribute_check=>true, :load_method => lambda { Batch.find(params[:assessment][:batch_id])}
  filter_access_to [:generate_previous_batch_exam_reports], :attribute_check=>true, :load_method => lambda { Batch.find(params[:batch_id])}
  filter_access_to [:subject_wise_generated_report,:subject_wise_generated_report_csv,:subject_wise_generated_report_pdf,:generate_cbse_scholastic_report,:generate_cbse_scholastic_report_csv], :attribute_check=>true, :load_method => lambda { (params[:subject_report][:subject_id] == "all" ? Batch.find(params[:subject_report][:batch_id]) : Subject.find(params[:subject_report][:subject_id]))}

  check_request_fingerprint :create_reports

  def index
  end


  def create_reports
    @courses = Course.cce
    if request.post?
      if params[:course].has_key?(:batch)
        @course=Course.find(params[:course][:id])
        @cce_report=CceReportGenerator.new(params[:course])
        @cce_report.validate_and_save
        batches=Batch.find_all_by_id(params[:course][:batch].keys)
        if batches.count == 1
          flash[:notice]="CCE Report is being generated for 1 batch of the class #{@course.full_name}. <a href='/scheduled_jobs/CceReportGenerator/1'>Click Here</a> to view the scheduled job."
        else
          flash[:notice]="CCE Report is being generated for #{batches.count} batches of the class #{@course.full_name}. <a href='/scheduled_jobs/CceReportGenerator/1'>Click Here</a> to view the scheduled job."
        end
      else
        flash[:notice]="No batch selected"
      end
    end

  end

  def get_batches
    if request.xhr?
      @course = Course.find_by_id(params[:course_id]) unless params[:course_id].blank?
      if @course
        case params[:type]
        when "1"
          @batches = @course.batches.active.all(:include=>:students)
          render :partial=>"batch_type"
        when "2"
          if params[:status] and params[:status] == "1"
            @batches = @course.batches.active.all(:include=>:students)
          else
            @batches = @course.batches.inactive
          end
          render :partial=>"sub_form"
        end
      else
        render :nothing=>true
      end
    end
  end

  def get_students_list
    @batch=Batch.find(params[:batch_id])
    sort_config = Exam.get_sort_config
    if @batch.is_active
      @students=@batch.students.all(:include=>:upscale_scores,:order=>"#{Student.sort_order}")
    else
      @students=Student.all(:joins=>"INNER JOIN batch_students bs on bs.student_id=students.id and bs.batch_id=#{@batch.id}",:order=>"soundex(bs.roll_number),length(bs.roll_number),bs.roll_number ASC") if sort_config == "roll_number"
      @students=Student.all(:joins=>"INNER JOIN batch_students bs on bs.student_id=students.id and bs.batch_id=#{@batch.id}",:order=>"#{Student.sort_order}") unless sort_config == "roll_number"
      @students.each do |student|
        student.roll_number = student.batch_students.last.roll_number
      end
    end
    render :partial=>'unique_student_list'
  end

  def student_wise_report
    get_respective_cce_batches
  end

  def generate_student_wise_report
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id])
      @eiop_eligibily_grade=CceReportSettingCopy.setting_result_as_hash(@batch,'grade')
      @pass_text=CceReportSettingCopy.setting_result_as_hash(@batch,'pass_text')
      @eiop_text=CceReportSettingCopy.setting_result_as_hash(@batch,'eiop_text')
      @grading_levels = @batch.grading_level_list
      @cce_categories=@batch.cce_exam_category
      @cat_id=params[:cat_id].to_i if params[:cat_id].present?
      @fa_group=params[:fa_group] if params[:fa_group].present?
      @check_term="all"
      @fa_group_names = []
      if params[:cat_id].present? and @cat_id!=0
        first_cce_exam_category_id=@batch.fetch_first_cce_exam_category
        
        if first_cce_exam_category_id==@cat_id
          @check_term="first_term"
        else
          @check_term="second_term"
        end
        #        @batch.exam_groups.first(:conditions=>{:cce_exam_category_id=>@cat_id}).exams.each do |e|
        #          e.subject.fa_groups.all(:conditions=>{:cce_exam_category_id=>@cat_id}).collect{|f| @fa_group_names << f.name.split(' ').last unless @fa_group_names.include?(f.name.split(' ').last)}
        #        end
        @batch.subjects.each do |subject|
          subject.fa_groups.all(:conditions=>{:cce_exam_category_id=>@cat_id}).collect{|f| @fa_group_names << f.name.split(' ').last unless @fa_group_names.include?(f.name.split(' ').last)}
        end
        @fa_group_names.sort!
      end

      @students=@batch.students.all(:order=>"#{Student.sort_order}")
      @student = (params[:student_id].present? ?  Student.find(params[:student_id]) : @students.first)
      
      if @student and !params[:fa_group].present?
        fetch_report
      elsif @student and params[:fa_group].present?
        fetch_fa_report        
      end
      unless @check_term=="all" or params[:fa_group].present?
        @exam_groups=@exam_groups.find_all_by_cce_exam_category_id(@cat_id)
      end
      render(:update) do |page|
        page.replace_html  'list_cce_category', :partial=>"list_cce_exam_cataegory", :object=>[@cce_categories,@batch,@student,@cat_id]
        page.replace_html  'fa_groups_list', :partial=>"fa_groups_list" if params[:cat_id].present? and @cat_id!=0 and !params[:fa_group].present?
        page.replace_html  'fa_groups_list', :text=>"" unless params[:cat_id].present?
        page.replace_html   'student_list', :partial=>"student_list", :object=>[@batch,@students,@cat_id,@fa_group]
        if @student.nil? 
          page.replace_html   'report', :text=>""
        elsif @student.present? and !params[:fa_group].present?
          page.replace_html   'report', :partial=>"student_report"
        elsif @student.present? and params[:fa_group].present?
          page.replace_html   'report', :partial=>"student_fa_report"
        end
        page.replace_html   'hider', :text=>""
      end
    else
      render(:update) do |page|
        page.replace_html  'list_cce_category', :text=>""
        page.replace_html  'fa_groups_list', :text=>""
        page.replace_html   'student_list', :text=>""
        page.replace_html   'report', :text=>""
        page.replace_html   'hider', :text=>""
      end
    end
  end

  def asl_report
    @asl_groups=[]
    @batches=[]
    get_respective_cce_courses
  end

  def generate_asl_report
    @assessment=params[:assessment][:asl_group_name]
    batch_id=params[:assessment][:batch_id]
    @batch=Batch.find batch_id
    @subject=@batch.subjects.asl_subject.first
    if  @subject.present?
      fetch_asl_report
      render(:update) do |page|
        page.replace_html 'hider', :text=>''
        page.replace_html 'report_table', :partial=>'asl_report'
      end
    else
      flash[:warn_notice]="No ASL Subject for this batch"
      error=true
    end
    if error
      render(:update) do |page|
        page.replace_html 'hider', :partial=>'error'
        page.replace_html 'report_table', :text=>''
      end
    end
  end

  def cce_full_exam_report
    @student = params[:type] == "former" ? ArchivedStudent.find_by_former_id(params[:id]) : Student.find_by_id(params[:id])
    @batch=(params[:batch_id].present? ?  Batch.find(params[:batch_id]) : @student.batch)
    @student.batch_in_context_id=@batch.id
    @exam_groups=@batch.exam_groups.all(:joins=>[:cce_exam_category,:exams],:group=>"id")
    @records=CceReportSettingCopy.result_as_hash(@batch,@student.id_in_context)
    @general_records=CceReportSettingCopy.general_records_as_hash(@batch)
    @config = Configuration.get_multiple_configs_as_hash ['InstitutionName', 'InstitutionAddress', 'InstitutionPhoneNo','InstitutionEmail','InstitutionWebsite']
    @settings = CceReportSetting.get_multiple_settings_as_hash ["TwoSubUpscaleStart", "TwoSubUpscaleEnd", "OneSubUpscaleStart", "OneSubUpscaleEnd"]
    @data_hash = CceReport.fetch_student_wise_report(params)
    @eiop_eligibily_grade=CceReportSettingCopy.setting_result_as_hash(@batch,'grade')
    @pass_text=CceReportSettingCopy.setting_result_as_hash(@batch,'pass_text')
    @eiop_text=CceReportSettingCopy.setting_result_as_hash(@batch,'eiop_text')
    @grading_levels = @batch.grading_level_list
    gsids=@batch.course.observation_groups.collect(&:cce_grade_set_id).uniq
    @grade_sets=CceGradeSet.find_all_by_id(gsids)
    fetch_attendance_data
    fetch_report
    render :pdf =>"cce_full_exam_report" ,:header =>{:content=>nil},:margin=>{:left=>10,:right=>10,:top=>5,:bottom=>5}, :show_as_html=>params[:d].present?
  end

  def upscale_report
    @all_batches=[]
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults")) or @current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
      @entries=Batch.all(:select=>"distinct batches.*,courses.course_name",:joins=>[:course,:upscale_scores],:conditions=>{:courses=>{:grading_type=>3},:is_deleted=>false,:is_active=>true}).group_by(&:course_name)
    elsif @current_user.is_a_batch_tutor
      @entries=@current_user.employee_record.batches.all(:select=>"distinct batches.*,courses.course_name",:joins=>[:course,:upscale_scores],:conditions=>{:courses=>{:grading_type=>3},:is_deleted=>false,:is_active=>true}).group_by(&:course_name)
    elsif @current_user.is_a_subject_teacher
      @current_user.employee_record.subjects.each do |subject|
        @all_batches<<subject.batch if subject.batch.course.grading_type=="3" and subject.batch.course.is_deleted==false
      end
      @all_batches.uniq.each do |batch|
        @batches<<batch
      end
    end
  end

  def student_report
    @check_term=params[:check_term]
    @cat_id=params[:cat_id].to_i
    @student = Student.find(params[:student_id])
    @fa_group=params[:fa_group]
    @batch=@student.batch
    @cce_categories=@batch.cce_exam_category
    @eiop_eligibily_grade=CceReportSettingCopy.setting_result_as_hash(@batch,'grade')
    @pass_text=CceReportSettingCopy.setting_result_as_hash(@batch,'pass_text')
    @eiop_text=CceReportSettingCopy.setting_result_as_hash(@batch,'eiop_text')
    @grading_levels = @batch.grading_level_list
    @fa_group_names = []
    if params[:cat_id].present? and @cat_id!=0
      @batch.exam_groups.first(:conditions=>{:cce_exam_category_id=>@cat_id}).exams.each do |e|
        e.subject.fa_groups.all(:conditions=>{:cce_exam_category_id=>@cat_id}).collect{|f| @fa_group_names << f.name.split(' ').last unless @fa_group_names.include?(f.name.split(' ').last)}
      end
      @fa_group_names.sort!
    end
    unless params[:fa_group].present?
      fetch_report
    else
      fetch_fa_report
    end
    unless @check_term=="all"  or params[:fa_group].present?
      @exam_groups=@exam_groups.find_all_by_cce_exam_category_id(@cat_id)
    end
    render(:update) do |page|
      page.replace_html  'list_cce_category', :partial=>"list_cce_exam_cataegory", :object=>[@cce_categories,@batch,@student,@cat_id]
      page.replace_html  'fa_groups_list', :partial=>"fa_groups_list" if params[:cat_id].present? and @cat_id!=0 and !params[:fa_group].present?
      page.replace_html  'fa_groups_list', :text=>"" unless params[:cat_id].present?
      page.replace_html   'report', :partial=>"student_report" unless params[:fa_group].present?
      page.replace_html   'report', :partial=>"student_fa_report" if params[:fa_group].present?
    end
  end
  
  
  def student_fa_report_pdf
    @student=Student.find_by_id(params[:id])
    if @student.nil?
      @student=ArchivedStudent.find_by_former_id(params[:id])
    end
    @batch=Batch.find(params[:batch_id])
    @student.batch_in_context_id = @batch.id
    @general_records=CceReportSettingCopy.general_records_as_hash(@student.batch_in_context)
    @fa_group=params[:fa_group]
    @grading_levels = @student.batch_in_context.grading_level_list
    fetch_fa_report
    render :pdf => "#{@student.first_name}-FA Report",:margin=>{:left=>10,:right=>10,:top=>8,:bottom=>8},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
  end

  def student_report_pdf
    @data_hash = CceReport.fetch_student_wise_report(params)
    @batch=@data_hash[:batch]
    @eiop_eligibily_grade=CceReportSettingCopy.setting_result_as_hash(@batch,'grade')
    @pass_text=CceReportSettingCopy.setting_result_as_hash(@batch,'pass_text')
    @eiop_text=CceReportSettingCopy.setting_result_as_hash(@batch,'eiop_text')
    @grading_levels = @batch.grading_level_list
    @check_term=params[:check_term]
    if params[:cat_id].present?
      @data_hash[:exam_groups].reject!{ |k|  k.cce_exam_category_id!=params[:cat_id].to_i}
    end
    @general_records=CceReportSettingCopy.general_records_as_hash(@batch)
    render :pdf => "#{@data_hash[:student].first_name}-CCE_Report",:margin=>{:left=>10,:right=>10,:top=>8,:bottom=>8},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
  end
  
  def batch_student_report
    @reports=BatchWiseStudentReport.all(:conditions => {:is_gradebook => false},:order=>'id desc')
  end

  def new_batch_wise_student_report
    get_respective_cce_courses
  end

  def generate_batch_student_report
    if params[:batch_ids].present?
      parameters = {:batch_ids => params[:batch_ids], :report_type => params[:report_type]}
      batch_student_report=BatchWiseStudentReport.new(:parameters=>parameters,:status=>'in queue',:course_id=>params[:course][:course_id])
      if batch_student_report.save
        Delayed::Job.enqueue(batch_student_report)
      end
      redirect_to :action=>'batch_student_report'
    else
      flash[:notice] = "No batches were selected"
      redirect_to :action => 'new_batch_wise_student_report'
    end
  end

  def batch_wise_student_report_download
    @report = BatchWiseStudentReport.find(params[:id])
    send_file(@report.report.path)
  end

  def student_transcript
    @report_type = params[:report_type]
    @student= (params[:type]=="former" ? ArchivedStudent.find_by_former_id(params[:id]) : Student.find(params[:id]))
    @type= params[:type] || "regular"
    @batch=(params[:batch_id].blank? ? @student.batch : Batch.find(params[:batch_id]))
    #    @batches=@student.all_batches.reverse
    @batches=@student.graduated_cce_batches.reverse
    @student.batch_in_context_id = @batch.id
    @eiop_eligibily_grade=CceReportSettingCopy.setting_result_as_hash(@batch,'grade')
    @pass_text=CceReportSettingCopy.setting_result_as_hash(@batch,'pass_text')
    @eiop_text=CceReportSettingCopy.setting_result_as_hash(@batch,'eiop_text')
    
    @grading_levels = @batch.grading_level_list
    @cce_categories=@batch.cce_exam_category
    @cat_id=params[:cat_id].to_i if params[:cat_id].present?
    @fa_group=params[:fa_group] if params[:fa_group].present?
    @check_term="all"
    @fa_group_names = []
    if params[:cat_id].present? and @cat_id!=0
      first_cce_exam_category_id=@batch.fetch_first_cce_exam_category
      if first_cce_exam_category_id==@cat_id
        @check_term="first_term"
      else
        @check_term="second_term"
      end
      @batch.exam_groups.first(:conditions=>{:cce_exam_category_id=>@cat_id}).exams.each do |e|
        e.subject.fa_groups.all(:conditions=>{:cce_exam_category_id=>@cat_id}).collect{|f| @fa_group_names << f.name.split(' ').last unless @fa_group_names.include?(f.name.split(' ').last)}
      end
      @fa_group_names.sort!
    end
    if @student and !params[:fa_group].present?
      fetch_report
    elsif @student and params[:fa_group].present?
      fetch_fa_report
      #    elsif @student and params[:fa_group].present? and !@fa_group_names.present?
      #      fetch_report     
    end
    unless @check_term=="all" or params[:fa_group].present?
      @exam_groups=@exam_groups.find_all_by_cce_exam_category_id(@cat_id)
    end
    
    if request.xhr?
      render(:update) do |page|
        #        page.replace_html  'list_cce_category', :partial=>"list_cce_exam_cataegory_student_wise", :object=>[@cce_categories,@batch,@cat_id]
        page.replace_html  'fa_groups_list', :partial=>"fa_groups_list_student_wise" if params[:cat_id].present? and @cat_id!=0 and !params[:fa_group].present?
        page.replace_html  'fa_groups_list', :text=>"" unless params[:cat_id].present?
        page.replace_html   'batch_list', :partial=>"all_batches_list", :object=>[@check_term,@type,@batches,@batch,@cat_id,@fa_group]
        if @student.nil? 
          page.replace_html   'report', :text=>""
        elsif @student.present? and !params[:fa_group].present?
          page.replace_html   'report', :partial=>"student_report"
        elsif @student.present? and params[:fa_group].present?
          page.replace_html   'report', :partial=>"student_fa_report"
        end        
      end
    end
  end
  
  
  def consolidated_report
    @exam_groups=[]
    get_respective_cce_courses
    @batches=[]
    @assessment_groups_cat_1=['FA1','FA2','FA3','FA4','SA1','SA2']
    @assessment_groups_cat_2=['SA1+SA2','FA1+FA2+FA3+FA4']
    @assessment_groups_cat_3=['FA1+FA2+SA1',"FA3+FA4+SA2"]
    @student_category=StudentCategory.active
  end
  
  def detailed_fa_report
    get_respective_cce_courses
    @batches=[]
    @student_category=StudentCategory.active
    @subjects=[]
  end
  
  def detailed_fa_batches
    unless params[:course_id].blank?
      course = Course.find(params[:course_id])
      get_respective_batches(course.id)
    else
      @batches=[]
    end
    render(:update) do |page|
      page.replace_html 'batch_select', :partial=>'detailed_fa_batches'
    end
  end
  
  def detailed_fa_list_subjects
    if params[:batch_id].present?
      batch = Batch.find params[:batch_id]
      subjects_without_exams = batch.exam_groups.present? ? batch.subjects.without_exams : []
      if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults")) or @current_user.privileges.include?(Privilege.find_by_name("ViewResults")) or @current_user.is_a_tutor_for_this_batch(batch)
        @subjects = subjects_without_exams.map{|a| [a.name,a.id]}
      elsif @current_user.is_a_subject_teacher(batch.id)
        employee_subjects=(batch.exam_groups.present? or params[:type].present?) ? @current_user.employee_record.subjects.without_exams.all(:conditions=>{:batch_id=>batch.id}) : []
        @subjects = employee_subjects.map{|a| [a.name,a.id]}
      else
        @subjects=[]
      end
    else
      @subjects=[]
    end
    render(:update) do |page|
      page.replace_html 'subject_select', :partial=>'detailed_fa_list_subjects'
    end
  end
  
  def detailed_fa_list_fa_groups
    if params[:subject_id].present?
      @fa_groups = [['FA1','FA1'],['FA2','FA2'],['FA3','FA3'],['FA4','FA4']]
    else
      @fa_groups = []
    end
    render(:update) do |page|
      page.replace_html 'set_assessment_groups', :partial=>'detailed_fa_list_fa_groups'
    end
  end
  
  def generated_detailed_fa_report
    unless params[:assessment][:batch_id].blank?
      unless params[:assessment][:assessment_group].blank?
        @batch= Batch.find params[:assessment][:batch_id]
        @student_category_id=params[:assessment][:student_category_id]
        @gender=params[:assessment][:gender]
        @subject = Subject.find params[:assessment][:subject_id]
        @assessment_group=params[:assessment][:assessment_group]
        @exam_group_id=params[:assessment][:exam_group_id]
        @fa_group = @subject.fa_groups.select{|s| s.name.split.last==@assessment_group}.first
        if @fa_group
          fetch_detailed_assessment_data
          calculate_overall_assessment_data(@subject,@fa_group,@batch)
        end
        if @fa_group
          render(:update) do |page|
            page.replace_html 'hider', :text=>''
            page.replace_html 'report_table', :partial=>'detailed_assessment_report'
            page.replace_html 'secondary_flash', :text=>''
          end
        else
          render(:update) do |page|
            page.replace_html 'secondary_flash', :text=>'<p class="flash-msg">No reports found for the search</p>'
            page.replace_html 'report_table', :text=>''
            page.replace_html 'hider', :text=>''
          end
        end
      else
        flash[:warn_notice]="Select FA group"
        error=true
      end
    else
      flash[:warn_notice]="Select a batch"
      error=true
    end
    if error
      render(:update) do |page|
        page.replace_html 'hider', :partial=>'error'
        page.replace_html 'report_table', :text=>''
        page.replace_html 'secondary_flash', :text=>''
      end
    end
  end

  def cbse_scholastic_report
    @exam_groups=[]
    @subjects=[]
    @batches=[]
    get_respective_cce_courses
    @assessment_groups=['FA1','FA2','FA3','FA4','SA1','SA2']
    @student_category=StudentCategory.active
  end

  def cbse_co_scholastic_report
    @observation_group=[]
    @subjects=[]
    @batches=[]
    get_respective_cce_courses
    @assessment_groups=['FA1','FA2','FA3','FA4','SA1','SA2']
    @student_category=StudentCategory.active
  end

  def generate_cbse_scholastic_report
    fetch_cbse_scholastic_data
    render(:update) do |page|
      page.replace_html 'hider', :text=>''
      page.replace_html 'report_table', :partial=>'cbse_scholastic_report'
    end
  end

  def generate_cbse_scholastic_report_csv
    fetch_cbse_scholastic_data
    csv_string=FasterCSV.generate do |csv|
      cols=[]
      cols << 'Session'
      cols << "#{@batch.start_date.year}-#{@batch.end_date.year}"
      cols << "  "
      cols << "EXAM"
      cols << "#{@batch.name}-#{@exam_group.name}"
      cols << "SUBJECT"
      cols << @subject.name
      csv << cols
      cols=[]
      3. times do
        cols << " "
      end
      fa_category=@subject.fa_groups.all(:conditions=>{:cce_exam_category_id=>@exam_group.cce_exam_category_id},:order=>'id asc')
      fa_category.each do |ag|
        cols << "#{ag.name.split.last}- MAX"
        cols << @fa_score_hash["config"][ag.name.split.last]["max_mark"]
        if (ag.name.split.last=="FA1" or ag.name.split.last=="FA2")
          @sa = "SA1"
        elsif (ag.name.split.last=="FA3" or ag.name.split.last=="FA4")
          @sa = "SA2"
        end
      end
      cols << "#{@sa} MAX"
      cols << @subject.exams.first(:conditions=>{:exam_group_id=>@exam_group.id}).maximum_marks
      csv << cols
      cols=[]
      3. times do
        cols << " "
      end
      fa_category.each do |ag|
        cols << "#{ag.name.split.last}"
        cols << ""
      end
      cols << @sa
      cols << ""
      csv << cols
      cols=[]
      cols << "BOARD REG. NO."
      cols << "ROLL NO"
      cols << "NAME"
      fa_category.each do |ag|
        cols << "obt."
        cols << "WT - " "#{ag.cce_exam_category.cce_weightages.first(:conditions=>{:criteria_type=>'FA'}).weightage}%"
        if @subject.is_asl
          max_marks = @subject.exams.first(:conditions=>{:exam_group_id=>@exam_group.id}).maximum_marks
          sa_weightage = ag.cce_exam_category.cce_weightages.first(:conditions=>{:criteria_type=>'SA'}).weightage
          asl_mark = @subject.asl_mark
          @sa = sa_weightage - ((asl_mark*sa_weightage)/max_marks)
        else
          @sa=ag.cce_exam_category.cce_weightages.first(:conditions=>{:criteria_type=>'SA'}).weightage
        end
      end
      cols << "obt."
      cols << "WT - #{@sa.to_f.round(2)}"
      csv << cols
      @students.each do |s|
        col=[]
        col << ""
        student_text = "#{s.full_name}"
        if Configuration.enabled_roll_number?
          col << (s.roll_number.present? ? s.roll_number : "NA")
        else
          col << ""
        end
        col<< student_text
        st=@fa_score_hash["students"].find{|c,v| c==s.id}
        if st
          fa_1_2_set=false
          fa_3_4_set=false
          c1=0
          c2=0
          fa_category.each do |ag|
            sc=@fa_score_hash["students"][s.id][@subject.id.to_s]
            if sc
              col << @fa_score_hash["students"][s.id][@subject.id.to_s][ag.name.split.last]['mark']
              if @fa_score_hash["students"][s.id][@subject.id.to_s][ag.name.split.last]['mark'].present?
                mark=@fa_score_hash["students"][s.id][@subject.id.to_s][ag.name.split.last]['converted_mark'].to_f * (ag.cce_exam_category.cce_weightages.first(:conditions=>{:criteria_type=>'FA'}).weightage)
                mark = (mark.is_a?String) ? "-" : (mark/100).to_f.round(2)
              else
                mark = " "
              end
              col << mark
              if (ag.name.split.last=="FA1" or ag.name.split.last=="FA2") and fa_1_2_set==false
                c1+=1
                if c1==fa_category.count
                  col << @fa_score_hash["students"][s.id][@subject.id.to_s]["SA1"]['mark']
                  if @fa_score_hash["students"][s.id][@subject.id.to_s]["SA1"]['mark'].present?
                    mark=@fa_score_hash["students"][s.id][@subject.id.to_s]["SA1"]['converted_mark'].to_f * @sa
                    mark = (mark.is_a?String) ? "-" : (mark/100).to_f.round(2)
                  else
                    mark = " "
                  end
                  col << mark
                  c1=0
                  fa_1_2_set=true
                end
              elsif (ag.name.split.last=="FA3" or ag.name.split.last=="FA4") and fa_3_4_set==false
                c2+=1
                if c2==fa_category.count
                  col << @fa_score_hash["students"][s.id][@subject.id.to_s]["SA2"]['mark']
                  if @fa_score_hash["students"][s.id][@subject.id.to_s]["SA2"]['mark'].present?
                    mark=@fa_score_hash["students"][s.id][@subject.id.to_s]["SA2"]['converted_mark'].to_f * @sa
                    mark=(mark.is_a?String) ? "-" : (mark/100).to_f.round(2)
                  else
                    mark = " "
                  end
                  col << mark
                  c2=0
                  fa_3_4_set=true
                end
              end
            else
              6.times do
                col << '-'
              end
            end
          end
        else
          6.times do
            col << '-'
          end
        end
        csv << col
      end
    end
    filename = "#{@batch.full_name}-#{params[:assessment_group]}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def generate_cbse_co_scholastic_report
    fetch_cbse_co_scholastic_data
    render(:update) do |page|
      page.replace_html 'hider', :text=>''
      page.replace_html 'report_table', :partial=>'cbse_co_scholastic_report'
    end
  end

  def generate_cbse_co_scholastic_report_csv
    fetch_cbse_co_scholastic_data
    csv_string=FasterCSV.generate do |csv|
      case @observation_group.observation_kind
      when "1"
        heads=[]
        heads << "SESSION"
        heads << "#{@batch.start_date.year}-#{@batch.end_date.year}"
        heads << "EXAM"
        heads <<  @batch.name
        heads << ""
        heads << ""
        csv << heads
        cols = []
        cols << "BORDER REG.NO"
        cols << "ROLL NO"
        cols << "NAME"
        @co_hash[:ob_list].each do |o|
          cols << "#{o[:code]} - #{o[:name].upcase}"
        end
        csv << cols
        @batch.students.find(:all, :order =>"#{Student.sort_order}").each do |s|
          cols = []
          cols << ""
          if Configuration.enabled_roll_number?
            cols << s.roll_number_in_context
          else
            cols << '-'
          end
          cols << s.full_name
          if @co_hash[s.id][:observations].present?
            @co_hash[s.id][:observations].sort{|a,b| a.last[:sort_order].to_i<=>b.last[:sort_order].to_i}.each do |o|
              cols << ((o.last[:grade].present?) ? o.last[:grade] : "-")
            end
          else
            @co_hash[:ob_list].each do |o|
              cols << "-"
            end
          end
          csv << cols
        end
      when "3"
        heads=[]
        heads << "SESSION"
        heads << "#{@batch.start_date.year}-#{@batch.end_date.year}"
        heads << "EXAM"
        heads <<  @batch.name
        heads << ""
        heads << ""
        csv << heads
        cols = []
        cols << "BORDER REG.NO"
        cols << "ROLL NO"
        cols << "NAME"
        @co_hash[:ob_list].length.times do
          cols << @observation_group.name
          cols << "Grade"
        end
        csv << cols
        @batch.students.find(:all, :order =>"#{Student.sort_order}").each do |s|
          cols = []
          cols << ""
          if Configuration.enabled_roll_number?
            cols << s.roll_number_in_context
          else
            cols << '-'
          end
          cols << s.full_name
          if @co_hash[s.id][:observations].present?
            @co_hash[s.id][:observations].sort{|a,b| a.last[:sort_order].to_i<=>b.last[:sort_order].to_i}.each do |o|
              cols << "#{o.last[:code]} - #{o.last[:name]}"
              cols << (o.last[:grade].present? ? o.last[:grade] : " ")
            end
          else
            @co_hash[:ob_list].each do |o|
              cols << "#{o[:code]} - #{o[:name]}"
              cols << "-"
            end
          end
          csv << cols
        end

      end
    end
    filename = "#{@batch.full_name}-#{params[:assessment_group]}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def list_batches
    unless params[:course_id].blank?
      course = Course.find(params[:course_id])
      get_respective_batches(course.id)
      case params[:type]
      when "cbse_scolastic_report"
        @action="list_exam_groups"
      when "cbse_co_scholatic_report"
        @action="list_observation_groups"
      when "asl"
        @action = "list_asl_groups"
      when "consolidated_report"
        @action = "update_assessment_groups"
      else
        @action=""
      end
    else
      @batches=[]
    end
    render(:update) do |page|
      page.replace_html 'batch_select', :partial=>'batch_list' unless params[:type]=="batch_student_report"
      page.replace_html 'batch_select', :partial=>'batch_select_list',:locals=>{:batches=>@batches, :batch_ids=>@batches.collect(&:id).uniq} if params[:type]=="batch_student_report"
    end
  end
  
  def update_assessment_groups
    if params[:batch_id].present?
      @assessment_groups_cat_1=['FA1','FA2','FA3','FA4','SA1','SA2']
      @assessment_groups_cat_2=['SA1+SA2','FA1+FA2+FA3+FA4']
      @assessment_groups_cat_3=['FA1+FA2+SA1',"FA3+FA4+SA2"]
    end
    render(:update) do |page|
      page.replace_html 'set_assessment_groups', :partial=>'assessment_list'
    end
  end

  def list_previous_batches
    unless params[:course_id].blank?
      @course = Course.find(params[:course_id])
      if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults")) or @current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
        @batches=@course.batches.inactive
      elsif @current_user.is_a_batch_tutor
        @batches=@current_user.employee_record.batches.all(:conditions=>{:is_deleted=>false,:is_active=>false,:courses=>{:id=>@course.id,:is_deleted=>false}},:joins=>:course)
      elsif @current_user.is_a_subject_teacher
        @batches=Batch.all(:joins=>[:course,{:subjects=>:employees}],:conditions=>{:is_deleted=>false,:is_active=>false,:courses=>{:id=>@course.id,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'batches.id',:order=>'batches.name ASC')
      else
        @batches=[]
      end
    else
      @batches=[]
    end
    render(:update) do |page|
      page.replace_html 'batch_select', :partial=>'inactive_batch_list'
    end
  end

  def list_asl_groups
    @asl_groups = ["ASL1","ASL2"]
    render(:update) do |page|
      page.replace_html 'exam_group_select', :partial=>'list_asl_groups'
    end
  end

  def list_exam_groups
    if params[:subject_id].present?
      subject=Subject.find params[:subject_id]
      @exam_groups=subject.exams.all(:select=>"exam_groups.*",:joins=>[:exam_group=>:cce_exam_category])
    elsif  params[:batch_id].present?
      batch=Batch.find params[:batch_id]
      @exam_groups=batch.exam_groups(:joins=>:cce_exam_category)
    else
      @exam_groups=[]
    end
    case params[:type]
    when "consolidated_report"
      @action = "set_assessment_group"
    when "cbse_scolastic_report"
      @action = "list_subjects"
    else
      @action = ""
    end
    render(:update) do |page|
      page.replace_html 'exam_group_select', :partial=>'list_exam_groups'
    end
  end

  def list_observation_groups
    if params[:batch_id].present?
      batch=Batch.find params[:batch_id]
      @observation_groups=batch.observation_groups.active
    else
      @observation_group=[]
      @observation_groups=[]
    end
    render(:update) do |page|
      page.replace_html 'observation_group_select', :partial=>'list_observation_groups'
    end
  end
  # for setting  assessment group
  def set_assessment_group
    unless params[:exam_group_id].blank?
      @assessment_groups=['FA1','FA2','FA3','FA4','SA1','SA2','SA1+SA2','FA1+FA2+FA3+FA4']
    else
      @assessment_groups=['FA1','FA2','FA3','FA4','SA1','SA2','SA1+SA2','FA1+FA2+FA3+FA4']
    end
  end

  def generated_report
    unless params[:assessment][:batch_id].blank?
      unless params[:assessment][:assessment_group].blank?
        @batch_id=params[:assessment][:batch_id]
        @student_category_id=params[:assessment][:student_category_id]
        @gender=params[:assessment][:gender]
        @assessment_group=params[:assessment][:assessment_group]
        @exam_group_id=params[:assessment][:exam_group_id]
        @config = Configuration.find_or_create_by_config_key('StudentSortMethod').config_value
        fetch_assessment_data
        render(:update) do |page|
          page.replace_html 'hider', :text=>''
          page.replace_html 'report_table', :partial=>'assessment_report'
        end
      else
        flash[:warn_notice]="Select an assessment group"
        error=true
      end
    else
      flash[:warn_notice]="Select a batch"
      error=true
    end
    if error
      render(:update) do |page|
        page.replace_html 'hider', :partial=>'error'
        page.replace_html 'report_table', :text=>''
      end
    end
  end

  def asl_report_csv
    @batch=Batch.find_by_id(params[:batch_id])
    @assessment=params[:asl_group_name]
    @subject=@batch.subjects.asl_subject.first
    fetch_asl_report
    csv_string=FasterCSV.generate do |csv|
      cols=[]
      cols << "SESSION"
      cols << "#{@batch.start_date.year} - #{@batch.end_date.year}"
      cols << " "
      cols << "EXAM"
      cols << "#{@batch.full_name}"
      cols << "SUBJECT"
      cols << "#{@subject.name}"
      csv << cols
      cols = []
      cols << " "
      cols << " "
      cols << " "
      if (@assessment == "ASL1")
        cols << "SA1 - MAX"
      else
        cols << "SA2 - MAX"
      end
      cols << "#{@fa_score_hash["asl_mark"]["score"]}"
      cols << " "
      cols << " "
      csv << cols
      cols = []
      cols << " "
      cols << " "
      cols << " "
      if (@assessment == "ASL1")
        cols << "SA1 - ASL"
      else
        cols << "SA2 - ASL"
      end
      cols << " "
      cols << " "
      cols << " "
      csv << cols
      cols = []
      cols << "BOARD REG.NO."
      if Configuration.enabled_roll_number?
        cols << "ROLLNO"
      end
      cols << "NAME"
      cols << "Obt."
      cols << "WT - #{(@fa_score_hash["asl_convert_mark"]["score"]).round(2)}%"
      cols << " "
      cols << " "
      csv << cols
      @students.each do |s|
        cols = []
        cols << " "
        if Configuration.enabled_roll_number?
          cols << s.roll_number_in_context
        end
        cols << s.full_name
        st=@fa_score_hash.find{|c,v| c==s.id}
        if st
          cols << (@fa_score_hash[s.id][@assessment]['obtained']).round(2)
          cols << (@fa_score_hash[s.id][@assessment]['convert']).round(2)
        else
          cols << " "
          cols << " "
        end
        cols << " "
        cols << " "
        cols << " "
        csv << cols
      end
    end
    filename = "#{@batch.full_name}-#{params[:assessment_group]}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def generated_report_csv
    @batch_id=params[:batch_id]
    @student_category_id=params[:student_category_id]
    @gender=params[:gender]
    @assessment_group=params[:assessment_group]
    @exam_group_id=params[:exam_group_id]
    @config = Configuration.find_or_create_by_config_key('StudentSortMethod').config_value
    fetch_assessment_data
    csv_string=FasterCSV.generate do |csv|
      cols=[]
      csv << "Consolidated Report"
      cols << 'Students'
      heads=[]
      @subjects.collect(&:name).each{|h| heads << h ; heads << ""}
      cols<< heads
      cols=cols.flatten
      csv << cols
      cols=[]
      cols << ""
      if @assessment_group=="ASL1" or @assessment_group=="ASL2" or @assessment_group=="ASLO"
        if @assessment_group=="ASL1"
          cols << "SA1"
        end
        if @assessment_group=="ASL2"
          cols << "SA2"
        end
        if @assessment_group=="ASLO"
          cols << "SA1"
          cols << ""
          cols << ""
          cols << "SA2"
        end
        csv << cols
        cols =[]
        cols << ""
        if @assessment_group=="ASL1" or @assessment_group=="ASL2" or @assessment_group=="ASLO"
          cols<< "Speaking Skills (20.0)"
          cols << "Listening Skills (20.0)"
          cols << "Marks Obtained (#{@fa_score_hash['asl_mark']['score']})"
          if @assessment_group=="ASLO"
            cols << "Speaking Skills (20.0)"
            cols << "Listening Skills (20.0)"
            cols << "Marks Obtained (#{@fa_score_hash['asl_mark']['score']})"
            cols << "Overall (Grade)"
          end
        end
      else
        @subjects.each{|s| cols<< "Grade" ; cols << "Mark(%)"}
      end
      csv << cols
      @students.each do |s|
        col=[]
        if @config == "admission_no" 
          student_text = "#{s.full_name} (#{s.admission_no})" 
        elsif @config == "roll_number" 
          if s.roll_number.present? 
            student_text = "#{s.full_name} (#{s.roll_number})"
          else
            student_text = "#{s.full_name} (-)" 
          end
        else
          if Configuration.enabled_roll_number? 
            if s.roll_number.present? 
              student_text = "#{s.full_name} (#{s.roll_number})"
            else
              student_text = "#{s.full_name} (-)" 
            end
          else
            student_text = "#{s.full_name} (#{s.admission_no})" 
          end
        end 
        col<< student_text
        st=@fa_score_hash.find{|c,v| c==s.id}
        if st
          if @assessment_group=="ASL1"
            col << @fa_score_hash[s.id]['ASL1']['speaking']
            col << @fa_score_hash[s.id]['ASL1']['listening']
            col << @fa_score_hash[s.id]['ASL1']['convert']
          elsif @assessment_group=="ASL2"
            col << @fa_score_hash[s.id]['ASL2']['speaking']
            col << @fa_score_hash[s.id]['ASL2']['listening']
            col << @fa_score_hash[s.id]['ASL2']['convert']
          elsif @assessment_group=="ASLO"
            col << @fa_score_hash[s.id]['ASL1']['speaking']
            col << @fa_score_hash[s.id]['ASL1']['listening']
            col << @fa_score_hash[s.id]['ASL1']['convert']
            col << @fa_score_hash[s.id]['ASL2']['speaking']
            col << @fa_score_hash[s.id]['ASL2']['listening']
            col << @fa_score_hash[s.id]['ASL2']['convert']
            if @fa_score_hash[s.id]['ASL2']['overall'].present?
              col << "#{@fa_score_hash[s.id]['ASL2']['overall']} (#{@fa_score_hash[s.id]['ASL2']['grade']})"
            else
              col << "#{@fa_score_hash[s.id]['ASL1']['overall']} (#{@fa_score_hash[s.id]['ASL1']['grade']})"
            end
          else
            @subjects.each do |sub|
              sc=@fa_score_hash[s.id][sub.id]
              if sc.present?
                col << @fa_score_hash[s.id][sub.id]['grade']
                col << @fa_score_hash[s.id][sub.id]['mark']
              else
                col << "-"
                col << "-"
              end
            end
          end
        else
          @subjects.each do |s|
            col << "-"
            col << "-"
            if @assessment_group=="ASL1" or @assessment_group=="ASL2" or @assessment_group=="ASLO"
              col << "-"
            end
            if @assessment_group=="ASLO"
              col << "-"
              col << "-"
              col << "-"
              col << "- (-)"
            end
          end
        end
        col=col.flatten
        csv<< col
      end
    end
    filename = "#{@batch.full_name}-#{params[:assessment_group]}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end
  
  def generated_detailed_fa_report_csv
    @batch= Batch.find params[:batch_id]
    @student_category_id=params[:student_category_id]
    @gender=params[:gender]
    @subject = Subject.find params[:subject_id]
    @assessment_group=params[:assessment_group]
    @exam_group_id=params[:exam_group_id]
    @fa_group = @subject.fa_groups.select{|s| s.name.split.last==@assessment_group}.first
    if @fa_group
      fetch_detailed_assessment_data
      calculate_overall_assessment_data(@subject,@fa_group,@batch)
    end
    csv_string=FasterCSV.generate do |csv|
      cols=[]
      csv << "Detailed FA Report"
      cols << 'Students'
      heads=[]
      @fa_criterias.each_with_index do |fa,i|
        indicators=fa.descriptive_indicators
        if indicators.present?
          heads << fa.fa_name
          (indicators.count + 1).times {heads << ""}
        end
      end
      cols<< heads
      cols=cols.flatten
      csv << cols
      cols=[]
      cols << ""
      @fa_criterias.each_with_index do |fa,i|
        indicators=fa.descriptive_indicators
        indicators.each do |indicator|
          cols << indicator.name
        end
        cols << "Total"
      end
      cols << "FA Total"
      cols << "Percentage"
      cols << "Grade"
      csv << cols
      @students.each do |s|
        col=[]
        student_text = "#{s.name_with_suffix})"
        col<< student_text
        @fa_criterias.each do |fa|
          indicators=fa.descriptive_indicators
          if indicators.present?
            indicators.each do |di|
              if @scores[s.id][di.id].present?
                col << @scores[s.id][di.id].first.grade_points
              else
                col << "-"
              end
            end
            if @report_data['criteria'][s.id].present?
              col << @report_data['criteria'][s.id]["criteria_total"][fa.id]
            else
              col << "-"
            end
          end
        end
        if @report_data['total'][s.id].present?
          col << @report_data['total'][s.id]['obtained_mark']
          col << @report_data['total'][s.id]['converted_mark']
          col << @report_data['total'][s.id]['grade']
        else
          col << "-"
          col << "-"
          col << "-"
        end
        csv << col
      end
    end
    filename = "#{@batch.full_name}-#{@subject.name}-#{params[:assessment_group]}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end
  
  def generated_report_pdf
    @batch_id=params[:batch_id]
    @student_category_id=params[:student_category_id]
    @gender=params[:gender]
    @assessment_group=params[:assessment_group]
    @exam_group_id=params[:exam_group_id]
    @config = Configuration.find_or_create_by_config_key('StudentSortMethod').config_value
    fetch_assessment_data
    render :pdf=>'generated_report_pdf',:orientation => 'Landscape',:margin=>{:left=>10,:right=>10}
  end

  def subject_wise_report
    @subjects=[]
    @student_category=StudentCategory.active
    @batches=[]
    get_respective_cce_courses
  end

  def subject_wise_batches
    unless params[:course_id].blank?
      course = Course.find(params[:course_id])
      get_respective_cce_batches(course.id)
    else
      @batches=[]
    end
    render(:update) do |page|
      if params[:type].present?
        page.replace_html 'batch_select', :partial=>'detailed_fa_batches' if params[:type]=='detailed_fa'
      else
        page.replace_html 'batch_select', :partial=>'subject_wise_batches'
      end
    end
  end

  def list_subjects
    if params[:exam_group_id].present?
      get_respective_subjects(params[:exam_group_id],'exam_group')
      @subjects = @subjects.map{|a| [a.name,a.id]}
    elsif params[:batch_id].present?
      batch = Batch.find params[:batch_id]
      subjects_without_exams = (batch.exam_groups.present? or params[:type].present?) ? batch.subjects.without_exams : []
      if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults")) or @current_user.privileges.include?(Privilege.find_by_name("ViewResults")) or @current_user.is_a_tutor_for_this_batch(batch)
        if params[:type].present?
          @subjects = subjects_without_exams.map{|a| [a.name,a.id]}
        else
          @subjects = subjects_without_exams.present? ? ([["All Subjects",'all']]+subjects_without_exams.map{|a| [a.name,a.id]}) : []
        end
      elsif @current_user.is_a_subject_teacher(batch.id)
        employee_subjects=(batch.exam_groups.present? or params[:type].present?) ? @current_user.employee_record.subjects.without_exams.all(:conditions=>{:batch_id=>batch.id}) : []
        if params[:type].present?
          @subjects = employee_subjects.map{|a| [a.name,a.id]}
        else
          @subjects = employee_subjects.present? ? ([["All Subjects",'all']]+employee_subjects.map{|a| [a.name,a.id]}) : []
        end 
      else
        @subjects=[]
      end
    end
    render(:update) do |page|
      page.replace_html 'subject_select', :partial=>'list_subjects'
    end
  end

  def subject_wise_generated_report
    unless params[:subject_report][:batch_id].blank?
      unless params[:subject_report][:subject_id].blank?
        @batch_id=params[:subject_report][:batch_id]
        @subject_id=params[:subject_report][:subject_id]
        @student_category_id=params[:subject_report][:student_category_id]
        @gender= params[:subject_report][:gender]
        @type = params[:subject_report][:report_type]
        @config = Configuration.find_or_create_by_config_key('StudentSortMethod').config_value
        fetch_subject_wise_report
        render(:update) do |page|
          page.replace_html 'hider', :text=>''
          page.replace_html 'report_table', :partial=>'subject_wise_generated_report'
        end
      else
        error=true
        flash[:warn_notice]="Select a subject"
      end
    else
      error=true
      flash[:warn_notice]="Select a batch"
    end
    if error
      render(:update) do |page|
        page.replace_html 'hider', :partial=>'error'
        page.replace_html 'report_table', :text=>''
      end
    end
  end

  def subject_wise_generated_report_csv
    @batch_id=params[:subject_report][:batch_id]
    @subject_id=params[:subject_report][:subject_id]
    @student_category_id=params[:subject_report][:student_category_id]
    @gender= params[:subject_report][:gender]
    @type = params[:subject_report][:report_type]
    @config = Configuration.find_or_create_by_config_key('StudentSortMethod').config_value
    fetch_subject_wise_report
    csv_string=FasterCSV.generate do |csv|
      cols = []
      cols << ""
      @subjects.each do |subject|
        cols << subject.name
        (@type == "m" ? 5 : 6).times do
          cols << ''
        end
      end
      csv << cols
      cols = ['Student']
      @subjects.count.times do
        cols += ['FA1','FA2','SA1','FA3','FA4','SA2']
        if @type == "w"
          cols << "Total"
        end
      end
      csv << cols
      cols = []
      cols << ""
      @subjects.each do |subject|
        if @type == "m"
          cols << (@score_hash['fa_marks'][subject.id]['FA1']['total_mark'] || "-")
          cols << (@score_hash['fa_marks'][subject.id]['FA2']['total_mark'] || "-")
          cols << (@score_hash['sa_marks'][subject.id]['SA1']['total_mark'] || "-")
          cols << (@score_hash['fa_marks'][subject.id]['FA3']['total_mark'] || "-")
          cols << (@score_hash['fa_marks'][subject.id]['FA4']['total_mark'] || "-")
          cols << (@score_hash['sa_marks'][subject.id]['SA2']['total_mark'] || "-")
        else
          cols << (@score_hash['fa_marks'][subject.id]['FA1']['weightage'] || "-")
          cols << (@score_hash['fa_marks'][subject.id]['FA2']['weightage'] || "-")
          cols << (@score_hash['sa_marks'][subject.id]['SA1']['weightage'] || "-")
          cols << (@score_hash['fa_marks'][subject.id]['FA3']['weightage'] || "-")
          cols << (@score_hash['fa_marks'][subject.id]['FA4']['weightage'] || "-")
          cols << (@score_hash['sa_marks'][subject.id]['SA2']['weightage'] || "-")
          fa_total = @score_hash['fa_marks'][subject.id]['sum_total']
          sa_total = @score_hash['sa_marks'][subject.id]['sum_total']
          cols << (fa_total+sa_total == 0 ? "-" : (fa_total+sa_total))
        end
      end
      csv << cols
      @students.each do |s|
        col=[]
        if @config == "admission_no" 
          student_text = "#{s.full_name} (#{s.admission_no})" 
        elsif @config == "roll_number" 
          if s.roll_number.present? 
            student_text = "#{s.full_name} (#{s.roll_number})"
          else
            student_text = "#{s.full_name} (-)" 
          end
        else
          if Configuration.enabled_roll_number? 
            if s.roll_number.present? 
              student_text = "#{s.full_name} (#{s.roll_number})"
            else
              student_text = "#{s.full_name} (-)" 
            end
          else
            student_text = "#{s.full_name} (#{s.admission_no})" 
          end
        end 
        col<< student_text
        @subjects.each do |subject|
          if @type == "m"
            unless @score_hash['fa_marks'][subject.id][s.id]['FA1'].present?
              col << "-(-)"
            else
              col << "#{@score_hash['fa_marks'][subject.id][s.id]['FA1']['mark']} (#{@score_hash['fa_marks'][subject.id][s.id]['FA1']['grade']})"
            end
            unless @score_hash['fa_marks'][subject.id][s.id]['FA2'].present?
              col << "-(-)"
            else
              col << "#{@score_hash['fa_marks'][subject.id][s.id]['FA2']['mark']} (#{@score_hash['fa_marks'][subject.id][s.id]['FA2']['grade']})"
            end
            unless @score_hash['sa_marks'][subject.id][s.id]['SA1'].present?
              col << "-(-)"
            else
              col << "#{@score_hash['sa_marks'][subject.id][s.id]['SA1']['mark']} (#{@score_hash['sa_marks'][subject.id][s.id]['SA1']['grade']})"
            end
            unless @score_hash['fa_marks'][subject.id][s.id]['FA3'].present?
              col << "-(-)"
            else
              col << "#{@score_hash['fa_marks'][subject.id][s.id]['FA3']['mark']} (#{@score_hash['fa_marks'][subject.id][s.id]['FA3']['grade']})"
            end
            unless @score_hash['fa_marks'][subject.id][s.id]['FA4'].present?
              col << "-(-)"
            else
              col << "#{@score_hash['fa_marks'][subject.id][s.id]['FA4']['mark']} (#{@score_hash['fa_marks'][subject.id][s.id]['FA4']['grade']})"
            end
            unless @score_hash['sa_marks'][subject.id][s.id]['SA2'].present?
              col << "-(-)"
            else
              col << "#{@score_hash['sa_marks'][subject.id][s.id]['SA2']['mark']} (#{@score_hash['sa_marks'][subject.id][s.id]['SA2']['grade']})"
            end
          else
            unless @score_hash['fa_marks'][subject.id][s.id]['FA1'].present?
              col << "-(-)"
            else
              col << "#{@score_hash['fa_marks'][subject.id][s.id]['FA1']['weighted_mark']} (#{@score_hash['fa_marks'][subject.id][s.id]['FA1']['grade']})"
            end
            unless @score_hash['fa_marks'][subject.id][s.id]['FA2'].present?
              col << "-(-)"
            else
              col << "#{@score_hash['fa_marks'][subject.id][s.id]['FA2']['weighted_mark']} (#{@score_hash['fa_marks'][subject.id][s.id]['FA2']['grade']})"
            end
            unless @score_hash['sa_marks'][subject.id][s.id]['SA1'].present?
              col << "-(-)"
            else
              col << "#{@score_hash['sa_marks'][subject.id][s.id]['SA1']['weighted_mark']} (#{@score_hash['sa_marks'][subject.id][s.id]['SA1']['grade']})"
            end
            unless @score_hash['fa_marks'][subject.id][s.id]['FA3'].present?
              col << "-(-)"
            else
              col << "#{@score_hash['fa_marks'][subject.id][s.id]['FA3']['weighted_mark']} (#{@score_hash['fa_marks'][subject.id][s.id]['FA3']['grade']})"
            end
            unless @score_hash['fa_marks'][subject.id][s.id]['FA4'].present?
              col << "-(-)"
            else
              col << "#{@score_hash['fa_marks'][subject.id][s.id]['FA4']['weighted_mark']} (#{@score_hash['fa_marks'][subject.id][s.id]['FA4']['grade']})"
            end
            unless @score_hash['sa_marks'][subject.id][s.id]['SA2'].present?
              col << "-(-)"
            else
              col << "#{@score_hash['sa_marks'][subject.id][s.id]['SA2']['weighted_mark']} (#{@score_hash['sa_marks'][subject.id][s.id]['SA2']['grade']})"
            end
            fa_total = @score_hash['fa_marks'][subject.id][s.id]['sum_total']
            sa_total = @score_hash['sa_marks'][subject.id][s.id]['sum_total']
            col << ((fa_total.present? and sa_total.present?) ? (fa_total + sa_total) : '-')
          end
        end
        col = col.flatten
        csv<< col
      end
    end
    filename = "#{@batch.full_name}-#{(@subject_id == "all" ? "All Subjects" : @subjects[0].name)}-#{Time.now.to_date.to_s}.csv"
    send_data(csv_string, :type => 'text/csv; charset=utf-8; header=present', :filename => filename)
  end

  def subject_wise_generated_report_pdf    
    @batch_id=params[:subject_report][:batch_id]
    @subject_id=params[:subject_report][:subject_id]
    @student_category_id=params[:subject_report][:student_category_id]
    @gender= params[:subject_report][:gender]
    @type = params[:subject_report][:report_type]
    @config = Configuration.find_or_create_by_config_key('StudentSortMethod').config_value
    fetch_subject_wise_report
    render :pdf=>'generated_report_pdf',:margin=>{:left=>10,:right=>10,:top=>8,:bottom=>8},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
  end

  def previous_batch_exam_reports
    @batches=[]
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))  or @current_user.privileges.include?(Privilege.find_by_name("ViewResults"))
      @courses=Course.cce.has_inactive_batches.uniq
    elsif @current_user.is_a_batch_tutor
      @courses=Course.all(:joins=>{:batches=>:employees},:conditions=>{:grading_type=>"3",:is_deleted=>false,:batches=>{:is_active=>false,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
    elsif @current_user.is_a_subject_teacher
      @courses=Course.all(:joins=>{:batches=>{:subjects=>:employees}},:conditions=>{:grading_type=>"3",:is_deleted=>false,:batches=>{:is_active=>false,:is_deleted=>false},:employees=>{:id=>@current_user.employee_record.id}},:group=>'courses.id',:order=>'courses.course_name ASC')
    else
      @courses=[]
    end
  end

  def generate_previous_batch_exam_reports
    unless params[:batch_id].blank?
      @batch=Batch.find(params[:batch_id])
      @course = @batch.course
      @eiop_eligibily_grade=CceReportSettingCopy.setting_result_as_hash(@batch,'grade')
      @pass_text=CceReportSettingCopy.setting_result_as_hash(@batch,'pass_text')
      @eiop_text=CceReportSettingCopy.setting_result_as_hash(@batch,'eiop_text')
      @grading_levels = @batch.grading_level_list
      @cce_categories=@batch.cce_exam_category
      @cat_id=params[:cat_id].to_i if params[:cat_id].present?
      @fa_group=params[:fa_group] if params[:fa_group].present?
      @check_term="all"
      @fa_group_names = []
      if params[:cat_id].present? and @cat_id!=0
        first_cce_exam_category_id=@batch.fetch_first_cce_exam_category
        if first_cce_exam_category_id==@cat_id
          @check_term="first_term"
        else
          @check_term="second_term"
        end
        @batch.exam_groups.first(:conditions=>{:cce_exam_category_id=>@cat_id}).exams.each do |e|
          e.subject.fa_groups.all(:conditions=>{:cce_exam_category_id=>@cat_id}).collect{|f| @fa_group_names << f.name.split(' ').last unless @fa_group_names.include?(f.name.split(' ').last)}
        end
        @fa_group_names.sort!
      end
      @config = Configuration.find_or_create_by_config_key('StudentSortMethod').config_value
      @students=BatchStudent.find_by_sql("select s.id sid,CONCAT_WS('',s.first_name,' ',s.last_name) full_name,s.admission_no,s.first_name,s.last_name,bs.roll_number roll_number from students s inner join batch_students bs on bs.student_id=s.id where bs.batch_id=#{@batch.id} UNION ALL select ars.former_id sid,CONCAT_WS('',ars.first_name,' ',ars.last_name) full_name,ars.admission_no,ars.first_name,ars.last_name,ars.roll_number roll_number from archived_students ars where ars.batch_id=#{@batch.id} UNION ALL select ars1.former_id sid,CONCAT_WS('',ars1.first_name,' ',ars1.last_name) full_name,ars1.admission_no,ars1.first_name,ars1.last_name,bs.roll_number roll_number from archived_students ars1 inner join batch_students bs on bs.student_id=ars1.former_id where bs.batch_id=#{@batch.id}  order by #{Student.sort_order}")
      if @students.present?
        unless params[:student_id].present?
          @student = Student.find_by_id(@students.first.sid)
          @type = "regular"
          if @student.nil?
            @student=ArchivedStudent.find_by_former_id(@students.first.sid)
            @type="former"
          end
          @student.roll_number = @students.first.roll_number
        else
          b_student = @students.find_by_sid(params[:student_id])
          @student=Student.find_by_id(params[:student_id])
          @type = "regular"
          if @student.nil?
            @student=ArchivedStudent.find_by_former_id(params[:student_id])
            @type="former"
          end
          @student.roll_number = b_student.roll_number
        end
      else
        @students=[]
      end
      if @student and !params[:fa_group].present?
        @student.batch_in_context_id = @batch.id
        fetch_report
      elsif @student and params[:fa_group].present?
        @student.batch_in_context_id = @batch.id
        fetch_fa_report   
      end
      unless @check_term=="all" or params[:fa_group].present?
        @exam_groups=@exam_groups.find_all_by_cce_exam_category_id(@cat_id)
      end
      render(:update) do |page|
        page.replace_html  'list_cce_category', :partial=>"list_previous_cce_exam_cataegory", :object=>[@cce_categories,@batch,@student,@cat_id]
        page.replace_html  'fa_groups_list', :partial=>"previous_fa_groups_list" if params[:cat_id].present? and @cat_id!=0 and !params[:fa_group].present?
        page.replace_html  'fa_groups_list', :text=>"" unless params[:cat_id].present?
        page.replace_html   'student_list', :partial=>"graduated_student_list", :object=>[@batch,@students,@cat_id,@fa_group]
        if @student.nil? 
          page.replace_html   'report', :text=>""
        elsif @student.present? and !params[:fa_group].present?
          page.replace_html   'report', :partial=>"student_report"
        elsif @student.present? and params[:fa_group].present?
          page.replace_html   'report', :partial=>"student_fa_report"
        end
        page.replace_html   'hider', :text=>""
      end
    else
      render(:update) do |page|
        page.replace_html  'list_cce_category', :text=>""
        page.replace_html   'student_list', :text=>""
        page.replace_html   'report', :text=>""
        page.replace_html   'hider', :text=>""
      end
    end
  end

  private
  
  def students
    if @subject.students.empty? or @subject_id == "all"
      @students=Student.search(:batch_id_equals=>@batch_id,:gender_like=>@gender,:student_category_id_equals=>@student_category_id).all(:order=>"#{Student.sort_order}")
    else
      @students= Student.send :with_scope,:find=>{:conditions=>{:students_subjects=>{:subject_id=>@subject.id}} ,:joins=>"INNER JOIN `students_subjects` ON `students`.id = `students_subjects`.student_id"} do Student.search(:batch_id_equals=>@batch_id,:gender_like=>@gender,:student_category_id_equals=>@student_category_id).all(:order=>"#{Student.sort_order}") end
    end
  end

  def fetch_attendance_data
    attendance_lock = AttendanceSetting.is_attendance_lock
    @attendance_hash={}
    setting=CceReportSettingCopy.setting_result_as_hash(@batch,'Attendance')
    if setting["Attendance"] == "0"
      config=Configuration.find_by_config_key('StudentAttendanceType')
      @exam_groups.each_with_index do |eg,i|
        unless config.config_value == 'Daily'
          i==0? month_date = @batch.start_date.to_date : month_date=(@exam_groups[i-1].exams.first(:order=>"end_time DESC").end_time.to_date+1).to_date
          i==0? end_date = (eg.exams.first(:order=>"start_time ASC").start_time).to_date : end_date = (@exam_groups[i].exams.first(:order=>"start_time ASC").start_time).to_date
          student_admission_date = Student.find_by_id(@student.id_in_context).admission_date
          month_date = Attendance.student_working_day(student_admission_date,month_date)
          unless attendance_lock
            academic_days=@batch.subject_hours(month_date, end_date, 0).values.flatten.compact.count
            student_attendance= SubjectLeave.fetch_attendance_data(@student,@batch,academic_days,month_date,end_date)
            @attendance_hash[eg.id]={"percent"=>student_attendance.percent,"leaves"=>student_attendance.leaves.to_f,"academic_days"=>academic_days.to_f}
          else
            academic_days = MarkedAttendanceRecord.subject_wise_working_days(@batch).select{|v| v <= end_date and  v >= month_date}
            @attendance_hash[eg.id] = SubjectLeave.fetch_save_attendance_data(@student.id,@batch,academic_days)
          end
        else
          i==0? month_date = @batch.start_date.to_date : month_date=(@exam_groups[i-1].exams.first(:order=>"end_time DESC").end_time.to_date+1).to_date
          i==0? end_date = (eg.exams.first(:order=>"start_time ASC").start_time).to_date : end_date = (@exam_groups[i].exams.first(:order=>"start_time ASC").start_time).to_date
          student_admission_date = Student.find_by_id(@student.id_in_context).admission_date
          month_date = Attendance.student_working_day(student_admission_date,month_date)
          unless attendance_lock
            working_days=@batch.date_range_working_days(month_date,end_date)
            academic_days = working_days.select{|v| v<=end_date}.count
            student_attendance = Attendance.dailywise_attendance_data(@student,@batch.id,month_date,end_date,academic_days)
            @attendance_hash[eg.id] = {"percent"=>student_attendance.percent,"leaves"=>student_attendance.leaves.to_f,"academic_days"=>academic_days.to_f}
          else
            working_days = MarkedAttendanceRecord.dailywise_working_days(@batch.id).select{|v| v <= end_date and  v >= month_date}
            academic_days = working_days.select{|v| v<=end_date}
            @attendance_hash[eg.id] = Attendance.dailywise_save_attendance_data(@student,@batch.id,academic_days)
          end
          
        end
      end
    end
    return @attendance_hash
  end
  
  def fetch_fa_report
    @get_result = true
    @student_fa_scores_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @student.cce_reports.scholastic.all(:select=>'cce_reports.*,subjects.name subject_name,subjects.no_exams no_exams,fa_groups.name fa_group_name',:joins=>[:subject,:fa_group],:conditions=>["cce_reports.batch_id = ? and fa_groups.name like ? and no_exams = ?",@batch.id,"%#{@fa_group}",false]).group_by(&:subject_name).each do |subject_name,score|
      if @current_user.student? or @current_user.parent?
        eg = score[0].batch.exam_groups.first(:conditions=>{:cce_exam_category_id=>score[0].cce_exam_category_id})
        fa_group = score[0].fa_group.name.split(' ').last
        unless ExamGroupFaStatus.find_by_exam_group_id_and_fa_group(eg,fa_group).present?
          @get_result = false
        end
      end
      @student_fa_scores_hash[subject_name] = {:obtained_mark=>score[0].obtained_mark,:max_mark=>score[0].max_mark,:grade=>score[0].grade_string} if @get_result
    end 
    @subjects=@student.all_subjects
    @all_student_fa_scores_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    CceReport.scholastic.all(:select=>'cce_reports.*,subjects.name subject_name,subjects.no_exams no_exams,fa_groups.name fa_group_name',:joins=>[:subject,:fa_group],:conditions=>["cce_reports.batch_id = ? and fa_groups.name like ? and no_exams = ?",@batch.id,"%#{@fa_group}",false]).group_by(&:subject_name).each do |subject_name,student_entries|
      student_entries.group_by(&:student_id).each do |student_id,score|
        if @current_user.student? or @current_user.parent?
          eg = score[0].batch.exam_groups.first(:conditions=>{:cce_exam_category_id=>score[0].cce_exam_category_id})
          fa_group = score[0].fa_group.name.split(' ').last
          unless ExamGroupFaStatus.find_by_exam_group_id_and_fa_group(eg,fa_group).present?
            @get_result = false
          end
        end
        @all_student_fa_scores_hash[subject_name][student_id] = {:obtained_mark=>score[0].obtained_mark,:max_mark=>score[0].max_mark,:grade=>score[0].grade_string} if @get_result
      end
    end 
    @data = []
    @data2 = []
    @subjects_list = []
    @subjects.each_with_index do |sub,i|
      @subjects_list << sub.code
      total_score =0
      count = 0
      if @all_student_fa_scores_hash[sub.name].present? and @all_student_fa_scores_hash[sub.name][@student.id].present?
        @data << [i,(@all_student_fa_scores_hash[sub.name][@student.id][:obtained_mark]/@all_student_fa_scores_hash[sub.name][@student.id][:max_mark])*100]
      else
        @data << [i,0]
      end
      if @all_student_fa_scores_hash[sub.name].present?
        @all_student_fa_scores_hash[sub.name].each do |key,value|
          if value.present?
            total_score += (value[:obtained_mark]/value[:max_mark])*100
            count+=1
          end
        end
      end
      @data2 << [i,(count != 0 ? (total_score/count) : 0)]
    end
  end

  def fetch_report
    @report=@student.individual_cce_report_cached
    @subjects=@student.all_subjects
    #    @exam_groups=ExamGroup.find_all_by_id(@report.exam_group_ids, :include=>:cce_exam_category)
    @exam_groups=@batch.exam_groups.all(:include=>:cce_exam_category)
    coscholastic=@report.coscholastic
    @observation_group_ids=coscholastic.collect(&:observation_group_id)
    @observation_groups=ObservationGroup.find_all_by_id(@observation_group_ids,:order=>"sort_order asc").collect(&:name)
    @co_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @obs_groups=@batch.observation_groups.all(:order=>"sort_order asc").to_a
    @og=@obs_groups.group_by(&:observation_kind)
    @co_hashi = {}
    @og.each do |kind, ogs|
      @co_hashi[kind]=[]
      coscholastic.each{|cs| @co_hashi[kind] << cs if ogs.collect(&:id).include? cs.observation_group_id}
    end
  end



  def fetch_assessment_data
    case @assessment_group
    when "FA1","FA2","FA3","FA4","SA1","SA2","ASL1","ASL2"
      calculate_assessment_data(@assessment_group)
    when "ASLO"
      total_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      total_hash=calculate_assessment_data("ASL1")
      unless total_hash.blank?
        asl2_hash=calculate_assessment_data("ASL2")
        unless asl2_hash.blank?
          total_hash.merge!(asl2_hash){|k,a_value,b_value| a_value.merge!(b_value)}
          @fa_score_hash=total_hash
        else
          @fa_score_hash={}
        end
      else
        @fa_score_hash={}
      end
      @fa_score_hash

    when "FA1+FA2+SA1"
      total_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      status_blank = false
      temp_hash_1 = calculate_assessment_data('FA1')
      status_blank = true unless temp_hash_1.present?
      total_hash.merge!(temp_hash_1)
      fa2_hash=calculate_assessment_data('FA2')
      status_blank = true unless fa2_hash.present?
      fa2_hash.each{|k,v| v.reject!{|k1,v1| !total_hash[k].keys.include? k1}}
      total_hash.each{|k,v| v.reject!{|k1,v1| !fa2_hash[k].keys.include? k1}}
      total_hash.merge!(fa2_hash){ |k, a_value, b_value| a_value.merge!(b_value){|k1, a1, b1| {"mark" => (a1["mark"].to_f * a1["wightage"]/100).to_f + ((b1["mark"].to_f * b1["wightage"].to_f)/100).to_f} } }
      sa1_hash=calculate_assessment_data('SA1')
      status_blank = true unless sa1_hash.present?
      sa1_hash.each{|k,v| v.reject!{|k1,v1| !total_hash[k].keys.include? k1}}
      sa1_hash.each{|k,v| v.reject!{|k1,v1| v1['mark'] == '-'}}
      total_hash.each{|k,v| v.reject!{|k1,v1| !sa1_hash[k].keys.include? k1}}
      total_hash.merge!(sa1_hash){ |k, a_value, b_value| a_value.merge!(b_value){|k1, a1, b1| {"mark" => (a1["mark"].to_f + (b1["mark"].to_f * b1["wightage"].to_f)/100).to_f}}}
      total_hash.each{|k,v| v.each{|k1,v1| v1['mark']=(((v1['mark'].to_f)*2)).round(2);v1['grade']=GradingLevel.percentage_to_grade(v1['mark'].to_f, @batch_id).present? ? GradingLevel.percentage_to_grade(v1['mark'].to_f, @batch_id) : '-'}}
      @fa_score_hash = status_blank ? {} : total_hash
    when "FA3+FA4+SA2"
      total_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      status_blank = false
      temp_hash_3 = calculate_assessment_data('FA3')
      status_blank = true unless temp_hash_3.present?
      total_hash.merge!(temp_hash_3)
      fa4_hash=calculate_assessment_data('FA4')
      status_blank = true unless fa4_hash.present?
      fa4_hash.each{|k,v| v.reject!{|k1,v1| !total_hash[k].keys.include? k1}}
      total_hash.each{|k,v| v.reject!{|k1,v1| !fa4_hash[k].keys.include? k1}}
      total_hash.merge!(fa4_hash){ |k, a_value, b_value| a_value.merge!(b_value){|k1, a1, b1| {"mark" => (a1["mark"].to_f * a1["wightage"]/100).to_f + ((b1["mark"].to_f * b1["wightage"])/100).to_f} } }
      sa2_hash=calculate_assessment_data('SA2')
      status_blank = true unless sa2_hash.present?
      sa2_hash.each{|k,v| v.reject!{|k1,v1| !total_hash[k].keys.include? k1}}
      sa2_hash.each{|k,v| v.reject!{|k1,v1| v1['mark'] == '-'}}
      total_hash.each{|k,v| v.reject!{|k1,v1| !sa2_hash[k].keys.include? k1}}
      total_hash.merge!(sa2_hash){ |k, a_value, b_value| a_value.merge!(b_value){|k1, a1, b1| {"mark" => (a1["mark"].to_f + (b1["mark"].to_f * b1["wightage"])/100).to_f}}}
      total_hash.each{|k,v| v.each{|k1,v1| v1['mark']=(((v1['mark'].to_f)*2)).round(2);v1['grade']=GradingLevel.percentage_to_grade(v1['mark'].to_f, @batch_id).present? ? GradingLevel.percentage_to_grade(v1['mark'].to_f, @batch_id) : '-'}}
      @fa_score_hash = status_blank ? {} : total_hash
    when "FA1+FA2+FA3+FA4"
      total_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      status_blank = false
      temp_hash_1 = calculate_assessment_data('FA1')
      status_blank = true unless temp_hash_1.present?
      total_hash.merge!(temp_hash_1)
      fa2_hash=calculate_assessment_data('FA2')
      status_blank = true unless fa2_hash.present?
      fa2_hash.each{|k,v| v.reject!{|k1,v1| !total_hash[k].keys.include? k1}}
      total_hash.each{|k,v| v.reject!{|k1,v1| !fa2_hash[k].keys.include? k1}}
      total_hash.merge!(fa2_hash){ |k, a_value, b_value| a_value.merge!(b_value){|k1, a1, b1| {"mark" => a1["mark"].to_f + b1["mark"].to_f,"grade" => a1["grade"]+b1["grade"]}}}
      fa3_hash=calculate_assessment_data('FA3')
      status_blank = true unless fa3_hash.present?
      fa3_hash.each{|k,v| v.reject!{|k1,v1| !total_hash[k].keys.include? k1}}
      total_hash.each{|k,v| v.reject!{|k1,v1| !fa3_hash[k].keys.include? k1}}
      total_hash.merge!(fa3_hash){ |k, a_value, b_value| a_value.merge!(b_value){|k1, a1, b1| {"mark" => a1["mark"].to_f + b1["mark"].to_f,"grade" => a1["grade"]+b1["grade"]}}}
      fa4_hash=calculate_assessment_data('FA4')
      status_blank = true unless fa4_hash.present?
      fa4_hash.each{|k,v| v.reject!{|k1,v1| !total_hash[k].keys.include? k1}}
      total_hash.each{|k,v| v.reject!{|k1,v1| !fa4_hash[k].keys.include? k1}}
      total_hash.merge!(fa4_hash){ |k, a_value, b_value| a_value.merge!(b_value){|k1, a1, b1| {"mark" => a1["mark"].to_f + b1["mark"].to_f,"grade" => a1["grade"]+b1["grade"]}}}
      total_hash.each{|k,v| v.each{|k1,v1| v1['mark']=(((v1['mark'].to_f)*100)/400).round(2);v1['grade']=GradingLevel.percentage_to_grade(v1['mark'], @batch_id).present? ? GradingLevel.percentage_to_grade(v1['mark'], @batch_id) : '-'}}
      @fa_score_hash = status_blank ? {} : total_hash
    when "SA1+SA2"
      total_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      status_blank = false
      temp_hash_1 = calculate_assessment_data('SA1')
      status_blank = true unless temp_hash_1.present?
      total_hash.merge!(temp_hash_1)
      sa2_hash=calculate_assessment_data('SA2')
      status_blank = true unless sa2_hash.present?
      sa2_hash.each{|k,v| v.reject!{|k1,v1| !total_hash[k].keys.include? k1}}
      sa2_hash.each{|k,v| v.reject!{|k1,v1| v1['mark'] == '-'}}
      total_hash.each{|k,v| v.reject!{|k1,v1| !sa2_hash[k].keys.include? k1}}
      total_hash.merge!(sa2_hash){ |k, a_value, b_value| a_value.merge!(b_value){|k1, a1, b1| {"mark" => a1["mark"].to_f + b1["mark"].to_f,"grade" => a1["grade"]+b1["grade"]}}}
      total_hash.each{|k,v| v.each{|k1,v1| v1['mark']=(((v1['mark'].to_f)*100)/200).round(2);v1['grade']=GradingLevel.percentage_to_grade(v1['mark'], @batch_id).present? ? GradingLevel.percentage_to_grade(v1['mark'], @batch_id) : '-'}}
      total_hash.each{|k,v| v.each{|k1,v1| v1["mark"] = (v1["mark"].to_f * v1["wightage"]/100).to_f if v1.has_key?("wightage")}}
      @fa_score_hash = status_blank ? {} : total_hash
    else
      return {}
    end
  end
  
  def fetch_detailed_assessment_data
    @fa_criterias=@fa_group.fa_criterias.active.all(:joins=>:descriptive_indicators,:include=>:descriptive_indicators,:group=>'fa_criterias.id')
    @students=Student.search(:batch_id_equals=>@batch.id,:gender_like=>@gender,:student_category_id_equals=>@student_category_id).all(:order=>"#{Student.sort_order}")
    di=@fa_criterias.collect(&:descriptive_indicator_ids).flatten
    @scores=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    scores=AssessmentScore.find(:all,:conditions=>{:batch_id=>@batch.id,:descriptive_indicator_id=>di, :subject_id=>@subject.id}).group_by(&:student_id)
    scores.each do |k,v|
      @scores[k]=v.group_by{|g| g.descriptive_indicator_id}
    end
  end
  
  def calculate_overall_assessment_data(subject,fg,batch)
    report_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @report_data=Hash.new { |l, m| l[m] = Hash.new(&l.default_proc) }
    report_hash["config"][fg.id]["fg_max_marks"] = fg.max_marks
    if fg.criteria_formula.present?
      formula = fg.criteria_formula
    else
      if fg.fa_criterias.active.count > 1
        formula = "avg(#{fg.fa_criterias.active.collect(&:formula_key).join(',')},@#{fg.max_marks.to_i})"
      elsif fg.fa_criterias.active.count == 1
        formula = "#{fg.fa_criterias.active.first.formula_key}"
      end
    end
    report_hash["config"][fg.id]["fg_formula"] = formula
    fg.fa_criterias.active.all(:include=>:assessment_scores).each do |f|
      report_hash["config"][fg.id][f.id]["fa_max_marks"] = f.max_marks
      report_hash["config"][fg.id][f.id]["indicator"] = f.formula_key
      f.assessment_scores.scoped(:conditions=>["cce_exam_category_id IS NOT NULL AND batch_id = ? and subject_id=?",batch.id,subject.id]).group_by(&:student_id).each do |k1,v1|
        v1.group_by(&:cce_exam_category_id).each do |k2,v2|
          v2.group_by(&:subject_id).each do |k3,v3|
            report_hash["students"][k1][k2][k3][fg.id][f.id] = (fg.di_formula == 1 ? (((v3.sum(&:grade_points)/v3.count))).to_f : ((v3.sum(&:grade_points)).to_f))
            @report_data['criteria'][k1]["criteria_total"][f.id] = report_hash["students"][k1][k2][k3][fg.id][f.id].to_f.round(2)
          end
        end
      end
    end
    config_value=Configuration.find_by_config_key("CceFaType").try(:config_value) || "1"
    report_hash["students"].each do |k,v|
      v.each do |ke,va|
        va.each do |k1,v1|
          v1.each do |k2,v2|
            fa_obtained_score_hash={}
            fa_max_score_hash={}
            if config_value=="1"
              v2.each do |k3,v3|
                hsh1={report_hash["config"][k2][k3]["indicator"]=>(v3.to_f)}
                fa_obtained_score_hash.merge!hsh1
              end
            else
              v2.each do |k3,v3|
                hsh1={report_hash["config"][k2][k3]["indicator"]=>(v3.to_f/report_hash["config"][k2][k3]["fa_max_marks"].to_f)}
                fa_obtained_score_hash.merge!hsh1
              end
            end
            if config_value == "1"
              v2.each do |k3,v3|
                hsh2={report_hash["config"][k2][k3]["indicator"]=>(report_hash["config"][k2][k3]["fa_max_marks"].to_f)}
                fa_max_score_hash.merge!hsh2
              end
            else
              v2.each do |k3,v3|
                hsh2={report_hash["config"][k2][k3]["indicator"]=>1}
                fa_max_score_hash.merge!hsh2
              end
            end
            config = config_value == "1" ? :tmm : :cdm
            if (ExamFormula::formula_validate(report_hash["config"][k2]["fg_formula"], config_value) == true)
              equation = ExamFormula.new(report_hash["config"][k2]["fg_formula"],:obtained_marks=>fa_obtained_score_hash,:max_marks=>fa_max_score_hash,:mode=>config)
              if equation.valid?
                result = equation.calculate
                converted_mark=result.into(100)
                obtained_mark=result.into(report_hash["config"][k2]["fg_max_marks"].to_f)
                grade_string=batch.to_grade(converted_mark)
              else
                converted_mark=obtained_mark=0.0
                grade_string=batch.to_grade(converted_mark)
              end
            else
              converted_mark=0.0
              obtained_mark=0.0
              grade_string=batch.to_grade(converted_mark)
            end
            @report_data['total'][k]['grade'] = grade_string
            @report_data['total'][k]['obtained_mark'] = obtained_mark.to_f.round(2)
            @report_data['total'][k]['converted_mark'] = converted_mark.to_f.round(2)
            @report_data['total'][k]['max_mark'] = report_hash["config"][k2]["fg_max_marks"].to_f.round(2)
          end
        end
      end
    end
  end
  
  def calculate_assessment_data(assessment_group)
    @fa_score_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @batch=Batch.find @batch_id
    fa_groups=['FA1','FA2','FA3','FA4']
    @students=Student.search(:batch_id_equals=>@batch_id,:gender_like=>@gender,:student_category_id_equals=>@student_category_id).all(:order=>"#{Student.sort_order}")
    unless @students.nil?
      student_ids=@students.collect(&:id)
    end
    @subjects=@batch.subjects.without_exams
    grades=@batch.grading_level_list
    if fa_groups.include? assessment_group
      fa_group_ids=[]
      @subjects.each do |subject|
        fa_group=subject.fa_groups.select{|s| s.name.split.last==assessment_group}.first
        unless fa_group.nil?
          fa_group_ids << fa_group.id
        end
      end


      CceReport.scholastic.all(:select=>"cce_reports.*,fa_groups.id fa_group_id",:joins=>[:fa_group], :conditions=>{:student_id=>student_ids,:subject_id=>@batch.subjects.collect(&:id),:fa_groups=>{:id=>fa_group_ids}}).group_by(&:student_id).each do |k,v|
        v.group_by(&:subject_id).each do |k1,v1|
          v1.group_by(&:fa_group_id).each do |k2,v2|
            exam_cat_id=v2.first.cce_exam_category_id
            wightage=CceWeightage.find_by_cce_exam_category_id_and_criteria_type(exam_cat_id,"FA").weightage
            grade_value=(v2.first.obtained_mark).to_f
            grade=grades.to_a.find{|g| g.min_score <= v2.first.converted_mark.round(2).round}.try(:name) || "-"
            grade_mark= grade=="-"? "-" : grade_value.to_f.round(2)
            @fa_score_hash[k][k1]={'grade'=>grade ,'mark'=>v2.first.converted_mark,'wightage'=>wightage}
          end
        end
      end
      return @fa_score_hash
    elsif assessment_group == "ASL1"
      fa_groups=@batch.fa_groups.select{|s| s.name.split.last=="FA1" or s.name.split.last=="FA2"}
      get_exam(fa_groups) if fa_groups.present?
      get_asl_marks_hash(@exam,student_ids,assessment_group) if @exam.present? and student_ids.present?
      return @fa_score_hash

    elsif assessment_group == "ASL2"
      fa_groups=@batch.fa_groups.select{|s| s.name.split.last=="FA3" or s.name.split.last=="FA4"}
      get_exam(fa_groups) if fa_groups.present?
      get_asl_marks_hash(@exam,student_ids,assessment_group) if @exam.present? and student_ids.present?
      return @fa_score_hash
    else
      subjects=@batch.subjects.active_and_has_exam.uniq
      if assessment_group=='SA1'
        cce=@batch.fa_groups.select{|s| s.name.split.last=="FA1" or s.name.split.last=="FA2"}
        unless cce.blank?
          cce_id=cce.first.cce_exam_category_id
          exam_group=@batch.exam_groups.find_by_cce_exam_category_id(cce_id)
          exams= Exam.find_all_by_subject_id_and_exam_group_id(subjects.collect(&:id),exam_group.id)
          ExamScore.all(:select=>'exam_scores.*,student_id,subject_id,exams.maximum_marks',:conditions=>{:exam_id=>exams.collect(&:id)},:joins=>[:exam],:include=>:grading_level).group_by(&:student_id).each do |k,v|
            v.group_by(&:subject_id).each do |k1,v1|
              #cce_weigtage

              exam_id=v1.first.exam_id
              exam=Exam.find exam_id
              exam_cat_id=exam.exam_group.cce_exam_category_id
              wightage=CceWeightage.find_by_cce_exam_category_id_and_criteria_type(exam_cat_id,"SA").weightage

              #cce_weigtages



              grade=v1.first.grading_level ? v1.first.grading_level.name : '-'
              grade_mark=v1[0].maximum_marks.to_f!=0?  grade=="-"? "-" : (v1[0].marks.to_f/v1 [0].maximum_marks.to_f)*100 : "-"

              grade_mark=grade_mark.round(2) unless grade_mark=="-"
              @fa_score_hash[k][k1.to_i]={'grade'=>grade , 'mark'=>grade_mark,'wightage'=>wightage}
            end
          end
        end
        return @fa_score_hash
      else
        cce=@batch.fa_groups.select{|s| s.name.split.last=="FA3" or s.name.split.last=="FA4"}
        unless cce.blank?
          cce_id=cce.first.cce_exam_category_id
          exam_group=@batch.exam_groups.find_by_cce_exam_category_id(cce_id)
          exams= Exam.find_all_by_subject_id_and_exam_group_id(@subjects.collect(&:id),exam_group.id)
          ExamScore.all(:select=>'exam_scores.*,student_id,subject_id,exams.maximum_marks',:conditions=>{:exam_id=>exams.collect(&:id)},:joins=>[:exam]).group_by(&:student_id).each do |k,v|
            v.group_by(&:subject_id).each do |k1,v1|


              #cce_weigtage

              exam_id=v1.first.exam_id
              exam=Exam.find exam_id
              exam_cat_id=exam.exam_group.cce_exam_category_id
              wightage=CceWeightage.find_by_cce_exam_category_id_and_criteria_type(exam_cat_id,"SA").weightage

              #cce_weigtages

              grade=v1.first.grading_level ? v1.first.grading_level.name : '-'
              grade_mark=v1[0].maximum_marks.to_f!=0 ? grade=="-"? "-" : (v1[0].marks.to_f/v1[0].maximum_marks.to_f)*100 : "-"
              grade_mark=grade_mark.round(2) unless grade_mark=="-"
              @fa_score_hash[k][k1.to_i]={'grade'=>grade , 'mark'=>grade_mark,'wightage'=>wightage}
            end
          end
        end
        return @fa_score_hash
      end
    end
  end

  def fetch_cbse_scholastic_data
    @fa_score_hash = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @batch=Batch.find params[:assessment][:batch_id]
    fa_groups=['FA1','FA2','FA3','FA4']
    @students=Student.search(:batch_id_equals=>@batch.id).all(:order=>"#{Student.sort_order}")
    unless @students.nil?
      student_ids=@students.collect(&:id)
    end
    grades=@batch.grading_level_list
    @exam_group=ExamGroup.find params[:assessment][:exam_group_id]
    @subject=Subject.find params[:subject_report][:subject_id]
    @subject.fa_groups.all(:conditions=>{:cce_exam_category_id=>@exam_group.cce_exam_category_id},:order=>'id asc').each do |ag|
      if fa_groups.include? ag.name.split.last
        exams = []
        if @exam_group.id.nil?
          exams=Exam.find_all_by_subject_id_and_exam_group_id(@subject.id,@exam_group.id,:include=>{:subject=>:fa_groups})
        else
          exams=Exam.find_all_by_exam_group_id(@exam_group.id,:include=>{:subject=>:fa_groups})
        end
        fa_group_ids=[]
        exams.each do |exam|
          fa_group=exam.subject.fa_groups.select{|s| s.name.split.last==ag.name.split.last}.first
          unless fa_group.nil?
            fa_group_ids << fa_group.id
          end
        end
        exam_ids=exams.collect(&:id)
        CceReport.scholastic.all(:select=>"cce_reports.*,exams.subject_id,fa_groups.id fa_group_id",:joins=>[:fa_group,:exam], :conditions=>{:student_id=>student_ids,:exam_id=>exam_ids,:fa_groups=>{:id=>fa_group_ids}}).group_by(&:student_id).each do |k,v|
          v.group_by(&:subject_id).each do |k1,v1|
            v1.group_by(&:fa_group_id).each do |k2,v2|
              fa_group=FaGroup.find(k2)
              @fa_score_hash["config"][fa_group.name.split.last]={"max_mark"=>v2.first.max_mark}
              grade_value=(v2.first.obtained_mark).to_f
              grade=grades.to_a.find{|g| g.min_score <= v2.first.converted_mark.round(2).round}.try(:name) || "-"
              grade_mark= grade=="-"? "-" : grade_value.to_f.round(2)
              @fa_score_hash["students"][k][k1][ag.name.split.last]={'grade'=>grade , 'mark'=>grade_mark ,'converted_mark'=>v2.first.converted_mark}
            end
          end
        end
        if ag.name.split.last=="FA1" or ag.name.split.last=="FA2"
          exams= Exam.find_all_by_subject_id_and_exam_group_id(@subject.id,@exam_group.id)
          ExamScore.all(:select=>'exam_scores.*,student_id,subject_id,exams.maximum_marks',:conditions=>{:exam_id=>exams.collect(&:id)},:joins=>[:exam],:include=>:grading_level).group_by(&:student_id).each do |k,v|
            v.group_by(&:subject_id).each do |k1,v1|
              grade=v1.first.grading_level ? v1.first.grading_level.name : '-'
              grade_mark=v1[0].maximum_marks.to_f!=0?  grade=="-"? "-" : v1[0].marks.to_f : "-"
              converted_mark=v1[0].maximum_marks.to_f!=0?  grade=="-"? "-" : (v1[0].marks.to_f/v1 [0].maximum_marks.to_f)*100 : "-"
              grade_mark=grade_mark.round(2) unless grade_mark=="-"
              @fa_score_hash["students"][k][k1]["SA1"]={'grade'=>grade , 'mark'=>grade_mark,'converted_mark'=>converted_mark}
            end
          end
        else
          exams= Exam.find_all_by_subject_id_and_exam_group_id(@subject.id,@exam_group.id)
          ExamScore.all(:select=>'exam_scores.*,student_id,subject_id,exams.maximum_marks',:conditions=>{:exam_id=>exams.collect(&:id)},:joins=>[:exam]).group_by(&:student_id).each do |k,v|
            v.group_by(&:subject_id).each do |k1,v1|
              grade=v1.first.grading_level ? v1.first.grading_level.name : '-'
              grade_mark=v1[0].maximum_marks.to_f!=0 ? grade=="-"? "-" : v1[0].marks.to_f : "-"
              converted_mark = v1[0].maximum_marks.to_f!=0 ? grade=="-"? "-" : (v1[0].marks.to_f/v1[0].maximum_marks.to_f)*100 : "-"
              grade_mark=grade_mark.round(2) unless grade_mark=="-"
              @fa_score_hash["students"][k][k1]["SA2"]={'grade'=>grade , 'mark'=>grade_mark,'converted_mark'=>converted_mark}
            end
          end
        end
      end
    end
  end

  def fetch_cbse_co_scholastic_data
    @batch=Batch.find params[:assessment][:batch_id]
    @observation_group = ObservationGroup.find params[:subject_report][:observation_group_id]
    @co_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @cbse_co_scholastic_entries=CbseCoScholasticSetting.find_all_by_course_id_and_observation_id(@batch.course_id,@observation_group.observations.collect(&:id))
    @co_hash[:ob_list] = []
    CceReport.coscholastic.all(:select=>"cce_reports.*,observations.observation_group_id,observations.name AS o_name, observations.sort_order,observation_groups.sort_order as s_order",:joins=>'INNER JOIN observations ON cce_reports.observable_id = observations.id INNER JOIN observation_groups on observation_groups.id=observations.observation_group_id', :conditions=>["batch_id=? and observation_groups.id=?", @batch.id,@observation_group.id], :order=>"observations.sort_order ASC").group_by(&:observable_id).each do |key,val|
      entry=@cbse_co_scholastic_entries.find_by_observation_id(key)
      @co_hash[:ob_list] << {:id=>val.find{|r| r.grade_string}.try(:observable_id), :name=> val.find{|r| r.grade_string}.try(:o_name).to_s,:code=>entry.try(:code).to_s,:sort_order=>val.find{|r| r.grade_string}.try(:sort_order)}
      @students =  @batch.students.all(:order=>"#{Student.sort_order}")
      @students.each do |s|
        @co_hash[s.id][:observations][key][:code] = @co_hash[:ob_list].find{|x| x[:id] == key }[:code]
        @co_hash[s.id][:observations][key][:name] = @co_hash[:ob_list].find{|x| x[:id] == key }[:name]
        @co_hash[s.id][:observations][key][:grade] = val.find{|r| r.student_id==s.id and r.observable_id==key}.present? ? val.find{|r| r.student_id==s.id and r.observable_id==key}.grade_string : " "
        @co_hash[s.id][:observations][key][:sort_order] = val.find{|r| r.student_id==s.id and r.observable_id==key}.present? ? val.find{|r| r.student_id==s.id and r.observable_id==key}.sort_order : @co_hash[:ob_list].find{|x| x[:id] == key }[:sort_order]
      end
    end
  end

  def fetch_asl_report
    @fa_score_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @students=Student.search(:batch_id_equals=>@batch.id).all(:order=>"#{Student.sort_order}")
    if @students.present?
      if @assessment == "ASL1"
        fa_groups = @batch.fa_groups.select{|s| s.name.split.last=="FA1" or s.name.split.last=="FA2"}
      elsif @assessment == "ASL2"
        fa_groups = @batch.fa_groups.select{|s| s.name.split.last=="FA3" or s.name.split.last=="FA4"}
      else
        fa_groups = []
      end
      get_exam(fa_groups) if fa_groups.present?
      get_asl_marks_cbse_hash(@exam,@students.map(&:id),@assessment) if @exam.present?
    end
    return @fa_score_hash
  end

  def get_asl_marks_cbse_hash(exam,student_ids,assessment_group)
    exam_cat_id = exam.exam_group.cce_exam_category_id
    weightage = CceWeightage.find_by_cce_exam_category_id_and_criteria_type(exam_cat_id,"SA").weightage
    exam_max_mark = exam.maximum_marks.to_f
    AslScore.all(:conditions=>{:student_id=>student_ids,:exam_id=>exam.id}).each do |asl_score|
      @fa_score_hash['asl_mark'] = {'score'=>exam.subject.asl_mark.to_f}
      @fa_score_hash['asl_convert_mark'] = {'score'=>(@fa_score_hash['asl_mark']['score']/exam_max_mark)*weightage}
      obtained = exam.subject.asl_mark == 20 ? (asl_score.speaking.to_f + asl_score.listening.to_f)/2 : (asl_score.speaking.to_f + asl_score.listening.to_f)/4
      convert = (obtained/exam_max_mark)*weightage
      @fa_score_hash[asl_score.student_id][assessment_group] = {'convert'=>convert.to_f,'obtained'=>obtained}
    end
    return @fa_score_hash
  end

  def get_exam(fa_groups)
    exam_groups=fa_groups.first.cce_exam_category.exam_groups
    if exam_groups.present?
      exam_group=exam_groups.first(:conditions=>{:batch_id=>@batch.id})
      if exam_group.present?
        exams=exam_group.exams
        if exams.present?
          @exam=exams.first(:joins=>:subject,:conditions=>{:subjects=>{:batch_id=>@batch.id,:is_asl=>true}})
          @subjects = []
          @subjects << @exam.subject if @exam.present?
        end
      end
    end
  end

  def get_asl_marks_hash(exam,student_ids,assessment_group)
    AslScore.all(:conditions=>{:student_id=>student_ids,:exam_id=>exam.id}).each do |asl_score|
      convert=exam.subject.asl_mark == 20 ? (asl_score.speaking.to_f + asl_score.listening.to_f)/2 : (asl_score.speaking.to_f + asl_score.listening.to_f)/4
      grade=GradingLevel.percentage_to_grade(asl_score.final_score.to_f, @batch.id)
      @fa_score_hash[asl_score.student_id][assessment_group] = {'speaking' => asl_score.speaking.to_f.round(2),'listening'=>asl_score.listening.to_f.round(2),'overall'=>asl_score.final_score.to_f.round(2),'convert'=>convert.to_f.round(2),'grade'=>grade.present? ? grade.name : '-'}
      @fa_score_hash['asl_mark'] = {'score'=>exam.subject.asl_mark.to_f.round(2)}
    end
    return @fa_score_hash
  end

  def fetch_subject_wise_report
    @batch=Batch.find @batch_id
    if @subject_id == "all"
      if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults")) or @current_user.privileges.include?(Privilege.find_by_name("ViewResults")) or @current_user.is_a_tutor_for_this_batch(@batch)
        @subjects = @batch.exam_groups.present? ? @batch.subjects.without_exams : []
      elsif @current_user.is_a_subject_teacher(@batch.id)
        @subjects = @batch.exam_groups.present? ? @current_user.employee_record.subjects.without_exams.all(:conditions=>{:batch_id=>@batch.id}) : []
      else
        @subjects = []
      end
    else
      @subjects = Subject.find_all_by_id(@subject_id)
    end
    fa_score_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    exam_score_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    @subjects.each do |subject|
      @subject = subject
      fa_score_hash[subject.id]["sum_total"] = 0
      fa_groups=subject.fa_groups
      if fa_groups.present?
        fg_ids = [] 
        fa_groups.each{|fg| fg_ids << fg.name.split.last.gsub('FA','').to_i}
        fa_groups.each do |fa_group|
          weightage = fa_group.cce_exam_category.cce_weightages.first(:conditions=>{:criteria_type=>'FA'}).try(:weightage)
          fa_score_hash[subject.id][fa_group.name.split.last] = {'weightage'=>weightage,'total_mark'=>fa_group.max_marks}
          fa_score_hash[subject.id]["sum_total"] += (weightage || 0)
        end
        unless fg_ids.sort! == [1,2,3,4]
          ([1,2,3,4]-fg_ids).each do |i|
            fa_score_hash[subject.id]["FA#{i}"] = {'weightage'=> nil,'total_mark'=>nil}
          end
          fa_score_hash[subject.id]["sum_total"] += 0
        end
      else
        [1,2,3,4].each do |i|
          fa_score_hash[subject.id]["FA#{i}"] = {'weightage'=> nil,'total_mark'=>nil}
        end
      end
      grades=@batch.grading_level_list
      exam_ids=subject.exams.all.collect(&:id)
      students
      unless @students.empty?
        student_ids=@students.collect(&:id)
      end
      @sa1=0
      @sa2=0
      cce=fa_groups.select{|s| s.name.split.last=="FA1" or s.name.split.last=="FA2"}
      unless cce.blank?
        cce_id=cce.first.cce_exam_category_id
        exam_group=@batch.exam_groups.find_by_cce_exam_category_id(cce_id)
        @sa1 = exam_group.present? ? exam_group.id : 0
      end
      cce=fa_groups.select{|s| s.name.split.last=="FA3" or s.name.split.last=="FA4"}
      unless cce.blank?
        cce_id=cce.first.cce_exam_category_id
        exam_group=@batch.exam_groups.find_by_cce_exam_category_id(cce_id)
        @sa2 = exam_group.present? ? exam_group.id : 0
      end
      CceReport.scholastic.all(:select=>"cce_reports.*,fa_groups.id fa_group_id",:joins=>[:fa_group], :conditions=>{:subject_id=>subject.id,:student_id=>student_ids}).group_by(&:student_id).each do |k,v|
        fa_score_hash[subject.id][k]["sum_total"] = 0
        v.group_by(&:fa_group_id).each do |k1,v1|
          fa_group=FaGroup.find_by_id(k1)
          cce_weightage = fa_group.cce_exam_category.cce_weightages.first(:conditions=>{:criteria_type=>'FA'}).try(:weightage)
          grade_value=(v1.first.obtained_mark)
          grade=grades.to_a.find{|g| g.min_score <= v1.first.converted_mark.round(2).round}.try(:name) || "-"
          grade_mark= grade=="-" ? "-" : grade_value.to_f.round(2)
          weighted_mark = ((grade_value * cce_weightage.to_i)/v1.first.max_mark).round(2)
          #          fa_score_hash[subject.id][fa_group.name.split.last].merge!({'total_mark'=>v1.first.max_mark})
          fa_score_hash[subject.id][k][fa_group.name.split.last]={'grade'=>grade , 'mark'=>grade_mark,'weighted_mark'=>weighted_mark}
          fa_score_hash[subject.id][k]["sum_total"] += weighted_mark
        end
      end
      exam_score_hash[subject.id]["sum_total"] = 0
      subject_exams = subject.exams
      exam_score_hash[subject.id]['SA1'] = {'weightage'=>nil,'total_mark'=>nil}
      exam_score_hash[subject.id]['SA2'] = {'weightage'=>nil,'total_mark'=>nil}
      if subject_exams.present?
        eg_ids = []
        subject_exams.each{|e| eg_ids << e.exam_group_id}
        subject_exams.each do |e|
          weightage = e.exam_group.cce_exam_category.cce_weightages.first(:conditions=>{:criteria_type=>'SA'}).try(:weightage)
          if e.exam_group_id == @sa1
            exam_score_hash[subject.id]['SA1'] = {'weightage'=>weightage,'total_mark'=>e.maximum_marks}
            exam_score_hash[subject.id]["sum_total"] += (weightage || 0)
          elsif e.exam_group_id == @sa2
            exam_score_hash[subject.id]['SA2'] = {'weightage'=>weightage,'total_mark'=>e.maximum_marks}
            exam_score_hash[subject.id]["sum_total"] += (weightage || 0)
          end
        end
      end
      ExamScore.all(:select=>'exam_scores.*,student_id,exam_group_id,exams.maximum_marks',:conditions=>{:exam_id=>exam_ids,:student_id=>student_ids},:joins=>[:exam],:include=>:grading_level).group_by(&:student_id).each do |k,v|
        exam_score_hash[subject.id][k]["sum_total"] = 0
        v.group_by(&:exam_group_id).each do |k1,v1|
          cce_weightage = v1[0].exam.exam_group.cce_exam_category.cce_weightages.first(:conditions=>{:criteria_type=>'SA'}).try(:weightage)
          grade=v1.first.grading_level ? v1.first.grading_level.name : '-'
          grade_mark=v1[0].maximum_marks.to_f != 0 ? grade=="-" ? "-"  : (v1[0].marks.to_f) : "-"
          grade_mark=grade_mark.round(2) unless grade_mark=="-"
          weighted_mark = grade_mark != "-" ? ((grade_mark * cce_weightage.to_i)/v1[0].maximum_marks.to_f).round(2) : 0
          if k1.to_i == @sa1
            exam_score_hash[subject.id][k]['SA1'] = {'grade'=>grade , 'mark'=>grade_mark,'weighted_mark'=>weighted_mark}
            exam_score_hash[subject.id][k]["sum_total"] += weighted_mark
          elsif k1.to_i == @sa2
            exam_score_hash[subject.id][k]['SA2'] = {'grade'=>grade , 'mark'=>grade_mark,'weighted_mark'=>weighted_mark}
            exam_score_hash[subject.id][k]["sum_total"] += weighted_mark
          end
        end
      end
    end
    @score_hash = {'fa_marks'=>fa_score_hash,'sa_marks'=>exam_score_hash}
  end

  def has_required_params
    case params[:action]
    when 'subject_wise_batches'
      handle_params_failure(params[:course_id],[:@batches],[['batch_select',{:partial=>'subject_wise_batches'}]])
    when 'list_previous_batches'
      handle_params_failure(params[:course_id],[:@batches],[['batch_select',{:text=>''}],['list_cce_category',{:text=>''}],['fa_groups_list',{:text=>''}],['student_list',{:text=>''}],['report',{:text=>''}],['hider',{:text=>''}]])
    when 'list_exam_groups'
      handle_params_failure(params[:batch_id],[:@exam_groups],[['exam_group_select',{:partial=>'list_exam_groups'}]])
    when 'list_observation_groups'
      handle_params_failure(params[:batch_id],[:@observation_groups,:@observation_group],[['observation_group_select',{:partial=>'list_observation_groups'}]])
    when 'list_asl_groups'
      handle_params_failure(params[:batch_id],[:@asl_groups],[['exam_group_select',{:partial=>'list_asl_groups'}]])
    when 'list_batches'
      unless params[:type]=="batch_student_report"
        handle_params_failure(params[:course_id],[:@batches],[['batch_select',{:partial=>'batch_list'}]])
      end
    when 'generate_student_wise_report'
      handle_params_failure(params[:batch_id],[],[['list_cce_category',{:text=>''}],['fa_groups_list',{:text=>''}],['student_list',{:text=>''}],['report',{:text=>''}],['hider',{:text=>''}]])
    when 'list_subjects'
      if params.has_key?(:batch_id)
        handle_params_failure(params[:batch_id],[:@subjects],[['subject_select',{:partial=>'list_subjects'}]])
      elsif params.has_key?(:exam_group_id)
        handle_params_failure(params[:exam_group_id],[:@subjects],[['subject_select',{:partial=>'list_subjects'}]])
      end
    when 'subject_wise_generated_report'
      handle_params_failure(params[:subject_report][:course_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select a class, batch and subject") and return
      handle_params_failure(params[:subject_report][:batch_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select a batch and subject") and return
      handle_params_failure(params[:subject_report][:subject_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select a subject") and return
    when 'generated_report'
      handle_params_failure(params[:assessment][:course_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select a class, batch and assessment group") and return
      handle_params_failure(params[:assessment][:batch_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select a batch and assessment group") and return
    when 'generated_detailed_fa_report'
      handle_params_failure(params[:assessment][:course_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}],['secondary_flash',{:text=>''}]],"Select a class, batch, subject and FA group") and return
      handle_params_failure(params[:assessment][:batch_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}],['secondary_flash',{:text=>''}]],"Select a batch, subject and FA group") and return
      handle_params_failure(params[:assessment][:subject_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}],['secondary_flash',{:text=>''}]],"Select a subject and FA group") and return
    when 'generate_cbse_scholastic_report'
      handle_params_failure(params[:assessment][:course_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select a class, batch, exam group and subject") and return
      handle_params_failure(params[:assessment][:batch_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select a batch, exam group and subject") and return
      handle_params_failure(params[:assessment][:exam_group_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select an exam group and subject") and return
      handle_params_failure(params[:subject_report][:subject_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select a subject") and return
    when 'generate_cbse_co_scholastic_report'
      handle_params_failure(params[:assessment][:course_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select a class, batch and observation group") and return
      handle_params_failure(params[:assessment][:batch_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select a batch and observation group") and return
      handle_params_failure(params[:subject_report][:observation_group_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select an observation group") and return
    when 'generate_asl_report'
      handle_params_failure(params[:assessment][:course_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select a class, batch and ASL group") and return
      handle_params_failure(params[:assessment][:batch_id],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select a batch and ASL group") and return
      handle_params_failure(params[:assessment][:asl_group_name],[],[['hider',{:partial=>'error'}],['report_table',{:text=>''}]],"Select an ASL group") and return
    when 'generate_previous_batch_exam_reports'
      handle_params_failure(params[:batch_id],[],[['list_cce_category',{:text=>''}],['fa_groups_list',{:text=>''}],['student_list',{:text=>''}],['report',{:text=>''}],['hider',{:text=>''}]])
    end
  end

end