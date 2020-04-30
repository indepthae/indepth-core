class RecordGroupsController < ApplicationController

  filter_access_to :all
  before_filter :login_required

  def index
    @record_groups=RecordGroup.paginate(:per_page=>20,:page=>params[:page],:select=>'id,name,is_active',:order=>'is_active desc,id desc')
  end
  
  def new
    @record_group=RecordGroup.new
  end

  def create
    @record_group=RecordGroup.new(params[:record_group])
    if @record_group.save
      @record_groups=RecordGroup.paginate(:per_page=>20,:page=>params[:page],:select=>'id,name,is_active',:order=>'is_active desc,id desc')
      flash.now[:notice]="#{t('record_group_created')}"
    else
      @error=true
    end
  end

  def edit
    @record_group=RecordGroup.find(params[:id])
  end

  def update
    @record_group=RecordGroup.find(params[:id])
    if @record_group.update_attributes(params[:record_group])
      @record_groups=RecordGroup.paginate(:per_page=>20,:page=>params[:page],:select=>'id,name,is_active',:order=>'is_active desc,id desc')
      flash.now[:notice]="#{t('record_group_updated')}"
    else
      @error=true
    end
  end

  def delete_warning
    @course=Course.find(params[:course_id],:include=>[:record_groups,:record_batch_assignments,:student_records]) if params[:course_id].present?
    @record_group=RecordGroup.find(params[:id],:include=>[{:courses=>:batches},:student_records])
    render :update do |page|
      if @course.present? and (@course.record_groups.present? or @course.record_batch_assignments.present? or @course.student_records.present?)
        page.replace_html 'modal-box', :partial => 'delete_warning_with_content_course',:object=>[@course,@record_group]
      elsif @record_group.courses.present? or @record_group.batches.present? or @record_group.student_records.present?
        page.replace_html 'modal-box', :partial => 'delete_warning_with_content',:object=>@record_group
      else
        page.replace_html 'modal-box', :partial => 'delete_warning_without_content',:object=>@record_group
      end
    end
  end

  def destroy
    @course=Course.find(params[:course_id],:include=>:batches) if params[:course_id]
    if @course.present?
      @course.record_assignments.all(:conditions=>{:record_group_id=>params[:id]}).each do |ra|
        RecordBatchAssignment.delete_all(["batch_id IN (?) and record_assignment_id=?",@course.batches.collect(&:id),ra.id])
        StudentRecord.delete_all(["batch_id IN (?) and additional_field_id IN (?)",@course.batches.collect(&:id),RecordGroup.find(params[:id]).records.collect(&:id)])
        ra.delete
      end
      @assigned_batches_count=Batch.count(:joins=>[:record_groups,:course],:conditions=>{:courses=>{:id=>@course.id}})
      @rg_remains=RecordGroup.active.count(:conditions=>["id NOT IN (?)",@course.record_assignments.collect(&:record_group_id)])
      @course_record_groups=@course.record_groups.all(:select=>'DISTINCT record_groups.id as rgid,record_groups.name rgname,record_assignments.course_id as cid,record_groups.is_active as rg_status,count(IF(batches.is_active=1,batches.id,NULL)) as active_batches_count,count(IF(batches.is_active=0,batches.id,NULL)) as inactive_batches_count',:joins=>"LEFT OUTER JOIN `record_batch_assignments` ON `record_batch_assignments`.`record_group_id` = `record_groups`.`id` and record_batch_assignments.batch_id IN (#{@course.batches.usable.all.collect(&:id).join(",")}) LEFT OUTER JOIN `batches` ON `batches`.`id` = `record_batch_assignments`.`batch_id`",:order=>'record_assignments.priority asc',:group=>'record_groups.id').group_by(&:rg_status)
    else
      @record_group=RecordGroup.find(params[:id])
      @record_group.destroy
    end
    @record_groups=RecordGroup.paginate(:per_page=>20,:page=>params[:page],:select=>'id,name,is_active',:order=>'is_active desc,id desc')
    flash.now[:notice]="#{t('record_group_deleted')}"
  end

  def manage_record_groups
    @courses_list_paginator=Course.active.paginate(:per_page=>20,:page=>params[:page],:select=>'courses.id,courses.course_name cname,if(count(record_assignments.id),1,count(record_assignments.id)) occurrence,count(DISTINCT IF(batches.course_id=courses.id,batches.id,NULL)) bcount,courses.grading_type',:joins=>"LEFT OUTER JOIN `record_assignments` ON (`courses`.`id` = `record_assignments`.`course_id`) LEFT OUTER JOIN `record_groups` ON (`record_groups`.`id` = `record_assignments`.`record_group_id`) LEFT OUTER JOIN `record_batch_assignments` ON (`record_groups`.`id` = `record_batch_assignments`.`record_group_id`) LEFT OUTER JOIN `batches` ON (`batches`.`id` = `record_batch_assignments`.`batch_id`)",:group=>'courses.id',:order=>'occurrence desc')
  end

  def add_record_groups_to_course
    @course=Course.active.find(params[:id],:include=>:record_assignments)
    unless @course.record_assignments.blank?
      @last_priority=@course.record_assignments.last.priority
    else
      @last_priority=0
    end
    @from_action=params[:from_action]||"manage_all"
    @active_batches=@course.batches.active.all(:conditions=>{:is_deleted=>false})
    @inactive_batches=@course.batches.inactive.all(:conditions=>{:is_deleted=>false})
    rg_ids=@course.record_assignments.collect(&:record_group_id)
    unless rg_ids.blank?
      @active_record_groups=RecordGroup.active.all(:conditions=>["id NOT IN (?)",rg_ids])
    else
      @active_record_groups=RecordGroup.active
    end
    @record_assignment=RecordAssignment.new
  end

  def assign_record_groups_to_course
    @record_assignment=RecordAssignment.new(params[:record_assignment])
    @from_action=params[:from_action]
    unless @record_assignment.save
      @error=true
    end
    if @from_action=="manage_all"
      @courses_list_paginator=Course.active.paginate(:per_page=>20,:page=>params[:page],:select=>'courses.id,courses.course_name cname,if(count(record_assignments.id),1,count(record_assignments.id)) occurrence,count(DISTINCT IF(batches.course_id=courses.id,batches.id,NULL)) bcount,courses.grading_type',:joins=>"LEFT OUTER JOIN `record_assignments` ON (`courses`.`id` = `record_assignments`.`course_id`) LEFT OUTER JOIN `record_groups` ON (`record_groups`.`id` = `record_assignments`.`record_group_id`) LEFT OUTER JOIN `record_batch_assignments` ON (`record_groups`.`id` = `record_batch_assignments`.`record_group_id`) LEFT OUTER JOIN `batches` ON (`batches`.`id` = `record_batch_assignments`.`batch_id`)",:group=>'courses.id',:order=>'occurrence desc')
      flash[:notice]="#{t('record_group_assigned')}"
    else
      @course=Course.active.find(params[:id])
      @course_record_groups=@course.record_groups.all(:select=>'DISTINCT record_groups.id as rgid,record_groups.name rgname,record_assignments.course_id as cid,record_groups.is_active as rg_status,count(IF(batches.is_active=1,batches.id,NULL)) as active_batches_count,count(IF(batches.is_active=0,batches.id,NULL)) as inactive_batches_count',:joins=>"LEFT OUTER JOIN `record_batch_assignments` ON `record_batch_assignments`.`record_group_id` = `record_groups`.`id` and record_batch_assignments.batch_id IN (#{@course.batches.usable.all.collect(&:id).join(",")}) LEFT OUTER JOIN `batches` ON `batches`.`id` = `record_batch_assignments`.`batch_id`",:order=>'record_assignments.priority asc',:group=>'record_groups.id').group_by(&:rg_status)
      @rg_remains=RecordGroup.active.count(:conditions=>["id NOT IN (?)",@course.record_assignments.collect(&:record_group_id)])
    end
  end

  def manage_record_groups_for_course
    @course=Course.active.find(params[:id])
    @course_record_groups=@course.record_groups.all(:select=>'DISTINCT record_groups.id as rgid,record_groups.name rgname,record_assignments.course_id as cid,record_groups.is_active as rg_status,count(IF(batches.is_active=1,batches.id,NULL)) as active_batches_count,count(IF(batches.is_active=0,batches.id,NULL)) as inactive_batches_count',:joins=>"LEFT OUTER JOIN `record_batch_assignments` ON `record_batch_assignments`.`record_group_id` = `record_groups`.`id` and record_batch_assignments.batch_id IN (#{@course.batches.usable.all.collect(&:id).join(",")}) LEFT OUTER JOIN `batches` ON `batches`.`id` = `record_batch_assignments`.`batch_id`",:order=>'record_assignments.priority asc',:group=>'record_groups.id').group_by(&:rg_status)
    @rg_remains=RecordGroup.active.count(:conditions=>["id NOT IN (?)",@course.record_assignments.collect(&:record_group_id)])
    @assigned_batches_count=Batch.count(:joins=>[:record_groups,:course],:conditions=>{:courses=>{:id=>@course.id}})
  end

  def record_group_settings
    @record_group=RecordGroup.find(params[:id])
    @course=Course.find(params[:course_id])
    @batches_list=@course.batches.usable.all(:select=>'batches.id bid,batches.name bname,batches.is_active bstatus',:order=>'bstatus desc').group_by(&:bstatus)
    @associated_batches=@course.record_assignments.all(:select=>'record_batch_assignments.batch_id bids',:conditions=>{:record_group_id=>@record_group.id},:joins=>:record_batch_assignments).collect(&:bids)
    @record_assignment=RecordAssignment.find_by_record_group_id_and_course_id(@record_group.id,@course.id)
    render :update do |page|
      page.replace_html 'modal-box', :partial => 'record_group_settings'
      page << "Modalbox.show($('modal-box'), {title: '#{t('record_group_setting_for_course')}', width: 650});"
    end
  end

  def save_record_group_settings_for_course
    @course=Course.find(params[:course_id])
    @record_assignment=RecordAssignment.find(params[:id])
    if @record_assignment.update_attributes(params[:record_assignment])
      @assigned_batches_count=Batch.count(:joins=>[:record_groups,:course],:conditions=>{:courses=>{:id=>@course.id}})
      @rg_remains=RecordGroup.active.count(:conditions=>["id NOT IN (?)",@course.record_assignments.collect(&:record_group_id)])
      @course_record_groups=@course.record_groups.all(:select=>'DISTINCT record_groups.id as rgid,record_groups.name rgname,record_assignments.course_id as cid,record_groups.is_active as rg_status,count(IF(batches.is_active=1,batches.id,NULL)) as active_batches_count,count(IF(batches.is_active=0,batches.id,NULL)) as inactive_batches_count',:joins=>"LEFT OUTER JOIN `record_batch_assignments` ON `record_batch_assignments`.`record_group_id` = `record_groups`.`id` and record_batch_assignments.batch_id IN (#{@course.batches.usable.all.collect(&:id).join(",")}) LEFT OUTER JOIN `batches` ON `batches`.`id` = `record_batch_assignments`.`batch_id`",:order=>'record_assignments.priority asc',:group=>'record_groups.id').group_by(&:rg_status)
      flash[:notice]="#{t('record_group_setting_saved')}"
    else
      @error=true
    end
  end

  def edit_priority
    @course=Course.find(params[:id])
    @record_assignments=@course.record_assignments.all(:order=>'record_assignments.priority asc')
    render :update do |page|
      page.replace_html 'student_items',:partial=>'edit_priority'
    end
  end

  def update_priority
    @course=Course.find(params[:id])
    @course.update_attributes(params[:course])
    @course_record_groups=@course.record_groups.all(:select=>'DISTINCT record_groups.id as rgid,record_groups.name rgname,record_assignments.course_id as cid,record_groups.is_active as rg_status,count(IF(batches.is_active=1,batches.id,NULL)) as active_batches_count,count(IF(batches.is_active=0,batches.id,NULL)) as inactive_batches_count',:joins=>"LEFT OUTER JOIN `record_batch_assignments` ON `record_batch_assignments`.`record_group_id` = `record_groups`.`id` and record_batch_assignments.batch_id IN (#{@course.batches.usable.all.collect(&:id).join(",")}) LEFT OUTER JOIN `batches` ON `batches`.`id` = `record_batch_assignments`.`batch_id`",:order=>'record_assignments.priority asc',:group=>'record_groups.id').group_by(&:rg_status)
    @rg_remains=(RecordGroup.active.count-@course.record_assignments.collect(&:record_group_id).count)
    render :update do |page|
      page.replace_html 'student_items',:partial=>'record_groups_for_course'
      page.replace_html 'flash-box',:text=>"<p class='flash-msg'> #{t('record_group_priority_updated')}</p>"
    end
  end
  
  def cancel
    @course=Course.find(params[:id])
    @course_record_groups=@course.record_assignments.all(:select=>"DISTINCT record_groups.id as rgid,record_groups.name rgname,record_assignments.course_id as cid,record_groups.is_active as rg_status,(select count(batches.id) from batches where batches.is_deleted =false and batches.is_active=true and batches.course_id=record_assignments.course_id) as active_batches_count,(select count(batches.id) from batches where batches.is_deleted =false and batches.is_active=false and batches.course_id=record_assignments.course_id) as inactive_batches_count",:joins=>"INNER JOIN `record_groups` ON `record_groups`.id = `record_assignments`.record_group_id LEFT OUTER JOIN `record_batch_assignments` ON record_batch_assignments.record_assignment_id = record_assignments.id LEFT OUTER JOIN `batches` ON `batches`.id = `record_batch_assignments`.batch_id",:order=>'record_assignments.priority asc').group_by(&:rg_status)
    @rg_remains=(RecordGroup.active.count-@course.record_assignments.collect(&:record_group_id).count)
    render :update do |page|
      page.replace_html 'student_items',:partial=>'record_groups_for_course'
    end
  end

  def student_record_preview
    @course = Course.find(params[:id])
    @batches=@course.batches.usable
    unless params[:batch_id].present?
      @batch=@batches.first
    else
      @batch=Batch.find(params[:batch_id])
    end
    @record_groups=RecordGroup.all(:select=>'distinct record_groups.*',:joins=>[:record_assignments,:record_batch_assignments],:conditions=>{:record_batch_assignments=>{:batch_id=>@batch.id},:record_assignments=>{:course_id=>@course.id}},:order=>'record_assignments.priority asc')
    if request.post?
      render :update do |page|
        page.replace_html 'batches_details',:partial=>'batches_student_records_preview'
      end
    end
  end

end
