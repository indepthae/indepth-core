class TcTemplateStudentDetailsController < ApplicationController
  before_filter :login_required
  before_filter :template_presence_required
  filter_access_to :all
  check_request_fingerprint :create_new_field, :update_field, :priority_change, :font_size_select


  def index
    @template_id = current_template.id
    get_student_details(current_template)
  end

  def edit
    @flag = false
    @student_additional_fields=StudentAdditionalField.all(:conditions=>["status = ?",true])
    @field=TcTemplateFieldStudentDetail.find(params[:id])
    if @field.field_info.field_type == "system"
      k=TcTemplateVersion::SYSTEM_FIELDS.select{|_,value| value[:field][@field.field_info.field_format_value]}
    else
      k=TcTemplateVersion::CUSTOM_FIELDS.select{|_,value| value[:field][@field.field_info.field_format_value]}
    end
    unless k.present?
      @selected_field_value = @field.field_info.field_format_value
    else
      @selected_field_value = k[0][0]
    end
    if @field.parent_field.present?
      @student_details = current_template.tc_template_field_student_details.parent_fields
      @parent = @field.parent_field
      @flag = true
    end
  end

  def show

  end

  def update_field
    if params.present?
      @flash = params[:flash]
      @result = TcTemplateFieldStudentDetail.edit_field(params[:tc_template_field_student_details])
      unless @result.blank?
        @errors=true
      else
        get_student_details(current_template)
      end
    end
  end

  def delete_field
    if params.present?
      TcTemplateFieldStudentDetail.delete_field(params)
      get_student_details(current_template)
    else
      @errors = true
    end
  end

  def new_field
    @new_student_detail_field = TcTemplateFieldStudentDetail.new
    @student_additional_fields=StudentAdditionalField.all(:conditions=>["status = ?",true])
    @subfield = params[:sub_field]
    if @subfield
      @student_details = current_template.tc_template_field_student_details.parent_fields
    end
  end

  def create_new_field
    if params.present?
      @flash = params[:flash]
      @result=TcTemplateFieldStudentDetail.create_new_field(params[:tc_template_field_student_details])
      unless @result.blank?
        @errors=true
      else
        get_student_details(current_template)
      end
    end
  end

  def priority_change
    if params.present?
      TcTemplateFieldStudentDetail.change_priority(params[:tc_template_student_details][:tc_template_student_details_attributes])
      get_student_details(current_template)
    else
      @errors=true
    end
  end

  def cancel
    current_template = TcTemplateVersion.find(params[:version_id])
    get_student_details(current_template)
    render :update do |page|
      page.replace_html 'other_details',:partial=>'reorder'
    end
  end

  def font_size_select
    if ((params[:font_size].present?) && (current_template.font_value != params[:font_size]) && (params[:font_size] != "#{t('select_text_size')}"))
      if current_template.tc_template_records.count > 0
        field_ids = []
        current_template.tc_template_field_ids.each do |ids|
          field_ids << ids
        end 
        current_template.add_new_version(params[:font_size]) 
        field_ids.each do|field_id|
          current_template.tc_template_field_ids <<= field_id
        end
        render :update do |page|
          page.replace_html 'flash-msg', :text=>"<p class='flash-msg'>#{t('flash_font_size')}</p>"
        end 
      else
        current_template.update_font_for_existing_version(params[:font_size])
        render :update do |page|
          page.replace_html 'flash-msg', :text=>"<p class='flash-msg'>#{t('flash_font_size')}</p>"
        end 
      end
    elsif (params[:font_size] == "#{t('select_text_size')}") || (current_template.font_value == params[:font_size])
      render :update do |page|
        page.replace_html 'flash-msg', :text=>"<p class='flash-msg'>#{t('select_font_size_error')}</p>"
      end     
    end
  end

  private

  def template_presence_required
    unless TcTemplateVersion.current
      TcTemplateVersion.initialize_first_template
    end
  end

  def current_template
    TcTemplateVersion.current
  end

  def get_student_details(current_template)
    @parent_student_details = current_template.tc_template_field_student_details.parent_fields
    @child_student_details = current_template.tc_template_field_student_details.child_fields
  end

end
