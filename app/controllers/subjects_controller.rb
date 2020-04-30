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

class SubjectsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  in_place_edit_with_validation_for :elective_group,:name
  check_request_fingerprint :create
  def index
    @courses = Course.active.all(:include => :batches)
    @batch = Batch.find(params[:batch_id], :include => [:subjects, {:elective_groups => :subjects}]) if params[:batch_id].present?
    if @batch.present?
#       @batches = @courses.map{ |x| x.batches if (x.id == @batch.course_id) }.flatten.compact
       @batches = Batch.all(:conditions => {:is_deleted => false, :is_active => true, :course_id => @batch.course_id },
        :joins=>:course,:select=>"`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",
        :order=>"course_full_name",:include=>:course)
       subject_include = [:subject_assessments, :subject_attribute_assessments]
       @batch = Batch.find(params[:batch_id], :include => [{:subjects => subject_include},
          {:batch_subject_groups => [{:elective_groups => {:subjects => subject_include}},{:subjects => subject_include }]}, 
          {:elective_groups => :subjects}, { :batch_class_timing_sets => {:class_timing_set => :class_timings }}])
       @components = @batch.subject_components
       @subjects = @batch.subjects.select {|x|x if !x.is_deleted and !x.elective_group_id.present? }
       @elective_groups = @batch.elective_groups.reject(&:is_deleted)
    end
  end

  def new
    @subject = Subject.new
    @batch = Batch.find params[:id] if request.xhr? and params[:id]
    @elective_group = ElectiveGroup.find params[:id2] unless params[:id2].nil?
    respond_to do |format|
      format.js { render :action => 'new' }
    end
  end

  def create
    @subject = Subject.new(params[:subject])
    @batch = @subject.batch
    if @subject.save
      if params[:subject][:elective_group_id] == ""
        @subjects = @subject.batch.normal_batch_subject
        @normal_subjects = @subject
        @elective_groups = ElectiveGroup.find_all_by_batch_id(@batch.id, :conditions =>{:is_deleted=>false})
      else
        @batch = @subject.batch
        @elective_groups = ElectiveGroup.find_all_by_batch_id(@batch.id, :conditions =>{:is_deleted=>false})
        @subjects = @subject.batch.normal_batch_subject
      end
      flash[:notice] = t('flash2')
    else
      @error = true
    end
  end

  def edit
    @subject = Subject.find params[:id]
    @batch = @subject.batch
    @elective_group = ElectiveGroup.find params[:id2] unless params[:id2].nil?
    @skill_sets = SubjectSkillSet.all(:joins => :subject_skills, :group => 'subject_skill_sets.id')
    respond_to do |format|
      format.html { }
      format.js { render :action => 'edit' }
    end
  end

  def update
    @subject = Subject.find params[:id]
    @batch = @subject.batch
    if @subject.update_attributes(params[:subject])
      if params[:subject][:elective_group_id] == ""
        @subjects = @subject.batch.normal_batch_subject
        @normal_subjects = @subject
        @elective_groups = ElectiveGroup.find_all_by_batch_id(@batch.id, :conditions =>{:is_deleted=>false})
      else
        @batch = @subject.batch
        @elective_groups = ElectiveGroup.find_all_by_batch_id(@batch.id, :conditions =>{:is_deleted=>false})
        @subjects = @subject.batch.normal_batch_subject
      end
      flash[:notice] = t('flash3')
    else
      @error = true
    end
  end

  def destroy
    @subject = Subject.find params[:id]
    @subject_exams= Exam.find_by_subject_id(@subject.id)
    unless @subject.is_not_eligible_for_delete
      @subject.inactivate
      @wk_cnt = @subject.batch.weekly_classes
      flash[:notice] = t('flash4')
    else
      flash[:notice] = t('cannot_delete_subjects')
#      @error_text = "#{t('cannot_delete_subjects')}"
    end
  end

  def destroy_elective_group
    @batch=Batch.find(params[:id])
    @elective_group=ElectiveGroup.find(params[:id2])
    @success = @elective_group.inactivate
    if(@success)
      flash[:notice] = t('elective_groups.flash2')
    else
      flash[:notice] = t('elective_groups.flash4')
    end
  end

  def show
    if params[:batch_id] == ''
      @subjects = []
      @elective_groups = []
    else
      @batch = Batch.find params[:batch_id]
      @subjects = @batch.normal_batch_subject
      @elective_groups = ElectiveGroup.find_all_by_batch_id(params[:batch_id], :conditions =>{:is_deleted=>false}, :include => :subjects)
    end
    respond_to do |format|
      format.js { render :action => 'show' }
    end
  end

  def no_subjects
    render "subjects/_no_subjects", :layout => false
  end
  
  def edit_elective_group
    @elective_group = ElectiveGroup.find(params[:id])
    if request.post?
      if @elective_group.update_attributes(params[:elective_group])
        flash[:notice] = "#{t('elective_groups.flash3')}"
        @success = true
      else
        @error = true
      end
    else
      @initial = true
    end
  end

  def enable_elective_group_delete
    @elective_group = ElectiveGroup.find(params[:id],:include => :subjects)
    render "subjects/_delete_elective_group", :layout => false, :locals => {:e => @elective_group}
  end

  def update_batch_list
    @batches = Batch.all(:conditions => {:is_deleted => false, :is_active => true, :course_id => params[:course_id] },
      :joins=>:course,:select=>"`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",
      :order=>"course_full_name",:include=>:course)
    render :update do |page|
      page.replace_html "subjects", :text => ""
      page.replace_html "batches", :partial => "batch_list"
    end
  end

  def load_subject_list
    if params[:batch_id].present?
