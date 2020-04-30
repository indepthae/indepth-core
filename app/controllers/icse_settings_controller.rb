class IcseSettingsController < ApplicationController
  before_filter [:login_required]
  filter_access_to :all,:except=>[:index,:icse_exam_categories,:new_icse_exam_category,:create_icse_exam_category,:edit_icse_exam_category,:update_icse_exam_category,:destroy_icse_exam_category,:icse_weightages,:new_icse_weightage,:create_icse_weightage,:edit_icse_weightage,:update_icse_weightage,:destroy_icse_weightage,:assign_icse_weightages,:select_subjects,:select_icse_weightages,:update_subject_weightages,:internal_assessment_groups,:new_ia_group,:create_ia_group,:edit_ia_group,:update_ia_group,:destroy_ia_group,:assign_ia_groups,:ia_group_subjects,:select_ia_groups,:update_subject_ia_groups,:ia_settings,:ia_total_example,:ia_total_example]
  filter_access_to [:index,:icse_exam_categories,:new_icse_exam_category,:create_icse_exam_category,:edit_icse_exam_category,:update_icse_exam_category,:destroy_icse_exam_category,:icse_weightages,:new_icse_weightage,:create_icse_weightage,:edit_icse_weightage,:update_icse_weightage,:destroy_icse_weightage,:assign_icse_weightages,:select_subjects,:select_icse_weightages,:update_subject_weightages,:internal_assessment_groups,:new_ia_group,:create_ia_group,:edit_ia_group,:update_ia_group,:destroy_ia_group,:assign_ia_groups,:ia_group_subjects,:select_ia_groups,:update_subject_ia_groups,:ia_settings,:ia_total_example,:ia_total_example],:attribute_check=>true, :load_method => lambda { current_user }

  def index
    
  end

  def icse_exam_categories
    @exam_categories=IcseExamCategory.paginate(:per_page=>20,:page=>params[:page])
    if request.xhr?
      render :update do |page|
        page.replace_html 'categories',:partial=>"exam_categories"
      end
    end
  end

  def new_icse_exam_category
    @exam_category=IcseExamCategory.new
  end

  def ia_settings
    @ia_setting = Configuration.find_or_create_by_config_key("IcseIaType")
    if request.put?
      icsa_ia_type = params[:configuration][:config_value]
       @ia_setting = Configuration.set_value("IcseIaType", icsa_ia_type)
      flash[:notice] = "IA Settings has been successfully saved"
      redirect_to :action => 'ia_settings'
    end
  end

  def ia_total_example
    respond_to do |format|
      format.js { render 'ia_total_example' }
    end
  end

  def ia_average_example
    respond_to do |format|
      format.js { render 'ia_average_example' }
    end
  end

  def create_icse_exam_category
    @exam_category=IcseExamCategory.new(params[:icse_exam_category])
    if @exam_category.save
      flash[:notice]="Exam Category created successfully."
      @exam_categories=IcseExamCategory.paginate(:per_page=>20,:page=>params[:page])
    else
      @error=true
    end
  end

  def edit_icse_exam_category
    @exam_category=IcseExamCategory.find params[:id]
  end

  def update_icse_exam_category
    @exam_category=IcseExamCategory.find params[:id]
    if @exam_category.update_attributes(params[:icse_exam_category])
      flash[:notice]="Exam Category updated successfully."
      @exam_categories=IcseExamCategory.paginate(:per_page=>20,:page=>params[:page])
    else
      @error=true
    end
  end
  def destroy_icse_exam_category
    exam_category=IcseExamCategory.find params[:id]
    if exam_category.destroy
      flash[:notice]="Exam Category deleted successfully."
      redirect_to icse_exam_categories_icse_settings_path
    else
      flash[:notice]="Sorry. unable to delete if dependencies exist."
      redirect_to icse_exam_categories_icse_settings_path
    end
  end

  def icse_weightages
    @icse_weightages=IcseWeightage.paginate(:per_page=>20,:page=>params[:page])
    if request.xhr?
      render :update do |page|
        page.replace_html 'categories',:partial=>"icse_weightages"
      end
    end
  end
  
  def new_icse_weightage
    @icse_weightage=IcseWeightage.new
    @icse_exam_categories=IcseExamCategory.all
  end

  def create_icse_weightage
    @icse_weightage=IcseWeightage.new(params[:icse_weightage])
    if @icse_weightage.save
      flash[:notice]="ICSE Weightage created successfully."
      @icse_weightages=IcseWeightage.paginate(:per_page=>20,:page=>params[:page])
    else
      @error=true
    end
  end

  def edit_icse_weightage
    @icse_weightage=IcseWeightage.find params[:id]
    @icse_exam_categories=IcseExamCategory.all
  end

  def update_icse_weightage
    @icse_weightage=IcseWeightage.find params[:id]
    if @icse_weightage.update_attributes(params[:icse_weightage])
      flash[:notice]="ICSE Weightage updated successfully."
      @icse_weightages=IcseWeightage.paginate(:per_page=>20,:page=>params[:page])
    else
      @error=true
    end
  end

  def destroy_icse_weightage
    icse_weightage=IcseWeightage.find params[:id]
    if icse_weightage.destroy
      flash[:notice]="ICSE Weightage deleted successfully"
      redirect_to icse_weightages_icse_settings_path
    else
      flash[:notice]="Sorry. Unabele to delete if dependencies exist."
      redirect_to icse_weightages_icse_settings_path
    end
  end

  def assign_icse_weightages
    @courses=Course.icse
  end
  def select_subjects
    @subjects = Subject.find(:all,:joins=>:batch, :conditions=>{:batches=>{:course_id=>params[:course_id],:is_deleted=>false,:is_active=>true},:is_deleted=>false},:group=>:code) if params[:course_id].present?
    render :update do |page|
      page.replace_html 'flash-box',:text=>""
      page.replace_html 'form-errors', :text=>""
      if params[:course_id].present?
        page.replace_html 'subjects', :partial => 'subjects', :object => @subjects
      else
        page.replace_html 'subjects',:text=>'<div id="flash-box"><p class="flash-msg"> Select a Course. </p></div>'
        page.replace_html 'select_fa_group',:text=>''
      end
    end
  end

  def select_icse_weightages
    if params[:subject_id].present?
      @subject=Subject.find params[:subject_id]
      @icse_weightages=IcseWeightage.all
      @selected_weightages=@subject.icse_weightages
    end
    render :update do |page|
      page.replace_html 'form-errors', :text=>""
      page.replace_html 'flash-box',:text=>""
      if @subject.present?
        page.replace_html 'select_fa_group',:partial=>'select_icse_weightages'
      else
        page.replace_html 'select_fa_group',:text=>'<div id="flash-box"><p class="flash-msg"> Select a Subject. </p></div>'
      end
    end
  end

  def update_subject_weightages
    @subject=Subject.find params[:id]
    weightage_ids=params[:subject].nil?? [] : params[:subject][:weightage_ids].nil?? [] : params[:subject][:weightage_ids]
    @icse_weightages=IcseWeightage.all
    new_icse_weightages=@icse_weightages.select{|s| weightage_ids.include? s.id.to_s}
    @subject.icse_weightages=new_icse_weightages
    if @subject.save
      @subject.batch.course.batches.all(:include=>:subjects).each do |batch|
        subject=batch.subjects.select{|s| s.code==@subject.code}.first
        if subject.present?
          subject.icse_weightages=new_icse_weightages
          unless subject.save
            @error=true
          end
        end
      end
    else
      @error=true
    end

    render :update do |page|
      @selected_weightages=@subject.icse_weightages
      unless @error
        page.replace_html 'form-errors', :text=>""
        page.replace_html 'flash-box',:text=>'<div id="flash-box"><p class="flash-msg"> Weightages successfully assigned for the selected subject. </p></div>'
        page.replace_html 'select_fa_group',:partial=>'select_icse_weightages'
        page<< "window.scrollTo(0,0)"
      else
        page.replace_html 'flash-box',:text=>""
        page.replace_html 'form-errors', :partial => 'errors', :object => @subject
        page.replace_html 'select_fa_group',:partial=>'select_icse_weightages'
        page<< "window.scrollTo(0,0)"
      end
    end
  end

  def internal_assessment_groups
    @ia_groups=IaGroup.paginate(:per_page=>20,:page=>params[:page])
  end

  def new_ia_group
    @ia_group=IaGroup.new
    @ia_group.ia_indicators.build
    @ia_group.build_ia_calculation
    @icse_exam_categories=IcseExamCategory.all
  end

  def create_ia_group
    @ia_group=IaGroup.new(params[:ia_group])
    if @ia_group.save
      flash[:notice]="IA Group created successfully"
      redirect_to internal_assessment_groups_icse_settings_path
    else
      @icse_exam_categories=IcseExamCategory.all
      render "new_ia_group"
    end
  end

  def edit_ia_group
    @ia_group=IaGroup.find(params[:id])
    @icse_exam_categories=IcseExamCategory.all
  end

  def update_ia_group
    @ia_group=IaGroup.find(params[:id])
    if @ia_group.update_attributes(params[:ia_group])
      flash[:notice]="IA Group updated successfully"
      redirect_to internal_assessment_groups_icse_settings_path
    else
      @icse_exam_categories=IcseExamCategory.all
      render "edit_ia_group"
    end
  end

  def destroy_ia_group
    ia_group=IaGroup.find params[:id]
    if ia_group.destroy
      flash[:notice]="IA Group deleted successfully"
      redirect_to internal_assessment_groups_icse_settings_path
    else
      flash[:notice]="Sorry. Unabele to delete if dependencies exist"
      redirect_to internal_assessment_groups_icse_settings_path
    end
  end

  def assign_ia_groups
    @courses=Course.icse
  end

  def ia_group_subjects
    @subjects = Subject.find(:all,:joins=>:batch, :conditions=>{:batches=>{:course_id=>params[:course_id],:is_deleted=>false,:is_active=>true},:is_deleted=>false},:group=>:code) if params[:course_id].present?
    render :update do |page|
      page.replace_html 'flash-box',:text=>""
      page.replace_html 'form-errors', :text=>""
      if params[:course_id].present?
        page.replace_html 'subjects', :partial => 'ia_group_subjects', :object => @subjects
      else
        page.replace_html 'subjects',:text=>'<div id="flash-box"><p class="flash-msg"> Select one course. </p></div>'
        page.replace_html 'select_ia_group',:text=>''
      end
    end
  end

  def select_ia_groups
    if params[:subject_id].present?
      @subject=Subject.find params[:subject_id]
      @ia_groups=IaGroup.all
      @selected_ia_groups=@subject.ia_groups
    end
    render :update do |page|
      page.replace_html 'form-errors', :text=>""
      page.replace_html 'flash-box',:text=>""
      if @subject.present?
        page.replace_html 'select_ia_group',:partial=>'select_ia_groups'
      else
        page.replace_html 'select_ia_group',:text=>'<div id="flash-box"><p class="flash-msg"> Select a Subject. </p></div>'
      end
    end
  end

  def update_subject_ia_groups
    @subject=Subject.find params[:id]
    ia_group_ids=params[:subject].nil?? [] : params[:subject][:ia_group_ids].nil?? [] : params[:subject][:ia_group_ids]
    @ia_groups=IaGroup.all
    new_ia_groups=@ia_groups.select{|s| ia_group_ids.include? s.id.to_s}
    @subject.ia_groups=new_ia_groups
    if @subject.save
      @subject.batch.course.batches.all(:include=>:subjects).each do |batch|
        subject=batch.subjects.select{|s| s.code==@subject.code}.first
        if subject.present?
          subject.ia_groups=new_ia_groups
          unless subject.save
            @error=true
          end
        end
      end
    else
      @error=true
    end
    render :update do |page|
      @selected_ia_groups=@subject.ia_groups
      unless @error
        page.replace_html 'form-errors', :text=>""
        page.replace_html 'flash-box',:text=>'<div id="flash-box"><p class="flash-msg"> IA Groups successfully assigned for the selected subject. </p></div>'
        page.replace_html 'select_ia_group',:partial=>'select_ia_groups'
        page<< "window.scrollTo(0,0)"
      else
        page.replace_html 'flash-box',:text=>""
        page.replace_html 'form-errors', :partial => 'errors', :object => @subject
        page.replace_html 'select_ia_group',:partial=>'select_ia_groups'
        page<< "window.scrollTo(0,0)"
      end
    end
  end
  
end
