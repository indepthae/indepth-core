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

class ExamGroupsController < ApplicationController
  before_filter :login_required
  filter_access_to :all, :except=>[:index,:show,:subject_list]
  filter_access_to [:index,:show,:subject_list], :attribute_check=>true, :load_method => lambda { Batch.find(params[:batch_id]) }
  
  before_filter :initial_queries
  before_filter :protect_other_student_data
  #  before_filter :restrict_employees_from_exam
  in_place_edit_with_validation_for :exam_group, :name
  in_place_edit_with_validation_for :exam, :maximum_marks
  in_place_edit_with_validation_for :exam, :minimum_marks
  in_place_edit_with_validation_for :exam, :weightage

  def index
    @sms_setting = SmsSetting.new
    @exam_groups = @batch.exam_groups
#    unless @batch.is_active
##      @exam_groups.reject!{|e| !@batch.course.cce_enabled?  and !@batch.course.icse_enabled?  and !@batch.grouped_exams.exists?(:exam_group_id=>e.id)}
#      @exam_groups.reject!{|e| !@batch.course.cce_enabled?  and !@batch.course.icse_enabled?}
#    end
  end

  def new
    @user_privileges = @current_user.privileges
    @cce_exam_categories = CceExamCategory.all if @batch.cce_enabled?
    @icse_exam_categories = IcseExamCategory.all if @batch.icse_enabled?
    if !@current_user.admin? and !@user_privileges.map{|p| p.name}.include?('ExaminationControl') and !@user_privileges.map{|p| p.name}.include?('EnterResults')
      flash[:notice] = "#{t('flash_msg4')}"
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def create
    @exam_group = ExamGroup.find(params[:exam_group_id])
    @error=false
    unless @type=="Grades"
      params[:exam_group][:exams_attributes].each do |exam|
        if exam[1][:_delete].to_s=="0" and @error==false
          unless exam[1][:maximum_marks].present?
            @exam_group.errors.add_to_base("#{t('maxmarks_cant_be_blank')}")
            @error=true
          end
          unless exam[1][:minimum_marks].present?
            @exam_group.errors.add_to_base("#{t('minmarks_cant_be_blank')}")
            @error=true
          end
        end
      end
    end
    if @error==false and @exam_group.save
      flash[:notice] =  "#{t('flash1')}"
      redirect_to batch_exam_groups_path(@exam_groups)
    else
      deliver_plugin_block :fedena_reminder do
        @exam_group.set_alert_settings(params.fetch(:exam_group,{})[:event_alerts_attributes])
      end
      @cce_exam_categories = CceExamCategory.all if @batch.cce_enabled?
      @icse_exam_categories = IcseExamCategory.all if @batch.icse_enabled?
      render 'exams/new'
    end
  end

  def edit
    @exam_group = ExamGroup.find params[:id]
    @cce_exam_categories = CceExamCategory.all if @batch.cce_enabled?
    @icse_exam_categories = IcseExamCategory.all if @batch.icse_enabled?
  end

  def update
    @exam_group = ExamGroup.find params[:id]
    if @exam_group.update_attributes(params[:exam_group])
      flash[:notice] = "#{t('flash2')}"
      redirect_to [@batch, @exam_group]
    else
      @cce_exam_categories = CceExamCategory.all if @batch.cce_enabled?
      @icse_exam_categories = IcseExamCategory.all if @batch.icse_enabled?
      render 'edit'
    end
  end

  def destroy
    @exam_group = ExamGroup.find(params[:id], :include => :exams)
    if @current_user.employee?
      @employee_subjects= @current_user.employee_record.subjects.map { |n| n.id}
      if @employee_subjects.empty? and !@current_user.privileges.map{|p| p.name}.include?("ExaminationControl") and !@current_user.privileges.map{|p| p.name}.include?("EnterResults")
        flash[:notice] = "#{t('flash_msg4')}"
        redirect_to :controller => 'user', :action => 'dashboard'
      end
    end
    flash[:notice] = "#{t('flash3')}" if @exam_group.destroy
    redirect_to batch_exam_groups_path(@batch)
  end

  def show
    @sms_setting = SmsSetting.new
    @exam_group = ExamGroup.find(params[:id], :include => [:exams,:batch])
    get_respective_subjects(@exam_group.id,'exam_group_exams')
    @course_exam_group = ExamGroup.find(params[:id]).course_exam_group
    if Configuration.cce_enabled?
      @fa_group_names = []
      @fa_group_status = []

