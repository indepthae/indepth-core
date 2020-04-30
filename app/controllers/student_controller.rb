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

class StudentController < ApplicationController
  lock_with_feature :finance_multi_receipt_data_updation, :only => [:mobile_fee_details]
  before_filter :login_required
  filter_access_to :all, :except=>[:reports,:profile]
  filter_access_to [:reports,:profile], :attribute_check=>true, :load_method => lambda { Student.find(params[:id]).user}
  before_filter  :set_precision
  before_filter :protect_other_student_data, :except =>[:show]
  protect_from_forgery :except => [:fee_details]
  before_filter :feature_access, :only => [:my_subjects]
  before_filter :find_student, :only => [
    :academic_report, :academic_report_all, :admission3, :change_to_former,
    :delete, :edit, :add_guardian, :email, :remove, :reports,
    :guardians, :academic_pdf,:show_previous_details,:fees,:fee_details
  ]
  check_request_fingerprint :admission1
  helper :all


  def academic_report_all
    @user = current_user
    @prev_student = @student.previous_student
    @next_student = @student.next_student
    @course = @student.course
    @examtypes = ExaminationType.find( ( @course.examinations.collect { |x| x.examination_type_id } ).uniq )

    @graph = open_flash_chart_object(965, 350, "/student/graph_for_academic_report?course=#{@course.id}&student=#{@student.id}")
    @graph2 = open_flash_chart_object(965, 350, "/student/graph_for_annual_academic_report?course=#{@course.id}&student=#{@student.id}")
  end

  def admission1
    @student = Student.new(params[:student])
    @selected_value = Configuration.default_country
    @application_sms_enabled = SmsSetting.find_by_settings_key("ApplicationEnabled")
    @last_admitted_student = User.last(:select=>"username",:conditions=>["student=?",true])
    @next_admission_no=User.next_admission_no("student")
    @config = Configuration.find_by_config_key('AdmissionNumberAutoIncrement')
    @categories = StudentCategory.active
    @batches = []
    if request.post?
      if params[:course].first.present? && params[:student][:batch_id].present?
        @roll_number_prefix = Batch.find(params[:student][:batch_id]).get_roll_number_prefix
        @selected_batch = params[:student][:batch_id]
        @selected_course = params[:course].first
        @batches = Course.find(@selected_course.to_i).batches.active
      end
      if @config.config_value.to_i == 1
        @exist = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:student][:admission_no]])
        if @exist.nil?
          @status = @student.save
        else
          @status = @student.save
        end
      else
        @status = @student.save
      end

      #      if @status
      #        if @student.batch.course.enable_student_elective_selection
      #          unless @student.batch.elective_groups.active.empty? #&& !@student.batch.subjects.select{|es| es.elective_group_id != nil}.blank?
      #            @student.batch.elective_groups.active.each do |eg|
      #              if !eg.end_date.nil? && !eg.subjects.active.empty? && eg.end_date >= Date.today
      #                end_date = eg.end_date
      #                recipients_array = [@student.user.id]
      #                content = "Electives for group #{eg.name} are available.Please select it on or before #{end_date}"
      #                links = {:target=>'choose_elective',:target_param=>'student_id'}
      #                inform(recipients_array,content,'Subject',links)
      #              end
      #            end
      #          end
      #        end
      #      end
      if @status
        #        sms_setting = SmsSetting.new()
        #        if sms_setting.application_sms_active and @student.is_sms_enabled
        #          recipients = []
        #          message = "#{t('student_admission_done_for')} #{@student.first_and_last_name}. #{t('username_is')} #{@student.admission_no}, #{t('guardian_password_is')} #{@student.admission_no}123. #{t('thanks')}"
        #          if sms_setting.student_admission_sms_active
        #            recipients.push @student.phone2 unless @student.phone2.blank?
        #          end
        #          unless recipients.empty?
        #            Delayed::Job.enqueue(SmsManager.new(message,recipients))
        #          end
        #        end
        if Configuration.find_by_config_key('EnableSibling').present? and Configuration.find_by_config_key('EnableSibling').config_value=="1"
          flash[:notice] = "#{t('flash22')}"
          redirect_to :controller => "student", :action => "admission1_2", :id => @student.id
        else
          flash[:notice] = "#{t('flash8')}"
          redirect_to :controller => "student", :action => "admission2", :id => @student.id
        end
      else
        transport_admission_data(@student) if FedenaPlugin.can_access_plugin?('fedena_transport')
      end
    end
  end

  def render_batch_list
    @batches=[]
    if params[:id].present?
      @batches = Course.find(params[:id]).batches.active
    end
    render :update do |page|
      page.replace_html 'batches_list', :partial => 'batch_list'
    end
  end

  def set_roll_number_prefix
    @batch = Batch.find(params[:id])
    @roll_number_prefix = @batch.get_roll_number_prefix
    respond_to do |fmt|
      fmt.json {render :json => {:prefix => @roll_number_prefix}}
    end
  end

  def admission1_2
    if Configuration.find_by_config_key('EnableSibling').present? and Configuration.find_by_config_key('EnableSibling').config_value=="1"
      @batches=Batch.active
      @student=Student.find(params[:id])
      @siblings=@student.siblings
     
      if request.post? and params[:sibling_no].present?
        sibling=Student.find(params[:sibling_no])
        #student=Student.find(params[:id])
        unless @student.all_siblings.present?
          @student.guardians.each do|guardian|
            guardian.user.destroy if guardian.user.present?
            guardian.destroy
          end
        else
          unless @student.all_siblings.collect(&:immediate_contact_id).include?(@student.immediate_contact_id)
            #            @student.immediate_contact.user.destroy if @student.immediate_contact.user.present?
            @student.immediate_contact.user.destroy if @student.immediate_contact.present?
          end
        end

        @student.update_attributes(:immediate_contact_id=>sibling.immediate_contact_id,:sibling_id=>sibling.sibling_id)
        #        sms_setting = SmsSetting.new()
        #        if sms_setting.application_sms_active and sms_setting.student_admission_sms_active and @student.is_sms_enabled
        #          recipients = []
        #          message = "#{t('you_are_added_as_an_emergency_contact_for')} #{@student.full_name}. #{t('your_username_is')} #{@student.immediate_contact.user.username}, #{t('guardian_password_is')} #{@student.immediate_contact.user.username}123. #{t('thanks')}"
        #          if sms_setting.parent_sms_active
        #            guardian = Guardian.find(@student.immediate_contact_id)
        #            recipients.push guardian.mobile_phone unless guardian.mobile_phone.nil?
        #          end
        #          unless recipients.empty?
        #            Delayed::Job.enqueue(SmsManager.new(message,recipients))
        #          end
        #        end
        if params[:configure].present?
          redirect_to :controller => "student", :action => "profile", :id => params[:id]
        else
          redirect_to :controller => "student", :action => "previous_data", :id => params[:id]
        end
      end
    else
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def admission2
    @student = Student.find params[:id]
    @guardian = Guardian.new(params[:guardian])
    if request.post? and @guardian.save
      redirect_to :controller => "student", :action => "admission2", :id => @student.id
    end
  end

  def admission3
    @student = Student.find(params[:id])
    @parents = @student.guardians
    if @parents.empty?
      redirect_to :controller => "student", :action => "previous_data", :id => @student.id
    end
    return if params[:immediate_contact].nil?
    if request.post?
      #      sms_setting = SmsSetting.new()
      @student = Student.update(@student.id, :immediate_contact_id => params[:immediate_contact][:contact])
      #      if sms_setting.application_sms_active and sms_setting.student_admission_sms_active and @student.is_sms_enabled
      #        recipients = []
      #        message = "#{t('you_are_added_as_an_emergency_contact_for')} #{@student.full_name}. #{t('your_username_is')} #{@student.immediate_contact.user.username}, #{t('guardian_password_is')} #{@student.immediate_contact.user.username}123. #{t('thanks')}"
      #        if sms_setting.parent_sms_active
      #          guardian = Guardian.find(@student.immediate_contact_id)
      #          recipients.push guardian.mobile_phone unless guardian.mobile_phone.nil?
      #        end
      #        unless recipients.empty?
      #          Delayed::Job.enqueue(SmsManager.new(message,recipients))
      #        end
      #      end
      if @student.batch.course.enable_student_elective_selection
        unless @student.batch.elective_groups.active.empty? #&& !@student.batch.subjects.select{|es| es.elective_group_id != nil}.blank?
          @student.batch.elective_groups.active.each do |eg|
            if !eg.end_date.nil? && !eg.subjects.active.empty? && eg.end_date >= Date.today
              end_date = eg.end_date
              recipients_array = [@student.immediate_contact.user.id]
              content = "Electives for group #{eg.name} are available.Please select it on or before #{end_date}"
              links = {:target=>'choose_elective',:target_param=>'student_id'}
              inform(recipients_array,content,"Subject",links)
            end
          end
        end
      end
      redirect_to :action => "previous_data", :id => @student.id
    end
  end

  def admission3_1
    @student = Student.find(params[:id])
    @parents = @student.guardians
    if @parents.empty?
      redirect_to :controller => "student", :action => "admission4", :id => @student.id
    end
    return if params[:immediate_contact].nil?
    if request.post?
      if @student.update_attributes(:immediate_contact_id=>params[:immediate_contact][:contact])
        #        sms_setting = SmsSetting.new()
        #        if sms_setting.application_sms_active and sms_setting.student_admission_sms_active and @student.is_sms_enabled
        #          recipients = []
        #          message = "#{t('you_are_added_as_an_emergency_contact_for')} #{@student.full_name}. #{t('your_username_is')} #{@student.immediate_contact.user.username}, #{t('guardian_password_is')} #{@student.immediate_contact.user.username}123. #{t('thanks')}"
        #          if sms_setting.parent_sms_active
        #            guardian = Guardian.find(@student.immediate_contact_id)
        #            recipients.push guardian.mobile_phone unless guardian.mobile_phone.nil?
        #          end
        #          unless recipients.empty?
        #            Delayed::Job.enqueue(SmsManager.new(message,recipients))
        #          end
        #        end
        flash[:notice] = "#{t('flash23')}"
        redirect_to :action => "profile", :id => @student.id
      else
        flash[:notice] = "#{t('flash_msg3')}"
        redirect_to :action => "profile", :id => @student.id
      end
    end
  end

  def previous_data
    @student = Student.find(params[:id])
    @previous_data = StudentPreviousData.new params[:student_previous_details]
    @previous_subject = StudentPreviousSubjectMark.find_all_by_student_id(@student)
    if request.post?
      if @previous_data.save
        redirect_to :action => "admission4", :id => @student.id
      else
        render :previous_data
      end
    else
      return
    end
  end

  def previous_data_from_profile
    @student = Student.find(params[:id])
    @previous_data = StudentPreviousData.new(params[:student_previous_details])
    @previous_subject = StudentPreviousSubjectMark.find_all_by_student_id(@student)
    if request.post?
      if @previous_data.save
        redirect_to :action => "profile", :id => @student.id
      else
        render :previous_data_from_profile
      end
    else
      return
    end
  end

  def previous_data_edit
    @student = Student.find(params[:id])
    @previous_data = StudentPreviousData.find_by_student_id(params[:id])
    unless @previous_data.nil?
      @previous_subject = StudentPreviousSubjectMark.find_all_by_student_id(@student)
      if request.post?
        if @previous_data.update_attributes(params[:previous_data])
          redirect_to :action => "show_previous_details", :id => @student.id
        else
          render :action => "previous_data_edit", :id => @student.id
        end
      end
    else
      redirect_to :action => "previous_data", :id => @student.id
    end
  end
  def previous_subject
    @student = Student.find(params[:id])
    @student_previous_subject_details=StudentPreviousSubjectMark.new
    render(:update) do |page|
      page.replace_html 'subject', :partial=>"previous_subject"
    end
  end

  def save_previous_subject
    @student_previous_subject_details = StudentPreviousSubjectMark.new params[:student_previous_subject_details]
    @student_previous_subject_details.save
    #@all_previous_subject = StudentPreviousSubjectMark.find(:all,:conditions=>"student_id = #{@previous_subject.student_id}")
  end

  def delete_previous_subject
    @previous_subject = StudentPreviousSubjectMark.find(params[:id])
    @student =Student.find(@previous_subject.student_id)
    if@previous_subject.delete
      @previous_subject=StudentPreviousSubjectMark.find_all_by_student_id(@student.id)
    end
    #@all_previous_subject = StudentPreviousSubjectMark.find(:all,:conditions=>"student_id = #{@previous_subject.student_id}")
  end

  def admission4
    @student = Student.find(params[:id])
    @student_additional_details = StudentAdditionalDetail.find_all_by_student_id(@student.id)
    @additional_fields = StudentAdditionalField.find(:all, :conditions=> "status = true", :order=>"priority ASC")
    if @additional_fields.empty?
      flash[:notice] = "#{t('flash9')} #{@student.first_name} #{@student.last_name}. #{t('new_admission_link')} <a href='/student/admission1'>Click Here</a>"
      redirect_to(:controller => "student", :action => "profile", :id => @student.id ) and return
    end
    if request.post?
      @error=false
      mandatory_fields = StudentAdditionalField.find(:all, :conditions=>{:is_mandatory=>true, :status=>true})
      mandatory_fields.each do|m|
        if params[:student_additional_details].present?
          unless params[:student_additional_details][m.id.to_s.to_sym].present?
            @student.errors.add_to_base("#{m.name} must contain atleast one selected option.")
            @error=true
          else
            if params[:student_additional_details][m.id.to_s.to_sym][:additional_info]==""
              @student.errors.add_to_base("#{m.name} cannot be blank.")
              @error=true
            end
          end
        else
          @student.errors.add_to_base("#{m.name} must contain atleast one selected option.")
          @error=true
        end
      end

      unless @error==true
        additional_field_ids_posted = []
        additional_field_ids = @additional_fields.map(&:id)
        if params[:student_additional_details].present?
          params[:student_additional_details].each_pair do |k, v|
            addl_info = v['additional_info']
            additional_field_ids_posted << k.to_i
            addl_field = StudentAdditionalField.find_by_id(k)
            if addl_field.input_type == "has_many"
              addl_info = addl_info.join(", ")
            end
            prev_record = StudentAdditionalDetail.find_by_student_id_and_additional_field_id(params[:id], k)
            unless prev_record.nil?
              unless addl_info.present?
                prev_record.destroy
              else
                prev_record.update_attributes(:additional_info => addl_info)
              end
            else
              addl_detail = StudentAdditionalDetail.new(:student_id => params[:id],
                :additional_field_id => k,:additional_info => addl_info)
              addl_detail.save if addl_detail.valid?
            end
          end
        end
        if additional_field_ids.present?
          StudentAdditionalDetail.find_all_by_student_id_and_additional_field_id(params[:id],(additional_field_ids - additional_field_ids_posted)).each do |additional_info|
            additional_info.destroy unless additional_info.student_additional_field.is_mandatory == true
          end
        end
        flash[:notice] = "#{t('flash9')} #{@student.first_name} #{@student.last_name}. #{t('new_admission_link')} <a href='/student/admission1'>Click Here</a>"
        redirect_to :controller => "student", :action => "profile", :id => @student.id
      end
    end
  end

  def edit_admission4
    @student = Student.find(params[:id])
    @additional_fields = StudentAdditionalField.find(:all, :conditions=> "status = true")
    @additional_details = StudentAdditionalDetail.find_all_by_student_id(@student)

    if @additional_details.empty?
      redirect_to :controller => "student",:action => "admission4" , :id => @student.id
    end
    if request.post?

      params[:student_additional_details].each_pair do |k, v|
        row_id=StudentAdditionalDetail.find_by_student_id_and_additional_field_id(@student.id,k)
        unless row_id.nil?
          additional_detail = StudentAdditionalDetail.find_by_student_id_and_additional_field_id(@student.id,k)
          StudentAdditionalDetail.update(additional_detail.id,:additional_info => v['additional_info'])
        else
          StudentAdditionalDetail.create(:student_id=>@student.id,:additional_field_id=>k,:additional_info=>v['additional_info'])
        end
      end
      flash[:notice] = "#{t('student_text')} #{@student.first_name} #{t('flash2')}"
      redirect_to :action => "profile", :id => @student.id
    end
  end
  def add_additional_details
    @all_details = StudentAdditionalField.find(:all, :order=>"priority ASC")
    @additional_details = StudentAdditionalField.find(:all, :conditions=>{:status=>true},:order=>"priority ASC")
    @inactive_additional_details = StudentAdditionalField.find(:all, :conditions=>{:status=>false},:order=>"priority ASC")
    @additional_field = StudentAdditionalField.new
    @student_additional_field_option = @additional_field.student_additional_field_options.build
    if request.post?
      priority = 1
      unless @all_details.empty?
        last_priority = @all_details.map{|r| r.priority}.compact.sort.last
        priority = last_priority + 1
      end
      @additional_field = StudentAdditionalField.new(params[:student_additional_field])
      @additional_field.priority = priority
      if @additional_field.save
        flash[:notice] = "#{t('flash1')}"
        redirect_to :controller => "student", :action => "add_additional_details"
      end
    end
  end
  def change_field_priority
    @additional_field = StudentAdditionalField.find(params[:id])
    priority = @additional_field.priority
    @additional_fields = StudentAdditionalField.find(:all, :conditions=>{:status=>true}, :order=> "priority ASC").map{|b| b.priority.to_i}
    position = @additional_fields.index(priority)
    if params[:order]=="up"
      prev_field = StudentAdditionalField.find_by_priority(@additional_fields[position - 1])
    else
      prev_field = StudentAdditionalField.find_by_priority(@additional_fields[position + 1])
    end
    @additional_field.update_attributes(:priority=>prev_field.priority)
    prev_field.update_attributes(:priority=>priority.to_i)
    @additional_field = StudentAdditionalField.new
    @additional_details = StudentAdditionalField.find(:all, :conditions=>{:status=>true},:order=>"priority ASC")
    @inactive_additional_details = StudentAdditionalField.find(:all, :conditions=>{:status=>false},:order=>"priority ASC")
    render(:update) do|page|
      page.replace_html "category-list", :partial=>"additional_fields"
    end
  end

  def edit_additional_details
    @additional_details = StudentAdditionalField.find(:all, :conditions=>{:status=>true},:order=>"priority ASC")
    @inactive_additional_details = StudentAdditionalField.find(:all, :conditions=>{:status=>false},:order=>"priority ASC")
    @additional_field = StudentAdditionalField.find(params[:id])
    @student_additional_field_option = @additional_field.student_additional_field_options   
    if request.get?
      render :action=>'add_additional_details'
    else 
      begin
        if @additional_field.update_attributes(params[:student_additional_field])
          flash[:notice] = "#{t('flash2')}"
          redirect_to :action => "add_additional_details"
        else
          flash[:notice] = "#{t('unable_to_delete_when_dependent_exists')}"
          redirect_to :action => "add_additional_details"
        end
      rescue RuntimeError => e
        flash[:notice] = "#{t(e.message)}"
        render :action=>"add_additional_details"
      end
    end
  end

  def delete_additional_details
    students = StudentAdditionalDetail.find(:all ,:conditions=>"additional_field_id = #{params[:id]}")
    if students.blank?
      StudentAdditionalField.find(params[:id]).destroy
      @additional_details = StudentAdditionalField.find(:all, :conditions=>{:status=>true},:order=>"priority ASC")
      @inactive_additional_details = StudentAdditionalField.find(:all, :conditions=>{:status=>false},:order=>"priority ASC")
      flash[:notice]="#{t('flash13')}"
      redirect_to :action => "add_additional_details"
    else
      flash[:notice]="#{t('flash14')}"
      redirect_to :action => "add_additional_details"
    end
  end

  def change_to_former
    @dependency = @student.former_dependency
      flash.now[:notice]="#{t('fee_due_msg')} <a href='/finance_extensions/pay_all_fees/#{@student.id}?batch_id=#{@student.batch.id}'>Click Here</a> to view the due amount." if @student.check_fee_dues
    if request.post?
      @student.archive_student(params[:remove][:status_description],params[:leaving_date])
      @former = ArchivedStudent.find_by_former_id(@student.id)
      render :update do |page|
        page.replace_html 'remove-student', :partial => 'student_tc_generate'
      end
    end
  end

  def generate_tc_pdf
    @student = ArchivedStudent.find_by_former_id(params[:id])
    @father = ArchivedGuardian.find_by_ward_id(@student.id, :conditions=>"relation = 'father'")
    @mother = ArchivedGuardian.find_by_ward_id(@student.id, :conditions=>"relation = 'mother'")
    @immediate_contact = ArchivedGuardian.find_by_ward_id(@student.immediate_contact_id) \
      unless @student.immediate_contact_id.nil? or @student.immediate_contact_id == ''
    render :pdf=>'generate_tc_pdf'
    #        respond_to do |format|
    #            format.pdf { render :layout => false }
    #        end
  end

  def generate_all_tc_pdf
    @ids = params[:stud]
    @students = @ids.map { |st_id| ArchivedStudent.find(st_id) }

    render :pdf=>'generate_all_tc_pdf'
  end

  def destroy
    student = Student.find(params[:id])
    unless student.check_dependency
      unless student.all_siblings.present?
        student.guardians.each do|guardian|
          guardian.user.destroy if guardian.user.present?
          guardian.destroy
        end
      end
      session[:student_id]=nil if student.id==session[:student_id]
      student.user.destroy
      student.destroy
      flash[:notice] = "#{t('flash10')}. #{student.admission_no}."
      redirect_to :controller => 'user', :action => 'dashboard'
    else
      #flash[:warn_notice] = "#{t('flash15')}"
      redirect_to  :action => 'delete', :id=>student.id
    end
  end

  def destroy_dependencies
    student = Student.find(params[:id])
    Student.transaction do
      Delayed::Job.enqueue(DelayedStudentDependencyDelete.new(params[:id], current_user))
    end
    flash[:notice] = "#{t('flash10')}. #{student.admission_no}. <a href='/scheduled_jobs'>Click Here</a> to view the scheduled job."
    redirect_to :controller => 'user', :action => 'dashboard'
  end

  def delete
    @student = Student.find(params[:id])
    @dependency_list = @student.student_dependencies_list
  end

  def edit
    @student = Student.find(params[:id])
    @student.gender=@student.gender.downcase
    @student_user = @student.user
    @student_categories = StudentCategory.active
    @student_dependency= @student.student_dependencies_list.empty? ? true:false
    unless @student.student_category.present? and @student_categories.collect(&:name).include?(@student.student_category.name)
      current_student_category=@student.student_category
      @student_categories << current_student_category if current_student_category.present?
    end
    @batches = Batch.active
    @student.biometric_id = BiometricInformation.find_by_user_id(@student.user_id).try(:biometric_id)
    @application_sms_enabled = SmsSetting.find_by_settings_key("ApplicationEnabled")
    if Configuration.enabled_roll_number?
      @roll_number_prefix = @student.batch.get_roll_number_prefix
      @student.roll_number.to_s.slice!(@roll_number_prefix.to_s)
      @roll_number_suffix = @student.roll_number
    end
    if request.put?
      unless params[:student][:image_file].blank?
        unless params[:student][:image_file].size.to_f > 280000
          if @student.update_attributes(params[:student])
            flash[:notice] = "#{t('flash3')}"
            redirect_to :controller => "student", :action => "profile", :id => @student.id
          end
        else
          flash[:notice] = "#{t('flash_msg11')}"
          redirect_to :controller => "student", :action => "edit", :id => @student.id
        end
      else
        if @student.update_attributes(params[:student])
          flash[:notice] = "#{t('flash3')}"
          redirect_to :controller => "student", :action => "profile", :id => @student.id
        end
      end
    end
  end


  def edit_guardian
    @parent = Guardian.find(params[:id])
    params[:student_id].present? ? @student = Student.find(params[:student_id]): @student = Student.find(params[:parent_detail][:ward_id])
    @countries = Country.all
    params[:parent_detail].delete "ward_id" if  params[:parent_detail]
    if request.post? and @parent.update_attributes(params[:parent_detail])
      #      if @parent.email.blank?
      #        @parent.email= "noreplyp#{@parent.ward.admission_no}@fedena.com"
      #        @parent.save
      #      end
      if @parent.id  == @student.immediate_contact_id
        unless @parent.user.nil?
          User.update(@parent.user.id, :first_name=> @parent.first_name, :last_name=> @parent.last_name, :email=> @parent.email, :role =>"Parent")
        else
          @parent.create_guardian_user(@student)
        end
      end
      flash[:notice] = "#{t('student.flash4')}"
      redirect_to :controller => "student", :action => "guardians", :id => @student.id
    end
  end

  def exam_report
    @user = current_user
    @examtype = ExaminationType.find(params[:exam])
    @course = Course.find(params[:course])
    @student = Student.find(params[:student]) if params[:student]
    @student ||= @course.students.first
    @prev_student = @student.previous_student
    @next_student = @student.next_student
    @subjects = @course.subjects_with_exams
    @results = {}
    @subjects.each do |s|
      exam = Examination.find_by_subject_id_and_examination_type_id(s, @examtype)
      res = ExaminationResult.find_by_examination_id_and_student_id(exam, @student)
      @results[s.id.to_s] = { 'subject' => s, 'result' => res } unless res.nil?
    end
    @graph = open_flash_chart_object(770, 350, "/student/graph_for_exam_report?course=#{@course.id}&examtype=#{@examtype.id}&student=#{@student.id}")
  end

  def update_student_result_for_examtype
    @student = Student.find(params[:student])
    @examtype = ExaminationType.find(params[:examtype])
    @course = @student.course
    @prev_student = @student.previous_student
    @next_student = @student.next_student
    @subjects = @course.subjects_with_exams
    @results = {}
    @subjects.each do |s|
      exam = Examination.find_by_subject_id_and_examination_type_id(s, @examtype)
      res = ExaminationResult.find_by_examination_id_and_student_id(exam, @student)
      @results[s.id.to_s] = { 'subject' => s, 'result' => res } unless res.nil?
    end
    @graph = open_flash_chart_object(770, 350, "/exam/graph_for_student_exam_result?course=#{@course.id}&examtype=#{@examtype.id}&student=#{@student.id}")
    render(:update) { |page| page.replace_html 'exam-results', :partial => 'student_result_for_examtype' }
  end

  def previous_years_marks_overview
    @student = Student.find(params[:student])
    @all_courses = @student.all_courses
    @graph = open_flash_chart_object(770, 350, "/student/graph_for_previous_years_marks_overview?student=#{params[:student]}&graphtype=#{params[:graphtype]}")
  end

  def reports
    @batch = @student.batch
    @grouped_exams = GroupedExam.find_all_by_batch_id(@batch.id)
    @normal_subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>"no_exams = false AND elective_group_id IS NULL AND is_deleted = false")
    @student_electives =StudentsSubject.all(:conditions=>{:student_id=>@student.id,:batch_id=>@batch.id,:subjects=>{:is_deleted=>false}},:joins=>[:subject])
    @elective_subjects = []
    @student_electives.each do |e|
      @elective_subjects.push Subject.find(e.subject_id)
    end
    @subjects = @normal_subjects+@elective_subjects
    @exam_groups = @batch.exam_groups
    @exam_groups.reject!{|e| e.result_published==false}
    @old_batches = @student.graduated_batches
    @graduated_cce_batches = @student.graduated_cce_batches
    @cce_categories = @batch.cce_exam_category if @batch.cce_enabled?
    @gradebook_reports = @student.fetch_individual_reports(@batch.id)
    @gb_old_batches_ids = @gradebook_reports.keys - [@batch.id.to_s]
    if @cce_categories.present? and @batch.cce_enabled?
      if @batch.fetch_first_cce_exam_category.present?
        @first_term  = @batch.cce_exam_category.find(@batch.fetch_first_cce_exam_category)
        second_term = (@batch.cce_exam_category.collect{|x| x.id} - @batch.fetch_first_cce_exam_category.to_a).first
        @second_term = @batch.cce_exam_category.find(second_term) if second_term.present?
      end
    end
  end

  def search_ajax
    if params[:option] == "active" or params[:option]=="sibling"
      if params[:query].length>= 3
        @students = Student.find(:all,
          :conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                            OR ltrim(admission_no) LIKE ? OR (concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? )
                              OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ? ) ",
            "#{params[:query]}%","#{params[:query]}%","#{params[:query]}%",
            "%#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%" ],
          :order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}]) unless params[:query] == ''
      else
        @students = Student.find(:all,
          :conditions => ["admission_no = ? " , params[:query]],
          :order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}]) unless params[:query] == ''
      end
      @students.reject!{|r| r.immediate_contact_id.nil?} if @students.present? and params[:option]=="sibling"
      render :layout => false
    else
      if params[:query].length>= 3
        @archived_students = ArchivedStudent.find(:all,
          :conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                            OR ltrim(admission_no) LIKE ? OR (concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? )
                              OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ? ) ",
            "#{params[:query]}%","#{params[:query]}%","#{params[:query]}%",
            "%#{params[:query]}%", "#{params[:query]}", "#{params[:query]}" ],
          :order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}]) unless params[:query] == ''
      else
        @archived_students = ArchivedStudent.find(:all,
          :conditions => ["admission_no = ? " , params[:query]],
          :order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}]) unless params[:query] == ''
      end
      render :partial => "search_ajax"
    end
  end

  def student_annual_overview
    @graph = open_flash_chart_object(770, 350, "/student/graph_for_student_annual_overview?student=#{params[:student]}&year=#{params[:year]}")
  end

  def subject_wise_report
    @student = Student.find(params[:student])
    @subject = Subject.find(params[:subject])
    @examtypes = @subject.examination_types
    @graph = open_flash_chart_object(770, 350, "/student/graph_for_subject_wise_report_for_one_subject?student=#{params[:student]}&subject=#{params[:subject]}")
  end

  def add_guardian
    @parent_info = @student.guardians.build(params[:parent_info])
    @countries = Country.all
    if request.post? and @parent_info.save
      #       @parent_info.update_attribute(:ward_id,@student.guardians.first.ward_id) if @student.guardians.present?
      flash[:notice] = "#{t('flash5')} #{@student.full_name}"
      redirect_to :controller => "student" , :action => "admission3_1", :id => @student.id
    end
  end

  def list_students_by_course
    @students = Student.find_all_by_batch_id(params[:batch_id], :order => 'first_name ASC')
    render(:update) { |page| page.replace_html 'students', :partial => 'students_by_course' }
  end

  def profile
    @student = Student.find(params[:id])
    @current_user = current_user
    @address = @student.address_line1.to_s + ' ' + @student.address_line2.to_s
    @sms_module = Configuration.available_modules
    @biometric_id = BiometricInformation.find_by_user_id(@student.user_id).try(:biometric_id)
    @sms_setting = SmsSetting.new
    @previous_data = @student.student_previous_data
    @immediate_contact = @student.immediate_contact
    @assigned_employees = @student.batch.employees
    @additional_details = @student.student_additional_details.find(:all,:include => [:student_additional_field],:conditions => ["student_additional_fields.status = true"],:order => "student_additional_fields.priority ASC")
    @additional_fields_count = StudentAdditionalField.count(:conditions => "status = true")
  end

  def profile_pdf
    @student = Student.find(params[:id])
    @current_user = current_user
    @address = @student.address_line1.to_s + ' ' + @student.address_line2.to_s
    @sms_module = Configuration.available_modules
    @biometric_id = BiometricInformation.find_by_user_id(@student.user_id).try(:biometric_id)
    @sms_setting = SmsSetting.new
    @previous_data = StudentPreviousData.find_by_student_id(@student.id)
    @immediate_contact = @student.immediate_contact
    @assigned_employees = @student.batch.employees
    @additional_details = @student.student_additional_details.find(:all,:include => [:student_additional_field],:conditions => ["student_additional_fields.status = true"],:order => "student_additional_fields.priority ASC")
    render :pdf=>'profile_pdf'
  end

  def show_previous_details
    @previous_data = StudentPreviousData.find_by_student_id(@student.id)
    @previous_subjects = StudentPreviousSubjectMark.find_all_by_student_id(@student.id)
  end

  def show
    @student = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:id]])
    send_data(@student.photo_data,
      :type => @student.photo_content_type,
      :filename => @student.photo_filename,
      :disposition => 'inline')
  end

  def guardians
    @parents = @student.guardians
  end

  def del_guardian
    @guardian = Guardian.find(params[:id])
    @student = Student.find(params[:student_id])

    unless @student.all_siblings.collect(&:immediate_contact_id).include? params[:id].to_i
      if @guardian.id==@student.immediate_contact_id
        if @guardian.destroy
          @guardian.user.soft_delete
          flash[:notice] = "#{t('flash6')}"
          redirect_to :controller => 'student', :action => 'admission3_1', :id => params[:student_id]
        end
      else
        if @guardian.destroy
          flash[:notice] = "#{t('flash6')}"
          redirect_to :controller => 'student', :action => 'profile', :id => params[:student_id]
        end
      end
    else
      flash[:notice] = "#{"Unable to delete guardian since there exist siblings"} #{@student.all_siblings.select{|s| s.immediate_contact_id==@guardian.id}.collect(&:full_name).join(',')}"
      redirect_to :controller => 'student', :action => 'profile', :id => params[:student_id]
    end
  end

  def academic_pdf
    @course = @student.old_courses.find_by_academic_year_id(params[:year]) if params[:year]
    @course ||= @student.course
    @subjects = Subject.find_all_by_course_id(@course, :conditions => "no_exams = false")
    @examtypes = ExaminationType.find( ( @course.examinations.collect { |x| x.examination_type_id } ).uniq )

    @arr_total_wt = {}
    @arr_score_wt = {}

    @subjects.each do |s|
      @arr_total_wt[s.name] = 0
      @arr_score_wt[s.name] = 0
    end

    @course.examinations.each do |x|
      @arr_total_wt[x.subject.name] += x.weightage
      ex_score = ExaminationResult.find_by_examination_id_and_student_id(x.id, @student.id)
      @arr_score_wt[x.subject.name] += ex_score.marks * x.weightage / x.max_marks unless ex_score.nil?
    end

    respond_to do |format|
      format.pdf { render :layout => false }
    end
  end

  def categories
    @student_categories = StudentCategory.active
    @student_category = StudentCategory.new(params[:student_category])
    if request.post?
      params[:student_category].each_value(&:strip!)
      if @student_category.save
        flash[:notice] = "#{t('flash7')}"
        redirect_to :action => 'categories'
      end
    end
  end

  def category_delete
    if params[:id].present?
      unless StudentCategory.can_be_deleted(params[:id])
        @deleted = false
      else
        @student_category = StudentCategory.update(params[:id], :is_deleted=>true)
        @deleted = true
      end
      @student_categories = StudentCategory.active
    end
  end

  def category_edit
    @student_category = StudentCategory.find(params[:id])
    @student_category_name=@student_category.name
  end

  def category_update
    @student_category = StudentCategory.find(params[:id])
    @student_category_name=@student_category.name
    if @student_category.update_attributes(:name => params[:name])
      @student_categories = StudentCategory.active
      @student_category = StudentCategory.new
    end
  end

  def view_all
    @batches = Batch.active
  end

  def advanced_search
    @search = Student.search(params[:search])
    unless params[:search].present?
      @batches = Batch.all
    else
      if params[:search].present?
        @students = Array.new
        if params[:advv_search].present? and params[:advv_search][:course_id].present?
          unless params[:search][:batch_id_equals].present?
            params[:search][:batch_id_in] = Batch.find_all_by_course_id(params[:advv_search][:course_id]).collect{|b|b.id}
          end
        end
        if params[:search][:is_active_equals]=="true"
          @students = Student.ascend_by_first_name.search(params[:search]).paginate(:page => params[:page],:per_page => 30)
        elsif params[:search][:is_active_equals]=="false"
          @students = ArchivedStudent.ascend_by_first_name.search(params[:search]).paginate(:page => params[:page],:per_page => 30)
        else
          @students = [{:student => {:search_options => params[:search], :order => :first_name}},{:archived_student => {:search_options => params[:search], :order => :first_name}}].model_paginate(:page => params[:page],:per_page => 30)#.sort!{|m, n| m.first_name.capitalize <=> n.first_name.capitalize}
        end
        @searched_for = ''
        @searched_for += "<span>#{t('name')}/#{t('admission_no')}: " + params[:search][:name_or_admssn_no_as].to_s + "</span>" if params[:search][:name_or_admssn_no_as].present?
        @searched_for += "<span>#{t('name')}: " + params[:search][:student_name_as].to_s + "</span>" if params[:search][:student_name_as].present?
        @searched_for += " <span>#{t('admission_no')}: " + params[:search][:admission_no_equals].to_s + "</span>" if params[:search][:admission_no_equals].present?
        if params[:advv_search].present? and params[:advv_search][:course_id].present?
          course = Course.find(params[:advv_search][:course_id])
          batch = Batch.find(params[:search][:batch_id_equals]) unless (params[:search][:batch_id_equals]).blank?
          @searched_for += "<span>#{t('course_text')}: " + course.full_name + "</span>"
          @searched_for += "<span>#{t('batch')}: " + batch.full_name + "</span>" if batch.present?
        end
        @searched_for += "<span>#{t('category')}: " + StudentCategory.find(params[:search][:student_category_id_equals]).name.to_s + "</span>" if params[:search][:student_category_id_equals].present?
        if  params[:search][:gender_equals].present?
          if  params[:search][:gender_equals] == 'm'
            @searched_for += "<span>#{t('gender')}: #{t('male')}</span>"
          elsif  params[:search][:gender_equals] == 'f'
            @searched_for += " <span>#{t('gender')}: #{t('female')}</span>"
          else
            @searched_for += " <span>#{t('gender')}: #{t('all')}</span>"
          end
        end
        @searched_for += "<span>#{t('blood_group')}: " + params[:search][:blood_group_like].to_s + "</span>" if params[:search][:blood_group_like].present?
        @searched_for += "<span>#{t('nationality')}: " + Country.find(params[:search][:nationality_id_equals]).full_name.to_s + "</span>" if params[:search][:nationality_id_equals].present?
        @searched_for += "<span>#{t('year_of_admission')}: " +  params[:advv_search][:doa_option].to_s + ' '+ params[:adv_search][:admission_date_year].to_s + "</span>" if  params[:advv_search].present? and params[:advv_search][:doa_option].present?
        @searched_for += "<span>#{t('year_of_birth')}: " +  params[:advv_search][:dob_option].to_s + ' ' + params[:adv_search][:birth_date_year].to_s + "</span>" if  params[:advv_search].present? and params[:advv_search][:dob_option].present?
        if params[:search][:is_active_equals]=="true"
          @searched_for += "<span>#{t('present_student')}</span>"
        elsif params[:search][:is_active_equals]=="false"
          @searched_for += "<span>#{t('former_student')}</span>"
        else
          @searched_for += "<span>#{t('all_students')}</span>"
        end
      end
    end
  end

  def list_doa_year
    doa_option = params[:doa_option]
    if doa_option == "Equal to"
      render :update do |page|
        page.replace_html 'doa_year', :partial=>"equal_to_select"
      end
    elsif doa_option == "Less than"
      render :update do |page|
        page.replace_html 'doa_year', :partial=>"less_than_select"
      end
    else
      render :update do |page|
        page.replace_html 'doa_year', :partial=>"greater_than_select"
      end
    end
  end

  def doa_equal_to_update
    year = params[:year]
    @start_date = "#{year}-01-01".to_date
    @end_date = "#{year}-12-31".to_date
    render :update do |page|
      page.replace_html 'doa_year_hidden', :partial=>"equal_to_doa_select"
    end
  end

  def doa_less_than_update
    year = params[:year]
    @start_date = "1900-01-01".to_date
    @end_date = "#{year}-01-01".to_date
    render :update do |page|
      page.replace_html 'doa_year_hidden', :partial=>"less_than_doa_select"
    end
  end

  def doa_greater_than_update
    year = params[:year]
    @start_date = "2100-01-01".to_date
    @end_date = "#{year}-12-31".to_date
    render :update do |page|
      page.replace_html 'doa_year_hidden', :partial=>"greater_than_doa_select"
    end
  end

  def list_dob_year
    dob_option = params[:dob_option]
    if dob_option == "Equal to"
      render :update do |page|
        page.replace_html 'dob_year', :partial=>"equal_to_select_dob"
      end
    elsif dob_option == "Less than"
      render :update do |page|
        page.replace_html 'dob_year', :partial=>"less_than_select_dob"
      end
    else
      render :update do |page|
        page.replace_html 'dob_year', :partial=>"greater_than_select_dob"
      end
    end
  end

  def dob_equal_to_update
    year = params[:year]
    @start_date = "#{year}-01-01".to_date
    @end_date = "#{year}-12-31".to_date
    render :update do |page|
      page.replace_html 'dob_year_hidden', :partial=>"equal_to_dob_select"
    end
  end

  def dob_less_than_update
    year = params[:year]
    @start_date = "1900-01-01".to_date
    @end_date = "#{year}-01-01".to_date
    render :update do |page|
      page.replace_html 'dob_year_hidden', :partial=>"less_than_dob_select"
    end
  end

  def dob_greater_than_update
    year = params[:year]
    @start_date = "2100-01-01".to_date
    @end_date = "#{year}-12-31".to_date
    render :update do |page|
      page.replace_html 'dob_year_hidden', :partial=>"greater_than_dob_select"
    end
  end

  def list_batches
    unless params[:course_id] == ''
      @batches = Batch.find(:all, :conditions=>"course_id = #{params[:course_id]}",:order=>"id DESC")
    else
      @batches = []
    end
    render(:update) do |page|
      page.replace_html 'course_batches', :partial=> 'list_batches'
    end
  end

  def advanced_search_pdf
    @data_hash = Student.fetch_student_advance_search_result(params)
    render :pdf=>'generate_tc_pdf', :margin =>{:top=>50,:bottom=>30,:left=>5,:right=>5}
  end
  #  def new_adv
  #    if params[:adv][:option] == "present"
  #      @search = Student.search(params[:search])
  #      @students = @search.all
  #    end
  #  end

  def electives
    @batch = Batch.find(params[:id])
    @elective_subject = Subject.active.find(params[:id2])
    @students = @batch.students.by_first_name.all(:include => {:exam_scores => :exam, :assessment_marks => :assessment})
    @elective_group = ElectiveGroup.find(@elective_subject.elective_group_id)
    flash[:notice] = nil
    if @elective_subject.nil?
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

  def assign_students
    @student = Student.find(params[:id])
    StudentsSubject.create(:student_id=>params[:id],:subject_id=>params[:id2],:batch_id=>@student.batch_id)
    @student = Student.find(params[:id])
    @elective_subject = Subject.find(params[:id2])
    render(:update) do |page|
      page.replace_html "stud_#{params[:id]}", :partial=> 'unassign_students'
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg39')}</p>"
    end
  end

  def choose_elective
    @student = Student.find(params[:id])
    StudentsSubject.create(:student_id=>params[:id],:subject_id=>params[:id2],:batch_id=>@student.batch_id)
    @student = Student.find(params[:id])
    @elective_subject = Subject.find(params[:id2])
    render(:update) do |page|
      page.replace_html "stud_#{params[:id2]}", :partial=> 'remove_elective'
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg46')}</p>"
    end
  end

  def assigned_elective_subjects
    @batch = Batch.find(params[:id])
    @students = @batch.students.paginate(:page => params[:page], :per_page => 10,:select => 'DISTINCT students.*',:joins => :subjects, :conditions=>["students.batch_id = ? AND subjects.is_deleted = ?", @batch.id, false], :order => "students.first_name")
    @elective_groups = @batch.elective_groups.active
    @elective_group_count = @elective_groups.count
  end

  def my_subjects
    @student = Student.find(params[:id])
    subjects = @student.batch.subjects.active
    subjects = subjects.sort_by{|sb| sb.priority.to_i}
    elective_subjects = subjects.select {|s| s.elective_group_id != nil && s.is_deleted == false}
    @elective_groups = @student.batch.elective_groups.active.all(:joins => :subjects, :select => 'elective_groups.*, count(subjects.id) as count', :conditions =>'subjects.is_deleted is false',:group => 'elective_groups.id')
    @normal_subjects = subjects - elective_subjects
    @can_select_elective = @student.batch.course.enable_student_elective_selection
    student_subjects = StudentsSubject.find(:all, :conditions => {:student_id => @student.id, :batch_id => @student.batch.id}, :include => [:subject => :elective_group])
    @student_electives = {}
    student_subjects.each do |s|
      if @student_electives.has_key? s.subject.elective_group.name
        @student_electives[s.subject.elective_group.name] << s.subject
      else
        @student_electives[s.subject.elective_group.name] = [s.subject]
      end
    end
  end

  def search_students
    @batch = Batch.find(params[:id])
    @elective_groups = @batch.elective_groups
    @elective_group_count = @elective_groups.count
    if params[:query].length>= 3
      @students = Student.all(:joins => :subjects, :select => 'DISTINCT students.*',:conditions => ["(students.first_name LIKE ? OR students.middle_name LIKE ? OR students.last_name LIKE ?
                            OR students.admission_no = ? OR (concat(students.first_name, \" \", students.last_name) LIKE ? )) AND students.batch_id = ? AND subjects.is_deleted = ?",
          "#{params[:query]}%","#{params[:query]}%","#{params[:query]}%",
          "#{params[:query]}", "#{params[:query]}", "#{@batch.id}", false ]).paginate(:page => params[:page], :per_page => 10)
    else
      @students = @batch.students.paginate(:page => params[:page], :per_page => 10,:select => 'DISTINCT students.*',:joins => :subjects, :conditions=>["students.batch_id = ? AND subjects.is_deleted = ?", @batch.id, false], :order => "students.first_name")
      #@students = @batch.students.all(:joins => :subjects, :select => 'DISTINCT students.*',:conditions=>["students.batch_id = ? AND subjects.is_deleted = ?",@batch.id,false])
    end
    render(:update) { |page| page.replace_html 'students', :partial => 'search_students' }
  end

  def assign_all_students
    @batch = Batch.find(params[:id])
    @students = @batch.students.by_first_name.all(:include => {:exam_scores => :exam, :assessment_marks => :assessment})
    @students.each do |s|
      @assigned = StudentsSubject.find_by_student_id_and_subject_id(s.id,params[:id2])
      StudentsSubject.create(:student_id=>s.id,:subject_id=>params[:id2],:batch_id=>@batch.id) if @assigned.nil?
    end
    @elective_subject = Subject.find(params[:id2])
    render(:update) do |page|
      page.replace_html 'category-list', :partial=>"all_assign"
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg40')}</p>"
    end
  end

  def unassign_students
    @student = Student.find(params[:id],:include => {:exam_scores => :exam, :assessment_marks => :assessment})
    @elective_subject = Subject.find(params[:id2])
    if @student.subject_exam(@elective_subject.id) and @student.has_assessment_marks(@elective_subject.id)
      StudentsSubject.find_by_student_id_and_subject_id(params[:id],params[:id2]).delete
      render(:update) do |page|
        page.replace_html "stud_#{params[:id]}", :partial=> 'assign_students'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg41')}</p>"
      end
    else
      flash[:notice] = t('error_occured')
      render(:update) { |page| page.redirect_to :controller => "user", :action => "dashboard"}
    end

  end

  def remove_elective
    @student = Student.find(params[:id],:include => {:exam_scores => :exam, :assessment_marks => :assessment})
    @elective_subject = Subject.find(params[:id2])
    if @student.subject_exam(@elective_subject.id) and @student.has_assessment_marks(@elective_subject.id)
      StudentsSubject.find_by_student_id_and_subject_id(params[:id],params[:id2]).delete
      render(:update) do |page|
        page.replace_html "stud_#{params[:id2]}", :partial=> 'choose_elective'
        page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg47')}</p>"
      end
    else
      flash[:notice] = t('error_occured')
      render(:update) { |page| page.redirect_to :controller => "user", :action => "dashboard"}
    end
  end

  def unassign_all_students
    @batch = Batch.find(params[:id])
    @elective_subject = Subject.find(params[:id2])
    @students = @batch.students.by_first_name.all(:include => {:exam_scores => :exam, :assessment_marks => :assessment})
    @students.each do |s|
      if s.subject_exam(@elective_subject.id) and s.has_assessment_marks(@elective_subject.id)
        @assigned = StudentsSubject.find_by_student_id_and_subject_id(s.id,params[:id2])
        @assigned.delete unless @assigned.nil?
      end
    end
    render(:update) do |page|
      page.replace_html 'category-list', :partial=>"all_assign"
      page.replace_html 'flash_box', :text => "<p class='flash-msg'>#{t('flash_msg42')}</p>"
    end
  end

  def fees
    @batches=@student.all_batches.reverse
    # @dates=@student.fees_list
    @enable_all_fee = PaymentConfiguration.find_by_config_key("enabled_pay_all").try(:config_value) || "true" if FedenaPlugin.can_access_plugin?("fedena_pay")
    @advance_fee_config = Configuration.advance_fee_payment_enabled?
    @dates=[]
    if @student.has_paid_fees
      @flash_notice=t('do_not_create_fee_collections_from_now_on')
    elsif @student.has_paid_fees_for_batch
      @flash_notice=t('do_not_create_fee_collections_for_this_student_in_the_current_batch')
    else
      @flash_notice=nil
    end
    @student_batch_fees = {}
    order = "finance_fees.is_paid ASC , finance_fee_collections.due_date ASC"
    @batches.map { |batch| @student_batch_fees[batch.id] = @student.fees_list_by_batch(batch.id,order) } if @batches.present?
  end

  def fee_details
    @fee_collection = @date  = FinanceFeeCollection.find(params[:id2])
    
    # calculating advance fees used
    
    @fine_detail_flag = true
    inc_fee_assoc = @fee_collection.tax_enabled? ? {:tax_collections => :tax_slab} : {}
    @financefee = @student.finance_fee_by_date(@date, inc_fee_assoc)
    @advance_fee_used = @financefee.finance_transactions.collect(&:wallet_amount).sum.to_f
    @due_date = @fee_collection.due_date
    @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id,
      :conditions => ["is_deleted IS NOT NULL"])
    @fee_particulars = @date.finance_fee_particulars.all(
      :conditions => "batch_id=#{@financefee.batch_id}").
      select do |par| 
      (par.receiver.present?) and 
        (par.receiver==@student or 
          par.receiver==@financefee.student_category or 
          par.receiver==@financefee.batch)
    end
    @categorized_particulars=@fee_particulars.group_by(&:receiver_type)
    @discounts=@date.fee_discounts.all(:conditions => "batch_id=#{@financefee.batch_id}").
      select do |par| 
      (par.receiver.present?) and 
        ((par.receiver==@financefee.student or 
            par.receiver==@financefee.student_category or 
            par.receiver==@financefee.batch) and 
          (par.master_receiver_type!='FinanceFeeParticular' or 
            (par.master_receiver_type=='FinanceFeeParticular' and 
              (par.master_receiver.receiver.present? and 
                @fee_particulars.collect(&:id).include? par.master_receiver_id) and 
              (par.master_receiver.receiver==@financefee.student or 
                par.master_receiver.receiver==@financefee.student_category or 
                par.master_receiver.receiver==@financefee.batch))))       
    end
    @categorized_discounts=@discounts.group_by(&:master_receiver_type)
    @total_discount = 0    
    @total_payable=@fee_particulars.map{|s| s.amount}.sum.to_f
    @total_discount =@discounts.map do |d| 
      d.master_receiver_type=='FinanceFeeParticular' ? 
        (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) : 
        @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100) 
    end.sum.to_f unless @discounts.nil?
    total_fees = @financefee.balance.to_f+params[:special_fine].to_f
    unless params[:fine].nil?
      total_fees += params[:fine].to_f
    end
    bal=(@total_payable-@total_discount).to_f
    @payment_date=Date.today
    #@payment_date=@financefee.finance_transactions.last.try(:transaction_date) || Date.today
    days=(@payment_date-@date.due_date.to_date).to_i
    auto_fine=@date.fine
    if days > 0 and auto_fine and !@financefee.is_fine_waiver
      @fine_rule=auto_fine.fine_rules.find(:last, 
        :conditions=>["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],
        :order=>'fine_days ASC')
      if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && @financefee.is_paid == false && !@financefee.balance_fine.nil?
        @fine_amount = @financefee.balance_fine
      else
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : 
          (bal*@fine_rule.fine_amount)/100 if @fine_rule
      end
    end
    if @financefee.tax_enabled?
      @tax_collections = @financefee.tax_collections
      @total_tax = @tax_collections.map(&:tax_amount).sum.to_f      
      @tax_slabs = @tax_collections.group_by {|tax_col| tax_col.tax_slab }      
      #      @tax_collections = @tax_collections.group_by {|x| x.slab_id }
      bal += @total_tax
    end
    @fine_amount=0 if @financefee.is_paid
    @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
  end

  def activities
    @student = Student.find(params[:id])
    weekday_id = Date.parse(Date.today.to_s).strftime("%w")
    batch_id = Student.find(params[:id]).batch.id
    classrooms = Classroom.all
    buildings = Building.all
    hash = {}
    i = 1
    allocations = TimetableEntry.find(:all,:joins => :timetable,
      :include =>[:allocated_classrooms, :entry,:employee,:class_timing, {:timetable_swaps => [:subject, :employee]}],
      :conditions => ["timetable_entries.weekday_id = ? and timetable_entries.batch_id = ? and timetables.start_date <= ? and timetables.end_date >= ?", weekday_id,batch_id,Date.today.to_s,Date.today.to_s],
      :order => "timetable_entries.class_timing_id"
    )
    allocations.each do |a|
      unless a.entry_type == "ElectiveGroup"
        allocation_swap = a.timetable_swaps.present? ? a.timetable_swaps.last : []
        hash[i] = {}
        hash[i]["status"] = allocation_swap.present? ? (allocation_swap.is_cancelled ? 'cancelled' : 'changed') : 'normal'
        hash[i]["class_timing"] = a.class_timing.start_time.strftime("%I:%M %P") + " - " + a.class_timing.end_time.strftime("%I:%M %P")
        hash[i]["subject"] =  (allocation_swap.present? and !allocation_swap.is_cancelled) ? allocation_swap.subject.name : a.assigned_name 
        hash[i]["employee"] = (allocation_swap.present? and !allocation_swap.is_cancelled) ? allocation_swap.employee.full_name : (a.employee_ids.present? ? a.employees.map(&:full_name).join(", ") : "#{t('no_teacher')}")
        hash[i]["classroom"] = []
        hash[i]["building"] = []
        a.allocated_classrooms.each do |c|
          hash[i]["classroom"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
          hash[i]["building"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => buildings.select{|b| b.id == classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.building_id}.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
        end
        i+= 1
      end
      if a.entry_type == "ElectiveGroup"
        s = a.entry.subjects.all(:include => :employees)
        #        s = Subject.find(:all,:joins => :employees,:conditions=> "subjects.elective_group_id = #{a.subject.elective_group_id}").uniq
        s.each do |sub|
          @assigned = StudentsSubject.find_by_student_id_and_subject_id(@student.id,sub.id)
          next if @assigned.nil?
          allocation = a.allocated_classrooms.select{|alloc| alloc.subject_id == sub.id }
          hash[i] = {}
          hash[i]["status"] = "normal"
          hash[i]["class_timing"] = a.class_timing.start_time.strftime("%I:%M %P") + " - " + a.class_timing.end_time.strftime("%I:%M %P")
          hash[i]["subject"] = sub.name
          hash[i]["employee"] = sub.employees.present? ? sub.employees.map(&:first_name).join(", ") : "#{t('no_teacher')}"
          hash[i]["classroom"] = []
          hash[i]["building"] = []
          allocation.each do |c|
            hash[i]["classroom"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
            hash[i]["building"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => buildings.select{|b| b.id == classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.building_id}.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
          end
          i+=1
        end

      end

    end
    @allocations = hash.sort
  end

  def update_activities
    @student = Student.find(params[:id])
    current_date = params[:date]
    weekday_id = Date.parse(current_date).strftime("%w")
    batch_id = Student.find(params[:id]).batch.id
    classrooms = Classroom.all
    buildings = Building.all
    hash = {}
    i = 1
    allocations = TimetableEntry.find(:all,:joins => :timetable,
      :include =>[:allocated_classrooms, :entry,:employees,:class_timing, {:timetable_swaps => [:subject, :employee]}],
      :conditions => ["timetable_entries.weekday_id = ? and timetable_entries.batch_id = ? and timetables.start_date <= ? and timetables.end_date >= ?", weekday_id,batch_id,current_date,current_date],
      :order => "timetable_entries.class_timing_id"
    )
    
    allocations.each do |a|
      unless a.entry_type == "ElectiveGroup"
        allocation_swap = a.timetable_swaps.present? ? a.timetable_swaps.select {|x| x.date.to_s == current_date }.last : []
        hash[i] = {}
        hash[i]["status"] = allocation_swap.present? ? (allocation_swap.is_cancelled ? 'cancelled' : 'changed') : 'normal'
        hash[i]["class_timing"] = a.class_timing.start_time.strftime("%I:%M %P") + " - " + a.class_timing.end_time.strftime("%I:%M %P")
        #        hash[i]["subject"] = a.assigned_name
        #        hash[i]["employee"] = a.employee_ids.present? ? a.employees.map(&:first_name).join(", ") : "#{t('no_teacher')}"
        
        hash[i]["subject"] =  (allocation_swap.present? and !allocation_swap.is_cancelled) ? allocation_swap.subject.name : a.assigned_name 
        hash[i]["employee"] = (allocation_swap.present? and !allocation_swap.is_cancelled) ? allocation_swap.employee.first_name : (a.employee_ids.present? ? a.employees.map(&:first_name).join(", ") : "#{t('no_teacher')}")
        hash[i]["classroom"] = []
        hash[i]["building"] = []
        a.allocated_classrooms.each do |c|
          hash[i]["classroom"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type =>  classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
          hash[i]["building"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => buildings.select{|b| b.id == classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.building_id}.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
        end
        i+= 1
      end
      if a.entry_type == "ElectiveGroup"
        s = a.entry.subjects.all(:include => :employees)
        #        s = Subject.find(:all,:joins => :employees,:conditions=> "subjects.elective_group_id = #{a.subject.elective_group_id}").uniq
        s.each do |sub|
          @assigned = StudentsSubject.find_by_student_id_and_subject_id(@student.id,sub.id)
          next if @assigned.nil?
          allocation = a.allocated_classrooms.select{|alloc| alloc.subject_id == sub.id }
          hash[i] = {}
          hash[i]["status"] = "normal"
          hash[i]["class_timing"] = a.class_timing.start_time.strftime("%I:%M %P") + " - " + a.class_timing.end_time.strftime("%I:%M %P")
          hash[i]["subject"] = sub.name
          hash[i]["employee"] = sub.employees.present? ? sub.employees.map(&:first_name).join(", ") : "#{t('no_teacher')}"
          hash[i]["classroom"] = []
          hash[i]["building"] = []
          allocation.each do |c|
            hash[i]["classroom"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
            hash[i]["building"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => buildings.select{|b| b.id == classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.building_id}.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
          end
          i+=1
        end
      end
    end
    @allocations = hash.sort
    render(:update) { |page| page.replace_html 'list', :partial => 'list_activities' }
  end

  def student_fees_preference
    @creation=false
    @student=Student.find(params[:id])
    if request.post?
      if params[:student].present?
        @student.attributes=params[:student]
        @student.send(:update_without_callbacks)
      end
      @creation=true
      @flash_msg=params[:flash_msg]
    end
  end
  
  def unlink_sibling
    @unlink_stud=Student.find_by_id(params[:unlink_id])
    if @unlink_stud.id == @unlink_stud.sibling_id
      @students = Student.find_all_by_sibling_id(params[:unlink_id]).reject{|a_s| a_s.id == @unlink_stud.id}
      @students.each do |s|
        s.update_attributes(:immediate_contact_id=>nil,:sibling_id=>s.id)
      end
      flash[:notice] = "#{t('unlink_successfully', {:student_admn_no => @students.map{|s| s.admission_no<<" "}})}"
      redirect_to :controller => "student", :action => "admission1_2", :id => params[:student_id]
    else
      @unlink_stud.update_attributes(:immediate_contact_id=>nil,:sibling_id=>@unlink_stud.id)
      flash[:notice] = "#{t('unlink_successfully', {:student_admn_no => @unlink_stud.admission_no} )}"
      redirect_to :controller => "student", :action => "admission1_2", :id => params[:student_id]
    end
  end

  #  # Graphs
  #
  #  def graph_for_previous_years_marks_overview
  #    student = Student.find(params[:student])
  #
  #    x_labels = []
  #    data = []
  #
  #    student.all_courses.each do |c|
  #      x_labels << c.name
  #      data << student.annual_weighted_marks(c.academic_year_id)
  #    end
  #
  #    if params[:graphtype] == 'Line'
  #      line = Line.new
  #    else
  #      line = BarFilled.new
  #    end
  #
  #    line.width = 1; line.colour = '#5E4725'; line.dot_size = 5; line.values = data
  #
  #    x_axis = XAxis.new
  #    x_axis.labels = x_labels
  #
  #    y_axis = YAxis.new
  #    y_axis.set_range(0,100,20)
  #
  #    title = Title.new(student.full_name)
  #
  #    x_legend = XLegend.new("Academic year")
  #    x_legend.set_style('{font-size: 14px; color: #778877}')
  #
  #    y_legend = YLegend.new("Total marks")
  #    y_legend.set_style('{font-size: 14px; color: #770077}')
  #
  #    chart = OpenFlashChart.new
  #    chart.set_title(title)
  #    chart.y_axis = y_axis
  #    chart.x_axis = x_axis
  #
  #    chart.add_element(line)
  #
  #    render :text => chart.to_s
  #  end
  #
  #  def graph_for_student_annual_overview
  #    student = Student.find(params[:student])
  #    course = Course.find_by_academic_year_id(params[:year]) if params[:year]
  #    course ||= student.course
  #    subs = course.subjects
  #    exams = Examination.find_all_by_subject_id(subs, :select => "DISTINCT examination_type_id")
  #    etype_ids = exams.collect { |x| x.examination_type_id }
  #    examtypes = ExaminationType.find(etype_ids)
  #
  #    x_labels = []
  #    data = []
  #
  #    examtypes.each do |et|
  #      x_labels << et.name
  #      data << student.examtype_average_marks(et, course)
  #    end
  #
  #    x_axis = XAxis.new
  #    x_axis.labels = x_labels
  #
  #    line = BarFilled.new
  #
  #    line.width = 1
  #    line.colour = '#5E4725'
  #    line.dot_size = 5
  #    line.values = data
  #
  #    y = YAxis.new
  #    y.set_range(0,100,20)
  #
  #    title = Title.new('Title')
  #
  #    x_legend = XLegend.new("Examination name")
  #    x_legend.set_style('{font-size: 14px; color: #778877}')
  #
  #    y_legend = YLegend.new("Average marks")
  #    y_legend.set_style('{font-size: 14px; color: #770077}')
  #
  #    chart = OpenFlashChart.new
  #    chart.set_title(title)
  #    chart.set_x_legend(x_legend)
  #    chart.set_y_legend(y_legend)
  #    chart.y_axis = y
  #    chart.x_axis = x_axis
  #
  #    chart.add_element(line)
  #
  #    render :text => chart.to_s
  #  end
  #
  #  def graph_for_subject_wise_report_for_one_subject
  #    student = Student.find params[:student]
  #    subject = Subject.find params[:subject]
  #    exams = Examination.find_all_by_subject_id(subject.id, :order => 'date asc')
  #
  #    data = []
  #    x_labels = []
  #
  #    exams.each do |e|
  #      exam_result = ExaminationResult.find_by_examination_id_and_student_id(e, student.id)
  #      unless exam_result.nil?
  #        data << exam_result.percentage_marks
  #        x_labels << XAxisLabel.new(exam_result.examination.examination_type.name, '#000000', 10, 0)
  #      end
  #    end
  #
  #    x_axis = XAxis.new
  #    x_axis.labels = x_labels
  #
  #    line = BarFilled.new
  #
  #    line.width = 1
  #    line.colour = '#5E4725'
  #    line.dot_size = 5
  #    line.values = data
  #
  #    y = YAxis.new
  #    y.set_range(0,100,20)
  #
  #    title = Title.new(subject.name)
  #
  #    x_legend = XLegend.new("Examination name")
  #    x_legend.set_style('{font-size: 14px; color: #778877}')
  #
  #    y_legend = YLegend.new("Marks")
  #    y_legend.set_style('{font-size: 14px; color: #770077}')
  #
  #    chart = OpenFlashChart.new
  #    chart.set_title(title)
  #    chart.set_x_legend(x_legend)
  #    chart.set_y_legend(y_legend)
  #    chart.y_axis = y
  #    chart.x_axis = x_axis
  #
  #    chart.add_element(line)
  #
  #    render :text => chart.to_s
  #  end
  #
  #  def graph_for_exam_report
  #    student = Student.find(params[:student])
  #    examtype = ExaminationType.find(params[:examtype])
  #    course = student.course
  #    subjects = course.subjects_with_exams
  #
  #    x_labels = []
  #    data = []
  #    data2 = []
  #
  #    subjects.each do |s|
  #      exam = Examination.find_by_subject_id_and_examination_type_id(s, examtype)
  #      res = ExaminationResult.find_by_examination_id_and_student_id(exam, student)
  #      unless res.nil?
  #        x_labels << s.name
  #        data << res.percentage_marks
  #        data2 << exam.average_marks * 100 / exam.max_marks
  #      end
  #    end
  #
  #    bargraph = BarFilled.new()
  #    bargraph.width = 1;
  #    bargraph.colour = '#bb0000';
  #    bargraph.dot_size = 5;
  #    bargraph.text = "Student's marks"
  #    bargraph.values = data
  #
  #    bargraph2 = BarFilled.new
  #    bargraph2.width = 1;
  #    bargraph2.colour = '#5E4725';
  #    bargraph2.dot_size = 5;
  #    bargraph2.text = "Class average"
  #    bargraph2.values = data2
  #
  #    x_axis = XAxis.new
  #    x_axis.labels = x_labels
  #
  #    y_axis = YAxis.new
  #    y_axis.set_range(0,100,20)
  #
  #    title = Title.new(student.full_name)
  #
  #    x_legend = XLegend.new("Academic year")
  #    x_legend.set_style('{font-size: 14px; color: #778877}')
  #
  #    y_legend = YLegend.new("Total marks")
  #    y_legend.set_style('{font-size: 14px; color: #770077}')
  #
  #    chart = OpenFlashChart.new
  #    chart.set_title(title)
  #    chart.y_axis = y_axis
  #    chart.x_axis = x_axis
  #    chart.y_legend = y_legend
  #    chart.x_legend = x_legend
  #
  #    chart.add_element(bargraph)
  #    chart.add_element(bargraph2)
  #
  #    render :text => chart.render
  #  end
  #
  #  def graph_for_academic_report
  #    student = Student.find(params[:student])
  #    course = student.course
  #    examtypes = ExaminationType.find( ( course.examinations.collect { |x| x.examination_type_id } ).uniq )
  #    x_labels = []
  #    data = []
  #    data2 = []
  #
  #    examtypes.each do |e_type|
  #      total = 0
  #      max_total = 0
  #      exam = Examination.find_all_by_examination_type_id(e_type.id)
  #      exam.each do |t|
  #        res = ExaminationResult.find_by_examination_id_and_student_id(t.id, student.id)
  #        total += res.marks
  #        max_total += res.maximum_marks
  #      end
  #      class_max =0
  #      class_total = 0
  #      exam.each do |t|
  #        res = ExaminationResult.find_all_by_examination_id(t.id)
  #        res.each do |res|
  #          class_max += res.maximum_marks
  #          class_total += res.marks
  #        end
  #      end
  #      class_avg = (class_total*100/class_max).to_f
  #      percentage = ((total*100)/max_total).to_f
  #      x_labels << e_type.name
  #      data << percentage
  #      data2 << class_avg
  #    end
  #
  #    bargraph = BarFilled.new()
  #    bargraph.width = 1;
  #    bargraph.colour = '#bb0000';
  #    bargraph.dot_size = 5;
  #    bargraph.text = "Student's average"
  #    bargraph.values = data
  #
  #    bargraph2 = BarFilled.new
  #    bargraph2.width = 1;
  #    bargraph2.colour = '#5E4725';
  #    bargraph2.dot_size = 5;
  #    bargraph2.text = "Class average"
  #    bargraph2.values = data2
  #
  #    x_axis = XAxis.new
  #    x_axis.labels = x_labels
  #    y_axis = YAxis.new
  #    y_axis.set_range(0,100,20)
  #
  #    x_legend = XLegend.new("Examinations")
  #    x_legend.set_style('{font-size: 14px; color: #778877}')
  #
  #    y_legend = YLegend.new("Percentage")
  #    y_legend.set_style('{font-size: 14px; color: #770077}')
  #
  #    chart = OpenFlashChart.new
  #
  #    chart.y_axis = y_axis
  #    chart.x_axis = x_axis
  #    chart.y_legend = y_legend
  #    chart.x_legend = x_legend
  #
  #    chart.add_element(bargraph)
  #    chart.add_element(bargraph2)
  #
  #    render :text => chart.render
  #  end
  #
  #  def graph_for_annual_academic_report
  #    student = Student.find(params[:student])
  #    student_all = Student.find_all_by_course_id(params[:course])
  #    total = 0
  #    sum = student_all.size
  #    student_all.each { |s| total += s.annual_weighted_marks(s.course.academic_year_id) }
  #    t = (total/sum).to_f
  #
  #    x_labels = []
  #    data = []
  #    data2 = []
  #
  #    x_labels << "Annual report".to_s
  #    data << student.annual_weighted_marks(student.course.academic_year_id)
  #    data2 << t
  #
  #    bargraph = BarFilled.new()
  #    bargraph.width = 1;
  #    bargraph.colour = '#bb0000';
  #    bargraph.dot_size = 5;
  #    bargraph.text = "Student's average"
  #    bargraph.values = data
  #
  #    bargraph2 = BarFilled.new
  #    bargraph2.width = 1;
  #    bargraph2.colour = '#5E4725';
  #    bargraph2.dot_size = 5;
  #    bargraph2.text = "Class average"
  #    bargraph2.values = data2
  #
  #    x_axis = XAxis.new
  #    x_axis.labels = x_labels
  #
  #    y_axis = YAxis.new
  #    y_axis.set_range(0,100,20)
  #
  #    x_legend = XLegend.new("Examinat1234ions")
  #    x_legend.set_style('{font-size: 14px; color: #778877}')
  #
  #    y_legend = YLegend.new("Weightage")
  #    y_legend.set_style('{font-size: 14px; color: #770077}')
  #
  #    chart = OpenFlashChart.new
  #
  #    chart.y_axis = y_axis
  #    chart.x_axis = x_axis
  #    chart.y_legend = y_legend
  #    chart.x_legend = x_legend
  #
  #    chart.add_element(bargraph)
  #    chart.add_element(bargraph2)
  #
  #    render :text => chart.render
  #
  #  end

  private
  def find_student
    @student_type = params[:student_type]
    if @student_type == 'former'
      @student = ArchivedStudent.find_by_former_id(params[:id].to_i) 
    else
      @student = Student.find(params[:id])
    end
  end

  def paginate_collection(model1,model1_condition,model2 = nil,model2_condition = Hash.new,per_page = 30,current_page = 0,type = "find",sort_by = nil)
    per_page = per_page.to_i
    klass1 = model1.to_s.camelize.constantize
    klass2 = model2.to_s.camelize.constantize
    collection1 = klass1.find(:all,:conditions => model1_condition).paginate :per_page => per_page/2 ,:page => current_page if type == "find"
    collection1 = klass1.send("ascend_by_#{sort_by}").search(model1_condition).paginate :per_page => per_page/2 ,:page => current_page if type == "search"
    per_page1 = per_page / 2
    if collection1.count < per_page/2
      per_page1 = per_page / 2 + (per_page / 2 - collection1.count)
    end
    collection2 = klass2.find(:all,:conditions => model2_condition).paginate :per_page => per_page1 ,:page => current_page  if type == "find"
    collection2 = klass2.send("ascend_by_#{sort_by}").search(model2_condition).paginate :per_page => per_page1 ,:page => current_page  if type == "search"
    final_collection = (collection1 + collection2).sort_by{|a| [a.send(sort_by).downcase]}
    return final_collection
  end

  def model_records_count(model1,model1_condition,model2,model2_condition,type)

  end

  def feature_access
    unless can_access_feature?('elective_selection')
      redirect_to :controller => "user", :action => "dashboard"
    end
  end

end
