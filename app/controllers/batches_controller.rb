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

class BatchesController < ApplicationController
  lock_with_feature :cce_enhancement
  before_filter :init_data,:except=>[:assign_tutor,:update_employees,:assign_employee,:remove_employee,:batches_ajax,:batch_summary]
  before_filter :login_required
  filter_access_to :all, :except=>[:show,:batches_ajax,:batch_summary,:list_batches,:tab_menu_items,:get_tutors,:get_batch_span]
  filter_access_to :show,:batches_ajax,:batch_summary,:list_batches,:tab_menu_items,:get_tutors,:get_batch_span,:attribute_check=>true, :load_method => lambda { current_user }

  def index
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
    end
  end

  def new
    @batch = @course.batches.build
    @academic_years = AcademicYear.all
  end

  def create
    @batch = @course.batches.build(params[:batch])

    if @batch.save
      flash[:notice] = "#{t('flash1')}"
      unless params[:import_subjects].nil?
        msg = []
        msg << "<ol>"
        course_id = @batch.course_id
        @previous_batch = Batch.find(:first,:order=>'id desc', :conditions=>"batches.id < '#{@batch.id }' AND batches.is_deleted = 0 AND course_id = ' #{course_id }'",:joins=>"INNER JOIN subjects ON subjects.batch_id = batches.id  AND subjects.is_deleted = 0")
        unless @previous_batch.blank?
          subjects = Subject.find_all_by_batch_id(@previous_batch.id,:conditions=>'is_deleted=false')
          subjects.each do |subject|
            if subject.elective_group_id.nil?
              Subject.create(:name=>subject.name,:code=>subject.code,:batch_id=>@batch.id,:no_exams=>subject.no_exams,
                :max_weekly_classes=>subject.max_weekly_classes,:elective_group_id=>subject.elective_group_id,:credit_hours=>subject.credit_hours,:is_deleted=>false,:is_asl=>subject.is_asl,:asl_mark=>subject.asl_mark,:is_sixth_subject=>subject.is_sixth_subject)
            else
              elect_group_exists = ElectiveGroup.find_by_name_and_batch_id(ElectiveGroup.find(subject.elective_group_id).name,@batch.id)
              if elect_group_exists.nil?
                elect_group = ElectiveGroup.create(:name=>subject.elective_group.name,
                  :batch_id=>@batch.id,:is_deleted=>false,:is_sixth_subject=>subject.elective_group.is_sixth_subject)
                Subject.create(:name=>subject.name,:code=>subject.code,:batch_id=>@batch.id,:no_exams=>subject.no_exams,
                  :max_weekly_classes=>subject.max_weekly_classes,:elective_group_id=>elect_group.id,:credit_hours=>subject.credit_hours,:is_deleted=>false)
              else
                Subject.create(:name=>subject.name,:code=>subject.code,:batch_id=>@batch.id,:no_exams=>subject.no_exams,
                  :max_weekly_classes=>subject.max_weekly_classes,:elective_group_id=>elect_group_exists.id,:credit_hours=>subject.credit_hours,:is_deleted=>false)
              end
            end
            msg << "<li>#{subject.name}</li>"
          end
          msg << "</ol>"
        else
          msg = nil
          flash[:no_subject_error] = "#{t('flash7')}"
        end
      end
      flash[:subject_import] = msg unless msg.nil?
      err = ""
      err1 = "<p style = 'font-size:16px'>#{t('following_pblm_occured_while_saving_the_batch')}</p>"
      err1 += "<ul>"
      unless params[:import_fees].nil?
        fee_msg = []
        course_id = @batch.course_id
        @previous_batch = Batch.find(:first, :order => 'id desc',
          :conditions => "batches.id < '#{@batch.id }' AND batches.is_deleted = 0 AND course_id = ' #{course_id } ' AND batches.is_active=true",
          :joins => "INNER JOIN category_batches ON category_batches.batch_id = batches.id
                                                INNER JOIN finance_fee_categories
                                                        ON finance_fee_categories.id=category_batches.finance_fee_category_id AND
                                                           finance_fee_categories.is_deleted = 0 AND is_master= 1")                                                 
        unless @previous_batch.blank?
          fee_msg << "<ol>"
          categories = CategoryBatch.find_all_by_batch_id(@previous_batch.id, :joins=> :finance_fee_category, 
            :conditions=>{:finance_fee_categories=>{:is_deleted=>false}}, :include => :finance_fee_category)
          fy_id = current_financial_year_id
          categories.each do |c|
            category = c.finance_fee_category
            particulars = FinanceFeeParticular.find(:all,:conditions=>"(receiver_type='Batch' or receiver_type='StudentCategory') and (batch_id=#{@previous_batch.id}) and (finance_fee_category_id=#{c.finance_fee_category_id})")

            #particulars = c.finance_fee_category.fee_particulars.all(:conditions=>"receiver_type='Batch' or receiver_type='StudentCategory'")
            particulars.reject!{|pt|pt.deleted_category}
            fee_discounts = FeeDiscount.find(:all,:conditions=>"(receiver_type='Batch' or receiver_type='StudentCategory') and (batch_id=#{@previous_batch.id}) and (finance_fee_category_id=#{c.finance_fee_category_id})")

            #category_discounts = StudentCategoryFeeDiscount.find_all_by_finance_fee_category_id(c.id)
            unless particulars.blank? and fee_discounts.blank?
              old_fee_category = category
              if old_fee_category.financial_year_id.to_i != fy_id.to_i
                exclude_attrs = ['id', 'created_at', 'updated_at', 'batch_id', 'financial_year_id']
                category = new_fee_category = FinanceFeeCategory.new(old_fee_category.attributes.except(*exclude_attrs))
                category.financial_year_id = fy_id.present? ? fy_id : 0
                # multi configs
                category.skip_multi_configs_on_errors = true
                category.account = old_fee_category.fee_account
                category.receipt_set = old_fee_category.receipt_number_set
                category.template = old_fee_category.fee_receipt_template

                category.save
              end
              new_category = CategoryBatch.new(:batch_id => @batch.id, :finance_fee_category_id => category.id)
              if new_category.save
                fee_msg << "<li>#{c.finance_fee_category.name}</li>"
                particulars.each do |p|
                  receiver_id=p.receiver_type=='Batch' ? @batch.id : p.receiver_id
                  exclude_attrs = ['id', 'created_at', 'updated_at', 'batch_id', 'receiver_id', 'finance_fee_category_id']
                  particular_attrs = p.attributes.except(*exclude_attrs)
                  new_particular = FinanceFeeParticular.new(particular_attrs)
                  new_particular.batch_id = @batch.id
                  new_particular.receiver_id = receiver_id

                  new_particular.finance_fee_category_id = category.id
                  unless new_particular.save
                    err += "<li> #{t('particular')} #{p.name} #{t('import_failed')}.</li>"
                  end
                end
                fee_discounts.each do |disc|
                  exclude_attrs = ['id', 'created_at', 'updated_at', 'batch_id', 'finance_fee_category_id', 'type']
                  discount_attributes = disc.attributes.
                    except(*exclude_attrs).merge({:batch_id => @batch.id,
                      :finance_fee_category_id => category.id })
                  discount_attributes = discount_attributes.merge({:receiver_id => @batch.id}) if disc.receiver_type=='Batch'
                  fee_discount = FeeDiscount.new(discount_attributes)
                  unless fee_discount.save
                    err += "<li> #{t('discount')} #{disc.name} #{t('import_failed')}.</li>"
                  end
                end
              else

                err += "<li>  #{t('category')} #{c.finance_fee_category.name}1 #{t('import_failed')}.</li>"
              end
            else

              err += "<li>  #{t('category')} #{c.finance_fee_category.name}2 #{t('import_failed')}.</li>"

            end
          end
          fee_msg << "</ol>"
          @fee_import_error = false
          flash[:fees_import_error] =nil
        else
          flash[:fees_import_error] =t('no_fee_import_message')
          @fee_import_error = true
        end
      end
      err2 = "</ul>"
      flash[:warn_notice] =  err1 + err + err2 unless err.empty?
      flash[:fees_import] =  fee_msg unless fee_msg.nil?

      redirect_to [@course, @batch]
    else
      @academic_years = AcademicYear.all
      @grade_types=[]
      gpa = Configuration.find_by_config_key("GPA").config_value
      if gpa == "1"
        @grade_types << "GPA"
      end
      cwa = Configuration.find_by_config_key("CWA").config_value
      if cwa == "1"
        @grade_types << "CWA"
      end
      render 'new'
    end
  end

  def edit
    @academic_years = AcademicYear.all
    @associated_assessments_present = @batch.assessment_group_batches.present?
  end

  def update
    if @batch.update_attributes(params[:batch])
      flash[:notice] = "#{t('flash2')}"
      redirect_to [@course, @batch]
    else
      @academic_years = AcademicYear.all
      @associated_assessments_present = @batch.assessment_group_batches.present?
      render 'edit'
      #flash[:notice] ="#{t('flash3')}"
      #redirect_to  edit_course_batch_path(@course, @batch)
    end
  end

  #  def load_batch
  #    redirect_to :show
  #  end

  def show
    @config=Configuration.find_by_config_key('StudentAttendanceType')
    @course = @batch.course if @batch.present?
    if current_user.admin? or current_user.privileges.include?(Privilege.find_by_name('ManageCourseBatch'))
      @courses=Course.active
      if @batch.present?
        @tutors=@batch.employees
        @students = Student.active.paginate(:conditions=>["batch_id=?",@batch.id],:per_page=>20,:page=>params[:page],:order=>"CONCAT(students.first_name, ' ' , students.middle_name, ' ', students.last_name) ASC")
        @student_count=@batch.students.active.count
        @batches=@batch.course.batches.active
      end
    elsif current_user.can_view_results?
      @batches=current_user.employee_record.batches.all(:include => :course)
      if @batch.present?
        @tutors=@batch.employees
        @students = Student.active.paginate(:conditions=>["batch_id=?",@batch.id],:per_page=>20,:page=>params[:page], :order=>"CONCAT(students.first_name, ' ' , students.middle_name, ' ', students.last_name) ASC")
        @student_count=@batch.students.active.count
      end
    end
  end

  def list_batches
    if current_user.admin? or current_user.privileges.include?(Privilege.find_by_name('ManageCourseBatch'))
      unless params[:course_id]==""
        course=Course.find(params[:course_id])
        @batches=course.batches.active
        render :update do |page|
          page.replace_html 'batch_area',:partial=>'list_batches'
          page.replace_html 'display_area', :partial => 'select_batch'
          page.replace_html 'batch_tutor_section', ''
          page.replace_html 'batch_mini_details', ''


        end
      else
        render :update do |page|
          page.replace_html 'batch_area',''
          page.replace_html 'display_area', :partial => 'select_batch'
          page.replace_html 'batch_tutor_section', ''
          page.replace_html 'batch_mini_details', ''
        end
      end
    end
  end

  def get_tutors
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id])
      @tutors=@batch.employees
    end
    render :partial=>'batch_tutors'
  end

  def get_batch_span
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id])
    end
    render :partial=>'batch_span'
  end

  def batch_summary
    attendance_lock = AttendanceSetting.is_attendance_lock
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id])
      @course=@batch.course
      @requested_summary_id=params[:request_id].to_i
      case @requested_summary_id
      when 1
        @students = Student.active.paginate(:conditions=>["batch_id=?",@batch.id],:per_page=>20,:page=>params[:page],:order=>"CONCAT(students.first_name, ' ' , students.middle_name, ' ', students.last_name) ASC")
        @student_count=@batch.students.active.count
        render :partial=>'students_summary'
      when 2
        @date = params[:date].nil? ? Date.today : params[:date]
        absentees = Attendance.all(:joins => :student, :conditions => {:batch_id => @batch.id,:month_date => @date})
        if attendance_lock
          academic_days = MarkedAttendanceRecord.dailywise_working_days(@batch.id)
          absentees = absentees.select{|a| academic_days.include?(a.month_date)}
          saved_date = academic_days.include?(@date.to_date)
        end
        @students = Student.paginate(:per_page => 20,:page => params[:page],:joins => :attendances,:conditions => ["attendances.batch_id = ? and attendances.month_date = ?",params[:batch_id],@date]) if !attendance_lock || (attendance_lock && saved_date)
        @students = @students.present? ? @students : []
        if !attendance_lock || (attendance_lock && academic_days.include?(@date.to_date))
          @absentees_count = absentees.to_a.reject{|ct| ct.attendance_label.try(:attendance_type) == "Late"}.count
          @batch_students_count=@batch.students.count
          @present_students_count=@batch_students_count-@absentees_count
          @attendance_percentage=@batch_students_count == 0 ? 0 : ((@present_students_count * 100 ) / @batch_students_count)
        else
          @absentees_count = '-'
          @batch_students_count= '-'
          @present_students_count= '-'
          @attendance_percentage= '-'
        end
        render :partial=>'attendance_summary'
      when 3
        @subjects_count=@batch.subjects.count
        @employees_count=@batch.employees_subjects.collect(&:employee_id).uniq.count
        tt_ids=@batch.time_table_class_timings.collect(&:timetable_id)
        @timetables=Timetable.all(:conditions=>["id in (?)",tt_ids],:order => "start_date DESC") if tt_ids.present?
        @timetable_id=params[:timetable_id]||@timetables.first.id if @timetables.present?
        if @timetable_id.present?
          @timetable_entries=TimetableEntry.find_all_by_batch_id_and_timetable_id(@batch.id,@timetable_id)
          @elective_subjects=ElectiveGroup.all(:select=>"elective_groups.*,subjects.id as sid,subjects.name as sname,employees.first_name as ename",
            :joins=>"LEFT OUTER JOIN `subjects` ON subjects.elective_group_id = elective_groups.id and subjects.school_id = #{@batch.school_id}
                     LEFT OUTER JOIN employees_subjects on employees_subjects.subject_id=subjects.id
                     LEFT OUTER JOIN employees on employees_subjects.employee_id=employees.id",
            :conditions=>["elective_groups.batch_id = ? and subjects.is_deleted=false",@batch.id],
            :include=>[:subjects=>:employees_subjects])
          @elective_sub_counts=ElectiveGroup.count(:joins=>"LEFT OUTER JOIN timetable_entries tte on tte.entry_id = elective_groups.id and tte.entry_type = 'ElectiveGroup'", :conditions=>["elective_groups.batch_id=? and tte.timetable_id=?",@batch.id,@timetable_id],:group => "elective_groups.id")
          @grouped_elective_subjects=@elective_subjects.to_a.group_by{|s| s.id}
          @grouped_elective_employees=@elective_subjects.to_a.group_by{|s| s.ename}
          @subject_wise_normal=@batch.subject_wise_normal_subjects(@timetable_id)
          @employee_wise_normal=@batch.employee_wise_normal_subjects(@timetable_id)
          @elelctive_employees_hash=@batch.employee_wise_electives_timetable_assignments(@timetable_id)
        end
        unless params[:timetable_id].present?
          render :partial=>'subject_employee_summary'
        else
          unless params[:link_id].present?
            render :update do |page|
              page.replace_html 'exam_items' ,:partial=>'exam_items'
              page.replace_html 'highlight', :partial=>'subject_teacher_highlights'
            end
          else
            render :partial=>'exam_items',:link_id=>params[:link_id]
          end
        end
      when 4
        date=params[:date]||Date.today
        @date=date.to_date
        @tt_entries=@batch.fetch_timetable_summary(@date)
        @calender_events=@batch.fetch_activities_summary(@date)
        render :partial=>'timetable_activities_summary'
      when 5
        @exam_groups=ExamGroup.paginate(:select=>"exam_groups.*,min(exams.start_time) as min_start,max(exams.end_time) as max_end",:conditions=>["batch_id=?",@batch.id],:per_page=>20,:page=>params[:page],:joins=>:exams,:group=>:exam_group_id)
        @new_exams_count=@batch.exam_groups.count(:conditions=>["is_published=? and result_published=?",false,false])
        @published_exams_count=@batch.exam_groups.all(:select=>"exam_groups.*,min(exams.start_time) as min_start,max(exams.end_time) as max_end",:having=>["is_published=? and result_published = ? and min_start > ? and max_end > ?",true,false,Time.now,Time.now],:joins=>:exams,:group=>:exam_group_id).count
        @results_published_exams_count=@batch.exam_groups.count(:conditions=>["is_published=? and result_published=?",true,true])
        @ongoing_exams_count=@batch.exam_groups.all(:select=>"exam_groups.*,min(exams.start_time) as min_start,max(exams.end_time) as max_end",:having=>["is_published=? and result_published= ? and min_start < ? and max_end > ?",true,false,Time.now,Time.now],:joins=>:exams,:group=>:exam_group_id).count
        @finished_exams_count=@batch.exam_groups.all(:select=>"exam_groups.*,min(exams.start_time) as min_start,max(exams.end_time) as max_end",:having=>["is_published =? and result_published=?  and min_start < ? and max_end < ?",true,false,Time.now,Time.now],:joins=>:exams,:group=>:exam_group_id).count
        render :partial=>'examination_summary'
      else

      end
    else
      render :partial=>'select_batch'
    end
  end

  def tab_menu_items
    if params[:batch_id].present?
      @batch=Batch.find(params[:batch_id])
      @course=@batch.course
      if params[:is_tutor] && params[:is_tutor]=='true'
        render :partial=>'tab_menu_items_for_tutor'
      else
        render :partial=>'tab_menu_items'
      end
    else
      render :text=>""
    end
  end

  def destroy
    if @batch.students.empty? and @batch.subjects.empty?
      @batch.inactivate
      flash[:notice] = "#{t('flash4')}"
      redirect_to @course
    else
      flash[:warn_notice] = "<p>#{t('batches.flash5')}</p>" unless @batch.students.empty?
      flash[:warn_notice] = "<p>#{t('batches.flash6')}</p>" unless @batch.subjects.empty?
      redirect_to [@course, @batch]
    end
  end

  def assign_tutor
    @batch = Batch.find_by_id(params[:id])
    if @batch.nil?
      page_not_found
    else
      @assigned_employee=@batch.employees
      @departments = EmployeeDepartment.ordered
    end
  end

  def update_employees
    @employees = Employee.find_all_by_employee_department_id(params[:department_id]).sort_by{|e| e.full_name.downcase}
    @batch = Batch.find_by_id(params[:batch_id])
    @assigned_employee=@batch.employees
    render :update do |page|
      page.replace_html 'employee-list', :partial => 'employee_list'
    end
  end

  def assign_employee
    @batch = Batch.find_by_id(params[:batch_id])
    @employees = Employee.find_all_by_employee_department_id(params[:department_id]).sort_by{|e| e.full_name.downcase}
    @batch.employee_ids=@batch.employee_ids << params[:id]
    @assigned_employee=@batch.employees
    render :update do |page|
      page.replace_html 'employee-list', :partial => 'employee_list'
      page.replace_html 'tutor-list', :partial => 'assigned_tutor_list'
      page.replace_html 'flash', :text=>"<p class='flash-msg'>#{t('tutor_assigned_successfully')}</p>"
    end
  end

  def remove_employee
    @batch = Batch.find_by_id(params[:batch_id])
    @employees = Employee.find_all_by_employee_department_id(params[:department_id]).sort_by{|e| e.full_name.downcase}
    @batch.employees.delete(Employee.find params[:id])
    @assigned_employee = @batch.employees
    render :update do |page|
      page.replace_html 'employee-list', :partial => 'employee_list'
      page.replace_html 'tutor-list', :partial => 'assigned_tutor_list'
      page.replace_html 'flash', :text=>"<p class='flash-msg'>#{t('tutor_removed_successfully')}</p>"
    end
  end

  def batches_ajax
    if request.xhr?
      @course = Course.find_by_id(params[:course_id]) unless params[:course_id].blank?
      @batches = @course.batches.active if @course
      if params[:type]=="list"
        render :partial=>"list"
      end
    end
  end
  private
  def init_data
    @batch = Batch.find_by_id params[:id] if ['show', 'edit', 'update', 'destroy'].include? action_name
    @course = Course.find_by_id params[:course_id]
  end
end
