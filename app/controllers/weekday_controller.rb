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
include WeekdayArranger
class WeekdayController < ApplicationController
  before_filter :login_required
  before_filter :fetch_default_weekdays
  filter_access_to :all
  before_filter :check_status
  before_filter :default_time_zone_present_time
  require 'set'

  def index
    @courses=Course.active
    @default_weekday_class_timing_set=BatchClassTimingSet.default
  end

  def list_batches
    if params[:course_id].present?
      @course=Course.find(params[:course_id])
      @batches=@course.batches.active
      @default_weekday_class_timing_set=BatchClassTimingSet.default
      render(:update) do |page|
        page.replace_html "batch_space", :partial=>"list_batches"
      end
    else
      @default_weekday_class_timing_set=BatchClassTimingSet.default
      render(:update) do |page|
        page.replace_html "batch_space", :text=>""
        page.replace_html "weekdays", :partial => "weekdays"
      end
    end
  end

  def week
    if params[:batch_id] == ''
      @default_weekday_class_timing_set=BatchClassTimingSet.default
    else
      @batch  = Batch.find params[:batch_id]
      @default_weekday_class_timing_set=@batch.batch_class_timing_sets || BatchClassTimingSet.default
    end
    render :update do |page|
      page.replace_html 'flash-box',:text=>""
      page.replace_html "weekdays", :partial => "weekdays"
    end
  end

  def get_class_timing_sets
    @weekday_id=params[:id]
    @class_timing_sets=ClassTimingSet.all
    render :partial=>"get_class_timing_sets"
  end

  def get_class_timing_set_for_edit
    @weekday_id=params[:id]
    @key_id=params[:key_id]
    @class_timing_sets=ClassTimingSet.all
    render :partial=>"get_class_timing_set_for_edit"
  end

  def create
    unless params[:batch_id]==""
      @batch =  Batch.find_by_id(params[:batch_id])
      applicable_from=(params[:applicable_from].to_date).to_datetime
      new_weekdays=params[:weekdays].map(&:to_i)
      weekday_set_found = nil
      flag = 0
      weekday_sets = WeekdaySet.all(:include=>:weekday_sets_weekdays).map{|ws| [ws.id,Set.new(ws.weekday_ids)]}
      weekday_sets.each do |weekday_set|
        if weekday_set.second == Set.new(new_weekdays)
          flag = 1
          weekday_set_found = weekday_set
        end
      end
      @attendances_after_split=@batch.attendances.all(:conditions=>["month_date > ?",applicable_from.to_date]).collect(&:month_date).map {|x| x.wday}.uniq
      @issue_days=@attendances_after_split-new_weekdays
      if flag == 1
        if @issue_days.blank?
          if @batch.update_attribute(:weekday_set_id,weekday_set_found.first)
            @batch.update_attributes(params[:batch])
            unless @batch.errors.nil?
              if @batch.end_date >= applicable_from
                AttendanceWeekdaySet.all(:conditions=>["batch_id=? and start_date >= ? and end_date <= ?",@batch.id,applicable_from,@batch.end_date]).each do |aws|
                  aws.destroy
                end
                last_weekday_set=@batch.attendance_weekday_sets.last
                last_weekday_set.update_attributes(:end_date=>applicable_from-1) if last_weekday_set.present?
                start_date_val=applicable_from >= @batch.start_date ? applicable_from : @batch.start_date
                AttendanceWeekdaySet.create(:batch_id=>@batch.id,:weekday_set_id=>weekday_set_found.first,:start_date=>start_date_val,:end_date=>@batch.end_date)
              end
            end
          end
        end
      else
        if @issue_days.blank?
          weekday_set = WeekdaySet.create
          weekday_set.weekday_ids = new_weekdays
          if @batch.update_attribute(:weekday_set_id,weekday_set.id)
            @batch.update_attributes(params[:batch])
            unless @batch.errors.nil? 
              if @batch.end_date >= applicable_from
                AttendanceWeekdaySet.all(:conditions=>["batch_id=? and start_date >= ? and end_date <= ?",@batch.id,applicable_from,@batch.end_date]).each do |aws|
                  aws.destroy
                end
                last_weekday_set=@batch.attendance_weekday_sets.last
                last_weekday_set.update_attributes(:end_date=>applicable_from-1) if last_weekday_set.present?
                start_date_val=applicable_from >= @batch.start_date ? applicable_from : @batch.start_date
                AttendanceWeekdaySet.create(:batch_id=>@batch.id,:weekday_set_id=>weekday_set.id,:start_date=>start_date_val,:end_date=>@batch.end_date)
              end
            end
          end
        end
      end
    else
      update_common_batch_class_timing_set(params[:batch][:batch_class_timing_sets_attributes].values,params[:weekdays])
    end
    if @batch.present?
      @batch.reload
      @default_weekday_class_timing_set=@batch.batch_class_timing_sets || BatchClassTimingSet.default
    else
      @default_weekday_class_timing_set=BatchClassTimingSet.default
    end
    weekdays_list = "#{@issue_days.map(&:to_i).map{|i| Date::DAYNAMES[i]}.join('(s), ')}(s)" unless @issue_days.blank?
    render :update do |page|
      page.replace_html 'flash-box',:text=>"<p class='flash-msg'> #{t('weekdays_modified')}</p>" if @issue_days.blank?
      page.replace_html 'flash-box',:text=>"<div class='errorExplanation'><p>#{t('activerecord.errors.template.body')}</p><ul><li>#{t('weekdays_unable_to_change_warning',:weekdays_list => weekdays_list)} </li></ul></div>" unless @issue_days.blank?
      unless params[:batch_id]==""
        page.replace_html 'flash-box',:text=>"<div class='errorExplanation'><p>#{t('activerecord.errors.template.body')}</p><ul><li>#{t('the_selected_class_timing_set_has_been_deleted')} </li></ul></div>" unless @batch.errors.empty?
      else
        page.replace_html 'flash-box',:text=>"<div class='errorExplanation'><p>#{t('activerecord.errors.template.body')}</p><ul><li>#{t('the_selected_class_timing_set_has_been_deleted')} </li></ul></div>" if @batch_class_timings==false
      end
      page.replace_html "weekdays", :partial => "weekdays"
    end
  end

  private

  def fetch_default_weekdays
    @default_weekdays = hash_weekdays
  end

  def update_common_batch_class_timing_set(params,weekdays)
    params.each do |param|
      if param[:_destroy].to_i==1 and param[:id].present?
        @batch_class_timings=BatchClassTimingSet.find(param[:id].to_i).destroy
      elsif param[:_destroy].to_i==0 and param[:id].present? and param[:class_timing_set_id].present?
        @batch_class_timings=BatchClassTimingSet.find(param[:id].to_i).update_attributes("class_timing_set_id"=>"#{param[:class_timing_set_id].to_i}")
      elsif param[:_destroy].to_i==0 and !param[:id].present?
        @batch_class_timings=BatchClassTimingSet.create(:weekday_id=>param[:weekday_id].to_i,:class_timing_set_id=>param[:class_timing_set_id].to_i)
      end
    end
    new_weekdays=weekdays.map(&:to_i)
    weekday_set_found = nil
    flag = 0
    weekday_sets = WeekdaySet.all(:include=>:weekday_sets_weekdays).map{|ws| [ws.id,Set.new(ws.weekday_ids)]}
    weekday_sets.each do |weekday_set|
      if weekday_set.second == Set.new(new_weekdays)
        flag = 1
        weekday_set_found = weekday_set
      end
    end
    if flag == 1
      WeekdaySet.common.update_attribute('is_common',false)
      WeekdaySet.find(weekday_set_found.first).update_attribute('is_common',true)
    else
      weekday_set = WeekdaySet.create
      weekday_set.weekday_ids = new_weekdays
      WeekdaySet.common.update_attribute('is_common',false)
      WeekdaySet.find(weekday_set.id).update_attribute('is_common',true)
    end
    @batch_class_timings
  end
end
