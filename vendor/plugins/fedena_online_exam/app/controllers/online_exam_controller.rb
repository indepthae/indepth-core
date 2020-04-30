class OnlineExamController < ApplicationController
  before_filter :login_required #,:online_exam_enabled
  before_filter :check_updating_status
  filter_access_to :all, :except=>[:evaluator_home,:evaluation_student_select,:publish_result]
  filter_access_to [:evaluator_home], :attribute_check=>true, :load_method => lambda { current_user }
  filter_access_to [:evaluation_student_select,:publish_result,:show_student_list,:evaluate_answers], :attribute_check=>true, :load_method => lambda { OnlineExamGroup.find(params[:id]) }

  def index
    
  end

  def new_online_exam
    @online_exam_group  = OnlineExamGroup.new(params[:online_exam_group])
    deliver_plugin_block :fedena_reminder do
      @online_exam_group.build_alert_settings if request.get?
    end
    @batches = Batch.active
    @batch_ids = []
    @assigned_employees = []
    if request.post?
      @errors = 0
      unless @online_exam_group.valid?
        @errors = 1
      end
      if @online_exam_group.exam_type == "subject_specific"
        unless params[:subject_ids].present?
          @online_exam_group.errors.add_to_base(t('no_subjects'))
          @errors = 1
        end
      end
      unless params[:student_ids].present?
        @online_exam_group.errors.add_to_base(t('no_students'))
        @errors = 1
      end
      if @online_exam_group.exam_format == "hybrid"
        unless params[:employee_ids].present?
          @online_exam_group.errors.add_to_base(t('no_evaluators'))
          @errors = 1
        end
      end
      if @errors == 0
        @online_exam_group.save
        @online_exam_group.students = Student.find_all_by_id(params[:student_ids])
        if @online_exam_group.exam_format == "hybrid"
          @online_exam_group.employees = Employee.find_all_by_user_id(params[:employee_ids])
        end
        if @online_exam_group.exam_type == "general"
          @online_exam_group.batches = Batch.find_all_by_id(params[:batch_ids])
        else
          @online_exam_group.batches = Batch.find_all_by_id(params[:online_exam][:assigned_batch])
          @online_exam_group.subjects = Subject.find_all_by_id(params[:subject_ids])
        end
        flash[:notice] = t('success_exam_create')
        redirect_to :action=>:new_question ,:id=>@online_exam_group.id
      else
        if @online_exam_group.exam_format == "hybrid" and params[:employee_ids].present?
          @assigned_employees = User.find_all_by_id(params[:employee_ids])
        end
        @students = []
        if @online_exam_group.exam_type == "general"
          if params[:batch_ids].present?
            @batch_ids = params[:batch_ids]
            @students = Student.find_all_by_batch_id(@batch_ids)
          end
        else
          if params[:online_exam].present? and params[:online_exam][:assigned_batch].present?
            @batch_id = params[:online_exam][:assigned_batch]
            @subjects = Batch.find_by_id(@batch_id).subjects
            @subjects.sort!{|a,b| a.name.downcase <=> b.name.downcase}
            if params[:subject_ids].present?
              @subject_ids = params[:subject_ids]
              subs = Subject.find_all_by_id(@subject_ids)
              general_subjects = subs.select{|sub| sub.elective_group_id.nil?}
              elective_subjects = subs.select{|sub| sub.elective_group_id.present?}
              elective_records = StudentsSubject.find_all_by_subject_id(elective_subjects.collect(&:id)).collect(&:student_id)
              elective_students = Student.find_all_by_id(elective_records).select{|s| s.batch_id = elective_subjects.first.batch_id}
              general_students = Student.find_all_by_batch_id(general_subjects.collect(&:batch_id))
              @students = general_students + elective_students
            else
              @subject_ids = []
            end
          else
            @batch_id = nil
            @subjects = []
          end
        end
        @students.uniq!
        @students.sort! { |a,b| a.first_name.downcase <=> b.first_name.downcase }
        @deselected_students = params[:student_ids].present? ? (@students.map{|s| s.id.to_s} - params[:student_ids].map{|ids| ids.to_s}) : @students.map{|s| s.id.to_s}
        deliver_plugin_block :fedena_reminder do
          @online_exam_group.set_alert_settings(params.fetch(:online_exam_group,{})[:event_alerts_attributes])
        end
        render :action=>:new_online_exam
      end
    end
  end

  def search_evaluator
    employees= User.active.find(:all, :conditions=>["employee=1 AND (username LIKE ? OR first_name LIKE ?)", "%#{params[:query]}%","%#{params[:query]}%"])
    render :json=>{'query'=>params["query"],'suggestions'=>employees.collect{|s| s.full_name.length+s.username.length > 18 ? s.full_name[0..(15-s.username.length)]+".. "+"-"+s.username : s.full_name+"-"+s.username},'data'=>employees.collect(&:id)  }
  end

  def evaluator_home
    @online_exam_groups = @current_user.employee_record.online_exam_groups.all(:conditions=>{:exam_format=>"hybrid"}, :order=>"end_date DESC")
  end

  def evaluation_student_select
    @exam = OnlineExamGroup.find(params[:id])
    @batches = @exam.batches
  end

  def evaluate_answers
    @exam = OnlineExamGroup.find(params[:id])
    @student = Student.find(params[:student_id])
    @descriptive_questions = @exam.online_exam_groups_questions.all(:include=>:online_exam_question).select{|q| q.online_exam_question.question_format=="descriptive"}.paginate(:page=>params[:page],:per_page=>5)
    @exam_attendance = OnlineExamAttendance.find_by_online_exam_group_id_and_student_id(@exam.id,@student.id)
    if params[:page].present? and @descriptive_questions.empty? and !request.put?
      flash[:notice]="#{t('evaluation_successful')}"
      redirect_to :action=>"evaluation_student_select", :id=>@exam.id
    else
      descriptive_question_ids = @descriptive_questions.collect(&:online_exam_question_id)
      @max_marks = @exam.online_exam_groups_questions.sum(:mark).to_f
      @answers = @exam_attendance.online_exam_score_details.all(:conditions=>{:online_exam_question_id=>descriptive_question_ids}).group_by(&:online_exam_question_id)
      if request.put?
        prev_desc_score = @answers.map{|a,s| s.first.marks_obtained.to_f}.sum
        if @exam_attendance.update_attributes(params[:online_exam_attendance])
          new_desc_score = @exam_attendance.online_exam_score_details.all(:conditions=>{:online_exam_question_id=>descriptive_question_ids}).map{|s| s.marks_obtained.to_f}.sum
          prev_total_score = @exam_attendance.total_score.to_f
          new_total_score = (prev_total_score - prev_desc_score) + new_desc_score
          @total_score = @exam_attendance.online_exam_group.online_exam_groups_questions.sum('mark')
          pass_mark = (@total_score*@exam_attendance.online_exam_group.pass_percentage.to_f)/100
          new_total_score >= pass_mark ? passed = true : passed = false
          @exam_attendance.update_attributes(:total_score=>new_total_score, :answers_evaluated=>true, :is_passed=>passed)
          if params[:page].present?
            redirect_to :action=>"evaluate_answers",:id=>@exam.id,:student_id=>@student.id,:page=>(params[:page].to_i + 1)
          else
            redirect_to :action=>"evaluate_answers",:id=>@exam.id,:student_id=>@student.id,:page=>2
          end
        else
          @scores=[]
          params[:online_exam_attendance][:online_exam_score_details_attributes].each_pair do|k,val|
            @scores.push(val)
          end
        end
      end
    end
    # @answers = @exam_questions.select{|q| q.online_exam_question.question_format == "descriptive"}.map{|d| @exam_attendance.online_exam_score_details.first(:conditions=>{:online_exam_question_id=>d.online_exam_question_id}).present? ? @exam_attendance.online_exam_score_details.first(:conditions=>{:online_exam_question_id=>d.online_exam_question_id}) : @exam_attendance.online_exam_score_details.build(:online_exam_question_id=>d.online_exam_question_id)}.group_by(&:online_exam_question_id)
  end

  def show_student_list
    @exam = OnlineExamGroup.find(params[:id])
    @students = @exam.students.all(:conditions=>{:batch_id=>params[:batch_id].to_i},:order=>"first_name ASC")
    @max_marks = @exam.online_exam_groups_questions.sum(:mark).to_f
    unless @students.blank?
      render :update do|page|
        page.replace_html "student-list", :partial=>"student_list"
      end
    else
      render :update do|page|
        page.replace_html "student-list", :text=>"<p class='flash-msg'>#{t('no_students')}</p>"
      end
    end
  end

  def publish_result
    @exam = OnlineExamGroup.find(params[:id])
    if @exam.update_attributes(:result_published=>true)
      flash[:notice]="#{t('published_successfully')}"
      body = "#{t('result_for_online_exam')} <b>#{@exam.name}</b> #{t('has_been_published')}"
      inform(@exam.students.collect(&:user_id),body,'Event-Examination')
    else
      flash[:notice]="#{t('could_not_publish')}"
    end
    redirect_to :action=>"evaluator_home"
  end

  def modify_batch_selection
    if params[:select_value]
      @batches = Batch.active
      if params[:select_value]=='general'
        render :update do |page|
          page.replace_html "batch_selection", :partial=>"multiple_batch_selector", :locals=>{:batches=>@batches,:batch_ids=>[]}
          page.replace_html "student_selection", :text=>""
        end
      else
        render :update do |page|
          page.replace_html "batch_selection", :partial=>"single_batch_selector", :locals=>{:batches=>@batches,:batch_id=>nil,:subjects=>[],:subject_ids=>[]}
          page.replace_html "student_selection", :text=>""
        end
      end
    end
  end

  def list_subjects
    if params[:batch_id].present?
      @subjects = Batch.find(params[:batch_id]).subjects
      @subjects.sort!{|a,b| a.name.downcase <=> b.name.downcase}
      render :update do |page|
        page.replace_html "subject-selector", :partial=>"multiple_subject_selector", :locals=>{:subjects=>@subjects,:subject_ids=>[]}
        page.replace_html "student_selection", :text=>""
      end
    else
      render :update do |page|
        page.replace_html "subject-selector", :text=>""
        page.replace_html "student_selection", :text=>""
      end
    end
  end

  def update_students_list
    @students = []
    if params[:batch_ids].present?
      @students = Student.find_all_by_batch_id(params[:batch_ids].to_s.split(","))
    end
    if params[:subject_ids].present?
      subs = Subject.find_all_by_id(params[:subject_ids].to_s.split(","))
      general_subjects = subs.select{|sub| sub.elective_group_id.nil?}
      elective_subjects = subs.select{|sub| sub.elective_group_id.present?}
      elective_records = StudentsSubject.find_all_by_subject_id(elective_subjects.collect(&:id)).collect(&:student_id)
      elective_students = Student.find_all_by_id(elective_records).select{|s| s.batch_id = elective_subjects.first.batch_id}
      general_students = Student.find_all_by_batch_id(general_subjects.collect(&:batch_id))
      @students = general_students + elective_students
    end
    @students.uniq!
    @students.sort! { |a,b| a.first_name.downcase <=> b.first_name.downcase }
    deselected_students = params[:deselected_students].present? ? params[:deselected_students].split(",") : []
    render :update do|page|
      page.replace_html "student_selection", :partial=>"multiple_student_selector", :locals=>{:students=>@students,:deselected_students=>deselected_students}
    end
  end

  def new_question
    @online_exam_group=OnlineExamGroup.find(params[:id])
    if @online_exam_group.has_attendence
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller=>:user,:action=>:dashboard
    else
      if @online_exam_group.exam_type=="subject_specific"
        @subjects = @online_exam_group.subjects
        @subjects.sort!{|a,b| a.name.downcase <=> b.name.downcase}
      end
      #@group_ids=OnlineExamGroup.find(:all,:conditions=>{:name=>exam_group.name,:start_date=>exam_group.start_date,:end_date=>exam_group.end_date,:maximum_time=>exam_group.maximum_time,:pass_percentage=>exam_group.pass_percentage,:option_count=>exam_group.option_count,:is_deleted=>exam_group.is_deleted,:is_published=>exam_group.is_published}).collect(&:id)
      #@option_count  = exam_group.option_count.to_i
      if params[:ref_id].present?
        @ref_id = params[:ref_id]
        @reference_question = OnlineExamQuestion.find(params[:ref_id])
        @online_exam_question = OnlineExamQuestion.new(:question=>@reference_question.question,:subject_id=>@reference_question.subject_id,:question_format=>@reference_question.question_format)
        if @online_exam_question.question_format=="descriptive"
          2.times{@online_exam_question.online_exam_options.build}
        else
          @reference_question.online_exam_options.each do|o|
            @online_exam_question.online_exam_options.build(:option=>o.option,:is_answer=>o.is_answer)
          end
        end
      else
        @online_exam_question = OnlineExamQuestion.new
        2.times{@online_exam_question.online_exam_options.build}
      end
      if request.post?
        @online_exam_question = OnlineExamQuestion.new(params[:online_exam_question])
        @online_exam_question.question_format="objective" if @online_exam_question.question_format.nil?
        assigned_mark = @online_exam_question.assigned_mark.to_f
        if @online_exam_question.question_format=="descriptive"
          params[:online_exam_question][:online_exam_options_attributes].clear
          @online_exam_question = OnlineExamQuestion.new(params[:online_exam_question])
        end
        if @online_exam_question.save
          if params[:ref_id].present?
            @last_ref = OnlineExamGroupsQuestion.find_by_online_exam_group_id_and_online_exam_question_id(@online_exam_group.id,params[:ref_id])
            last_priority = @last_ref.position - 1
            @last_ref.destroy
          else
            last_priority = OnlineExamGroupsQuestion.last_position(@online_exam_group.id)
          end
          if @online_exam_question.question_format=="descriptive"
            OnlineExamGroupsQuestion.create(:online_exam_group_id=>@online_exam_group.id, :online_exam_question_id=>@online_exam_question.id, :mark=>assigned_mark, :position=>(last_priority.to_i + 1))
          else
            OnlineExamGroupsQuestion.create(:online_exam_group_id=>@online_exam_group.id, :online_exam_question_id=>@online_exam_question.id, :mark=>assigned_mark, :position=>(last_priority.to_i + 1), :answer_ids=>@online_exam_question.online_exam_options.collect(&:id))
          end
          flash[:notice]= "#{t('question_created_successfully')}"
          if params[:ref_id].present?
            redirect_to :action=>:exam_details, :id=>@online_exam_group.id
          else
            redirect_to :action=>:new_question, :id=>@online_exam_group.id
          end
        else
          if @online_exam_question.question_format=="descriptive"
            2.times{@online_exam_question.online_exam_options.build}
          end
          @ref_id = params[:ref_id] if params[:ref_id].present?
          render :action=>:new_question
        end
      end
    end
  end

  def toggle_options_div
    #    if params[:question_format].present?
    #      if params[:question_format] == "descriptive"
    #        render :update do|page|
    #          page.replace_html "options-input", :text=>""
    #        end
    #      else
    #        render :update do|page|
    #          page.replace_html "options-input", :partial=>"options_input_box"
    #        end
    #      end
    #    end
  end

  def create_question

  end

  def view_online_exam
    @batches = Batch.active
  end

  def show_active_exam
    @batch = Batch.find_by_id(params[:batch_id])
    @exams=[]
    if @batch.present?
      @exams = @batch.online_exam_groups.paginate(:page => params[:page], :per_page => 20 ,:conditions=>[ "is_deleted = FALSE"], :include=> :online_exam_attendances,:order=>"id DESC")
      #@exams = OnlineExamGroup.paginate(:page => params[:page], :per_page => 20 ,:conditions=>[ "batch_id = '#{params[:batch_id]}'"], :include=> :online_exam_attendances,:order=>"id DESC")
    end
    render :partial=>'active_exam_list', :locals=>{:batch_id=>params[:batch_id]}
  end

  def edit_exam_group
    @online_exam_group = OnlineExamGroup.find(params[:id])
    deliver_plugin_block :fedena_reminder do
      @online_exam_group.set_alert_settings(params.fetch(:online_exam_group,{})[:event_alerts_attributes])
    end
    if @online_exam_group.has_attendence
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller=>:user,:action=>:dashboard
    else
      @batches = Batch.active
      @assigned_employees = []
      assigned_batches = @online_exam_group.batches
      assigned_students = @online_exam_group.students
      if @online_exam_group.exam_type=="general"
        @batch_ids = assigned_batches.collect(&:id)
        @students = Student.find_all_by_batch_id(@batch_ids)
        @students.sort! { |a,b| a.first_name.downcase <=> b.first_name.downcase }
      else
        @batch_id = assigned_batches.collect(&:id).first
        @subjects = assigned_batches.first.subjects
        assigned_subjects = @online_exam_group.subjects
        @subject_ids = assigned_subjects.collect(&:id)
        general_subjects = assigned_subjects.select{|sub| sub.elective_group_id.nil?}
        elective_subjects = assigned_subjects.select{|sub| sub.elective_group_id.present?}
        elective_records = StudentsSubject.find_all_by_subject_id(elective_subjects.collect(&:id)).collect(&:student_id)
        elective_students = Student.find_all_by_id(elective_records).select{|s| s.batch_id = elective_subjects.first.batch_id}
        general_students = Student.find_all_by_batch_id(general_subjects.collect(&:batch_id))
        @students = general_students + elective_students
        @students.uniq!
        @students.sort!{|a,b| a.first_name.downcase <=> b.first_name.downcase}
      end
      @batch_ids = @online_exam_group.batches.present? ? @online_exam_group.batches.map{|b| b.id.to_s} : []
      @assigned_employees = User.find_all_by_id(@online_exam_group.employees.collect(&:user_id)) if @online_exam_group.exam_format=="hybrid"
      @deselected_students = @students.map{|s| s.id.to_s} - assigned_students.map{|st| st.id.to_s}
      if request.post?
        @errors = 0
        @exam_questions = @online_exam_group.online_exam_questions
        deliver_plugin_block :fedena_reminder do
          params.fetch(:online_exam_group,{})[:event_alerts_attributes].each do |k,v|
            v["event_alert_occurrences_attributes"].each do |key,val|
              v["event_alert_occurrences_attributes"].delete(key) if val["checked_value"] == "1" and val["id"].nil?
            end
          end
        end
        @online_exam_group.attributes = params[:online_exam_group]
        unless @online_exam_group.valid?
          @errors = 1
        end
        if @online_exam_group.exam_type == "subject_specific"
          unless params[:subject_ids].present?
            @online_exam_group.errors.add_to_base(t('no_subjects'))
            @errors = 1
          else
            question_subjects = @exam_questions.map{|m| m.subject.nil? ? nil : m.subject.code.to_s}.uniq
            if question_subjects.include?(nil)
              @online_exam_group.errors.add_to_base(t('obj_to_sub_not_possible'))
              @errors = 1
            else
              unless (question_subjects - params[:subject_ids].map{|s| Subject.find(s).code.to_s}).empty?
                @online_exam_group.errors.add_to_base(t('already_assigned'))
                @errors = 1
              end
            end
          end
        end
        unless params[:student_ids].present?
          @online_exam_group.errors.add_to_base(t('no_students'))
          @errors = 1
        end
        if @online_exam_group.exam_format == "hybrid"
          unless params[:employee_ids].present?
            @online_exam_group.errors.add_to_base(t('no_evaluators'))
            @errors = 1
            @assigned_employees = []
          end
        else
          unless @exam_questions.select{|q| q.question_format=="descriptive"}.empty?
            @online_exam_group.errors.add_to_base(t('sub_to_obj_no_possible'))
            @errors = 1
          end
        end
        if @errors == 0
          if @online_exam_group.exam_format=="objective"
            @online_exam_group.result_published = true if (@online_exam_group.is_published == true)
          end
          @online_exam_group.save
          @online_exam_group.students = Student.find_all_by_id(params[:student_ids])
          if @online_exam_group.exam_format == "hybrid"
            @online_exam_group.employees = Employee.find_all_by_user_id(params[:employee_ids])
          else
            @online_exam_group.employees = []
          end
          if @online_exam_group.exam_type == "general"
            @online_exam_group.batches = Batch.find_all_by_id(params[:batch_ids])
            @online_exam_group.subjects=[]
          else
            @online_exam_group.batches = Batch.find_all_by_id(params[:online_exam][:assigned_batch])
            @online_exam_group.subjects = Subject.find_all_by_id(params[:subject_ids])
          end
          flash[:notice] = t('success_exam_update')
          redirect_to :action=>:view_online_exam
        else
          if @online_exam_group.exam_format == "hybrid" and params[:employee_ids].present?
            @assigned_employees = User.find_all_by_id(params[:employee_ids])
          end
          @students = []
          if @online_exam_group.exam_type == "general"
            if params[:batch_ids].present?
              @batch_ids = params[:batch_ids]
              @students = Student.find_all_by_batch_id(@batch_ids)
            else
              @batch_ids=[]
            end
          else
            if params[:online_exam].present? and params[:online_exam][:assigned_batch].present?
              @batch_id = params[:online_exam][:assigned_batch]
              @subjects = Batch.find_by_id(@batch_id).subjects
              @subjects.sort!{|a,b| a.name.downcase <=> b.name.downcase}
              if params[:subject_ids].present?
                @subject_ids = params[:subject_ids]
                subs = Subject.find_all_by_id(@subject_ids)
                general_subjects = subs.select{|sub| sub.elective_group_id.nil?}
                elective_subjects = subs.select{|sub| sub.elective_group_id.present?}
                elective_records = StudentsSubject.find_all_by_subject_id(elective_subjects.collect(&:id)).collect(&:student_id)
                elective_students = Student.find_all_by_id(elective_records).select{|s| s.batch_id = elective_subjects.first.batch_id}
                general_students = Student.find_all_by_batch_id(general_subjects.collect(&:batch_id))
                @students = general_students + elective_students
              else
                @subject_ids = []
              end
            else
              @batch_id = nil
              @subjects = []
            end
          end
          @students.uniq!
          @students.sort!{|a,b| a.first_name.downcase <=> b.first_name.downcase}
          @deselected_students = params[:student_ids].present? ? (@students.map{|s| s.id.to_s} - params[:student_ids].map{|ids| ids.to_s}) : @students.map{|s| s.id.to_s}
          render :action=>:edit_exam_group
        end
      end
    end
  end

  def update_exam_group
    @exam_group = OnlineExamGroup.find(params[:id])
    unless @exam_group.update_attributes(params[:exam_group])
      @error = true
    end
    @exams = OnlineExamGroup.paginate(:page => params[:page], :conditions=>[ "batch_id = '#{@exam_group.batch_id}'"], :order=>"id DESC")
  end

  def delete_exam_group
    @exam_group = OnlineExamGroup.find(params[:id])
    if @exam_group.destroy
      #flash[:notice]="#{t('exam_group_successfully_deleted')}"
    end
    @batch = Batch.find_by_id(params[:batch_id])
    @exams=[]
    if @batch.present?
      @exams = @batch.online_exam_groups.paginate(:page => params[:page], :per_page => 20 ,:conditions=>[ "is_deleted = FALSE"], :include=> :online_exam_attendances,:order=>"id DESC")
      #@exams = OnlineExamGroup.paginate(:page => params[:page], :per_page => 20 ,:conditions=>[ "batch_id = '#{params[:batch_id]}'"], :include=> :online_exam_attendances,:order=>"id DESC")
    end
    render :update do |page|
      page.replace_html 'exam-list', :partial=>'active_exam_list', :locals=>{:batch_id=>params[:batch_id]}
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('online_exam.exam_group_successfully_deleted')}</p>"
    end
  end

  def exam_details
    @exam_group=OnlineExamGroup.find(params[:id])
    @evaluators = @exam_group.employees
    @attendance=@exam_group.has_attendence
    @exam_questions = @exam_group.online_exam_groups_questions.paginate(:per_page=>5,:page=>params[:page],:order=>"position ASC",:include=>[:online_exam_question])
  end

  def import_questions
    @exam_group = OnlineExamGroup.find(params[:id])
    if @exam_group.has_attendence
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller=>:user,:action=>:dashboard
    else
      if @exam_group.exam_type == "subject_specific"
        @courses = Course.all(:order=>"course_name ASC")
        @questions = []
      else
        @questions = OnlineExamQuestion.paginate(:page=>params[:page],:per_page=>20,:conditions=>["question_format is NULL or question_format = 'objective'"],:order=>"created_at DESC")
        @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>["question_format is NULL or question_format = 'objective'"]).collect(&:id)
      end
    end
  end

  def load_more_questions
    @exam_group = OnlineExamGroup.find(params[:exam_id].to_i)
    if params[:course_id]=="0"
      if params[:question_format]=="descriptive"
        @questions = OnlineExamQuestion.paginate(:page=>(params[:page_no].to_i + 1),:per_page=>20,:conditions=>["question_format = 'descriptive' AND subject_id is NULL"],:order=>"created_at DESC")
        @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>["question_format = 'descriptive' AND subject_id is NULL"]).collect(&:id)
      else
        @questions = OnlineExamQuestion.paginate(:page=>(params[:page_no].to_i + 1),:per_page=>20,:conditions=>["(question_format is NULL or question_format = 'objective') AND subject_id is NULL"],:order=>"created_at DESC")
        @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>["(question_format is NULL or question_format = 'objective') AND subject_id is NULL"]).collect(&:id)
      end
    else
      course = Course.find(params[:course_id])
      subject_code = params[:subject_code]
      if params[:question_format] == "descriptive"
        @questions = OnlineExamQuestion.paginate(:page=>(params[:page_no].to_i + 1),:per_page=>20,:conditions=>{:question_format=>"descriptive",:subject_id=>Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),subject_code)},:order=>"created_at DESC")
        @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>{:question_format=>"descriptive",:subject_id=>Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),subject_code)}).collect(&:id)
      else
        @questions = OnlineExamQuestion.paginate(:page=>(params[:page_no].to_i + 1),:per_page=>20,:conditions=>["(question_format is NULL or question_format = 'objective') AND subject_id IN (?)",Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),subject_code).collect(&:id)],:order=>"created_at DESC")
        @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>["(question_format is NULL or question_format = 'objective') AND subject_id IN (?)",Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),subject_code).collect(&:id)]).collect(&:id)
      end
    end
    render :partial=>"questions_to_import", :locals=>{:questions=>@questions, :assigned_questions=>@assigned_questions}
  end

  def view_question_details
    if params[:question_id].present? and params[:exam_id].present?
      question_row = OnlineExamGroupsQuestion.find_by_online_exam_group_id_and_online_exam_question_id(params[:exam_id],params[:question_id])
      if question_row.present?
        @question = question_row.online_exam_question
        @exam_group = question_row.online_exam_group
        @answers = OnlineExamOption.find_all_by_id(question_row.answer_ids)
        @marks = question_row.mark
        render :partial=>"question_details", :locals=>{:question=>@question,:answers=>@answers,:marks=>@marks,:exam_group=>@exam_group}
      else
        @question = OnlineExamQuestion.find_by_id(params[:question_id])
        @answers = @question.online_exam_options
        @group_question = OnlineExamGroupsQuestion.new(:online_exam_group_id=>params[:exam_id],:online_exam_question_id=>params[:question_id])
        render :partial=>"import_form", :locals=>{:question=>@question,:answers=>@answers,:group_question=>@group_question}
      end
    end
  end

  def load_importing_form
    if params[:question_id].present? and params[:exam_id].present?
      @question = OnlineExamQuestion.find_by_id(params[:question_id])
      @answers = @question.online_exam_options
      if params[:box_checked]=="checked"
        @group_question = OnlineExamGroupsQuestion.new(:online_exam_group_id=>params[:exam_id],:online_exam_question_id=>params[:question_id])
        render :partial=>"import_form", :locals=>{:question=>@question,:answers=>@answers,:group_question=>@group_question}
      else
        @group_question = OnlineExamGroupsQuestion.find_by_online_exam_group_id_and_online_exam_question_id(params[:exam_id],params[:question_id])
        @group_question.destroy unless @group_question.nil?
        @marks = 0
        render :partial=>"question_details", :locals=>{:question=>@question,:answers=>@answers,:marks=>@marks}
      end
    end
  end

  def reload_stats
    @exam_group = OnlineExamGroup.find(params[:exam_id])
    render :partial=>"exam_stats", :locals=>{:exam_group=>@exam_group}
  end

  def save_imported_question
    @group_question = OnlineExamGroupsQuestion.new(params[:online_exam_groups_question])
    @question = OnlineExamQuestion.find(@group_question.online_exam_question_id)
    @answers = @question.online_exam_options
    unless @question.question_format=="descriptive"
      @group_question.answer_ids = @question.online_exam_options.collect(&:id)
    end
    last_row = OnlineExamGroupsQuestion.find(:first,:conditions=>{:online_exam_group_id=>@group_question.online_exam_group_id},:order=>"position DESC")
    unless last_row.nil?
      position = last_row.position + 1
    else
      position = 1
    end
    @group_question.position = position
    if @group_question.save
      render :update do|page|
        page.replace_html "right-panel",:partial=>"question_details", :locals=>{:question=>@question,:answers=>@answers,:marks=>@group_question.mark,:exam_group=>@group_question.online_exam_group}
        page.replace_html "qn-#{@question.id}",:text=>"<div class='each-question assigned selected' id='#{@question.id}' onclick='show_question_details(this);'>
      <div class='question-box'>
        #{@question.question}
      </div>
    </div>"
        page.replace_html "exam-stats",:partial=>"exam_stats", :locals=>{:exam_group=>@group_question.online_exam_group}
      end
    else
      render :update do|page|
        page.replace_html "right-panel",:partial=>"import_form", :locals=>{:question=>@question,:answers=>@answers,:group_question=>@group_question}
      end
    end
  end

  def revert_import
    if params[:id].present? and params[:exam_id].present?
      @question = OnlineExamQuestion.find_by_id(params[:id])
      @answers = @question.online_exam_options
      @exam_group = OnlineExamGroup.find(params[:exam_id])
      @group_question = OnlineExamGroupsQuestion.find_by_online_exam_group_id_and_online_exam_question_id(@exam_group.id,@question.id)
      @group_question.destroy unless @group_question.nil?
      render :update do|page|
        page.replace_html "right-panel",:partial=>"import_form", :locals=>{:question=>@question,:answers=>@answers,:group_question=>OnlineExamGroupsQuestion.new(:online_exam_group_id=>@exam_group.id,:online_exam_question_id=>@question.id)}
        page.replace_html "qn-#{@question.id}",:text=>"<div class='each-question selected' id='#{@question.id}' onclick='show_question_details(this);'>
      <div class='question-box'>
        #{@question.question}
      </div>
    </div>"
        page.replace_html "exam-stats",:partial=>"exam_stats", :locals=>{:exam_group=>@exam_group}
      end
    end
  end

  def show_course_list
    @exam_group = OnlineExamGroup.find(params[:exam_id]) 
    question_type = params[:select_value]
    question_format = params[:question_format]
    if question_type=="subject_specific"
      courses = Course.all(:order=>"course_name ASC")
      render :update do|page|
        page.replace_html "question-list", :partial=>"questions_to_import", :locals=>{:questions=>[], :assigned_questions=>[]}
        page.replace_html "right-panel", :text=>""
        page.replace_html "course-selection", :partial=>"course_select", :locals=>{:courses=>courses}
      end
    else
      if question_format=="descriptive"
        @questions = OnlineExamQuestion.paginate(:page=>params[:page],:per_page=>20,:conditions=>["question_format = 'descriptive'"],:order=>"created_at DESC")
        @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>["question_format = 'descriptive'"]).collect(&:id)
      else    
        @questions = OnlineExamQuestion.paginate(:page=>params[:page],:per_page=>20,:conditions=>["question_format is NULL or question_format = 'objective'"],:order=>"created_at DESC")
        @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>["question_format is NULL or question_format = 'objective'"]).collect(&:id)
      end
      render :update do|page|
        page.replace_html "course-selection", :text=>""
        page.replace_html "question-list",:partial=>"questions_to_import", :locals=>{:questions=>@questions, :assigned_questions=>@assigned_questions}
        unless @questions.empty?
          if @assigned_questions.include?(@questions.first.id)
            page.replace_html "right-panel", :partial=>"question_details", :locals=>{:question=>@questions.first,:answers=>@questions.first.assigned_answers(@exam_group.id),:marks=>@questions.first.marks_assigned(@exam_group.id),:exam_group=>@exam_group}
          else
            page.replace_html "right-panel", :partial=>"import_form", :locals=>{:question=>@questions.first,:answers=>@questions.first.assigned_answers(@exam_group.id),:group_question=>OnlineExamGroupsQuestion.new(:online_exam_group_id=>@exam_group.id,:online_exam_question_id=>@questions.first.id)}
          end
        else
          page.replace_html "right-panel", :text=>""
        end
        page.replace_html "hidden-fields", :text=>"<input id='page_number' type='hidden' value='1' name='page_number'>
        <input id='last_page' type='hidden' value='0' name='last_page'>"
      end
    end
  end

  def list_subject_codes
    exam_group = OnlineExamGroup.find(params[:exam_id])
    course = Course.find(params[:course_id])
    if exam_group.exam_type == "subject_specific"
      assigned_subject_codes = exam_group.subjects.collect(&:code)
      subjects = Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),assigned_subject_codes)
    else
      subjects = Subject.find_all_by_batch_id(course.batches.collect(&:id))
    end
    subject_codes = subjects.collect(&:code).uniq.sort
    render :update do|page|
      page.replace_html "question-list", :partial=>"questions_to_import", :locals=>{:questions=>[], :assigned_questions=>[]}
      page.replace_html "subject-selection", :partial=>"subject_select", :locals=>{:subject_codes=>subject_codes}
    end
  end

  def list_questions
    @exam_group = OnlineExamGroup.find(params[:exam_id])
    question_format = params[:question_format]
    subject_code = params[:subject_code]
    course = Course.find(params[:course_id])
    if question_format == "descriptive"
      @questions = OnlineExamQuestion.paginate(:page=>params[:page],:per_page=>20,:conditions=>{:question_format=>"descriptive",:subject_id=>Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),subject_code)},:order=>"created_at DESC")
      @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>{:question_format=>"descriptive",:subject_id=>Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),subject_code)}).collect(&:id)
    else
      @questions = OnlineExamQuestion.paginate(:page=>params[:page],:per_page=>20,:conditions=>["(question_format is NULL or question_format = 'objective') AND subject_id IN (?)",Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),subject_code).collect(&:id)],:order=>"created_at DESC")
      @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>["(question_format is NULL or question_format = 'objective') AND subject_id IN (?)",Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),subject_code).collect(&:id)]).collect(&:id)
    end
    render :update do|page|
      page.replace_html "question-list",:partial=>"questions_to_import", :locals=>{:questions=>@questions, :assigned_questions=>@assigned_questions}
      unless @questions.empty?
        if @assigned_questions.include?(@questions.first.id)
          page.replace_html "right-panel", :partial=>"question_details", :locals=>{:question=>@questions.first,:answers=>@questions.first.assigned_answers(@exam_group.id),:marks=>@questions.first.marks_assigned(@exam_group.id),:exam_group=>@exam_group}
        else
          page.replace_html "right-panel", :partial=>"import_form", :locals=>{:question=>@questions.first,:answers=>@questions.first.assigned_answers(@exam_group.id),:group_question=>OnlineExamGroupsQuestion.new(:online_exam_group_id=>@exam_group.id,:online_exam_question_id=>@questions.first.id)}
        end
      else
        page.replace_html "right-panel", :text=>""
      end
      page.replace_html "hidden-fields", :text=>"<input id='page_number' type='hidden' value='1' name='page_number'>
        <input id='last_page' type='hidden' value='0' name='last_page'>"
    end
  end

  def update_question_list
    @exam_group = OnlineExamGroup.find(params[:exam_id])
    if params[:course_id]=="0"
      if params[:question_format]=="descriptive"
        @questions = OnlineExamQuestion.paginate(:page=>params[:page],:per_page=>20,:conditions=>["question_format = 'descriptive' AND subject_id is NULL"],:order=>"created_at DESC")
        @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>["question_format = 'descriptive' AND subject_id is NULL"]).collect(&:id)
      else
        @questions = OnlineExamQuestion.paginate(:page=>params[:page],:per_page=>20,:conditions=>["(question_format is NULL or question_format = 'objective') AND subject_id is NULL"],:order=>"created_at DESC")
        @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>["(question_format is NULL or question_format = 'objective') AND subject_id is NULL"]).collect(&:id)
      end
    else
      course = Course.find(params[:course_id])
      subject_code = params[:subject_code]
      if params[:question_format] == "descriptive"
        @questions = OnlineExamQuestion.paginate(:page=>params[:page],:per_page=>20,:conditions=>{:question_format=>"descriptive",:subject_id=>Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),subject_code)},:order=>"created_at DESC")
        @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>{:question_format=>"descriptive",:subject_id=>Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),subject_code)}).collect(&:id)
      else
        @questions = OnlineExamQuestion.paginate(:page=>params[:page],:per_page=>20,:conditions=>["(question_format is NULL or question_format = 'objective') AND subject_id IN (?)",Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),subject_code).collect(&:id)],:order=>"created_at DESC")
        @assigned_questions = @exam_group.online_exam_questions.all(:conditions=>["(question_format is NULL or question_format = 'objective') AND subject_id IN (?)",Subject.find_all_by_batch_id_and_code(course.batches.collect(&:id),subject_code).collect(&:id)]).collect(&:id)
      end
    end
    render :update do|page|
      page.replace_html "question-list",:partial=>"questions_to_import", :locals=>{:questions=>@questions, :assigned_questions=>@assigned_questions}
      unless @questions.empty?
        if @assigned_questions.include?(@questions.first.id)
          page.replace_html "right-panel", :partial=>"question_details", :locals=>{:question=>@questions.first,:answers=>@questions.first.assigned_answers(@exam_group.id),:marks=>@questions.first.marks_assigned(@exam_group.id),:exam_group=>@exam_group}
        else
          page.replace_html "right-panel", :partial=>"import_form", :locals=>{:question=>@questions.first,:answers=>@questions.first.assigned_answers(@exam_group.id),:group_question=>OnlineExamGroupsQuestion.new(:online_exam_group_id=>@exam_group.id,:online_exam_question_id=>@questions.first.id)}         
        end
      else
        page.replace_html "right-panel", :text=>""
      end
      page.replace_html "hidden-fields", :text=>"<input id='page_number' type='hidden' value='1' name='page_number'>
        <input id='last_page' type='hidden' value='0' name='last_page'>"
    end
  end

  def edit_question
    @question = OnlineExamQuestion.find(params[:id])
    @exam_group=OnlineExamGroup.find(params[:group_id])
    if @exam_group.has_attendence or @question.has_other_exams?
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller=>:user,:action=>:dashboard
    else
      assigned_row = OnlineExamGroupsQuestion.find_by_online_exam_group_id_and_online_exam_question_id(@exam_group.id,@question.id)
      @question.assigned_mark = assigned_row.mark
      if request.post? and @question.update_attributes(params[:question])
        assigned_row.update_attributes(:mark=>params[:question][:assigned_mark])
        flash[:notice]="#{t('flash_ques_update')}"
        redirect_to :action=>:exam_details, :id=>@exam_group.id
      end
    end
  end

  def delete_question
    @question = OnlineExamQuestion.find(params[:id])
    exam_group = OnlineExamGroup.find(params[:group_id])
    if exam_group.has_attendence
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller=>:user,:action=>:dashboard
    else
      assigned_row = OnlineExamGroupsQuestion.find_by_online_exam_group_id_and_online_exam_question_id(exam_group.id,@question.id)
      assigned_row.destroy
      if @question.online_exam_groups_questions.empty?
        @question.destroy
      end
      flash[:notice]= "#{t('flash_ques_delete')}"
      redirect_to :action=>:exam_details, :id=>exam_group
    end
  end

  def edit_exam_option
    @option = OnlineExamOption.find(params[:id])
    @exam_group=OnlineExamGroup.find(params[:group_id])
    unless @exam_group.has_attendence or @option.assigned_to_other_exams(@exam_group.id)
      if request.post? and @option.update_attributes(params[:option])
        flash[:notice]="#{t('flash_option_update')}"
        redirect_to :action=>:exam_details, :id=>@exam_group.id
      end
    else
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end

  def delete_exam_option
    @option = OnlineExamOption.find(params[:id])
    @exam_group = OnlineExamGroup.find(params[:group_id])
    assigned_row = OnlineExamGroupsQuestion.find_by_online_exam_group_id_and_online_exam_question_id(@exam_group.id,@option.online_exam_question_id)
    answers = assigned_row.answer_ids
    if answers.count > 2
      answers.delete(@option.id)
      assigned_row.update_attributes(:answer_ids=>answers)
      flash[:notice] = "#{t('flash_option_delete')}"
      redirect_to :action=>:exam_details, :id=>@exam_group.id
    else
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller=>:user,:action=>:dashboard
    end
  end

  def add_extra_question
    @exam_group = OnlineExamGroup.find(params[:id])
    @online_exam_question = OnlineExamQuestion.new
    @exam_group.option_count.to_i.times { @online_exam_question.online_exam_options.build }
    if request.post?
      @online_exam_question = OnlineExamQuestion.new(params[:online_exam_question])
      @online_exam_question.online_exam_group_id = @exam_group.id
      if @online_exam_question.save
        redirect_to :action=>:exam_details, :id=>@exam_group.id
      end
    end
  end

  def rearrange_questions
    @exam_group = OnlineExamGroup.find(params[:id])
    #@questions = @exam_group.online_exam_questions
    @question_positions = @exam_group.online_exam_groups_questions.paginate(:page=>params[:page],:per_page=>8,:order=>"position ASC",:include=>:online_exam_question)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def randomize_question_order
    if params[:exam_group]
      @exam_group = OnlineExamGroup.find_by_id(params[:exam_group][:group_id].to_i)
      if params[:exam_group][:randomized].to_i==1
        @exam_group.randomize_questions = true
      else
        @exam_group.randomize_questions = false
      end
      if @exam_group.save
        render :text=>t('updated')
      else
        render :text=>t('not_updated')
      end
    end
  end

  def update_question_positions
    if params[:exam_group]
      @exam_group = OnlineExamGroup.find_by_id(params[:exam_group][:exam_group_id].to_i)
      assigned_questions = @exam_group.online_exam_groups_questions.all(:order=>"position ASC")
      rearranged_question = assigned_questions.find_by_online_exam_question_id(params[:exam_group][:question_id].to_i)
      unless params[:exam_group][:next_question_id].to_i == 0
        next_question = assigned_questions.find_by_online_exam_question_id(params[:exam_group][:next_question_id].to_i)
      end
      prev_next_question = assigned_questions[(assigned_questions.index(rearranged_question))+1]
      unless next_question.present?
        last_position = assigned_questions.last.position
        affected_questions = assigned_questions.select{|s| s.position > rearranged_question.position}
        affected_questions.each do|a|
          unless a.id == rearranged_question.id
            a.position = a.position - 1
            a.save
          end
        end      
        rearranged_question.position = last_position
        rearranged_question.save
      else
        if prev_next_question.nil?
          curr_position = next_question.position
          affected_questions = assigned_questions.select{|s| s.position >= next_question.position}
          affected_questions.each do|a|
            unless a.id == rearranged_question.id
              a.position = a.position + 1
              a.save
            end
          end
          rearranged_question.position = curr_position
          rearranged_question.save
        else
          if prev_next_question.position > next_question.position
            curr_position = next_question.position
            affected_questions = assigned_questions.select{|s| (s.position < prev_next_question.position) and (s.position >= next_question.position)}
            affected_questions.each do|a|
              unless a.id == rearranged_question.id
                a.position = a.position + 1
                a.save
              end
            end
            rearranged_question.position = curr_position
            rearranged_question.save
          else
            curr_position = assigned_questions[(assigned_questions.index(next_question))-1].position
            affected_questions = assigned_questions.select{|s| (s.position >= prev_next_question.position) and (s.position < next_question.position)}
            affected_questions.each do|a|
              unless a.id == rearranged_question.id
                a.position = a.position - 1
                a.save
              end
            end
            rearranged_question.position = curr_position
            rearranged_question.save
          end
        end
      end
      render :text=>t('rearranged')
    else
      render :text=>t('no_params_found')
    end
  end

  def publish
    @exam_group = OnlineExamGroup.find(params[:id])
    unless @exam_group.online_exam_questions.blank?
      if @exam_group.exam_format == "hybrid"
        result_published=false
      else
        result_published=true
      end
      if @exam_group.end_date<Date.today
        flash[:notice] = "#{t('online_exam.the_exam_has_ended')}"
      else
        if @exam_group.update_attributes(:is_published=>true,:result_published=>result_published)
          flash[:notice] = "#{t('online_exam.exam_published')}"
          body = "#{t('schedule_for_online_exam')} <b>#{@exam_group.name}</b> #{t('has_been_published')}"
          inform(@exam_group.students.collect(&:user_id),body,'Event-Examination')
        end
      end
    else
      flash[:notice] = "#{t('online_exam.sorry_cannot_publish_an_exam_without_questions_please_add_minimum_one_question')}"
    end
    redirect_to :action=>"exam_details",:id=>@exam_group.id
  end

  def publish_exam
    @exam_group = OnlineExamGroup.find(params[:id])
    unless @exam_group.online_exam_questions.blank? or @exam_group.end_date<Date.today
      if @exam_group.exam_format == "hybrid"
        result_published=false
      else
        result_published=true
      end
      @exam_group.update_attributes(:is_published=>true,:result_published=>result_published)
      body = "#{t('schedule_for_online_exam')} <b>#{@exam_group.name}</b> #{t('has_been_published')}"
      inform(@exam_group.students.collect(&:user_id),body,'Event-Examination')
    end

    @batch = Batch.find_by_id(params[:batch_id])
    @exams=[]
    if @batch.present?
      @exams = @batch.online_exam_groups.paginate(:page => params[:page], :per_page => 20 ,:conditions=>[ "is_deleted = FALSE"], :include=> :online_exam_attendances,:order=>"id DESC")
      #@exams = OnlineExamGroup.paginate(:page => params[:page], :per_page => 20 ,:conditions=>[ "batch_id = '#{params[:batch_id]}'"], :include=> :online_exam_attendances,:order=>"id DESC")
    end

    #@exams = OnlineExamGroup.paginate(:page => params[:page], :per_page => 20, :conditions=>[ "batch_id = '#{@exam_group.batch_id}'"], :order=>"id DESC")
    if @exam_group.end_date<Date.today
      if @exam_group.online_exam_questions.blank?
        render :update do |page|
          page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('online_exam.sorry_cannot_publish_an_exam_without_questions_please_add_minimum_one_question')}</p>"
        end
      else
        render :update do |page|
          page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('online_exam.the_exam_has_ended')}</p>"
        end
      end
    else
      unless @exam_group.online_exam_questions.blank?
        render :update do |page|
          page.replace_html 'exam-list', :partial=>'active_exam_list', :locals=>{:batch_id=>params[:batch_id]}
          page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('online_exam.exam_published')}</p>"
        end
      else
        render :update do |page|
          page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('online_exam.sorry_cannot_publish_an_exam_without_questions_please_add_minimum_one_question')}</p>"
        end
      end
    end
  end

  def view_result
    @batches = Batch.active
  end

  def update_exam_list
    @batch = Batch.find(params[:batch_id])
    @exams =@batch.online_exam_groups.paginate(:conditions=>['is_published = ? AND result_published = ?',1,1] ,:per_page=>20,:page=>params[:page],:order=>"id DESC")
    render :update do |page|
      page.replace_html 'exam-list', :partial=>'exam_list'
    end
  end

  def exam_result
    @exam_group = OnlineExamGroup.find(params[:id])
    @batch = Batch.find(params[:batch_id])
    @attendance = @exam_group.online_exam_attendances.paginate(:include=>[:student,:batch],:per_page=>20,:page=>params[:page],:conditions=>["online_exam_attendances.batch_id=? || online_exam_attendances.batch_id IS ?",@batch.id,nil],:order=>"students.first_name ASC")
    @attendance.reject!{|s|s.student.nil?}
  end
    
  def exam_result_pdf
    @exam_group = OnlineExamGroup.find(params[:id])
    @batch = Batch.find(params[:batch_id])
    @attendance = @exam_group.online_exam_attendances.all(:include=>[:student,:batch],:conditions=>["online_exam_attendances.batch_id=? || online_exam_attendances.batch_id IS ?",@batch.id,nil],:order=>"students.first_name ASC")
    @attendance.reject!{|s|s.student.nil?}
    render :pdf=>'Online_exam_result'
  end

  def reset_exam
    @batches = Batch.active.all(:include=>:course)
  end

  def update_student_exam
    @batch = Batch.find(params[:batch_id])
    @exams = @batch.online_exam_groups.all(:conditions=>"is_published = 1",:order=>"id DESC")
    render :update do |page|
      page.replace_html 'exam-list', :partial=>'student_exam_list'
    end
  end

  def update_student_list
    @exam_group = OnlineExamGroup.find(params[:id])
    @batch = Batch.find(params[:batch_id])
    @attendance = @exam_group.online_exam_attendances.all(:include=>[:student])
    @attendance.reject!{|s|s.student.nil? or s.student.batch_id!=@batch.id}
    unless @attendance.empty?
      render :update do |page|
        page.replace_html 'student-list', :partial=>'students_list'
      end
    else
      render :update do |page|
        page.replace_html 'student-list', :text=>"<p class='flash-msg'>#{t('online_exam.no_student_attended_this_exam')}</p>"
      end
    end
  end

  def update_reset_exam
    unless request.get?
      unless params[:att_id].blank?
        ActiveRecord::Base.transaction do
          OnlineExamAttendance.soft_delete(params[:att_id])
        end
        flash[:notice]="#{t('exam_reset_successful_for_selected_students')}"
        redirect_to :action=>:reset_exam
      else
        flash[:notice]="#{t('sorry_no_students_selected')}"
        redirect_to :action => :index
      end
    else
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  private
  def check_updating_status
    config_row = Configuration.find_by_config_key("ModifyingOnlineExam")
    unless config_row.nil?
      if config_row.config_value=="1"
        flash[:notice] = "An update is going on for Online Examination module which once completed will provide you with an enhanced version which includes some exciting features. Please wait for the update to complete."
        redirect_to :controller => "user", :action => "dashboard"
      end
    end
  end
end
