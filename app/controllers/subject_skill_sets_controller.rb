class SubjectSkillSetsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  require 'lib/override_errors'
  helper OverrideErrors
  
  def index
    @sets = SubjectSkillSet.paginate(:include => :subject_skills, :per_page => 10, :page => params[:page])
  end
  
  def show
    @set = SubjectSkillSet.find(params[:id], :include => [:subject_skills, :course_subjects, :subjects])
  end
  
  def new
    @set = SubjectSkillSet.new(:calculate_final => true)
    render_skill_set_form
  end
  
  def create
    @set = SubjectSkillSet.new(params[:subject_skill_set])
    if @set.save
      flash[:notice] = "#{t('subject_skill_set_created')}"
      render :update do |page|
        page.redirect_to(subject_skill_sets_path)
      end
    else
      render_skill_set_form
    end
  end
  
  def edit
    @set = SubjectSkillSet.find(params[:id])
    render_skill_set_form
  end
  
  def update
    @set = SubjectSkillSet.find(params[:id])
    if @set.update_attributes(params[:subject_skill_set])
      flash[:notice] = "#{t('subject_skill_set_updated')}"
      render :update do |page|
        page.redirect_to(subject_skill_set_path(@set))
      end
    else
      render_skill_set_form
    end
  end
  
  def destroy
    @set = SubjectSkillSet.find(params[:id])
    if@set.dependencies_present? or @set.exam_dependencies_present?
      flash[:notice] = "#{t('subject_skill_set_has_dependency')}"
    else
      @set.destroy
      flash[:notice] = "#{t('subject_skill_set_destroyed')}"
    end
    render :update do |page|
        page.redirect_to(subject_skill_sets_path)
    end
  end
  
  def add_skills
    @set = SubjectSkillSet.find(params[:id])
    unless @set.subject_skills.present?
      4.times do
        @set.subject_skills.build
      end
    end
  end
  
  def update_skills
    @set = SubjectSkillSet.find(params[:id])
    if @set.update_attributes(params[:subject_skill_set])
      flash[:notice] = "#{t('subject_skill_set_updated')}"
      redirect_to :action=>'add_skills', :id=> @set.id
    else
      render :add_skills
    end
  end
  
  def add_sub_skills
    @skill = SubjectSkill.find params[:id]
    @set = @skill.subject_skill_set
    unless @skill.sub_skills.present?
      if @set.exam_dependencies_present?
        flash[:notice] = "#{t('flash_msg4')}"
        redirect_to(:action=>'show', :id=> @set.id) 
      end
      4.times { @skill.sub_skills.build }
    end
  end
  
  def update_sub_skills
    @skill = SubjectSkill.find(params[:id])
    if @skill.update_attributes(params[:subject_skill])
      flash[:notice] = "#{t('subject_skill_set_updated')}"
      redirect_to :action=>'add_sub_skills', :id=> @skill.id
    else
      render :add_sub_skills
    end
  end
  
  private
  
  def render_skill_set_form 
    render :update do |page|
      page << "build_modal_box({'title' : '#{@set.new_record? ? t('create_skill_set') : t('edit_skill_set')}'})" unless params[:subject_skill_set].present?
      page.replace_html 'popup_content', :partial => 'subject_skill_set_form'
    end
  end
end