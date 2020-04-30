class ApplicantsAdminsController < ApplicationController
  lock_with_feature :finance_multi_receipt_data_updation, :only => [:update_applicant_status, :update_status]
  before_filter :login_required
  filter_access_to :all

  def show
    @enabled_courses = RegistrationCourse.find(:all,:conditions=>{:is_active=>true},:order => "courses.course_name",:include => [:course,:applicants])
    @disabled_courses = RegistrationCourse.find(:all,:conditions=>{:is_active=>false},:order => "courses.course_name",:include => [:course,:applicants])
  end

  def show_inactivating_form
    if request.post?
      if params[:registration_course_ids].present?
        if RegistrationCourse.update_all({:is_active=>false},{:id=>params[:registration_course_ids]})
          flash[:notice] = "#{t('courses_inactivated')}"
        end
      end
      @enabled_courses = RegistrationCourse.find(:all,:conditions=>{:is_active=>true},:order => "courses.course_name",:include => [:course,:applicants])
      @disabled_courses = RegistrationCourse.find(:all,:conditions=>{:is_active=>false},:order => "courses.course_name",:include => [:course,:applicants])
      render :update do|page|
        page.replace_html 'courses_list', :partial => 'courses_list', :locals=>{:enabled_courses=>@enabled_courses, :disabled_courses=>@disabled_courses}
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        page << "Modalbox.hide();"
      end
    else
      @enabled_courses = RegistrationCourse.find(:all,:conditions=>{:is_active=>true},:order => "courses.course_name",:include => [:course])
      render :update do|page|
        page.replace_html 'modal-box', :partial => 'inactivating_form'
        page << "Modalbox.show($('modal-box'), {title: '#{t('applicants_admins.inactivate_applicant_reg_for_courses')}'});"
      end
    end
  end

  def show_activating_form
    if request.post?
      if params[:registration_course_ids].present?
        if RegistrationCourse.update_all({:is_active=>true},{:id=>params[:registration_course_ids]})
          flash[:notice] = "#{t('courses_activated')}"
        end
      end
      @enabled_courses = RegistrationCourse.find(:all,:conditions=>{:is_active=>true},:order => "courses.course_name",:include => [:course,:applicants])
      @disabled_courses = RegistrationCourse.find(:all,:conditions=>{:is_active=>false},:order => "courses.course_name",:include => [:course,:applicants])
      render :update do|page|
        page.replace_html 'courses_list', :partial => 'courses_list', :locals=>{:enabled_courses=>@enabled_courses, :disabled_courses=>@disabled_courses}
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        page << "Modalbox.hide();"
      end
    else
      @disabled_courses = RegistrationCourse.find(:all,:conditions=>{:is_active=>false},:order => "courses.course_name",:include => [:course])
      render :update do|page|
        page.replace_html 'modal-box', :partial => 'activating_form'
        page << "Modalbox.show($('modal-box'), {title: '#{t('applicants_admins.activate_applicant_reg_for_courses')}'});"
      end
    end
  end

  def add_course
    if request.post?
      @registration_course = RegistrationCourse.new(params[:registration_course])
      if @registration_course.save
        flash[:notice] = "#{t('registration_courses.create_successfully')}"
        @disabled_courses = RegistrationCourse.find(:all,:conditions=>{:is_active=>false},:order => "courses.course_name",:include => [:course,:applicants])
        @enabled_courses = RegistrationCourse.find(:all,:conditions=>{:is_active=>true},:order => "courses.course_name",:include => [:course,:applicants])
        render :update do|page|
          page.replace_html 'courses_list', :partial => 'courses_list', :locals=>{:enabled_courses=>@enabled_courses, :disabled_courses=>@disabled_courses}
          page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
          page << "Modalbox.hide();"
        end
      else
        render :update do|page|
          page.replace_html 'form-errors', :partial => 'course_errors', :object => @registration_course
          page.visual_effect(:highlight, 'form-errors')
        end
      end
    else
      @registration_course = RegistrationCourse.new
      courses = Course.active.all(:include=>[:registration_course])
      @available_courses = courses.select{|c| c.registration_course.nil?}
      render :update do|page|
        page.replace_html 'modal-box', :partial => 'course_form'
        page << "Modalbox.show($('modal-box'), {title: '#{t('registration_courses.add_course')}'});"
      end
    end
  end

  def registration_settings
    @statuses = ApplicationStatus.all
    if @statuses.select{|s| s.is_default == true}.count < 3
      @statuses = ApplicationStatus.create_defaults_and_return
    end
    @instruction = ApplicationInstruction.find_or_initialize_by_registration_course_id(nil)
  end

  def save_instruction
    @instruction = ApplicationInstruction.find_or_initialize_by_registration_course_id(nil)
    @instruction.attributes = params[:application_instruction]
    if @instruction.save
      render :update do |page|
        if params[:type_of_action].present?
          if params[:type_of_action]=="hide_instructions"
            page.replace_html "flash-box",:text=>"<p class='flash-msg'>#{t('instructions_skipped_successfully')}</p>"
          elsif params[:type_of_action]=="show_instructions"
            page.replace_html "flash-box",:text=>"<p class='flash-msg'>#{t('instructions_shown_successfully')}</p>"
          end
        else
          page.replace_html "flash-box",:text=>"<p class='flash-msg'>#{t('instructions_updated_successfully')}</p>"
        end
      end
    else
      render :update do |page|
        page.replace_html "flash-box",:text=>"<p class='flash-msg'>#{t('instructions_not_updated')}</p>"
      end
    end
  end

  def new_status
    if request.post?
      @application_status = ApplicationStatus.new(params[:application_status])
      if @application_status.save
        flash[:notice] = "#{t('status_created_successfully')}"
        @statuses = ApplicationStatus.all
        render :update do|page|
          page.replace_html 'status-box', :partial => 'status_box', :locals=>{:statuses=>@statuses}
          page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
          page << "Modalbox.hide();"
        end
      else
        render :update do|page|
          page.replace_html 'form-errors', :partial => 'status_errors', :object => @application_status
          page.visual_effect(:highlight, 'form-errors')
        end
      end
    else
      @application_status = ApplicationStatus.new
      render :update do|page|
        page.replace_html 'modal-box', :partial => 'status_form'
        page << "Modalbox.show($('modal-box'), {title: '#{t('create_status')}'});"
      end
    end
  end

  def edit_status
    @application_status = ApplicationStatus.find(params[:id])
    if request.post?
      if @application_status.update_attributes(params[:application_status])
        flash[:notice] = "#{t('status_updated_successfully')}"
        @statuses = ApplicationStatus.all
        render :update do|page|
          page.replace_html 'status-box', :partial => 'status_box', :locals=>{:statuses=>@statuses}
          page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
          page << "Modalbox.hide();"
        end
      else
        render :update do|page|
          page.replace_html 'form-errors', :partial => 'status_errors', :object => @application_status
          page.visual_effect(:highlight, 'form-errors')
        end
      end
    else
      render :update do|page|
        page.replace_html 'modal-box', :partial => 'status_form', :object=>@application_status
        page << "Modalbox.show($('modal-box'), {title: '#{t('edit_status')}'});"
      end
    end
  end

  def delete_status
    @status = ApplicationStatus.find(params[:id])
    unless @status.is_default == true
      @status.destroy
      flash[:notice] = "#{t('status_deleted_successfully')}"
    else
      flash[:notice] = "#{t('status_could_not_be_deleted')}"
    end
    @statuses = ApplicationStatus.all
    render :update do |page|
      page.replace_html "flash-box",:text=>"<p class='flash-msg'>#{flash[:notice]}</p>"
      page.replace_html "status-box", :partial=>"status_box", :locals=>{:statuses=>@statuses}
    end
  end

  def archive_all_applicants
    active_applicants = Applicant.find_all_by_is_deleted_and_submitted(false,true)
    active_applicants.each do|a|
      a.update_attributes(:is_deleted=>true)
    end
    flash[:notice] = "#{t('archived_all_successfully')}"
    redirect_to registration_settings_applicants_admins_path
  end

  def customize_form
    @application_section = ApplicationSection.find_by_registration_course_id(nil)
    if request.post?
      if @application_section.present?
        if @application_section.update_attributes(params[:application_section])
          flash[:notice] = "#{t('application_form_modified_successfully')}"
          redirect_to registration_settings_applicants_admins_path
        end
      else
        @application_section = ApplicationSection.new(params[:application_section])
        if @application_section.save
          flash[:notice] = "#{t('application_form_created_successfully')}"
          redirect_to registration_settings_applicants_admins_path
        end
      end
    end
  end
  
  def add_section
    @field_group = ApplicantAddlFieldGroup.new
    @section_order = params[:last_order].to_i + 1
    @section_index = params[:last_index].to_i + 1
    render :update do|page|
      page.replace_html 'flash-box', :text=>""
      page.replace_html 'modal-box', :partial => 'add_section_form'
      page << "Modalbox.show($('modal-box'), {title: '#{t('create_form_section')}'});"
    end
  end
  
  def create_section
    @field_group = ApplicantAddlFieldGroup.new(params[:applicant_addl_field_group])
    section_index = params[:section_index]
    if @field_group.save
      flash[:notice] = "#{t('section_created_successfully')}"
      a=Hash.new
      a[:section_order] = params[:section_order]
      a[:fields] = []
      a[:applicant_addl_field_group_id] = @field_group.id
      a[:section_name] = ""
      render :update do|page|
        page.insert_html :bottom, 'custom-area', :partial=>'section_form',:locals=>{:a=>a, :guardian_count=>1, :i=>section_index}
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        page << "Modalbox.hide();"
      end
    else
      render :update do|page|
        page.replace_html 'form-errors', :partial => 'section_errors', :object => @field_group
        page.visual_effect(:highlight, 'form-errors')
      end
    end    
  end
  
  def edit_section
    @field_group = ApplicantAddlFieldGroup.find(params[:id])
    render :update do|page|
      page.replace_html 'flash-box', :text=>""
      page.replace_html 'modal-box', :partial => 'add_section_form'
      page << "Modalbox.show($('modal-box'), {title: '#{t('edit_form_section')}'});"
    end
  end
  
  def update_section
    @field_group = ApplicantAddlFieldGroup.find(params[:id])
    if @field_group.update_attributes(params[:applicant_addl_field_group])
      flash[:notice] = "#{t('section_updated_successfully')}"
      a=Hash.new
      a[:applicant_addl_field_group_id] = @field_group.id
      a[:section_name] = ""
      render :update do|page|
        page.replace_html 'edited-section', :partial=>'section_header',:locals=>{:a=>a, :field_group=>@field_group}
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        page << "$('edited-section').removeAttribute('id');"
        page << "Modalbox.hide();"
      end
    else
      render :update do|page|
        page.replace_html 'form-errors', :partial => 'section_errors', :object => @field_group
        page.visual_effect(:highlight, 'form-errors')
      end
    end   
  end
  
  def delete_section
    @field_group = ApplicantAddlFieldGroup.find(params[:id])
    if @field_group.destroy
      flash[:notice] = "#{t('section_deleted_successfully')}"
      render :update do|page|
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        page << "$('deleted-section').remove();"
      end
    else
      flash[:notice] = "#{t('section_not_deleted')}"
      render :update do|page|
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        page << "$('deleted-section').removeAttribute('id');"
      end
    end
  end
  
  def add_field
    field_order = params[:last_field_order].to_i + 1
    field_index = params[:last_field_index].to_i + 1
    field_section_index = params[:field_section_index].to_i
    unless params[:section_name] == "attachments"
      if params[:group_id].to_i == 0
        @applicant_addl_field = ApplicantAddlField.new(:multi_select_type=>'single_select',:section_name=>params[:section_name])
      else
        @applicant_addl_field = ApplicantAddlField.new(:multi_select_type=>'single_select',:applicant_addl_field_group_id=>params[:group_id])
      end
      @applicant_addl_field.applicant_addl_field_values.build    
      @applicant_addl_field.applicant_addl_field_values.build
      linked_additional_fields = ApplicantStudentAddlField.all(:conditions=>{:registration_course_id=>nil}).collect(&:student_additional_field_id)
      @student_addl_fields = StudentAdditionalField.active.reject{|r| linked_additional_fields.include?(r.id)}
      render :update do|page|
        if (params[:section_name] == "guardian_personal_details" or params[:section_name] == "guardian_contact_details")
          page.replace_html 'modal-box', :partial => 'input_field_form', :locals=>{:field_order=>field_order,:field_index=>field_index,:field_section_index=>field_section_index}
        else
          page.replace_html 'modal-box', :partial => 'add_field_form', :locals=>{:field_order=>field_order,:field_index=>field_index,:field_section_index=>field_section_index}
        end
        page << "Modalbox.show($('modal-box'), {title: '#{t('add_new_input_field')}', afterLoad: assign_observers});"
      end
    else
      @applicant_addl_attachment_field = ApplicantAddlAttachmentField.new(:registration_course_id=>nil)
      render :update do|page|
        page.replace_html 'modal-box', :partial => 'add_attachment_field_form', :locals=>{:field_order=>field_order,:field_index=>field_index,:field_section_index=>field_section_index}
        page << "Modalbox.show($('modal-box'), {title: '#{t('add_new_attachment_field')}'});"
      end
    end
  end
  
  def create_field
    @applicant_addl_field = ApplicantAddlField.new(params[:applicant_addl_field])
    @applicant_addl_field.is_active = true
    if @applicant_addl_field.save
      flash[:notice] = "#{t('field_created_successfully')}"
      f=Hash.new
      f[:mandatory] = @applicant_addl_field.is_mandatory
      f[:show_field] = true
      f[:field_order] = params[:field_order]
      f[:field_type] = "applicant_additional"
      f[:field_name] = @applicant_addl_field.id
      render :update do|page|
        page.insert_html :bottom, 'insert-to-section', :partial=>'each_field',:locals=>{:f=>f,:indx=>params[:field_index],:i=>params[:field_section_index]}
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        page << "j('#row-to-remove').remove();"
        if @applicant_addl_field.applicant_addl_field_group_id.present?
          @field_group = @applicant_addl_field.applicant_addl_field_group
          a={:applicant_addl_field_group_id=>@field_group.id,:section_name=>""}
          page << "j('#insert-to-section').parent().parent().find('.sec-head').attr('id','current-top-section')"
          page.replace_html 'current-top-section', :partial=>'section_header',:locals=>{:a=>a, :field_group=>@field_group}
          page << "$('current-top-section').removeAttribute('id');"
          page << "if ((j('#insert-to-section').find('.row-b').length >= 2) && (j('#insert-to-section').parent().parent().find('.reorder_link').length === 0)) j('#insert-to-section').parent().parent().find('.link-section').find('.hide-on-sort').append('<a onclick=\"show_reorder_fields_form(this); return false;\" href=\"#\" class=\"reorder_link\">'+'#{t('reorder_fields')}'+'</a>');"
        else
          page << "if (j('#insert-to-section').find('.row-b').length === 2) j('#insert-to-section').parent().parent().find('.link-section').find('.hide-on-sort').append('<a onclick=\"show_reorder_fields_form(this); return false;\" href=\"#\" class=\"reorder_link\">'+'#{t('reorder_fields')}'+'</a>');"
        end
        page << "$('insert-to-section').removeAttribute('id');"
        page << "Modalbox.hide();"
      end
    else
      render :update do|page|
        page.replace_html 'input-form-errors', :partial => 'input_form_errors', :object => @applicant_addl_field
        page.visual_effect(:highlight, 'form-errors')
        page << "$('input-form-errors').scrollIntoView();"
      end
    end
  end
  
  
  def create_attachment_field
    @applicant_addl_attachment_field = ApplicantAddlAttachmentField.new(params[:applicant_addl_attachment_field])
    if @applicant_addl_attachment_field.save
      flash[:notice] = "#{t('field_created_successfully')}"
      f=Hash.new
      f[:mandatory] = @applicant_addl_attachment_field.is_mandatory
      f[:show_field] = true
      f[:field_order] = params[:field_order]
      f[:field_type] = "applicant_attachment"
      f[:field_name] = @applicant_addl_attachment_field.id
      render :update do|page|
        page.insert_html :bottom, 'insert-to-section', :partial=>'each_field',:locals=>{:f=>f,:indx=>params[:field_index],:i=>params[:field_section_index]}
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        page << "j('#row-to-remove').remove();"
        page << "if (j('#insert-to-section').find('.row-b').length === 2) j('#insert-to-section').parent().parent().find('.link-section').find('.hide-on-sort').append('<a onclick=\"show_reorder_fields_form(this); return false;\" href=\"#\" class=\"reorder_link\">'+'#{t('reorder_fields')}'+'</a>');"
        page << "$('insert-to-section').removeAttribute('id');"
        page << "Modalbox.hide();"
      end
    else
      render :update do|page|
        page.replace_html 'input-form-errors', :partial => 'applicant_attachment_errors', :object => @applicant_addl_attachment_field
        page.visual_effect(:highlight, 'form-errors')
        page << "$('input-form-errors').scrollIntoView();"
      end
    end
  end
  
  def edit_field
    if params[:field_type] == "applicant_additional"
      @applicant_addl_field = ApplicantAddlField.find(params[:id])
      if @applicant_addl_field.can_edit_field(nil)
        if @applicant_addl_field.applicant_addl_field_values.blank?
          @applicant_addl_field.applicant_addl_field_values.build    
          @applicant_addl_field.applicant_addl_field_values.build
        end
        render :update do|page|
          page.replace_html 'modal-box', :partial => 'input_field_form', :locals=>{:field_order=>0,:field_index=>0,:field_section_index=>0}
          page << "Modalbox.show($('modal-box'), {title: '#{t('edit_input_field')}', afterLoad: assign_observers});"
        end
      else
        render :update do|page|
          page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{t('cannot_edit_field')}</p>"
        end
      end
    elsif params[:field_type] == "applicant_attachment"
      @applicant_addl_attachment_field = ApplicantAddlAttachmentField.find(params[:id])
      if @applicant_addl_attachment_field.can_edit_field(nil)
        render :update do|page|
          page.replace_html 'modal-box', :partial => 'add_attachment_field_form', :locals=>{:field_order=>0,:field_index=>0,:field_section_index=>0}
          page << "Modalbox.show($('modal-box'), {title: '#{t('edit_attachment_field')}'});"
        end
      else
        render :update do|page|
          page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{t('cannot_edit_field')}</p>"
        end
      end
    end
  end
  
  def update_field
    @applicant_addl_field = ApplicantAddlField.find(params[:id])
    if (@applicant_addl_field.can_edit_field(nil) and @applicant_addl_field.update_attributes(params[:applicant_addl_field])) 
      flash[:notice] = "#{t('field_updated_successfully')}"
      render :update do|page|
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        page << "j('#edited-field').find('.field-name').html('#{@applicant_addl_field.field_name}');"
        if @applicant_addl_field.is_mandatory == true
          page << "j('#edited-field').find('.mandatory_field_checkbox').prop('checked',true).trigger('change');"
        else
          page << "j('#edited-field').find('.mandatory_field_checkbox').prop('checked',false).trigger('change');"
        end
        page << "$('edited-field').removeAttribute('id');"
        page << "Modalbox.hide();"
      end
    else
      render :update do|page|
        page.replace_html 'input-form-errors', :partial => 'input_form_errors', :object => @applicant_addl_field
        page.visual_effect(:highlight, 'form-errors')
        page << "$('input-form-errors').scrollIntoView();"
      end
    end
  end
  
  def update_attachment_field
    @applicant_addl_attachment_field = ApplicantAddlAttachmentField.find(params[:id])
    if (@applicant_addl_attachment_field.can_edit_field(nil) and @applicant_addl_attachment_field.update_attributes(params[:applicant_addl_attachment_field]))
      flash[:notice] = "#{t('field_updated_successfully')}"
      render :update do|page|
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        page << "j('#edited-field').find('.field-name').html('#{@applicant_addl_attachment_field.name}');"
        if @applicant_addl_attachment_field.is_mandatory == true
          page << "j('#edited-field').find('.mandatory_field_checkbox').prop('checked',true).trigger('change');"
        else
          page << "j('#edited-field').find('.mandatory_field_checkbox').prop('checked',false).trigger('change');"
        end
        page << "$('edited-field').removeAttribute('id');"
        page << "Modalbox.hide();"
      end
    else
      render :update do|page|
        page.replace_html 'input-form-errors', :partial => 'applicant_attachment_errors', :object => @applicant_addl_attachment_field
        page.visual_effect(:highlight, 'form-errors')
        page << "$('input-form-errors').scrollIntoView();"
      end
    end
  end
  
  def delete_field
    field_deleted = 0
    addl_field_group_id = 0
    if params[:field_type] == "applicant_additional"
      @applicant_addl_field = ApplicantAddlField.find(params[:id])
      addl_field_group_id = @applicant_addl_field.applicant_addl_field_group_id if @applicant_addl_field.applicant_addl_field_group_id.present?
      if @applicant_addl_field.can_delete_field(nil)
        if @applicant_addl_field.destroy
          field_deleted = 1
        end
      end
    elsif params[:field_type] == "student_additional"
      @applicant_student_addl_field = ApplicantStudentAddlField.find_by_registration_course_id_and_student_additional_field_id(nil,params[:id])
      addl_field_group_id = @applicant_student_addl_field.applicant_addl_field_group_id if @applicant_student_addl_field.applicant_addl_field_group_id.present?
      if @applicant_student_addl_field.can_delete_field(nil)
        if @applicant_student_addl_field.destroy
          field_deleted = 1
        end
      end
    elsif params[:field_type] == "applicant_attachment"
      @applicant_addl_attachment_field = ApplicantAddlAttachmentField.find(params[:id])
      if @applicant_addl_attachment_field.can_delete_field(nil)
        if @applicant_addl_attachment_field.destroy
          field_deleted = 1
        end
      end
    end
    if field_deleted == 1
      flash[:notice] = "#{t('field_deleted_successfully')}"
      render :update do|page|
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        unless addl_field_group_id == 0
          @field_group = ApplicantAddlFieldGroup.find(addl_field_group_id)
          a={:applicant_addl_field_group_id=>@field_group.id,:section_name=>""}
          page << "j('#deleted-field').parent().parent().parent().find('.sec-head').attr('id','current-top-section')"
          page.replace_html 'current-top-section', :partial=>'section_header',:locals=>{:a=>a, :field_group=>@field_group}
          page << "$('current-top-section').removeAttribute('id');"
          page << "if ((j('#deleted-field').parent().find('.row-b').length >= 3) && (j('#deleted-field').parent().parent().parent().find('.reorder_link').length === 0)) j('#deleted-field').parent().parent().parent().find('.link-section').find('.hide-on-sort').append('<a onclick=\"show_reorder_fields_form(this); return false;\" href=\"#\" class=\"reorder_link\">'+'#{t('reorder_fields')}'+'</a>');"
        else
          page << "if (j('#deleted-field').parent().find('.row-b').length === 2) j('#deleted-field').parent().parent().parent().find('.reorder_link').remove();"
        end
        page << "if (j('#deleted-field').parent().find('.row-b').length === 1) j('#deleted-field').parent().append(\"<tr class='row-b empty-row'><td colspan='3'>#{t('no_fields_added')}</td></tr>\");"
        page << "$('deleted-field').remove();"
      end
    else
      flash[:notice] = "#{t('field_not_deleted')}"
      render :update do|page|
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        page << "$('deleted-field').removeAttribute('id');"
      end
    end
  end
  
  def link_student_additional_fields
    field_ids = params[:additional_field_ids]
    section_name = params[:section_name] || nil
    field_group_id = params[:applicant_addl_field_group_id] || nil
    if field_ids.present?
      field_index = params[:field_index].to_i
      field_order = params[:field_order].to_i
      addl_fields = StudentAdditionalField.find_all_by_id(field_ids)
      field_ids.each do |f|
        ApplicantStudentAddlField.create(:student_additional_field_id=>f.to_i,:section_name=>section_name,:applicant_addl_field_group_id=>field_group_id,:registration_course_id=>nil)
      end
      flash[:notice] = "#{t('field_created_successfully')}"
      render :update do|page|
        field_ids.each do|f|
          sf=Hash.new
          sf[:mandatory] = addl_fields.find_by_id(f.to_i).is_mandatory == true ? "default_true":false
          sf[:show_field] = true
          sf[:field_order] = field_order
          sf[:field_type] = "student_additional"
          sf[:field_name] = f
          page.insert_html :bottom, 'insert-to-section', :partial=>'each_field',:locals=>{:f=>sf,:indx=>field_index,:i=>params[:field_section_index]}
          field_index = field_index + 1
          field_order = field_order + 1
        end
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{flash[:notice]}</p>" unless flash[:notice].nil?
        page << "j('#row-to-remove').remove();"
        if field_group_id.present?
          @field_group = ApplicantAddlFieldGroup.find(field_group_id)
          a={:applicant_addl_field_group_id=>@field_group.id,:section_name=>""}
          page << "j('#insert-to-section').parent().parent().find('.sec-head').attr('id','current-top-section')"
          page.replace_html 'current-top-section', :partial=>'section_header',:locals=>{:a=>a, :field_group=>@field_group}
          page << "$('current-top-section').removeAttribute('id');"
        end
        page << "if ((j('#insert-to-section').find('.row-b').length >= 2) && (j('#insert-to-section').parent().parent().find('.reorder_link').length === 0)) j('#insert-to-section').parent().parent().find('.link-section').find('.hide-on-sort').append('<a onclick=\"show_reorder_fields_form(this); return false;\" href=\"#\" class=\"reorder_link\">'+'#{t('reorder_fields')}'+'</a>');"
        page << "$('insert-to-section').removeAttribute('id');"
        page << "Modalbox.hide();"
      end
    else
      render :update do|page|
        page.replace_html 'link-form-errors', :text=>"<div id='error-box'><ul><li>#{t('select_one_field')}</li></ul></div>"
      end
    end
  end
  
  def preview_form
    @registration_courses = RegistrationCourse.active(:include=>:course)
    @registration_settings = ApplicationInstruction.find_by_registration_course_id(nil)
  end
  
  def show_course_instructions
    if params[:registration_course_id].present?
      @registration_course = RegistrationCourse.find_by_id_and_is_active!(params[:registration_course_id],true)
      @registration_settings = ApplicationInstruction.find_by_registration_course_id(params[:registration_course_id].to_i)
    end
    @registration_settings = ApplicationInstruction.find_by_registration_course_id(nil) unless @registration_settings.present?
    render :update do|page|
      page.replace_html "instruction-box", :partial=>"application_instructions"
    end
  end
  
  def show_form
    if params[:registration_course][:course_id].present?
      @registration_course = RegistrationCourse.find_by_id_and_is_active!(params[:registration_course][:course_id],true)
      @application_section = @registration_course.application_section
      unless @application_section.present?
        @application_section = ApplicationSection.find_by_registration_course_id(nil)
      end
      @applicant = Applicant.new
      @field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
      @applicant_addl_fields = ApplicantAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?) and is_active=true",@registration_course.id],:include=>:applicant_addl_field_values)
      @applicant_student_addl_fields = ApplicantStudentAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?)",@registration_course.id],:include=>[:student_additional_field=>:student_additional_field_options])
      @addl_attachment_fields = ApplicantAddlAttachmentField.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
      @selected_subject_ids = @applicant.subject_ids.nil? ? [] : @applicant.subject_ids
      @mandatory_attributes = []
      @mandatory_guardian_attributes = []
      @mandatory_previous_attributes = []
      @mandatory_addl_attributes =[]
      @mandatory_student_attributes = []
      @mandatory_attachment_attributes = []
      @currency = currency
      @application_fee= @registration_course.amount.to_f
      if @registration_course.is_subject_based_registration
        @subjects = @registration_course.course.batches.active.map(&:all_elective_subjects).flatten.compact.map(&:code).compact.flatten.uniq
        @subjects=@registration_course.get_elective_subjects_and_amount
        if @registration_course.subject_based_fee_colletion == true
          @normal_subject_amount=@registration_course.get_major_subjects_amount
          @total_fee= @application_fee+@normal_subject_amount
        end
      else
        @normal_subject_amount = 0.to_f
        @total_fee= @application_fee + 0.to_f
      end
      render :update do|page|
        page.replace_html "form-box", :partial=>"application_form"
        page << 'j("#view-instruction-tab").show();'
        page << 'j("#selection-box").hide();'
      end
    end
  end
  
  def applicants
    @registration_course = RegistrationCourse.find(params[:id])
    @applicants = @registration_course.applicants.all(:conditions=>{:is_deleted=>false,:submitted=>true},:include=>[:batch,:application_status],:order=>"created_at desc")
    @filtered_applicants = @applicants.dup
    @shown_applicants = @applicants.dup
    @search_params = ""
    @start_date = ""
    @end_date = ""
    @active_statuses = ApplicationStatus.all(:conditions=>{:is_active=>true})
    @selected_status = ""
  end
  
  def fee_collection_list
    if request.xhr?
      if params[:batch_id].present?
        batch = Batch.find(params[:batch_id])
        @finance_fee_collections = batch.fee_collection_batches.current_active_financial_year.all(:conditions => "fa.id IS NULL OR fa.is_deleted = false",
          :joins => "INNER JOIN finance_fee_collections ffc ON ffc.id = fee_collection_batches.finance_fee_collection_id
                     LEFT JOIN fee_accounts fa ON fa.id = ffc.fee_account_id").map do |s|
          [s.finance_fee_collection_id, s.finance_fee_collection.name]
        end

        unless @finance_fee_collections.present?
          render :update do|page|
            page.replace_html 'fee_collections', :text => ""
          end
        else
          render :update do|page|
            page.replace_html 'fee_collections', :partial => 'fee_collection_list',
              :locals => {:finance_fee_collections => @finance_fee_collections,
              :financial_year_name => FinancialYear.current_financial_year_name}
          end
        end
      else
        render :update do|page|
          page.replace_html 'fee_collections', :text => ""
        end
      end
    end
  end
  
  def archived_applicants
    @registration_course = RegistrationCourse.find(params[:id])
    @applicants = @registration_course.applicants.all(:conditions=>{:is_deleted=>true,:submitted=>true},:include=>[:batch,:application_status],:order=>"created_at desc")
    @filtered_applicants = @applicants.dup
    @shown_applicants = @applicants.dup
    @search_params = ""
    @start_date = ""
    @end_date = ""
    @active_statuses = ApplicationStatus.all
    @selected_status = ""
  end
  
  def filter_applicants
    @registration_course = RegistrationCourse.find(params[:registration_course_id])
    @start_date = params[:start_date].present? ? params[:start_date].to_date : ""
    @end_date = params[:end_date].present? ? params[:end_date].to_date : ""
    @search_params = params[:name_search_param].present? ? params[:name_search_param] : ""
    @active_statuses = ApplicationStatus.all(:conditions=>{:is_active=>true})
    @selected_status = params[:selected_status].present? ? @active_statuses.find_by_id(params[:selected_status].to_i) : ""
    @filtered_applicants = Applicant.show_filtered_applicants(@registration_course,@start_date,@end_date,@search_params,nil,true)
    @shown_applicants = @selected_status.present? ? @filtered_applicants.select{|a| a.status.to_i == @selected_status.id} : @filtered_applicants.dup
    render :update do|page|
      page.replace_html "result-main-section", :partial=>"result_main_section"
    end
  end
  
  def filter_archived_applicants
    @registration_course = RegistrationCourse.find(params[:registration_course_id])
    @start_date = params[:start_date].present? ? params[:start_date].to_date : ""
    @end_date = params[:end_date].present? ? params[:end_date].to_date : ""
    @search_params = params[:name_search_param].present? ? params[:name_search_param] : ""
    @active_statuses = ApplicationStatus.all
    @selected_status = params[:selected_status].present? ? @active_statuses.find_by_id(params[:selected_status].to_i) : ""
    @filtered_applicants = Applicant.show_filtered_applicants(@registration_course,@start_date,@end_date,@search_params,nil,false)
    @shown_applicants = @selected_status.present? ? @filtered_applicants.select{|a| a.status.to_i == @selected_status.id} : @filtered_applicants.dup
    render :update do|page|
      page.replace_html "result-main-section", :partial=>"archived_result_main_section"
    end
  end
  
  def update_status
    applicants_to_update = Applicant.find_all_by_id_and_submitted(params[:applicant_ids],true)
    target_status = nil
    target_status_id = params[:target_status]
    if target_status_id.present?
      target_status = ApplicationStatus.find(:first,:conditions=>{:is_active=>true,:id=>target_status_id.to_i})
    end
    payment_status = params[:mark_paid].to_i
    applicants_to_update.each do|applicant|
      applicant.hostname = "#{request.protocol}#{request.host_with_port}"
      applicant.update_payment_and_application_status(target_status,payment_status)
    end
    @registration_course = RegistrationCourse.find(params[:registration_course_id])
    @applicants = @registration_course.applicants.all(:conditions=>{:is_deleted=>false,:submitted=>true},:include=>[:batch,:application_status],:order=>"created_at desc")
    @start_date = params[:start_date].present? ? params[:start_date].to_date : ""
    @end_date = params[:end_date].present? ? params[:end_date].to_date : ""
    @search_params = params[:name_search_param].present? ? params[:name_search_param] : ""
    @active_statuses = ApplicationStatus.all(:conditions=>{:is_active=>true})
    @selected_status = params[:selected_status].present? ? @active_statuses.find_by_id(params[:selected_status].to_i) : ""
    @filtered_applicants = Applicant.show_filtered_applicants(@registration_course,@start_date,@end_date,@search_params,nil,true)
    @shown_applicants = @selected_status.present? ? @filtered_applicants.select{|a| a.status.to_i == @selected_status.id} : @filtered_applicants.dup
    render :update do|page|
      page.replace_html "main-section", :partial=>"main_section"
      page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{t('applicants_updated_successfully')}</p>"
    end
  end
  
  def discard_applicants
    applicants_to_discard = Applicant.find_all_by_id_and_submitted(params[:applicant_ids],true)
    target_status = ApplicationStatus.find_by_name_and_is_default("discarded",true)
    if target_status.present?
      applicants_to_discard.each do|applicant|
        applicant.update_attributes(:status=>target_status.id)
      end
      @registration_course = RegistrationCourse.find(params[:registration_course_id])
      @applicants = @registration_course.applicants.all(:conditions=>{:is_deleted=>false,:submitted=>true},:include=>[:batch,:application_status],:order=>"created_at desc")
      @start_date = params[:start_date].present? ? params[:start_date].to_date : ""
      @end_date = params[:end_date].present? ? params[:end_date].to_date : ""
      @search_params = params[:name_search_param].present? ? params[:name_search_param] : ""
      @active_statuses = ApplicationStatus.all(:conditions=>{:is_active=>true})
      @selected_status = params[:selected_status].present? ? @active_statuses.find_by_id(params[:selected_status].to_i) : ""
      @filtered_applicants = Applicant.show_filtered_applicants(@registration_course,@start_date,@end_date,@search_params,nil,true)
      @shown_applicants = @selected_status.present? ? @filtered_applicants.select{|a| a.status.to_i == @selected_status.id} : @filtered_applicants.dup
      render :update do|page|
        page.replace_html "main-section", :partial=>"main_section"
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{t('applicants_discarded_successfully')}</p>"
      end
    else
      page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{t('applicants_not_discarded')}</p>"
    end
  end

  #  def applicants
  #    search_by =""
  #    if params[:search].present?
  #      search_by=params[:search]
  #    end
  #    @sort_order=""
  #    if params[:sort_order].present?
  #      @sort_order=params[:sort_order]
  #    end
  #    @results=Applicant.search_by_order(params[:id], @sort_order, search_by)
  #    if @sort_order==""
  #      @results = @results.sort_by { |u1| [u1.status,u1.created_at.to_date] }.reverse if @results.present?
  #    end
  #    @applicants = @results.paginate :per_page=>10,:page => params[:page]
  #    @registration_course = RegistrationCourse.find(params[:id])
  #  end

  def applicants_pdf
    @registration_course = RegistrationCourse.find(params[:id])
    @start_date = params[:start_date].present? ? params[:start_date].to_date : ""
    @end_date = params[:end_date].present? ? params[:end_date].to_date : ""
    @search_params = params[:name_search_param].present? ? params[:name_search_param] : ""
    @statuses = ApplicationStatus.all
    @selected_status = params[:selected_status].present? ? @statuses.find_by_id(params[:selected_status].to_i) : ""
    @applicants = Applicant.show_filtered_applicants(@registration_course,@start_date,@end_date,@search_params,@selected_status,(params[:applicant_type]=="active" ? true : false))
    #    search_by =""
    #    if params[:search].present?
    #      search_by=params[:search]
    #    end
    #    @sort_order=""
    #    if params[:sort_order].present?
    #      @sort_order=params[:sort_order]
    #    end
    #    @results=Applicant.search_by_order(params[:id], @sort_order, search_by)
    #    if @sort_order==""
    #      @results = @results.sort_by { |u1| [u1.status,u1.created_at.to_date] }.reverse if @results.present?
    #    end
    #    @applicants = @results
    #    @course = RegistrationCourse.find(params[:id]).course
    render :pdf => 'applicants_pdf'
  end

  def search_by_registration
    @search_params = params[:search][:registration_no]
    @applicants = Applicant.show_filtered_applicants(nil,nil,nil,@search_params,nil,true)
    render "applicants/search_results"
  end

  def search_by_registration_pdf
    @search_params = params[:reg_no]
    @applicants = Applicant.show_filtered_applicants(nil,nil,nil,@search_params,nil,true)
    render :pdf => "search_by_registration_pdf"
  end

  def view_applicant
    @currency = currency
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],true, :include=>[:applicant_previous_data,:application_status,:applicant_guardians,:applicant_addl_values,:applicant_additional_details,:applicant_addl_attachments])

    @financetransaction = FinanceTransaction.last(
      :joins => "INNER JOIN finance_transaction_receipt_records ftrr
                                              ON ftrr.finance_transaction_id = finance_transactions.id
                                       LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
      :conditions => ["payee_id = ? AND payee_type = 'Applicant' AND
                                            (fa.id IS NULL OR fa.is_deleted = false)", @applicant.id])
    @online_transaction_id = nil
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      online_payment = Payment.find_by_payee_id_and_payee_type_and_status_and_amount(@applicant.id,'Applicant',true,@applicant.amount)
      if online_payment.present?
        @online_transaction_id = online_payment.gateway_response[:transaction_reference]
      end
    end
    @registration_course = @applicant.registration_course
    @application_section = @registration_course.application_section
    unless @application_section.present?
      @application_section = ApplicationSection.find_by_registration_course_id(nil)
    end
    @field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    @applicant_addl_fields = ApplicantAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?) and is_active=true",@registration_course.id],:include=>:applicant_addl_field_values)
    @applicant_student_addl_fields = ApplicantStudentAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?)",@registration_course.id],:include=>[:student_additional_field=>:student_additional_field_options])
    @addl_attachment_fields = ApplicantAddlAttachmentField.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    if @applicant.is_deleted == false
      @previous_applicant = Applicant.find(:first,:conditions=>["created_at > ? and registration_course_id = ? and is_deleted=false and submitted=true",@applicant.created_at,@registration_course.id])
      @next_applicant = Applicant.find(:last,:conditions=>["created_at < ? and registration_course_id = ? and is_deleted=false and submitted=true",@applicant.created_at,@registration_course.id])
    else
      @previous_applicant = Applicant.find(:first,:conditions=>["created_at > ? and registration_course_id = ? and is_deleted=true and submitted=true",@applicant.created_at,@registration_course.id])
      @next_applicant = Applicant.find(:last,:conditions=>["created_at < ? and registration_course_id = ? and is_deleted=true and submitted=true",@applicant.created_at,@registration_course.id])
    end
    @active_statuses = ApplicationStatus.all(:conditions=>{:is_active=>true})
    #    @elective_name=[]
    #    @applicant = Applicant.find params[:id]
    #    @electives=@applicant.subject_ids
    #    @electives.each do |elec|
    #      @elective_name<<Subject.find_by_code(elec)
    #    end
    #    @addl_values = @applicant.applicant_addl_values
    #    @additional_details = @applicant.applicant_additional_details
    #    @financetransaction=FinanceTransaction.find_by_title("Applicant Registration - #{@applicant.reg_no} - #{@applicant.full_name}")
    #    if FedenaPlugin.can_access_plugin?("fedena_pay")
    #      if (PaymentConfiguration.config_value("enabled_fees").present? and PaymentConfiguration.is_applicant_registration_fee_enabled?)
    #        online_payment = Payment.find_by_payee_id_and_payee_type(@applicant.id,'Applicant')
    #        if online_payment.nil?
    #          @online_transaction_id = @applicant.has_paid == true ? nil : t('fee_not_paid')
    #        else
    #          if online_payment.gateway_response.keys.include? :transaction_id
    #            @online_transaction_id = online_payment.gateway_response[:transaction_id]
    #          elsif online_payment.gateway_response.include? :x_trans_id
    #            @online_transaction_id = online_payment.gateway_response[:x_trans_id]
    #          end
    #        end
    #      end
    #    end
  end
  
  def print_applicant_pdf
    @currency = currency
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],true, :include=>[:applicant_previous_data,:application_status,:applicant_guardians,:applicant_addl_values,:applicant_additional_details,:applicant_addl_attachments])
    @financetransaction=@applicant.finance_transaction
    @online_transaction_id = nil
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      online_payment = Payment.find_by_payee_id_and_payee_type_and_status_and_amount(@applicant.id,'Applicant',true,@applicant.amount)
      if online_payment.present?
        @online_transaction_id = online_payment.gateway_response[:transaction_reference]
      end
    end
    @registration_course = @applicant.registration_course
    @application_section = @registration_course.application_section
    unless @application_section.present?
      @application_section = ApplicationSection.find_by_registration_course_id(nil)
    end
    @field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    @applicant_addl_fields = ApplicantAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?) and is_active=true",@registration_course.id],:include=>:applicant_addl_field_values)
    @applicant_student_addl_fields = ApplicantStudentAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?)",@registration_course.id],:include=>[:student_additional_field=>:student_additional_field_options])
    @addl_attachment_fields = ApplicantAddlAttachmentField.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    render :pdf => "print_applicant_pdf",:zoom => 0.90
  end
  
  def edit_applicant
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],true, :include=>[:applicant_previous_data,:application_status,:applicant_guardians,:applicant_addl_values,:applicant_additional_details,:applicant_addl_attachments])
    unless @applicant.application_status.name == "alloted"
      @registration_course = @applicant.registration_course
      @application_section = @registration_course.application_section
      unless @application_section.present?
        @application_section = ApplicationSection.find_by_registration_course_id(nil)
      end
      @fee_paid = (@applicant.has_paid.present? and @applicant.has_paid) ? true : false
      subject_amounts = @applicant.subject_amounts
      @field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
      @applicant_addl_fields = ApplicantAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?) and is_active=true",@registration_course.id],:include=>:applicant_addl_field_values)
      @applicant_student_addl_fields = ApplicantStudentAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?)",@registration_course.id],:include=>[:student_additional_field=>:student_additional_field_options])
      @addl_attachment_fields = ApplicantAddlAttachmentField.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
      @selected_subject_ids = @applicant.subject_ids.nil? ? [] : @applicant.subject_ids
      @mandatory_attributes = []
      @mandatory_guardian_attributes = []
      @mandatory_previous_attributes = []
      @mandatory_addl_attributes =[]
      @mandatory_student_attributes = []
      @mandatory_attachment_attributes = []
      @currency = currency
      @normal_subject_amount = 0.to_f
      @total_fee = 0.to_f
      if subject_amounts.present? and @fee_paid
        @application_fee = subject_amounts[:application_fee]
        @normal_subject_amount = subject_amounts[:normal_subject_amount].present? ? subject_amounts[:normal_subject_amount] : 0.to_f
        elective_subject_hash = subject_amounts[:elective_subject_amounts]
        @content = ""
        elective_subject_hash.each_pair{|key, value| @content+= (", #{Subject.find_by_code(key,:select=>'name').name}(elective): #{@currency} #{precision_label(value)}") }
        @total_elective_amount = elective_subject_hash.values.sum.to_f
        @total_fee = @application_fee + @normal_subject_amount + @total_elective_amount
        if @registration_course.is_subject_based_registration
          @subjects = @registration_course.get_elective_subjects_and_amount
        end
      else
        @financetransaction = @applicant.finance_transaction if @fee_paid
        @application_fee = @registration_course.amount.to_f
        @application_fee = @financetransaction.amount.to_f if @financetransaction.present?
        @total_fee = @application_fee
        if @registration_course.is_subject_based_registration
          @subjects = @registration_course.get_elective_subjects_and_amount
          if @registration_course.subject_based_fee_colletion == true
            @normal_subject_amount = @registration_course.get_major_subjects_amount
            @total_fee = @application_fee + @normal_subject_amount
          end
        end
      end
    else
      flash[:notice] = "#{t('cannot_edit_alloted_applicant')}"
      redirect_to view_applicant_applicants_admin_path(@applicant)
    end
  end
  
  def update_applicant
    @registration_course = RegistrationCourse.find(params[:applicant][:registration_course_id])
    subject_amounts = @registration_course.course.subject_amounts
    if params[:applicant][:subject_ids].nil?
      params[:applicant][:subject_ids]=[]
      @ele_subject_amount=0.to_f
    else
      @ele_subject_amount=subject_amounts.find(:all,:conditions => {:code => params[:applicant][:subject_ids]}).flatten.compact.map(&:amount).sum.to_f
    end
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],true)
    guardians =  params[:applicant][:applicant_guardians_attributes]
    elective_subject_amounts = Hash.new
    @registration_amount = @registration_course.amount.to_f
    @normal_subject_amount = 0.to_f
    if @registration_course.is_subject_based_registration
      elective_subject_amounts = @registration_course.get_applicant_elective_subject_amounts_hash(params[:applicant][:subject_ids])
      @registration_amount = @ele_subject_amount+@registration_course.amount.to_f
      if @registration_course.subject_based_fee_colletion == true
        @normal_subject_amount = @registration_course.get_major_subjects_amount
        @registration_amount = @normal_subject_amount+@ele_subject_amount+@registration_course.amount.to_f   
      end
    end
    @applicant.amount = @registration_amount.to_f
    @applicant.has_paid = true if @applicant.amount==0.0
    application_fee = @registration_course.amount.to_f
    @applicant.guardians =  params[:applicant][:applicant_guardians_attributes]
    subject_amounts_hsh = Hash.new
    subject_amounts_hsh = {:application_fee => application_fee, :normal_subject_amount => @normal_subject_amount, :elective_subject_amounts => elective_subject_amounts}
    @applicant.subject_amounts = subject_amounts_hsh
    if @applicant.update_attributes(params[:applicant])
      @applicant.save
      flash[:notice] = t('application_updated_successfully')
      obj = {:resp_text=>"saved_successfully",:redirect_url=>url_for(:controller=>"applicants_admins",:action=>"view_applicant",:id=>@applicant.id)}
      render :json=>obj
      #render :js => "window.location = '#{success_applicants_path(:id=>@applicant.id)}'"
    else
      render :partial=>"applicants/applicant_errors", :object=>@applicant
    end
  end

  def discard_applicant
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],true)
    target_status = ApplicationStatus.find_by_name_and_is_default("discarded",true)
    if target_status.present?
      @applicant.update_attributes(:status=>target_status.id)
      flash[:notice] = "#{t('applicant_discarded_successfully')}"
    else
      flash[:notice] = "#{t('applicant_not_discarded')}"
    end
    redirect_to view_applicant_applicants_admin_path(@applicant)
  end
  
  def allocate_applicant
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],true)
    batch_id = params[:batch_id]
    allocation_errors = []
    if @applicant.has_paid == true
      @applicant.being_allotted = true
      a_status = @applicant.admit(batch_id)
      unless a_status.last == 1
        allocation_errors = a_status.first.flatten
      else
        @applicant = Applicant.find_by_id_and_submitted!(params[:id],true)
        @applicant.hostname = "#{request.protocol}#{request.host_with_port}"
        @applicant.send_email_and_sms_alert
        if params[:collection_ids].present?
          dates = FinanceFeeCollection.find(params[:collection_ids])
          if (a_status[1].present?)
            unless (a_status[1].has_paid_fees or a_status[1].has_paid_fees_for_batch)
              dates.each do |date|
                date.invoice_number_enabled = FeeInvoice.is_generated_for_collection?(date)
                FinanceFee.new_student_fee(date,a_status[1])
              end
            end
          end
        end
      end
    else
      allocation_errors.push("#{t('application_fee_unpaid')}")
    end
    if allocation_errors.empty?
      flash[:notice] = "#{t('applicant_allocated_successfully')}"
    else
      flash[:notice] = "Applicant could not be allotted. Reason : #{[allocation_errors.join(', ')]}"
    end
    redirect_to view_applicant_applicants_admin_path(@applicant)
  end
  
  def update_applicant_status
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],true)
    target_status = nil
    target_status_id = params[:application_status]
    if target_status_id.present?
      target_status = ApplicationStatus.find(:first,:conditions=>{:is_active=>true,:id=>target_status_id.to_i})
    end
    payment_status = params[:has_paid].present? ? 1 : 0
    @applicant.hostname = "#{request.protocol}#{request.host_with_port}"
    @applicant.update_payment_and_application_status(target_status,payment_status)
    flash[:notice] = "#{t('status_updated_successfully')}"
    redirect_to view_applicant_applicants_admin_path(@applicant)
  end

  def admit_applicant
    @applicant = Applicant.find(params[:id])
    @batches = @applicant.registration_course.course.batches.active
    render :update do |page|
      #atmts = Applicant.commit(params[:applicant_id],params[:batch_id],"allot")
      #flash[:notice] = "#{atmts}"
      page.replace_html 'modal-box', :partial => 'allotment_form'
      page << "Modalbox.show($('modal-box'), {title: ''});"
    end
  end

  def allot_applicant
    
    unless params[:allotment][:batch_id].blank?
      applicant = Applicant.find(params[:allotment][:id])
      atmts =  applicant.admit(params[:allotment][:batch_id])
      if atmts.second == 1
        flash[:notice] = "#{atmts.first.join(', ')}"
      else
        flash[:warn_notice] = "#{atmts.first.join(', ')}"
      end
      render :update do |page|
        page.redirect_to :controller => "applicants_admins",:action => "view_applicant",:id => params[:allotment][:id]
      end
    else
      flash[:notice] = t('select_batch_to_allot')
      render :update do |page|
        page.redirect_to :controller => "applicants_admins",:action => "view_applicant",:id => params[:allotment][:id]
      end
    end
  end
  
  def allot_applicants
    applicants_to_allot = Applicant.find_all_by_id_and_submitted(params[:applicant_ids],true)
    batch_id = params[:batch_id]
    failed_allocations = []
    applicants_to_allot.each do|applicant|
      if applicant.has_paid == true
        applicant.being_allotted == true
        a_status = applicant.admit(batch_id)
        unless a_status.last == 1
          failed_allocations.push([applicant.id,a_status.first])
        else
          applicant = Applicant.find_by_id_and_submitted(applicant.id,true)
          applicant.hostname = "#{request.protocol}#{request.host_with_port}"
          applicant.send_email_and_sms_alert
          if params[:fee_collection_ids].present?
            dates = FinanceFeeCollection.find(params[:fee_collection_ids])
            if (a_status[1].present?)
              unless (a_status[1].has_paid_fees or a_status[1].has_paid_fees_for_batch)
                dates.each do |date|              
                  date.invoice_number_enabled = FeeInvoice.is_generated_for_collection?(date)
                  FinanceFee.new_student_fee(date,a_status[1])
                end
              end
            end
          end
        end
      else
        failed_allocations.push([applicant.id,["#{t('application_fee_unpaid')}"]])
      end
    end
    @registration_course = RegistrationCourse.find(params[:registration_course_id])
    @applicants = @registration_course.applicants.all(:conditions=>{:is_deleted=>false,:submitted=>true},:include=>[:batch,:application_status],:order=>"created_at desc")
    @start_date = params[:start_date].present? ? params[:start_date].to_date : ""
    @end_date = params[:end_date].present? ? params[:end_date].to_date : ""
    @search_params = params[:name_search_param].present? ? params[:name_search_param] : ""
    @active_statuses = ApplicationStatus.all(:conditions=>{:is_active=>true})
    @selected_status = params[:selected_status].present? ? @active_statuses.find_by_id(params[:selected_status].to_i) : ""
    @filtered_applicants = Applicant.show_filtered_applicants(@registration_course,@start_date,@end_date,@search_params,nil,true)
    @shown_applicants = @selected_status.present? ? @filtered_applicants.select{|a| a.status.to_i == @selected_status.id} : @filtered_applicants.dup
    render :update do|page|
      page.replace_html "main-section", :partial=>"main_section"
      if failed_allocations.present?
        error_list = []
        failed_allocations.each do|f|
          page << "j('.show_field_checkbox[value=\"#{f.first.to_s}\"]').parent().parent().addClass('red-border')"
          error_list = error_list + f.last.flatten.compact
        end
        page.replace_html 'input-form-errors', :partial=>"allotment_errors", :locals=>{:all_errors=>error_list.uniq,:error_header=>"Batch allocation failed for #{failed_allocations.count} applicants."}
      else
        page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{t('applicants_allotted_successfully')}</p>"
      end
    end
  end

  def allot
    allot_to = (params[:allotment].present? and params[:allotment][:batch].present?) ? params[:allotment][:batch]  : ""
    if params[:regid].present? and  params[:commit].present?
      if params[:commit]==t('allot')
        atmts =  Applicant.commit(params[:regid],allot_to,'Allot')
      else
        atmts =  Applicant.commit(params[:regid],allot_to,'Discard')
      end
      flash[:notice] = "#{atmts.first.join(', ')}"
      redirect_to :action=>"applicants",:id=>params[:id],:view=>params[:allotment][:view]
    else
      flash[:notice] = t('no_applicant_selected')
      redirect_to :action=>"applicants",:id=>params[:id]
    end
  end

  def mark_paid
    @applicant = Applicant.find params[:id]
    if @applicant.has_paid
      render(:update) do |p|
        flash[:warn_notice] = "#{t('fees_text')} #{t('already_payed')}"
        p.reload
      end
    else
      @applicant.mark_paid
      render(:update) do |p|
        p.reload
      end
    end
  end

  def mark_academically_cleared
    @applicant = Applicant.find params[:id]
    @applicant.mark_academically_cleared
    render(:update) do |p|
      flash[:notice] = t('applicants_admins.applicant_academically_cleared')
      p.reload
    end
  end
      
  def generate_fee_receipt_pdf
    @applicant = Applicant.find_by_id_and_submitted!(params[:id],true)
    finance_transactions = @applicant.finance_transaction.to_a
    #    finance_transactions = FinanceTransaction.find_all_by_id(params[:transaction_id], 
    #      :include => :finance_transaction_receipt_record)
    template_ids = []
    @transactions = finance_transactions.map do |ft| 
      receipt_data = ft.receipt_data
      template_ids << receipt_data.template_id = ft.fetch_template_id
      receipt_data
    end
    template_ids = template_ids.compact.uniq
    configs = ['PdfReceiptSignature', 'PdfReceiptSignatureName', 
      'PdfReceiptCustomFooter','PdfReceiptAtow','PdfReceiptNsystem', 'PdfReceiptHalignment']
    #    fetch_config_hash configs
    @config = Configuration.get_multiple_configs_as_hash configs
    
    @default_currency = Configuration.default_currency
    #    template_ids = finance_transactions.map {|x| x.fetch_template_id }.uniq.compact
    @data = {:templates => template_ids.present? ? FeeReceiptTemplate.find(template_ids).group_by(&:id) : {} }
    render :pdf => 'generate_fee_receipt_pdf',
      :template => "finance_extensions/receipts/generate_fee_receipt_pdf.erb",
      :margin =>{:top => 2, :bottom => 20, :left => 5, :right => 5},
      :header => {:html => { :content=> ''}},  :footer => {:html => {:content => ''}}, 
      :show_as_html => params.key?(:debug)
    #    @config = Configuration.get_multiple_configs_as_hash ['PdfReceiptSignature', 'PdfReceiptSignatureName', 'PdfReceiptCustomFooter','PdfReceiptAtow','PdfReceiptNsystem', 'PdfReceiptHalignment']
    #    @default_currency = Configuration.default_currency
    #    @currency = currency
    #    @applicant = Applicant.find_by_id_and_submitted!(params[:id],true)
    #    @financetransaction = @applicant.finance_transaction
    #    @registration_course = @applicant.registration_course
    #    @subject_amounts = @applicant.subject_amounts
    #    @application_fee = @applicant.amount.to_f
    #    if @subject_amounts.present?
    #      @application_fee = @subject_amounts[:application_fee]
    #      @elective_subject_amount = 0.to_f
    #      @total_fee = @application_fee + 0.to_f
    #      elective_subject_hash = @subject_amounts[:elective_subject_amounts]
    #      @elective_subject_amount = elective_subject_hash.values.sum.to_f
    #      active_batch_ids = @registration_course.course.batches.all(:conditions=>{:is_active=>true,:is_deleted=>false}).collect(&:id)
    #      @elective_subjects = Subject.find_all_by_code_and_batch_id(elective_subject_hash.keys,active_batch_ids).map(&:name).flatten.compact.uniq.join(', ')
    #      @normal_subject_amount = @subject_amounts[:normal_subject_amount].present? ? @subject_amounts[:normal_subject_amount] : 0.to_f
    #      @total_fee = @application_fee+@normal_subject_amount+@elective_subject_amount
    #    end
    #    @online_transaction_id = nil
    #    if FedenaPlugin.can_access_plugin?("fedena_pay")
    #      online_payment = Payment.find_by_payee_id_and_payee_type_and_status_and_amount(@applicant.id,'Applicant',true,@applicant.amount)
    #      if online_payment.present?
    #        @online_transaction_id = online_payment.gateway_response[:transaction_reference]
    #      end
    #    end
    #    render :pdf => 'generate_fee_receipt_pdf',:margin =>{:top=>2,:bottom=>20,:left=>5,:right=>5},:header => {:html => { :content=> ''}}, :footer => {:html => {:content => ''}}, :show_as_html => params.key?(:debug)
  end
  
  def detailed_csv_report
    parameters = {:id => params[:id], :start_date => params[:start_date], :end_date => params[:end_date], :name_search_param => params[:name_search_param], :selected_status => params[:selected_status], :applicant_type => params[:applicant_type]}
    csv_export('applicant', 'applicant_registration_detailed_data', parameters)
  end

  def print_application_form
    @currency = currency
    @registration_course = RegistrationCourse.find(params[:id])
    @application_section = @registration_course.application_section
    unless @application_section.present?
      @application_section = ApplicationSection.find_by_registration_course_id(nil)
    end
    @field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    @applicant_addl_fields = ApplicantAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?) and is_active=true",@registration_course.id],:include=>:applicant_addl_field_values)
    @applicant_student_addl_fields = ApplicantStudentAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?)",@registration_course.id],:include=>[:student_additional_field=>:student_additional_field_options])
    @default_fields = ApplicationSection::DEFAULT_FIELDS
    @application_sections = @application_section.present? ? @application_section.section_fields : Marshal.load(Marshal.dump(ApplicationSection::DEFAULT_FORM))
    @addl_attachment_fields = ApplicantAddlAttachmentField.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",@registration_course.id])
    @guardian_count = @application_section.present? ? @application_section.guardian_count : 1
    @application_fee = @registration_course.amount.to_f
    if @registration_course.is_subject_based_registration
      @subjects = @registration_course.get_elective_subjects_and_amount
      if @registration_course.subject_based_fee_colletion == true
        @normal_subject_amount = @registration_course.get_major_subjects_amount
        @total_fee = @application_fee + @normal_subject_amount
      else
        @normal_subject_amount = 0.to_f
        @total_fee = @application_fee + 0.to_f
      end
    end
    
    render :pdf => "print_application_form", :header =>{:content=>nil}, :zoom => 0.90,:margin=>{:left=>15,:right=>15,:top=>10,:bottom=>10},:show_as_html=>params.key?(:debug), :footer => ""
  end
  
  def message_applicants
    if request.post?
      @errors = []
      send_flag = false
      applicant_ids = params[:applicant_ids].present? ? params[:applicant_ids] : ""
      applicants = Applicant.find_all_by_id(applicant_ids) if applicant_ids.present?
      if params[:mode_sms].present?
        unless params[:mode_sms] == "0"
          sms_content = params[:sms_content].present? ? params[:sms_content] : ""
          unless sms_content.present?
            @errors << t('sms_content_is_empty')
          else
            phone_numbers = Applicant.find_all_by_id(applicant_ids).collect(&:phone2).reject(&:blank?) if applicants.present?
            student_recipients = {:recipient_type => "ApplicantStudent", :values => applicant_ids }
            sms_setting = SmsSetting.new()
            if sms_setting.application_sms_active
              if params[:sent_to_applicant].present? and params[:sent_to_applicant] == "1"
                if phone_numbers.present?
                  message_log = SmsMessage.create(:body=> sms_content, :automated_message => false)
                  Delayed::Job.enqueue(SmsManager.new(sms_content, student_recipients, false, message_log), {:queue => 'sms'})
                end
              end
              if params[:sent_to_parent].present? and params[:sent_to_parent] == "1"
                guardian_phone_numbers = Applicant.applicant_guardian_phone(applicants) if applicants.present?
                applicant_gids = Applicant.applicant_guardian_ids(applicants) if applicants.present?
                guardian_recipients = {:recipient_type => "ApplicantGuardian", :values => applicant_gids }
                if guardian_phone_numbers.present?
                  message_log = SmsMessage.create(:body=> sms_content, :automated_message => false)
                  Delayed::Job.enqueue(SmsManager.new(sms_content, guardian_recipients, false, message_log), {:queue => 'sms'})
                end
              end
              send_flag = true
            else
              @errors << t('sms_not_active_in_settings')   
            end
          end
        end
      end
      if params[:mode_email].present?
        unless params[:mode_email] == "0"
          email_content = params[:email_content].present? ? params[:email_content] : ""
          email_subject = params[:email_subject].present? ? params[:email_subject] : ""
          unless email_content.present? or email_subject.present?
            @errors << t('email_content_is_empty')
          else
            
            email_ids = Applicant.find_all_by_id(applicant_ids).collect(&:email).reject(&:blank?) if applicant_ids.present?
            hostname = "#{request.protocol}#{request.host_with_port}"
            school_details = Applicant.school_details
            if params[:sent_to_applicant].present? and params[:sent_to_applicant] == "1"
              if email_ids.present? and hostname.present?
                begin
                  Delayed::Job.enqueue(FedenaApplicantRegistration::ApplicantMessageMail.new(email_ids, email_subject, email_content, hostname, school_details), {:queue => 'email'})
                rescue Exception => e
                  puts "Error------#{e.message}------#{e.backtrace.inspect}"
                  return
                end
              end
            end
            if params[:sent_to_parent].present? and params[:sent_to_parent] == "1"
              guardian_emails = Applicant.applicant_guardian_email(applicants) if applicants.present?
              if guardian_emails.present? and hostname.present?
                begin
                  Delayed::Job.enqueue(FedenaApplicantRegistration::ApplicantMessageMail.new(guardian_emails, email_subject, email_content, hostname, school_details), {:queue => 'email'})
                rescue Exception => e
                  puts "Error------#{e.message}------#{e.backtrace.inspect}"
                  return
                end
              end
            end
            send_flag = true
          end
        end
      end
      if send_flag == true 
        @registration_course = RegistrationCourse.find(params[:registration_course_id])
        @applicants = @registration_course.applicants.all(:conditions=>{:is_deleted=>false,:submitted=>true},:include=>[:batch,:application_status],:order=>"created_at desc")
        @start_date = params[:start_date].present? ? params[:start_date].to_date : ""
        @end_date = params[:end_date].present? ? params[:end_date].to_date : ""
        @search_params = params[:name_search_param].present? ? params[:name_search_param] : ""
        @active_statuses = ApplicationStatus.all(:conditions=>{:is_active=>true})
        @selected_status = params[:selected_status].present? ? @active_statuses.find_by_id(params[:selected_status].to_i) : ""
        @filtered_applicants = Applicant.show_filtered_applicants(@registration_course,@start_date,@end_date,@search_params,nil,true)
        @shown_applicants = @selected_status.present? ? @filtered_applicants.select{|a| a.status.to_i == @selected_status.id} : @filtered_applicants.dup
        render :update do|page|
          page.replace_html "main-section", :partial=>"main_section"
          page.replace_html 'flash-box', :text=>"<p class='flash-msg'>#{t('message_notification_sent_successfully')}</p>"
          page << "Modalbox.hide();"
        end
      else
        render :update do|page|
          page.replace_html 'form-errors', :partial => 'message_applicants_errors', :locals => {:errors => @errors }
          page.call 'onErrorPresent'
          page.visual_effect(:highlight, 'form-errors')
        end
      end
    else
      render :update do|page|
        page.replace_html 'modal-box', :partial => 'message_applicants'
        page << "Modalbox.show($('modal-box'), {title: '#{t('message_applicants')}'});"
        page << "onloadModal();"
      end
    end
  end
  
  private
  
  def csv_export(model, method, parameters)
    csv_report=AdditionalReportCsv.find_by_model_name_and_method_name(model, method)
    if csv_report.nil?
      csv_report=AdditionalReportCsv.new(:model_name => model, :method_name => method, :parameters => parameters, :status => true)
      if csv_report.save
        Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
      end
    else
      unless csv_report.status
        if csv_report.update_attributes(:parameters => parameters, :csv_report => nil, :status => true)
          Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
        end
      end 
    end
    flash[:notice]="#{t('csv_report_is_in_queue')}"
    redirect_to :controller=> :reports, :action => :csv_reports, :model => model, :method => method
  end
  
end
