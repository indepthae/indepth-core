class GradebookReportsController < ApplicationController
  before_filter :login_required
  filter_access_to :all , :except => [:reload_cosolidated_exam_types,:reload_consolidated_exams,:consolidated_exam_report,:subject_wise_generated_report,:reload_exams,:reload_report_type,:reload_subjects,:subject_reports,:student_reports,:reload_batches,:reload_reports,:reload_students,:student_wise_generated_report,:change_academic_year,:reload_checkboxes,:show_consolidated_exam_report ]
  filter_access_to [:reload_checkboxes,:show_consolidated_exam_report,:reload_cosolidated_exam_types,:reload_consolidated_exams,:consolidated_exam_report,:subject_wise_generated_report,:reload_exams,:reload_report_type,:reload_subjects,:subject_reports,:change_academic_year,:student_wise_generated_report,:reload_reports,:reload_students,:student_reports,:reload_batches], :attribute_check=>true, :load_method => lambda {current_user }
  before_filter :has_required_params
  before_filter :find_academic_year, :only=>[:student_reports,:subject_reports,:consolidated_exam_report]
  
  
  
  def index
  end
  
  def student_reports
    if @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin?
      @is_privilaged = true
    end
    @report_type='student_report'
    @academic_years = AcademicYear.all
    if @is_privilaged
      @courses = Course.all(:order=>"course_name", :conditions=>["is_deleted = ?",false])
    elsif @current_user.is_a_batch_tutor?
      @courses = @current_user.employee_record.batches.all(:include => :course,:order => "courses.course_name",:conditions => {:is_deleted => false,:is_active => true,:'courses.is_deleted' => false}).collect(&:course).uniq
    end
    @list = []
    @batches = []
    @students = []
  end
  
  def change_academic_year
    @academic_years = AcademicYear.all
    @academic_year = AcademicYear.find params[:id]
    @courses = Course.all(:order=>"course_name", :conditions=>["is_deleted = ?",false])
    @batches = []
    @report_type = params[:report_type]
    render :update do |page|
      page.replace_html 'academic_year_select_box', :partial=>'academic_year_select'
      page.replace_html 'select_course', :partial=>'select_course'
      page.replace_html 'select_batch', :partial=>'select_batch'
    end
  end
   
  def reload_batches
    if @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin?
      @is_privilaged = true
    end
    @report_type = params[:report_type]
    if params[:course_id].present?
      academic_year = AcademicYear.find params[:academic_year_id]
      @course = Course.find params[:course_id]
      if @is_privilaged
        @batches = @course.batches_in_academic_year(academic_year)
      elsif @current_user.is_a_batch_tutor?
        batch_ids = @current_user.employee_record.batches.collect(&:id)
        @batches = @course.batches_in_academic_year(academic_year).all(:conditions=>["batches.id in (?)",batch_ids])
      end
    else
      @batches = []
    end
    render :update do |page|
      page.replace_html 'select_batch', :partial=>'select_batch'
    end
  end
  
  def reload_subjects
    if params[:batch_id].present?
      @batch = Batch.find_by_id params[:batch_id]
      @subjects = Subject.all(:conditions=>["batch_id = ? and !no_exams and !is_deleted",params[:batch_id]])
    else
      @subjects = []
    end
    render :update do |page|
      page.replace_html 'select_subject', :partial=>'select_subject'
    end
  end
  
  def reload_exams
    arr = []
    @list = []
    batch = Batch.find_by_id params[:batch_id]
    course = batch.course
    if params[:subject_id].present?
      hsh = AssessmentGroupBatch.all(:joins=>:assessment_group,:conditions=>["batch_id = ? and assessment_groups.parent_type = 'AssessmentTerm' and assessment_groups.type != 'ActivityAssessmentGroup'",params[:batch_id]],:select=>"assessment_groups.id,assessment_groups.name,assessment_groups.parent_id").group_by(&:parent_id)
      keys = hsh.keys
      terms = AssessmentTerm.find(:all, :conditions=>["id in (?)",keys])
      hsh.each_pair{|key,val| arr = [terms.find{|t| t.id == key.to_i}.name,val.map{|v| [v.name,v.id]}]; @list.push(arr)} if hsh.present?
      plan = course.assessment_plans.find(:all,:conditions=>["academic_year_id = ?",batch.academic_year.id]).first
      final_assessment = plan.final_assessment
      arr = []
      if batch.generated_report_batches.all(:joins => :generated_report, :conditions => {:generated_reports => {:report_type => 'AssessmentPlan'}}).present?
        arr = [plan.name,[[final_assessment.name,final_assessment.id]]] if !final_assessment.new_record? and !final_assessment.no_exam
      end
      @list.push(arr) if arr.present?
    end
    render :update do |page|
      page.replace_html 'select_exam', :partial => 'select_exam'
    end
  end
  
  def reload_report_type
    if params[:exam_id].present?
      @assessment_group = AssessmentGroup.find_by_id params[:exam_id]
      render :update do |page|
        if @assessment_group.type=="DerivedAssessmentGroup" or @assessment_group.is_single_mark_entry == false
          page.replace_html 'select_type', :partial => 'select_report_types'
        else
          page.replace_html 'select_type', :partial => 'select_report_type'
        end
      end
    else
      render :update do |page|
        page.replace_html 'select_type', :partial => 'select_report_type'
      end
    end
  end
  
  def reload_reports
    @list = []
    if params[:batch_id].present?
      @batch = Batch.find_by_id params[:batch_id]
      @list = @batch.fetch_gradebook_reports
    end
    render :update do |page|
      page.replace_html 'select_report', :partial=>'select_report'
    end
    
  end
  
  def reload_students
    @students = []
    if params[:grb_id].present?
      @grb_id = params[:grb_id]
      @batch = Batch.find_by_id params[:batch_id]
      @students = @batch.effective_students
    end
    render :update do |page|
      page.replace_html 'select_student', :partial=>'select_student'
    end
  end
    
  def student_wise_generated_report
    @batch = Batch.find params[:student_report][:batch]
    @students = @batch.effective_students
    @student = @students.find{|student| student.s_id.to_s == params[:student_report][:student]}
    @grb_id = params[:student_report][:report]
    @schol_report = @student.fetch_school_report(@grb_id)
    @exam_type = @schol_report.find_exam_type if @schol_report.present?
    @reportable = @schol_report.reportable if @schol_report.present?
    if @reportable.present?
      render :update do |page|
        page.replace_html 'flash', :text => ""
        page.replace_html 'remarks_section', :partial => "assessment_reports/#{@exam_type}_remarks_section.erb"
        page.replace_html 'pdf_link', :partial => 'pdf_link'
        if @schol_report.individual_report_pdf.present?
          page << "renderPdf('#{@schol_report.individual_report_pdf.attachment.url(:original, false)}', 'planner-canvas')"
        else
          page.replace_html 'student_report', :partial => "assessment_reports/student_#{@exam_type}.erb"
        end
      end
    else
      render :update do |page|
        page.replace_html 'pdf_link', :text => ""
        page.replace_html 'remarks_section', :text => ""
        page.replace_html 'flash', :text => ""
        page.replace_html 'student_report', :text => "<p class = 'flash-msg'>#{t('no_reports')} </p>"
      end
    end
  end
  
  def subject_reports
    if @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin?
      @is_privilaged = true
    end
    @report_type = 'subject_report'
    @academic_years = AcademicYear.all
    if @is_privilaged
      @courses = Course.all(:order=>"course_name", :conditions=>["is_deleted = ?",false])
    elsif @current_user.is_a_batch_tutor?
      @courses = @current_user.employee_record.batches.all(:include => :course,:order => "courses.course_name",:conditions => {:is_deleted => false,:is_active => true,:'courses.is_deleted' => false}).collect(&:course).uniq
    end
    @batches = []
    @list = []
    @subjects = []
    @student_category = StudentCategory.all
  end

  def subject_wise_generated_report
    course = Course.find params[:subject_report][:course]
    subject = Subject.find params[:subject_report][:subject]
    @assessment_group = AssessmentGroup.find_by_id params[:subject_report][:exam]
    @max_marks = @assessment_group.maximum_marks_for(subject,course )
    @grades = true if (@assessment_group.scoring_type == 3)
    @report = ConvertedAssessmentMark.fetch_subject_wise_report(params[:subject_report])
    @report_hash = @report.group_by(&:student_id)
    @student_ids = @report.collect(&:student_id)
    @students = ConvertedAssessmentMark.fetch_gradebook_students(params[:subject_report]).select{|obj| @student_ids.include? obj.s_id}
    
    if @report.present?
      if @report.first.ag_type == "SubjectAssessmentGroup"
        @assessment_attributes = AssessmentAttribute.all 
        @attrib_report = @report.find{|r| r.actual_mark.present?}
        @attrib_count = @attrib_report.actual_mark.keys.count if @attrib_report.present?
      elsif @report.first.ag_type == "DerivedAssessmentGroup"
        @exam_groups = @assessment_group.assessment_groups
        @exam_groups_count = @exam_groups.count
      end
    end
    render :update do |page|
      if @report.present?
        if @report.first.subject_exam == "0" and params[:subject_report][:type] == "D" 
          page.replace_html 'subject_report', :partial =>'subject_attrib_report'
        elsif @report.first.subject_exam == "0" and params[:subject_report][:type] == "F"
          page.replace_html 'subject_report', :partial =>'subject_report'
        elsif @report.first.ag_type == "DerivedAssessmentGroup" and params[:subject_report][:type] == "D"
          page.replace_html 'subject_report', :partial =>'derived_assessment_report'
        elsif @report.first.ag_type == "DerivedAssessmentGroup" and params[:subject_report][:type] == "F"
          page.replace_html 'subject_report', :partial =>'subject_report'
        else
          page.replace_html 'subject_report', :partial =>'subject_report'
        end
      else
        page.replace_html 'subject_report', :text => "<p class = 'flash-msg'>#{t('no_reports')} </p>"
      end
      page.replace_html 'flash', :text => ""
    end
  end
  
  def consolidated_exam_report
    if @current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or @current_user.admin?
      @is_privilaged = true
    end
    @report_type='consolidated_exam_report'
    @academic_years = AcademicYear.all
    @list = []
    @types = []
    @batches = []
    if @is_privilaged
      @courses = Course.all(:order=>"course_name", :conditions=>["is_deleted = ?",false])
    elsif @current_user.is_a_batch_tutor?
      @courses = @current_user.employee_record.batches.all(:include => :course,:order => "courses.course_name",:conditions => {:is_deleted => false,:is_active => true,:'courses.is_deleted' => false}).collect(&:course).uniq
    end
    @checkbox_average_highest = true
    @checkbox_total_rank = true
  end
  
  def show_consolidated_exam_report
    id = params[:consolidated_exam_report][:exam].split('_').last.to_i
    type = params[:consolidated_exam_report][:exam].split('_').first
    @batch = Batch.find params[:consolidated_exam_report][:batch]
    @students = @batch.effective_students
    @type = params[:consolidated_exam_report][:type]
    if type == "exam"
      @assessment_group = AssessmentGroup.find id
      agb = AssessmentGroupBatch.first(:conditions=>["batch_id=? and assessment_group_id=?",@batch.id,@assessment_group.id])
      @subjects = Subject.all(:joins=>:converted_assessment_marks,:conditions=>["assessment_group_batch_id=? and !no_exams",agb.id],:group=>:name)
      @subjects = @batch.subjects if @assessment_group.type == "ActivityAssessmentGroup"
      @report_generator = GradebookReportGenerator.new(params[:consolidated_exam_report],agb.id)
      @report = @report_generator.create_report
      @score_hash = @report.fetch_report_data
      @aggregate_hash = @report.calculate_total if params[:consolidated_exam_report][:total] == "1"
      @header_hash = @report.fetch_report_headers if @assessment_group.assessment_group_type == 'Activity' or (@assessment_group.assessment_group_type == 'Subject Attributes' and params[:consolidated_exam_report][:type] == "attribute" )
      @avg_hash = @report.calculate_average if params[:consolidated_exam_report][:average] == "1"
      @highest = @report.find_highest if params[:consolidated_exam_report][:highest] == "1"
      @rank = @report.find_rank if params[:consolidated_exam_report][:rank] == "1"
    elsif ["term","plan"].include? type
      @detailed_report_generator = GradebookDetailedReportGenerator.new(params[:consolidated_exam_report])
      @detailed_report = @detailed_report_generator.create_report
      @score_hash = @detailed_report.fetch_report_data
      @header_hash = @detailed_report.fetch_report_headers
      @aggregate_hash = @detailed_report.calculate_total if params[:consolidated_exam_report][:total] == "1"
      @rank = @detailed_report.find_rank if params[:consolidated_exam_report][:rank] == "1"
      @avg_hash = @detailed_report.calculate_average if params[:consolidated_exam_report][:average] == "1"
      @highest = @detailed_report.find_highest if params[:consolidated_exam_report][:highest] == "1"
      @subjects = Subject.all(:conditions=>["id in (?)  and !no_exams",@header_hash.keys]) if type == "term"
      if type == "plan"
        @subjects = {}
        @terms = AssessmentTerm.all(:conditions=>["assessment_terms.assessment_plan_id = ?",id],:group=>:name)
        @terms.each do |term|
          subjects = Subject.all(:conditions=>["id in (?) and batch_id = ? and !no_exams and !is_deleted",@header_hash[term.id].keys.uniq, @batch])
          @subjects[term.id] = subjects if subjects.present?
        end
      end
    end
    render :update do |page|
      if @subjects.present? and @students.present?
        #@subjects = @subjects.sort_by{|sb| sb.priority.to_i}        
        @subjects = type == "plan" ? @subjects.each{|k,v| v.sort_by{|sb| sb.priority.to_i }} : @subjects.sort_by{|sb| sb.priority.to_i}        
        page.replace_html 'flash', :text => ""
        page.replace_html 'consolidated_report', :partial=>"consolidated_activity_report" if params[:consolidated_exam_report][:type] == "obtained_score"
        page.replace_html 'consolidated_report', :partial=>"consolidated_attribute_report" if params[:consolidated_exam_report][:type] == "attribute"
        page.replace_html 'consolidated_report', :partial=>"consolidated_planner_score" if ["exam","planner","obtained_grade","percent"].include? params[:consolidated_exam_report][:type] and type == "exam"
        page.replace_html 'consolidated_report', :partial=>"consolidated_term_report" if type == "term"
        page.replace_html 'consolidated_report', :partial=>"consolidated_plan_report" if type == "plan"
      else
        page.replace_html 'flash', :text => ""
        page.replace_html 'consolidated_report', :text => "<p class = 'flash-msg flash-msg2'> #{t('no_reports')} </p>"
      end
    end
  end

  def reload_consolidated_exams
    arr = []
    terms_arr= []
    @list = []
    if params[:batch_id].present?
      batch = Batch.find params[:batch_id]
      course = batch.course
      plan = course.assessment_plans.find(:all,:conditions=>["academic_year_id = ?",batch.academic_year.id]).first
      hsh = AssessmentGroupBatch.all(:joins=>:assessment_group,:conditions=>["batch_id = ? and assessment_groups.parent_type = 'AssessmentTerm'",params[:batch_id]],:select=>"assessment_groups.id,assessment_groups.name,assessment_groups.parent_id").group_by(&:parent_id)
      keys = hsh.keys
      terms = AssessmentTerm.find(:all, :conditions=>["id in (?)",keys])
      hsh.each_pair{|key,val| arr = [terms.find{|t| t.id == key.to_i}.name,val.map{|v| [v.name,"exam_#{v.id}"]}]; @list.push(arr)} if hsh.present?
      terms_arr = terms.map{|t| [t.name,"term_#{t.id}"]} if terms.present?
      terms_arr << [plan.name,"plan_#{plan.id}"] if plan.present?
      final_assessment = plan.final_assessment
      if batch.generated_report_batches.all(:joins => :generated_report, :conditions => {:generated_reports => {:report_type => 'AssessmentPlan'}}).present?
        terms_arr << [final_assessment.name,"exam_#{final_assessment.id}"] if !final_assessment.new_record? and !final_assessment.no_exam
      end
      arr = [t('consolidated_reports')]
      arr << terms_arr if terms_arr.present?
      @list.push(arr) unless @list.empty?
    end
    render :update do |page|
      page.replace_html 'select_exam', :partial =>'select_consolidated_exam_group'
    end
  end
  
  def reload_cosolidated_exam_types
    id = params[:exam_id].split('_').last.to_i
    type = params[:exam_id].split('_').first
    @list = []
    if type == "exam"
      ag = AssessmentGroup.find id
      if ag.type == "SubjectAssessmentGroup" and [1,3].include?(ag.scoring_type) and ag.is_single_mark_entry 
        @list = [[t('exam_score'),"exam"],[t('planner_score'),"planner"],[t('percentage'),"percent"]]
      elsif ag.type == "DerivedAssessmentGroup"
        @list = [[t('planner_score'),"planner"]]
      elsif ag.type == "ActivityAssessmentGroup"
        @list = [[t('obtained_score'),'obtained_score']]
      elsif ag.type == "SubjectAssessmentGroup" and ag.scoring_type == 2
        @list = [[t('obtained_grade'),'obtained_grade']]
      elsif ag.type == "SubjectAssessmentGroup" and !ag.is_single_mark_entry 
        @list = [[t('attribute_score'),"attribute"],[t('planner_score'),"planner"],[t('percentage'),"percent"]]
      end
    elsif ["plan","term"].include? type
      @list = [[t('exam_score'),"exam"],[t('planner_score'),"planner"],[t('percentage'),"percent"]]
    end
    render :update do |page|
      page.replace_html 'select_type', :partial =>'select_consolidated_exam_type'
    end
  end
  
  def reload_checkboxes
    if ["exam","planner","attribute"].include? params[:type]
      @checkbox_average_highest = false#disabled false
      @checkbox_total_rank = false
    elsif params[:type] == "percent"
      @checkbox_average_highest = false
      @checkbox_total_rank = true
    elsif params[:type] == "obtained_score" or params[:type] == "obtained_grade"
      @checkbox_average_highest = true#disabled true
      @checkbox_total_rank = true
    elsif params[:type] == ""
      @checkbox_average_highest = true
      @checkbox_total_rank = true
    end
    render :update do |page|
      page.replace_html 'checkboxes', :partial =>'check_boxes'
    end
  end
  
  def has_required_params
    param = ""
    case params[:action]
    when 'student_wise_generated_report'
      unless params[:student_report][:course].present?
        param += " #{t('course')},"
      end
      unless params[:student_report][:batch].present?
        param += " #{t('batch')},"
      end
      unless params[:student_report][:report].present?
        param += " #{t('report')} #{t('and')}"
      end
      unless params[:student_report][:student].present?
        param += " #{t('student_text')}"
      end
      if param.present?
        render :update do |page|
          page.replace_html 'flash',:text => "<p class = 'flash-msg'>#{t('select_a')} #{param} </p>"
          page.replace_html 'student_report', :text =>""
          page.replace_html 'remarks_section',  :text =>""
          page.replace_html 'pdf_link', :text =>""
        end
      end
    when 'show_consolidated_exam_report'
      unless params[:consolidated_exam_report][:course].present?
        param += " #{t('course')},"
      end
      unless params[:consolidated_exam_report][:batch].present?
        param += " #{t('batch')},"
      end
      unless params[:consolidated_exam_report][:exam].present?
        param += " #{t('exam_text')} #{t('and')}"
      end
      unless params[:consolidated_exam_report][:type].present?
        param += " #{t('type')}"
      end
      if param.present?
        render :update do |page|
          page.replace_html 'flash',:text => "<p class = 'flash-msg'>#{t('select_a')} #{param} </p>"
          page.replace_html 'consolidated_report', :text =>""
        end
      end
    when 'subject_wise_generated_report'
      unless params[:subject_report][:course].present?
        param += " #{t('course')},"
      end
      unless params[:subject_report][:batch].present?
        param += " #{t('batch')},"
      end
      unless params[:subject_report][:subject].present?
        param += " #{t('subject')} #{t('and')}"
      end
      unless params[:subject_report][:exam].present?
        param += " #{t('exam_text')}"
      end
      if param.present?
        render :update do |page|
          page.replace_html 'flash',:text => "<p class = 'flash-msg'>#{t('select_a')} #{param} </p>"
          page.replace_html 'subject_report', :text =>""
        end
      end
    end
  end
  
end