#      @exam_group.exams.each do |e|
#        e.subject.fa_groups.all(:conditions=>{:cce_exam_category_id=>@exam_group.cce_exam_category_id}).collect{|f| @fa_group_names << f.name.split(' ').last unless @fa_group_names.include?(f.name.split(' ').last)}
#      end
      @batch = Batch.find params[:batch_id] if params[:batch_id].present?
      @batch.subjects.each do |subject|
        subject.fa_groups.all(:conditions=>{:cce_exam_category_id=>@exam_group.cce_exam_category_id}).collect{|f| @fa_group_names << f.name.split(' ').last unless @fa_group_names.include?(f.name.split(' ').last)}
      end
      @fa_group_names.sort!
      @fa_group_sms_sent = get_sms_sent_status(@exam_group.id)
      @fa_group_status = get_fa_statuses(@exam_group.id)
      @exam_group.exam_group_fa_statuses.each do |e|
        @fa_group_status << e.fa_group
      end
    end
  end
  
  def fa_group_result_publish
    @exam_group_fa_status = ExamGroupFaStatus.create(:exam_group_id => params[:exam_group_id],:fa_group=>params[:fa_group])
    @fa_group = params[:fa_group]
    @exam_group = ExamGroup.find params[:exam_group_id]
    @batch = @exam_group.batch
    students = Student.find_all_by_batch_id(params[:batch_id])
    guardians = students.map {|x| x.immediate_contact.user_id if x.immediate_contact.present?}.compact
    available_user_ids = students.collect(&:user_id).compact
    available_user_ids << guardians
#    Delayed::Job.enqueue(
#      DelayedReminderJob.new( :sender_id  => current_user.id,
#        :recipient_ids => available_user_ids,
#        :subject=>"#{t('result_published')}",
#        :body=>"#{params[:fa_group]} #{t('result_has_been_published')}  <br/>#{t('view_reports')}")
#    )
    content = "#{params[:fa_group]} #{t('result_has_been_published')}  <br/>#{t('view_reports')}"
    links = {:target=>'view_reports',:target_param=>'student_id'}
    inform(available_user_ids,content,'Event-Examination',links)
    @sms_setting_notice = "#{t('exam_result_published')}"
    @fa_group_sms_sent = get_sms_sent_status(@exam_group.id)
    @fa_group_status = get_fa_statuses(@exam_group.id)
    render(:update) do |page|
      page.replace_html 'flash_msg', :text=>"<p class='flash-msg'>#{@sms_setting_notice}</p>"
      page.replace_html "#{params[:fa_group]}", :partial=>"exam_groups/fa_sms_status", :object=>@fa_group_status
    end
  end
  
  def sent_resend_fa_group_publish_sms
    @exam_group = ExamGroup.find params[:exam_group_id]
    @exam_group_fa_status = @exam_group.exam_group_fa_statuses.find_by_fa_group(params[:fa_group])
    @fa_group = params[:fa_group]
    sms_setting = SmsSetting.all(:conditions=>["settings_key = ?","ExamScheduleResultEnabled"])
    student_sms_setting = settings.select{|x| x.user_type=="Student"}
    guardian_sms_setting = settings.select{|x| x.user_type=="Guardian"}
    students = @exam_group.batch.students
    if @sms_setting.application_sms_active and @sms_setting.exam_result_schedule_sms_active
      @exam_group_fa_status.update_attributes(:send_or_resend_sms => true)
      @sms_setting_notice = "#{t('sent_sms_notification')}"
      
    else
      @sms_setting_notice = "#{t('no_sent_sms_notification')}"
    end
    @fa_group_sms_sent = get_sms_sent_status(@exam_group.id)
    @fa_group_status = get_fa_statuses(@exam_group.id)
    render(:update) do |page|
      page.replace_html 'flash_msg', :text=>"<p class='flash-msg'>#{@sms_setting_notice}</p>"
      page.replace_html "#{params[:fa_group]}", :partial=>"exam_groups/fa_sms_status", :object=>@fa_group_sms_sent
    end
  end

  def subject_list
    @batch=Batch.find(params[:batch_id])
    @exam_group=ExamGroup.find(params[:exam_group_id])
    if @current_user.admin or @current_user.privileges.include?(Privilege.find_by_name("ExaminationControl")) or @current_user.privileges.include?(Privilege.find_by_name("EnterResults"))
      @subjects=@batch.subjects.active
    elsif @current_user.is_a_subject_teacher
      @subjects=@current_user.employee_record.subjects.active.all(:conditions=>{:batch_id=>@batch.id,:no_exams=>false}).uniq
    else
      @subjects=[]
    end
  end

  private
  def initial_queries
    @batch = Batch.find params[:batch_id], :include => :course unless params[:batch_id].nil?
    @course = @batch.course unless @batch.nil?
  end
  def get_fa_statuses(exam_group_id)
    exam_group = ExamGroup.find exam_group_id
    fa_group_status = []
    exam_group.exam_group_fa_statuses.each do |e|
      fa_group_status << e.fa_group
    end
    return fa_group_status
  end
  
  def get_sms_sent_status(exam_group_id)
    exam_group = ExamGroup.find exam_group_id
    fa_group_sms_sent = []
    exam_group.exam_group_fa_statuses.each do |e|
      fa_group_sms_sent << e.fa_group if e.send_or_resend_sms
    end
    return fa_group_sms_sent
  end

end
