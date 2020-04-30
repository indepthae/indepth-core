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

class FaGroupsController < ApplicationController
  lock_with_feature :cce_enhancement
  before_filter :login_required
  filter_access_to :all

  def index
    @fa_groups = FaGroup.active.paginate(:page => params[:page], :per_page => 20,:order=>'name ASC')
  end

  def new
    @fa_group=FaGroup.new
    @exam_categories=CceExamCategory.all
  end

  def create
    if params[:fa_group][:name].present?
      full_name=params[:fa_group][:name]+" "+params[:fa_group_prefix][:prefix]
      params[:fa_group][:name]=full_name
    end
    @fa_group=FaGroup.new(params[:fa_group])
    if @fa_group.save
      @fa_groups=FaGroup.active.paginate(:page => params[:page], :per_page => 20,:order=>'name ASC')
      flash[:notice]="FA Group created successfully."
    else
      @error=true
    end
  end

  def show
    @fa_group=FaGroup.find(params[:id])
    @fa_criterias=@fa_group.fa_criterias.active
  end

  def edit
    @fa_group=FaGroup.find(params[:id])
    @assessments_count=AssessmentScore.count(:joins=>{:descriptive_indicator=>{:fa_criteria=>:fa_group}},:conditions=>["fa_groups.id=? and fa_groups.is_deleted=? and fa_criterias.is_deleted=?",params[:id],false,false])
    @exam_categories=CceExamCategory.all
    @grade_sets=CceGradeSet.all
  end

  def update
    unless params[:name] == ""
      full_name=params[:name]+" "+params[:fa_group_prefix][:prefix]
      params[:fa_group][:name]=full_name
    else
      params[:fa_group][:name]=nil
    end
    @fa_group=FaGroup.find(params[:id])
    @fa_group.attributes=params[:fa_group]
    if @fa_group.save
      @fa_groups=FaGroup.active.paginate(:page => params[:page], :per_page => 20,:order=>'name ASC')
      flash[:notice]="FA Group updated successfully."
    else
      @error=true
    end
  end

  def destroy
    @fa_group=FaGroup.find(params[:id])
    unless @fa_group.fa_criterias.active.present?
      if @fa_group.update_attribute(:is_deleted,true)
        flash[:notice]="FA Group deleted"
      else
        flash[:notice]="Unable to delete FA Group."
      end
    end
    redirect_to :action => "index"
  end

  def assign_fa_groups
    @courses = Course.cce
    @subjects = []
  end

  
  def select_subjects
    
    @subjects = Subject.find(:all,:joins=>:batch, :conditions=>["batches.course_id=? and subjects.is_deleted=? and batches.is_deleted=? and batches.is_active=?",params[:course_id],false,false,true],:group=>:code)
    render :update do |page|
      page.replace_html 'subjects', :partial => 'subjects', :object => @subjects
    end
  end

  def select_fa_groups
    if request.post?
      @subject=Subject.find(params[:subject_id])
      @subject_fa_groups=@subject.fa_groups
      @fa_groups=FaGroup.active.all(:order=>'name ASC')
      render(:update) do |page|
        page.replace_html 'flash-box',""
        page.replace_html 'select_fa_group',:partial=>"select_fa_groups"
      end
    end
  end

  def update_subject_fa_groups
    unless params[:subject].present?
      flash[:notice] = t('select_atleast_one_fa_group')
      render :js=>"window.location='/fa_groups/assign_fa_groups'" and return
    end
    @subject=Subject.find(params[:id])
    fa_group_ids=@subject.fa_group_ids
    new_fa_group_ids = params[:subject].present? ? params[:subject][:fa_group_ids] : Array.new
    new_fa_group_ids=new_fa_group_ids.map{|s| s=s.to_i}
    fa_ids= (fa_group_ids | new_fa_group_ids ) - (fa_group_ids & new_fa_group_ids )
    unless fa_ids.empty?
      assessment_score_ids=AssessmentScore.scholastic.all(:select=>"assessment_scores.id",:joins=>[{:descriptive_indicator=>{:fa_criteria=>:fa_group}},{:subject=>:batch}],:conditions=>["subject_id=? and fa_groups.id IN (?) and batches.is_deleted=? and batches.is_active=?",params[:id],fa_ids,false,true]).collect(&:id)
      unless assessment_score_ids.empty?
        AssessmentScore.delete(assessment_score_ids)
      end
    end
    subjects=Subject.find(:all,:joins=>:batch,:readonly=>false, :conditions=>{:code=>@subject.code, :is_deleted=>false,:batches=>{:is_deleted=>false,:is_active=>true,:course_id=>@subject.batch.course_id}})
    new_fa_groups = params[:subject][:fa_group_ids] if params[:subject]
    new_fa_groups ||= []
    fa_groups = FaGroup.find_all_by_id(new_fa_groups)
    a=s=nil
    Subject.transaction do
      subjects.each do |sub|
        s=sub
        s.fa_groups = fa_groups
        a=s.save
      end
    end

    #    flash[:notice] = (!a ? "not saved" : "saved" )
    if a
      flash[:notice] = "FA Groups successfully assigned for the selected subject."
      render :js=>"window.location='/fa_groups/assign_fa_groups'"

    else
      @error_object=s
      @subject_fa_groups=@subject.fa_groups
      @fa_groups=FaGroup.active.all(:order=>'name ASC')
      render(:update) do |page|
        page.replace_html 'error-div',:partial=>"layouts/errors"
        page.replace_html 'select_fa_group',:partial=>"select_fa_groups"
      end
    end
    #    redirect_to :action=>:assign_fa_groups
  end

  def new_fa_criteria
    @fa_group=FaGroup.find(params[:fa_group_id])
    @fa_criteria=@fa_group.fa_criterias.new
  end

  def create_fa_criteria
    @fa_criteria=FaCriteria.new(params[:fa_criteria])
    @fa_group=FaGroup.find(params[:fa_criteria][:fa_group_id])
    @fa_criteria.sort_order=@fa_group.fa_criterias.find(:last,:order=>"sort_order ASC").try(:sort_order).to_i+1 || 1
    if @fa_criteria.save
      @fa_criterias=@fa_group.fa_criterias.active
    else
      @error=true
    end
  end

  def edit_fa_criteria
    @fa_criteria=FaCriteria.find(params[:id])
    @fa_group=@fa_criteria.fa_group
    @editable = @fa_criteria.is_editable
  end

  def update_fa_criteria
    @fa_criteria=FaCriteria.find(params[:id])
    @fa_group=@fa_criteria.fa_group
    if @fa_criteria.is_editable == false
      params[:fa_criteria].delete("max_marks")
    end
    @fa_criteria.attributes=params[:fa_criteria]
    if @fa_criteria.save
      @fa_criterias=@fa_criteria.fa_group.fa_criterias.active
    else
      @error=true
    end
  end

  def destroy_fa_criteria
    @fa_criteria=FaCriteria.find(params[:id])
    @fa_group=@fa_criteria.fa_group
    unless @fa_criteria.descriptive_indicators.present?
      if @fa_criteria.update_attribute(:is_deleted,true)
        flash[:notice]="Scholastic criteria deleted"
      else
        flash[:notice]="Scholastic criteria cannot be deleted"
      end
    end
    @fa_criterias=@fa_criteria.fa_group.fa_criterias.active
    render(:update) do |page|
      page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
      page.replace_html 'fa_group_details', :partial => 'fa_group_summary'
      page.replace_html 'fa_criterias', :partial => 'fa_criterias', :object => @fa_criterias
    end
  end

  def edit_criteria_formula
    @fa_group=FaGroup.find(params[:id])
  end

  def update_criteria_formula
    @fa_group=FaGroup.find(params[:id])
    if @fa_group.update_attributes(params[:fa_group])
      redirect_to :action=>'show',:id=>params[:id]
    else
      render "edit_criteria_formula"
    end
  end

  def reorder
    if request.post?
      fa_criteria=FaCriteria.find(params[:id])
      fa_group=fa_criteria.fa_group
      swap=fa_group.fa_criterias.all(:order=>"sort_order ASC")
      initial=params[:count].to_i
      src=swap[initial]
      if params[:direction]=='up'
        dest=swap[initial-1]
      elsif params[:direction]=='down'
        dest=swap[initial+1]
      end
      dest_id=dest.sort_order.to_i
      dest.update_attribute(:sort_order,src.sort_order.to_i)
      src.update_attribute(:sort_order,dest_id)
      @fa_criterias=fa_group.fa_criterias.active
      render(:update) do |page|
        page.replace_html 'fa_criterias', :partial => 'fa_criterias', :object => @fa_criterias
      end
    end
  end

end
