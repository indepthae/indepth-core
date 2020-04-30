class AttendanceLabelsController < ApplicationController
  before_filter :login_required
  before_filter :default_time_zone_present_time
  before_filter :check_status

  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors

  def index
    @attendance_labels = AttendanceLabel.create_default_labels
    @config = Attendance.attendacne_type_status
    attendance_config = Configuration.get_config_value('AttendanceCalculation')
    @at_config = attendance_config if attendance_config.present?
    @enable = @config == "1" ? 1 : 0
    AttendanceSetting.create_attendance_lock_configuration
    @attendance_lock = AttendanceSetting.find_by_setting_key('AttendanceLock')
    @at_lock_duration = Configuration.get_config_value('AttendanceLockDuration')
  end

  #  def create
  #    @config = Attendance.attendacne_type_status
  #    if @config == "1"
  #      @attendance_label = AttendanceLabel.new(params[:attendance_label])
  #      if @attendance_label.save
  #        flash[:notice] = "Added"
  #        redirect_to attendance_labels_path
  #      else
  #        @attendance_labels = AttendanceLabel.all
  #        render :action => 'index'
  #      end
  #    end
  #  end


  def edit
    @attendance_label = AttendanceLabel.find(params[:id])
  end

  def update
    @attendance_label = AttendanceLabel.find(params[:id])
    if  @attendance_label.update_attributes(params[:attendance_label])
      @attendance_labels = AttendanceLabel.all
      flash[:notice] = "#{t('update_label_details')}"
      redirect_to attendance_labels_path
    else
      @attendance_labels = AttendanceLabel.all
      @config = Attendance.attendacne_type_status
      render :action => 'edit'
    end
  end

  #
  #  def delete_label
  #    attendance_label = AttendanceLabel.find(params[:id])
  #    unless attendance_label.is_default?
  #      @absent = Attendance.find_by_attendance_label_id(params[:id])
  #      unless  @absent.present?
  #        if attendance_label.present? and attendance_label.destroy
  #          flash[:notice] = "#{t('delete_label_details')}"
  #          redirect_to attendance_labels_path
  #        else
  #          flash[:notice] = " Not Delete"
  #          redirect_to attendance_labels_path
  #        end
  #      else
  #        flash[:notice] = "#{t('delete_label_detail_dependent_data')}"
  #        redirect_to attendance_labels_path
  #      end
  #    else
  #      flash[:notice] = "#{t('default_label_details')}"
  #      redirect_to attendance_labels_path
  #    end
  #
  #  end

  def make_configuration
    @enable = params[:attendance_status][:enable] if params[:attendance_status][:enable].present?
    attendance_calculations = params[:attendance_status][:attendance_calculation].present? ? params[:attendance_status][:attendance_calculation] : ''
    Configuration.set_value('AttendanceCalculation', attendance_calculations.to_s)   if attendance_calculations.present?
    attendance_lock = params[:attendance_status][:mark_frequency].present? ? params[:attendance_status][:mark_frequency] : ''
    lock_value = (attendance_lock.present? and attendance_lock == '1')  ? true : false
    AttendanceSetting.attendance_lock_setting('AttendanceLock',lock_value) if attendance_lock.present?
    lock_duration = params[:attendance_status][:lock_duration].present? ? params[:attendance_status][:lock_duration] : ''
    lock_duration = Configuration.set_value("AttendanceLockDuration", lock_duration) if lock_duration.present?
    Delayed::Job.enqueue(DelayedSaveStudentAttendance.new(current_user),{:queue => "attendance"}) if lock_value
    if @enable == '1'
      if Configuration.set_value('CustomAttendanceType', "1")
        @attendance_labels = AttendanceLabel.all
        render_response
      end
    else
      render_response if Configuration.set_value('CustomAttendanceType', "0")
    end
  end



  private

  def render_response
    render :update do |page|
      flash[:notice] = "#{t('attendance_settings_updated')}"
      page.redirect_to attendance_labels_path
    end

  end


end
