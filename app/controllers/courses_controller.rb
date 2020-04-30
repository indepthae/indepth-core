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

class CoursesController < ApplicationController
  before_filter :login_required
  before_filter :find_course, :only => [:show, :edit, :update, :destroy]
  filter_access_to :all
  before_filter :set_precision

  def index
    @courses = Course.active
  end

  def new
    @academic_years = AcademicYear.all
    @course = Course.new
    @grade_types=Course.grading_types_as_options
    @start_date = Date.today
    @end_date = @start_date +1.year
    #    gpa = Configuration.find_by_config_key("GPA").config_value
    #    if gpa == "1"
    #      @grade_types << "GPA"
    #    end
    #    cwa = Configuration.find_by_config_key("CWA").config_value
    #    if cwa == "1"
    #      @grade_types << "CWA"
    #    end
  end

  def manage_course
    @courses = Course.active.paginate(:per_page=>20,:page=>params[:page])
  end

  def assign_subject_amount
    @course = Course.active.find(params[:id])
    @subjects = @course.batches.active.map(&:subjects).flatten.compact.map(&:code).compact.flatten.uniq
    @subject_amount = @course.subject_amounts.build
    @subject_amounts = @course.subject_amounts.find_all_by_code(@subjects)
    if request.post?
      code = params[:subject_amount][:code]
      @subject_amount = @course.subject_amounts.build(params[:subject_amount])
      if @subject_amount.save
        @subject_amounts = @course.subject_amounts.reject{|sa| sa.new_record?}
        flash[:notice] = "Subject amount saved successfully"
        redirect_to assign_subject_amount_courses_path(:id => @course.id)
      else
        render :assign_subject_amount
      end
    end
  end

  def edit_subject_amount
    @subject_amount = SubjectAmount.find(params[:subject_amount_id])
    @course = @subject_amount.course
    @subjects = @course.batches.active.map(&:subjects).flatten.compact.map(&:code).compact.flatten.uniq
    if request.post?
      if @subject_amount.update_attributes(params[:subject_amount])
        flash[:notice] = "Subject amount has been updated successfully"
        redirect_to assign_subject_amount_courses_path(:id => @subject_amount.course_id)
      else
        render :edit_subject_amount
      end
    end
  end

  def destroy_subject_amount
    subject_amount = SubjectAmount.find(params[:subject_amount_id])
    course_id = subject_amount.course_id
    subject_amount.destroy
    flash[:notice] = "Subject amount has been destroyed successfully"
    redirect_to assign_subject_amount_courses_path(:id => course_id)
  end

  def manage_batches

  end

  def grouped_batches
    @course = Course.find(params[:id])
    @batch_groups = @course.batch_groups
    @batches = @course.active_batches.reject{|b| GroupedBatch.exists?(:batch_id=>b.id)}
    @batch_group = BatchGroup.new
  end

  def create_batch_group
    @batch_group = BatchGroup.new(params[:batch_group])
    @course = Course.find(params[:course_id])
    @batch_group.course_id = @course.id
    @error=false
    if params[:batch_ids].blank?
      @error=true
    end
    if @batch_group.valid? and @error==false
      @batch_group.save
      batches = params[:batch_ids]
      batches.each do|batch|
        GroupedBatch.create(:batch_group_id=>@batch_group.id,:batch_id=>batch)
      end
      @batch_group = BatchGroup.new
      @batch_groups = @course.batch_groups
      @batches = @course.active_batches.reject{|b| GroupedBatch.exists?(:batch_id=>b.id)}
      render(:update) do|page|
        page.replace_html "category-list", :partial=>"batch_groups"
        page.replace_html 'flash', :text=>'<p class="flash-msg"> Batch Group created successfully. </p>'
        page.replace_html 'errors', :partial=>"form_errors"
        page.replace_html 'class_form', :partial=>"batch_group_form"
      end
    else
      if params[:batch_ids].blank?
        @batch_group.errors.add_to_base "Atleast one batch must be selected."
      end
      render(:update) do|page|
        page.replace_html 'errors', :partial=>'form_errors'
        page.replace_html 'flash', :text=>""
      end
    end
  end

  def edit_batch_group
    @batch_group = BatchGroup.find(params[:id])
    @course = @batch_group.course
    @assigned_batches = @course.active_batches.reject{|b| (!GroupedBatch.exists?(:batch_id=>b.id,:batch_group_id=>@batch_group.id))}
    @batches = @course.active_batches.reject{|b| (GroupedBatch.exists?(:batch_id=>b.id))}
    @batches = @assigned_batches + @batches
    render(:update) do|page|
      page.replace_html "class_form", :partial=>"batch_group_edit_form"
      page.replace_html 'errors', :partial=>'form_errors'
      page.replace_html 'flash', :text=>""
    end
  end

  def update_batch_group
    @batch_group = BatchGroup.find(params[:id])
    @course = @batch_group.course
    unless params[:batch_ids].blank?
      if @batch_group.update_attributes(params[:batch_group])
        @batch_group.grouped_batches.map{|b| b.destroy}
        batches = params[:batch_ids]
        batches.each do|batch|
          GroupedBatch.create(:batch_group_id=>@batch_group.id,:batch_id=>batch)
        end
        @batch_group = BatchGroup.new
        @batch_groups = @course.batch_groups
        @batches = @course.active_batches.reject{|b| GroupedBatch.exists?(:batch_id=>b.id)}
        render(:update) do|page|
          page.replace_html "category-list", :partial=>"batch_groups"
          page.replace_html 'flash', :text=>'<p class="flash-msg"> Batch Group updated successfully. </p>'
          page.replace_html 'errors', :partial=>"form_errors"
          page.replace_html 'class_form', :partial=>"batch_group_form"
        end
      else
        render(:update) do|page|
          page.replace_html 'errors', :partial=>'form_errors'
          page.replace_html 'flash', :text=>""
        end
      end
    else
      @batch_group.errors.add_to_base("Atleat one Batch must be selected.")
      render(:update) do|page|
        page.replace_html 'errors', :partial=>'form_errors'
        page.replace_html 'flash', :text=>""
      end
    end
  end

  def delete_batch_group
    @batch_group = BatchGroup.find(params[:id])
    @course = @batch_group.course
    @batch_group.destroy
    @batch_group = BatchGroup.new
    @batch_groups = @course.batch_groups
    @batches = @course.active_batches.reject{|b| GroupedBatch.exists?(:batch_id=>b.id)}
    render(:update) do|page|
      page.replace_html "category-list", :partial=>"batch_groups"
      page.replace_html 'flash', :text=>'<p class="flash-msg"> Batch Group deleted successfully. </p>'
      page.replace_html 'errors', :partial=>"form_errors"
      page.replace_html 'class_form', :partial=>"batch_group_form"
    end
  end

  def update_batch
    if(params[:course_name]!="")
      @course_id=params[:course_name]
      @course_id_int=@course_id.to_i
      course=Course.find(params[:course_name])
      batches_list=course.batches
      if(params[:type]=='active_batch')
        @active_batches = Batch.paginate(:all, :page => params[:page],:per_page => 20,:order=>'name ASC', :conditions => {:course_id=>@course_id, :is_deleted => false, :is_active => true })
        active_batches_count_list=batches_list.select{|b| b.is_active==true and b.is_deleted==false}
        @active_batch_count=active_batches_count_list.count
        render(:update) do |page|
          page.replace_html 'update_batch', :partial=>'update_batch'
        end
      elsif(params[:type]=='inactive_batch')
        @inactive_batches = Batch.paginate(:all,:page => params[:page],:per_page => 20,:order=>'name ASC', :conditions => {:course_id=>@course_id, :is_deleted => false, :is_active => false })
        inactive_batches_count_list=batches_list.select{|b| b.is_active==false and b.is_deleted==false}
        @inactive_batch_count=inactive_batches_count_list.count
        render(:update) do |page|
          page.replace_html 'update_batch', :partial=>'update_inactive_batch'
        end
      else
        params[:page]=1
        @active_batches = Batch.paginate(:all, :page => params[:page],:per_page => 20,:order=>'name ASC',  :conditions => {:course_id=>@course_id, :is_deleted => false, :is_active => true })
        active_batches_count_list=batches_list.select{|b| b.is_active==true and b.is_deleted==false}
        inactive_batches_count_list=batches_list.select{|b| b.is_active==false and b.is_deleted==false}
        @inactive_batch_count=inactive_batches_count_list.count
        @active_batch_count=active_batches_count_list.count
        render(:update) do |page|
          page.replace_html 'batch_updates', :partial=>'batch_updates'
          page.replace_html 'update_batch', :partial=>'update_batch'
        end
      end
    else
      render(:update) do |page|
        page.replace_html 'batch_updates', :text=>''
      end
    end
  end

  def inactivate_batch
    batch=Batch.find(params[:id])
    @course_id=batch.course_id
    if batch.students.empty?
      if batch.is_active
        batch.is_active=false
      else
        batch.is_active=true
      end
      if batch.save
        course=Course.find(@course_id)
        batches_list=course.batches
        if (params[:page]=='')
          params[:page]=1
        end
        if(params[:type]=='active')
          @active_batches = Batch.paginate(:page => params[:page],:per_page => 20,:order=>'name ASC',  :conditions => {:course_id=>batch.course_id, :is_deleted => false, :is_active => true })
          if @active_batches.empty?&&params[:page]>"1"
            @page=params[:page].to_i
            @page=@page-1
            params[:page]=@page.to_s
            @active_batches = Batch.paginate(:page => params[:page],:per_page => 20,:order=>'name ASC',  :conditions => {:course_id=>batch.course_id, :is_deleted => false, :is_active => true })
          else
            @active_batches = Batch.paginate(:page => params[:page],:per_page => 20,:order=>'name ASC',  :conditions => {:course_id=>batch.course_id, :is_deleted => false, :is_active => true })
          end
          active_batches_count_list=batches_list.select{|b| b.is_active==true and b.is_deleted==false}
          inactive_batches_count_list=batches_list.select{|b| b.is_active==false and b.is_deleted==false}
          @inactive_batch_count=inactive_batches_count_list.count
          @active_batch_count=active_batches_count_list.count
          render(:update) do |page|
            page.replace_html 'active_batch_button', :text=>"Active Batches(#{@active_batch_count})"
            page.replace_html 'inactive_batch_button', :text=>"Inactive Batches(#{@inactive_batch_count})"
            page.replace_html 'update_batch', :partial=>'update_batch'
            page.replace_html 'flash-div', :text=>"<p class='flash-msg'>#{t('inactivated_successfully')}</p>"
          end
        elsif(params[:type]=='inactive')
          @inactive_batches = Batch.paginate(:page => params[:page],:per_page => 20,:order=>'name ASC',  :conditions => {:course_id=>batch.course_id, :is_deleted => false, :is_active => false })
          if @inactive_batches.empty? && params[:page]>"1"
            @page=params[:page].to_i
            @page=@page-1
            params[:page]=@page.to_s
            @inactive_batches = Batch.paginate(:page => params[:page],:per_page => 20,:order=>'name ASC',  :conditions => {:course_id=>batch.course_id, :is_deleted => false, :is_active => false })
          else
            @inactive_batches = Batch.paginate(:page => params[:page],:per_page => 20,:order=>'name ASC',  :conditions => {:course_id=>batch.course_id, :is_deleted => false, :is_active => false })
          end
          active_batches_count_list=batches_list.select{|b| b.is_active==true and b.is_deleted==false}
          inactive_batches_count_list=batches_list.select{|b| b.is_active==false and b.is_deleted==false}
          @inactive_batch_count=inactive_batches_count_list.count
          @active_batch_count=active_batches_count_list.count
          render(:update) do |page|
            page.replace_html 'active_batch_button', :text=>"Active Batches(#{@active_batch_count})"
            page.replace_html 'inactive_batch_button', :text=>"Inactive Batches(#{@inactive_batch_count})"
            page.replace_html 'update_batch', :partial=>'update_inactive_batch'
            page.replace_html 'flash-div', :text=>"<p class='flash-msg'>#{t('activated_successfully')}</p>"
          end
        end
      end
    else
      render(:update) do |page|
        page.replace_html 'flash-div', :text=>"<p class='flash-msg'>#{t('batch_has_students')}</p>"
      end
    end
  end

  def create
    @course = Course.new params[:course]
    if @course.save
      flash[:notice] = "#{t('flash1')}"
      redirect_to :action=>'manage_course'
    else
      @grade_types=Course.grading_types_as_options
      @academic_years = AcademicYear.all
      settings = params[:course][:batches_attributes]
      settings.each_pair do |_,value|
        @start_date = value['start_date'].to_date
        @end_date = value['end_date'].to_date
      end
      render 'new'
    end
  end

  def edit
    @grade_types=Course.grading_types_as_options
    #    @grade_types=[]
    #    gpa = Configuration.find_by_config_key("GPA").config_value
    #    if gpa == "1"
    #      @grade_types << "GPA"
    #    end
    #    cwa = Configuration.find_by_config_key("CWA").config_value
    #    if cwa == "1"
    #      @grade_types << "CWA"
    #    end
  end

  def update
    if @course.update_attributes(params[:course])
      #      if @course.cce_enabled
      #        @course.batches.update_all(:grading_type=>nil)
      #      end
      flash[:notice] = "#{t('flash2')}"
      redirect_to :action=>'manage_course'
    else
      @grade_types=Course.grading_types_as_options
      render 'edit'
    end
  end

  def destroy
    if @course.batches.active.empty?
      @course.inactivate
      flash[:notice]="#{t('flash3')}"
      redirect_to :action=>'manage_course'
    else
      flash[:warn_notice]="<p>#{t('courses.flash4')}</p>"
      redirect_to :action=>'manage_course'
    end

  end

  def show
    @batches = @course.batches.active.paginate(:per_page=>20,:page=>params[:page])
  end

  private
  def find_course
    @course = Course.find params[:id]
  end

  
end
