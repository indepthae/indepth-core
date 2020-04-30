class OnlineStudentExamController < ApplicationController
  require 'will_paginate/array'
  before_filter :login_required#,:only_student_allowed,:online_exam_enabled
  before_filter :check_updating_status
  filter_access_to :all, :except=>[:view_answersheet], :attribute_check=>true, :load_method=>lambda{current_user}
  filter_access_to [:view_answersheet], :attribute_check=>true, :load_method=>lambda{OnlineExamAttendance.find(params[:id])}
  def index
    @student = current_user.student_record
    @exams = @student.available_online_exams
    if request.post?
      unless params[:exam][:exam_id].blank?
        @current_exam = OnlineExamGroup.find(params[:exam][:exam_id])
        render :update do |page|
          page.replace_html 'box', :partial=>'details'
        end
      else
        flash[:warn_notice]="#{t('please_select_one_exam')}"
        render :update do |page|
          page.replace_html 'errors', :partial=>'errors'
        end
      end
    end
  end

  def view_results
    @student = current_user.student_record
    @attendances = @student.online_exam_attendances.all(:include=>[:online_exam_group], :order=>"start_time DESC")
    @attendances.reject!{|a| a.online_exam_group.result_published==false}
    @attendances.reject!{|a| a.is_exam_over? == false}
  end

  def view_answersheet
    @exam_attendance = OnlineExamAttendance.find(params[:id])
    @exam = @exam_attendance.online_exam_group
    @max_marks = @exam.online_exam_groups_questions.sum(:mark).to_f
    @exam_questions = @exam.online_exam_groups_questions.paginate(:per_page=>5,:page=>params[:page],:order=>"position ASC",:include=>[:online_exam_question])
    @student = current_user.student_record
    @answers = @exam_attendance.online_exam_score_details.all(:conditions=>{:online_exam_question_id=>@exam_questions.collect(&:online_exam_question_id)}).group_by(&:online_exam_question_id)
  end

  def start_exam
    @student = Student.find_by_user_id(current_user.id,:select=>"id,batch_id")
    @exam = @student.available_online_exams.find_by_id(params[:id].to_i)
    if @exam.present?
      unless @exam.already_attended(@student.id)
        @exam_attendance = OnlineExamAttendance.create(:online_exam_group_id=> @exam.id, :student_id=>@student.id, :start_time=>Time.now, :batch_id=>@student.batch_id)
        if @exam.randomize_questions==true
          @exam_questions=@exam.online_exam_groups_questions.shuffle_it(current_user.id).paginate(:per_page=>5,:page=>params[:page], :include=>:online_exam_question)
        else
          @exam_questions=@exam.online_exam_groups_questions.paginate(:per_page=>5,:page=>params[:page],:order=>"position ASC", :include=>:online_exam_question)
        end
        @descriptive_answers = @exam_questions.select{|q| q.online_exam_question.question_format == "descriptive"}.map{|d| @exam_attendance.online_exam_score_details.build(:online_exam_question_id=>d.online_exam_question_id)}.group_by(&:online_exam_question_id)
        question_ids=@exam_questions.collect(&:id)
        @options=OnlineExamOption.all(:conditions=>{:id=>@exam_questions.collect(&:answer_ids).flatten.compact}).map {|op| @exam_attendance.online_exam_score_details.build(:online_exam_question_id=>op.online_exam_question_id, :online_exam_option_id=>op.id)}.group_by(&:online_exam_question_id)
      else
        render :partial => 'already_attended' and return
      end
      render :layout => false
    else
      flash[:notice]=t('flash_msg4')
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def started_exam
    @exam = OnlineExamGroup.find(params[:id])
    @exam_attendance = OnlineExamAttendance.find(params[:attendance_id])
    render :partial => 'late_submit' and return if @exam_attendance.start_time+@exam_attendance.online_exam_group.maximum_time.minutes+2.minutes < Time.now
    if @exam.randomize_questions==true
      @exam_questions=@exam.online_exam_groups_questions.shuffle_it(current_user.id).paginate(:per_page=>5,:page=>params[:page], :include=>:online_exam_question)
    else
      @exam_questions=@exam.online_exam_groups_questions.paginate(:per_page=>5,:page=>params[:page],:order=>"position ASC", :include=>:online_exam_question)
    end
    @descriptive_answers = @exam_questions.select{|q| q.online_exam_question.question_format == "descriptive"}.map{|d| @exam_attendance.online_exam_score_details.first(:conditions=>{:online_exam_question_id=>d.online_exam_question_id}).present? ? @exam_attendance.online_exam_score_details.first(:conditions=>{:online_exam_question_id=>d.online_exam_question_id}) : @exam_attendance.online_exam_score_details.build(:online_exam_question_id=>d.online_exam_question_id)}.group_by(&:online_exam_question_id)
    question_ids=@exam_questions.collect(&:online_exam_question_id)
    @selected_options=@exam_attendance.online_exam_score_details.all(:select=>"id,online_exam_option_id",:conditions=>{:online_exam_question_id=>question_ids,:online_exam_attendance_id=>@exam_attendance.id}).group_by(&:online_exam_option_id)
    @options=OnlineExamOption.all(:conditions=>{:id=>@exam_questions.collect(&:answer_ids).flatten.compact}).map {|op| @exam_attendance.online_exam_score_details.build(:online_exam_question_id=>op.online_exam_question_id, :online_exam_option_id=>op.id)}.group_by(&:online_exam_question_id)
    render :update do |page|
      page.replace_html 'questions', :partial=>'exam_questions'
    end
  end

  def save_scores
    @exam_attendance = OnlineExamAttendance.find(params[:attendance_id])
    render :partial => 'late_submit' and return if @exam_attendance.start_time+@exam_attendance.online_exam_group.maximum_time.minutes+2.minutes < Time.now
    @exam_attendance.update_attributes(:online_exam_score_details_attributes=>params[:online_exam_attendance][:online_exam_score_details_attributes])
    render :nothing=>true
  end

  def save_final_score
    @exam_attendance = OnlineExamAttendance.find(params[:attendance_id])
    render :partial => 'late_submit' and return if @exam_attendance.start_time+@exam_attendance.online_exam_group.maximum_time.minutes+2.minutes < Time.now
    @exam_attendance.update_attributes(:online_exam_score_details_attributes=>params[:online_exam_attendance][:online_exam_score_details_attributes])
    @exam_attendance.reload
    @total_score = @exam_attendance.online_exam_group.online_exam_groups_questions.sum('mark')
    score = @exam_attendance.student_score
    pass_mark = (@total_score*@exam_attendance.online_exam_group.pass_percentage.to_f)/100
    score >= pass_mark ? passed = true : passed = false
    if @exam_attendance.online_exam_group.exam_format=="hybrid"
      evaluated=false
    else
      evaluated=true
    end
    @exam_attendance.update_attributes(:total_score=>score, :is_passed=>passed, :end_time=>local_time_zone, :answers_evaluated=>evaluated)
    render :nothing=>true
  end

  def save_exam
    @exam_attendance = OnlineExamAttendance.find(params[:attendance_id])
    render :partial => 'late_submit' and return if @exam_attendance.start_time+@exam_attendance.online_exam_group.maximum_time.minutes+2.minutes < Time.now
    @exam_attendance.update_attributes(:online_exam_score_details_attributes=>params[:online_exam_attendance][:online_exam_score_details_attributes])
    @exam_attendance.reload
    @total_score = @exam_attendance.online_exam_group.online_exam_groups_questions.sum('mark')
    score = @exam_attendance.student_score
    pass_mark = (@total_score*@exam_attendance.online_exam_group.pass_percentage.to_f)/100
    score >= pass_mark ? passed = true : passed = false
    if @exam_attendance.online_exam_group.exam_format=="hybrid"
      evaluated=false
    else
      evaluated=true
    end
    if @exam_attendance.update_attributes(:total_score=>score, :is_passed=>passed, :end_time=>local_time_zone, :answers_evaluated=>evaluated)
      flash.now[:notice]="#{t('you_have_successfully_completed_the_exam')}"
    end
    render :layout => false and return
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

def local_time_zone
  server_time = Time.now
  server_time_to_gmt = server_time.getgm
  local_tzone_time = server_time
  time_zone = Configuration.find_by_config_key("TimeZone")
  unless time_zone.nil?
    unless time_zone.config_value.nil?
      zone = TimeZone.find_by_id(time_zone.config_value)
      if zone.present?
        if zone.difference_type=="+"
          local_tzone_time = server_time_to_gmt + zone.time_difference
        else
          local_tzone_time = server_time_to_gmt - zone.time_difference
        end
      end
    end
  end
  return local_tzone_time
end
