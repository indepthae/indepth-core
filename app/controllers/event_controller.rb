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

class EventController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  check_request_fingerprint :create, :update
  
  require 'lib/override_errors'
  helper OverrideErrors

  def index
    @events = Event.new(params[:event])
    @events.bulid_batches_and_departments
    @events.is_common = true
    deliver_plugin_block :fedena_reminder do
      @events.build_alert_settings if request.get?
    end
    if params[:id].nil?
      @date = FedenaTimeSet.current_time_to_local_time(Time.now)
    else
      date = params[:id].to_date
      @date = date.to_time
    end
  end
  
  def create
    @events = Event.new(params[:event])
    unless params[:confirm_attendance].present?
      @flag = false
      if @events.valid? 
        @flag = true
        if params[:event][:is_holiday] == "1"
          @att=Event.check_attendance(params)
        end
        if @att.present?
          render_confirm_box 
        else
          save_event(params,@events)
        end
      else
        @events.bulid_batches_and_departments
        deliver_plugin_block :fedena_reminder do
          @events.set_alert_settings(params.fetch(:event,{})[:event_alerts_attributes])
        end
        @date = params[:event][:start_date].to_time
      end
    else
      save_event(params,@events)
    end
  end
  
  def update
    @events = Event.find(params[:id])
    @events.attributes = params[:event]
    unless params[:confirm_attendance].present?
      @flag = false
      if @events.valid? 
        @flag = true
        if params[:event][:is_holiday] == "1"
          @att=Event.check_attendance(params)
        end
        if @att.present?
          render_update_confirm_box 
        else
          update_event(params)
        end
      else
        @events.bulid_batches_and_departments
        deliver_plugin_block :fedena_reminder do
          @events.set_alert_settings(params.fetch(:event,{})[:event_alerts_attributes])
        end
      end
    else
      update_event(params)
    end
  end

  def event_group
    @event = Event.find(params[:id])
  end

  def course_event
    event = Event.find(params[:id])
    batch_id_list = params[:select_options][:batch_id] unless params[:select_options].nil?
    unless batch_id_list.nil?
      batch_id_list.each do |c|
        batch_event_exists = BatchEvent.find_by_event_id_and_batch_id(event.id,c)
        if batch_event_exists.nil?
          BatchEvent.create(:event_id => event.id,:batch_id=>c)
        end
      end
    end

    flash[:notice] = "#{t('flash1')}"
    redirect_to :action=>"show", :id => event.id
  end

  def remove_batch
    @batch_event = BatchEvent.find(params[:id])
    @event = @batch_event.event_id
    @batch_event.delete
    flash[:notice] = "#{t('batches.flash4')}"
    redirect_to :action=>"show", :id=>@event
  end

  def select_employee_department
    @event_id = params[:id]
    @employee_department = EmployeeDepartment.active_and_ordered
    render :update do |page|
      page.replace_html 'select-options', :partial => 'select_employee_department'
    end
  end

  def department_event
    event = Event.find(params[:id])
    department_id_list = params[:select_options][:department_id] unless params[:select_options].nil?
    unless department_id_list.nil?
      department_id_list.each do |c|
        department_event_exists = EmployeeDepartmentEvent.find_by_event_id_and_employee_department_id(event.id,c)
        if department_event_exists.nil?
          EmployeeDepartmentEvent.create(:event_id=>event.id,:employee_department_id=>c)
        end
      end
    end
    flash[:notice] = "#{t('flash2')}"
    redirect_to :action=>"show", :id=>event.id
  end

  def remove_department
    @department_event = EmployeeDepartmentEvent.find(params[:id])
    @event = @department_event.event_id
    @department_event.delete
    flash[:notice] = "#{t('flash4')}"
    redirect_to :action=>"show", :id=>@event
  end

  def show
    @event = Event.find(params[:id])
    @command = params[:cmd]
    event_start_date = "#{@event.start_date.year}-#{@event.start_date.month}-#{@event.start_date.day}".to_date
    event_end_date = "#{@event.end_date.year}-#{@event.end_date.month}-#{@event.end_date.day}".to_date
    @other_events = Event.find(:all, :conditions=>"id != #{@event.id}")
    if @event.is_common ==false
      @batch_events = BatchEvent.find(:all, :conditions=>"event_id = #{@event.id}")
      @department_event = EmployeeDepartmentEvent.find(:all, :conditions=>"event_id = #{@event.id}")
    end
  end

  def cancel_event
    event = Event.find(params[:id])
    batch_event = BatchEvent.find(:all, :conditions=>"event_id = #{params[:id]}")
    dept_event = EmployeeDepartmentEvent.find(:all, :conditions=>"event_id = #{params[:id]}")
    event.destroy

    batch_event.each { |x| x.destroy } unless batch_event.nil?
    dept_event.each { |x| x.destroy } unless dept_event.nil?
    flash[:notice] ="#{t('flash3')}"
    redirect_to :action=>"index"
  end

  def edit_event
    @events = Event.find(params[:id])
    @events.bulid_batches_and_departments
    if @events.nil?
      page_not_found
    end
    deliver_plugin_block :fedena_reminder do
      @events.set_alert_settings(params.fetch(:event,{})[:event_alerts_attributes])
    end
  end
  
  private
  def render_confirm_box
    respond_to do |format|
      format.js { render :action => 'create' }
    end
  end
  def render_update_confirm_box
    respond_to do |format|
      format.js { render :action => 'update' }
    end
  end
  
  def save_event(params,events)
    if events.save
      event_reminder_messages(params,events)
    end
  end
  
  def update_event(params)
    events = Event.find(params[:id].to_i)
    if events.update_attributes(params[:event])
      event_reminder_messages(params,events)
    end
  end
  
  def event_reminder_messages(params,events)
    reminder_recipient_ids,reminder_subject,reminder_body=Event.create_event(params,events.id)
    events.manual = true
    events.verify_update_and_send_sms
    links = {:target=>'view_calendar'}
    inform(reminder_recipient_ids,reminder_body,'Event',links)
    render :update do |page|
      page.redirect_to :controller=>'calendar',:action=>'index'
    end
  end
end