#      @batch = Batch.find(params[:batch_id],
#        :include => [{:subjects => [:subject_assessments, :subject_attribute_assessments]},
#          {:elective_groups => {:subjects => [:subject_assessments, :subject_attribute_assessments]} },
#          { :batch_class_timing_sets => {:class_timing_set => :class_timings }}],
#        :joins => "LEFT OUTER JOIN subjects on subjects.batch_id = #{params[:batch_id]} and subjects.elective_group_id = NULL and subjects.is_deleted = false
#                LEFT OUTER JOIN elective_groups on elective_groups.batch_id = #{params[:batch_id]} and elective_groups.is_deleted = false#")
      subject_include = [:subject_assessments, :subject_attribute_assessments]
      @batch = Batch.find(params[:batch_id], :include => [{:subjects => subject_include},
          {:batch_subject_groups => [{:elective_groups => {:subjects => subject_include}},{:subjects => subject_include }]}, 
          {:elective_groups => :subjects}, { :batch_class_timing_sets => {:class_timing_set => :class_timings }}])
      @components = @batch.subject_components
      @subjects = @batch.subjects.select {|x|x if !x.is_deleted and !x.elective_group_id.present? } #Subject.all(:conditions => {:elective_group_id => nil, :batch_id => params[:batch_id], :is_deleted => false })
      @elective_groups = @batch.elective_groups.reject(&:is_deleted) #ElectiveGroup.all(:conditions =>{:batch_id => params[:batch_id], :is_deleted=>false}, :include => :subjects)
      @weekly_classes = @batch.batch_class_timing_sets.map{|bcts| bcts.class_timing_set.class_timings.reject {|ct| ct.is_break }}.flatten.length
    end
    render :update do |page|
      page.replace_html "subjects", :partial => "subjects_new" if params[:batch_id].present?
      page.replace_html "subjects", :text => "" unless params[:batch_id].present?
    end
  end
  
  def edit_component
    
  end
  
  def delete_component
    @component = params[:type].camelize.constantize.find(params[:id])
    @component.check_and_destroy
    flash[:notice] = "#{t('deleted_component_'+params[:type])}"
    render :update do |page|
      page.redirect_to :action => 'index', :batch_id => @component.batch_id
    end
  end

  def import_subjects
    @batch = Batch.find(params[:id], :include => [:subjects, {:elective_groups => :subjects}])
    course_id = @batch.course_id
    @previous_batch = Batch.find(:first,
      :order=>'id desc',
      :include => [:subjects, { :elective_groups => :subjects }],
      :conditions=>"batches.id < '#{@batch.id }' AND batches.is_deleted = 0 AND course_id = ' #{course_id }'",
      :joins=>"INNER JOIN subjects ON subjects.batch_id = batches.id  AND subjects.is_deleted = 0")
    @existing_subjects = @batch.subjects
    @existing_elective_groups = @batch.elective_groups.reject {|x| x.is_deleted }
    unless @previous_batch.blank?
      @normal_subjects = @previous_batch.subjects.select {|x| (!x.elective_group_id.present? and !x.is_deleted)}
      @elective_groups = @previous_batch.elective_groups.reject {|x| x.is_deleted }
      @elective_group_subjects = Hash.new
      @elective_groups.map {|x| @elective_group_subjects[x] = x.subjects.reject {|y| y.is_deleted } }
      importable_subjects = (@normal_subjects + @elective_group_subjects.values).flatten
      @importable_subjects = importable_subjects.reject {|x| @existing_subjects.map(&:code).include? x.code }
      @cce_course = @batch.course.cce_enabled?
      @asl_subject = @batch.asl_subject
      @sixth_subject = @batch.sixth_subject
      if @cce_course
        if @asl_subject.present?
          @importable_subjects = @importable_subjects.reject {|x| x.is_asl}
        end
        if @sixth_subject.present?
          @importable_subjects = @importable_subjects.reject {|x| (x.is_sixth_subject or (x.elective_group_id.present? and x.elective_group.is_sixth_subject))}
        end
      end
      flash.now[:notice] = t('batches.flash8') unless @importable_subjects.present?
    else
      flash[:notice] = t('batch_transfers.flash4')
    end    
    
    if request.post?
      subjects = Subject.find_all_by_id_and_batch_id(params[:subjects],@previous_batch.id,:conditions=>'is_deleted=false',:include => :elective_group)
      already_existing_subjects = []
      subjects.each do |subject|
        sub_exists = @existing_subjects.find_by_id(subject.id)
        if sub_exists.nil?
          reject_attr = ['is_deleted','created_at','deleted_at', 'elective_group_id', 'batch_id']
          subject_attr = subject.attributes.reject {|key,val| (reject_attr.include? key) }
          subject_attr[:batch_id] = @batch.id
          if subject.elective_group_id.present?
            elect_group_exists = @existing_elective_groups.any? {|eg| eg.name == subject.elective_group.name }
            unless elect_group_exists
              elect_group = ElectiveGroup.create(:name=> subject.elective_group.name, :batch_id=>@batch.id,:is_sixth_subject=>subject.elective_group.is_sixth_subject)
              @existing_elective_groups << elect_group unless (@existing_elective_groups.include? elect_group)
            else
              elect_group = @existing_elective_groups.select {|x| x.name == subject.elective_group.name }.last
            end
            subject_attr[:elective_group_id] = elect_group.id
          end
          s=Subject.create(subject_attr)
        else
          already_existing_subjects << subject.code
        end
      end
      @existing_subjects = Subject.find_all_by_batch_id(@batch.id,:conditions=>'is_deleted=false')
      flash[:notice] = (already_existing_subjects.length == subjects.length) ? t('subject_import_ignore_warning') : t('subject_import_success')
    end
  end
end
