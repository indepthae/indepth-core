class RegistrationCoursesController < ApplicationController
  before_filter :login_required
  before_filter :set_precision
  filter_access_to :all


  def index
    @registration_courses = RegistrationCourse.find(:all,:order => "courses.course_name",:joins => :course).paginate(:page => params[:page],:per_page => 30)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @registration_courses }
    end
  end

  # GET /registration_courses/1
  # GET /registration_courses/1.xml
  def show
    @courses = Course.active.select{|c| c.registration_course.nil?}
    @registration_courses = RegistrationCourse.all

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @registration_course }
    end
  end

  # GET /registration_courses/new
  # GET /registration_courses/new.xml
  def new
    @registration_course = RegistrationCourse.new
    @additional_fields = StudentAdditionalField.active.sort_by(&:priority)
    @courses = Course.active.select{|c| c.registration_course.nil?}

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @registration_course }
    end
  end

  # GET /registration_courses/1/edit
  def edit
    @registration_course = RegistrationCourse.find(params[:id])
    @additional_fields = StudentAdditionalField.active.sort_by(&:priority)
    @courses = Course.active.select{|c| c.registration_course.nil?}
  end

  # POST /registration_courses
  # POST /registration_courses.xml
  def create
    @courses = Course.active.select{|c| c.registration_course.nil?}
    @registration_course = RegistrationCourse.new(params[:registration_course])
    @additional_fields = StudentAdditionalField.active.sort_by(&:priority)

    respond_to do |format|
      if @registration_course.save
        @registration_course.manage_pin_system(params[:is_pin_enabled])
        flash[:notice] = t('create_successfully')
        format.html { redirect_to(:action=>"index") }
        format.xml  { render :xml => @registration_course, :status => :created, :location => @registration_course }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @registration_course.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /registration_courses/1
  # PUT /registration_courses/1.xml
  def update
    @courses = Course.active.select{|c| c.registration_course.nil?}
    @registration_course = RegistrationCourse.find(params[:id])
    @additional_fields = StudentAdditionalField.active.sort_by(&:priority)
    unless params[:registration_course][:additional_field_ids].present?
      params[:registration_course] = params[:registration_course].merge(:additional_field_ids => [])
    end
    respond_to do |format|
      if @registration_course.update_attributes(params[:registration_course])
        @registration_course.manage_pin_system(params[:is_pin_enabled])
        flash[:notice] = t('update_successfully')
        format.html { redirect_to(:action=>"index") }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @registration_course.errors, :status => :unprocessable_entity }
      end
    end
  end

  def registration_settings
    @registration_course = RegistrationCourse.find(params[:id],:include=>[:course,:application_instruction])
    @currency = currency
    unless @registration_course.application_instruction.present?
      @registration_course.build_application_instruction
    end
    @subject_count = @registration_course.course.batches.active.map(&:all_elective_subjects).flatten.compact.map(&:code).compact.flatten.uniq.count
    if request.put?
      @registration_course.attributes = params[:registration_course]
      if @registration_course.save
        @registration_course.manage_pin_system(params[:is_pin_enabled])
        flash[:notice] = "#{t('update_successfully')}"
        redirect_to applicants_admin_path
      end
    end
  end
  
  def archive_all_applicants
    @registration_course = RegistrationCourse.find(params[:id])
    active_applicants = @registration_course.applicants.all(:conditions=>{:is_deleted=>false,:submitted=>true})
    active_applicants.each do|a|
      a.update_attributes(:is_deleted=>true)
    end
    flash[:notice] = "#{t('archived_all_successfully')}"
    redirect_to registration_settings_registration_course_path(@registration_course)
  end
 
  #-----------------------------------------------------------------------------------------------------
  
  def customize_form
    @registration_course = RegistrationCourse.find(params[:id])
    @application_section = ApplicationSection.find_by_registration_course_id(@registration_course.id)
    if request.post?
      if @application_section.present?
        if @application_section.update_attributes(params[:application_section])
          flash[:notice] = "#{t('application_form_modified_successfully')}"
          redirect_to registration_settings_registration_course_path(@registration_course)
        end
      else
        @application_section = ApplicationSection.new(params[:application_section])
        if @application_section.save
          flash[:notice] = "#{t('application_form_created_successfully')}"
          redirect_to registration_settings_registration_course_path(@registration_course)
        end
      end
    else 
      unless @application_section.present?
        default_application_form = ApplicationSection.find_by_registration_course_id(nil)
        if default_application_form.present?
          @application_section = ApplicationSection.new(:registration_course_id=>@registration_course.id,:section_fields=>default_application_form.section_fields,:guardian_count=>default_application_form.guardian_count)
        end
      end
    end
  end
  
  def restore_defaults
    @registration_course = RegistrationCourse.find(params[:id])
    @application_section = ApplicationSection.find_by_registration_course_id(@registration_course.id)
    if @application_section.present?
      @application_section.destroy
      flash[:notice]="#{t('application_form_restored_successfully')}"
    end
    redirect_to customize_form_registration_course_path(@registration_course)
  end
  
  def add_section
    @registration_course = RegistrationCourse.find(params[:registration_course_id])
    @field_group = ApplicantAddlFieldGroup.new(:registration_course_id=>@registration_course.id)
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
      @registration_course = @field_group.registration_course
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
        page.replace_html 'form-errors', :partial => 'applicants_admins/section_errors', :object => @field_group
        page.visual_effect(:highlight, 'form-errors')
      end
    end    
  end
  
  def edit_section
    @field_group = ApplicantAddlFieldGroup.find(params[:id])
    if @field_group.can_edit_section(params[:registration_course_id].to_i)
      render :update do|page|
        page.replace_html 'flash-box', :text=>""
        page.replace_html 'modal-box', :partial => 'add_section_form'
        page << "Modalbox.show($('modal-box'), {title: '#{t('edit_form_section')}'});"
      end
    end
  end
  
  def update_section
    @field_group = ApplicantAddlFieldGroup.find(params[:id])
    if @field_group.update_attributes(params[:applicant_addl_field_group])
      @registration_course = @field_group.registration_course
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
        page.replace_html 'form-errors', :partial => 'applicants_admins/section_errors', :object => @field_group
        page.visual_effect(:highlight, 'form-errors')
      end
    end   
  end
  
  def delete_section
    @field_group = ApplicantAddlFieldGroup.find(params[:id])
    if @field_group.can_edit_section(params[:registration_course_id].to_i) and @field_group.destroy
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
        @applicant_addl_field = ApplicantAddlField.new(:multi_select_type=>'single_select',:section_name=>params[:section_name],:registration_course_id=>params[:registration_course_id].to_i)
      else
        @applicant_addl_field = ApplicantAddlField.new(:multi_select_type=>'single_select',:applicant_addl_field_group_id=>params[:group_id],:registration_course_id=>params[:registration_course_id].to_i)
      end
      @applicant_addl_field.applicant_addl_field_values.build    
      @applicant_addl_field.applicant_addl_field_values.build
      linked_additional_fields = ApplicantStudentAddlField.all(:conditions=>["registration_course_id IS NULL or registration_course_id=?",params[:registration_course_id].to_i]).collect(&:student_additional_field_id)
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
      @applicant_addl_attachment_field = ApplicantAddlAttachmentField.new(:registration_course_id=>params[:registration_course_id].to_i)
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
      @registration_course = @applicant_addl_field.registration_course
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
        page.replace_html 'input-form-errors', :partial => 'applicants_admins/input_form_errors', :object => @applicant_addl_field
        page.visual_effect(:highlight, 'form-errors')
        page << "$('input-form-errors').scrollIntoView();"
      end
    end
  end
  
  
  def create_attachment_field
    @applicant_addl_attachment_field = ApplicantAddlAttachmentField.new(params[:applicant_addl_attachment_field])
    if @applicant_addl_attachment_field.save
      @registration_course = @applicant_addl_attachment_field.registration_course
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
        page.replace_html 'input-form-errors', :partial => 'applicants_admins/applicant_attachment_errors', :object => @applicant_addl_attachment_field
        page.visual_effect(:highlight, 'form-errors')
        page << "$('input-form-errors').scrollIntoView();"
      end
    end
  end
  
  def edit_field
    if params[:field_type] == "applicant_additional"
      @applicant_addl_field = ApplicantAddlField.find(params[:id])
      if @applicant_addl_field.can_edit_field(params[:registration_course_id].to_i)
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
      if @applicant_addl_attachment_field.can_edit_field(params[:registration_course_id].to_i)
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
    if @applicant_addl_field.update_attributes(params[:applicant_addl_field])
      @registration_course = @applicant_addl_field.registration_course
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
        page.replace_html 'input-form-errors', :partial => 'applicants_admins/input_form_errors', :object => @applicant_addl_field
        page.visual_effect(:highlight, 'form-errors')
        page << "$('input-form-errors').scrollIntoView();"
      end
    end
  end
  
  def update_attachment_field
    @applicant_addl_attachment_field = ApplicantAddlAttachmentField.find(params[:id])
    if @applicant_addl_attachment_field.update_attributes(params[:applicant_addl_attachment_field])
      @registration_course = @applicant_addl_attachment_field.registration_course
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
        page.replace_html 'input-form-errors', :partial => 'applicants_admins/applicant_attachment_errors', :object => @applicant_addl_attachment_field
        page.visual_effect(:highlight, 'form-errors')
        page << "$('input-form-errors').scrollIntoView();"
      end
    end
  end
  
  def delete_field
    field_deleted = 0
    addl_field_group_id = 0
    @registration_course = RegistrationCourse.find(params[:registration_course_id].to_i) if params[:registration_course_id].present?
    if params[:field_type] == "applicant_additional"
      @applicant_addl_field = ApplicantAddlField.find(params[:id])
      addl_field_group_id = @applicant_addl_field.applicant_addl_field_group_id if @applicant_addl_field.applicant_addl_field_group_id.present?
      if @applicant_addl_field.can_delete_field(@registration_course.id)
        if @applicant_addl_field.destroy
          field_deleted = 1
        end
      end
    elsif params[:field_type] == "student_additional"
      @applicant_student_addl_field = ApplicantStudentAddlField.find_by_registration_course_id_and_student_additional_field_id(@registration_course.id,params[:id])
      addl_field_group_id = @applicant_student_addl_field.applicant_addl_field_group_id if @applicant_student_addl_field.applicant_addl_field_group_id.present?
      if @applicant_student_addl_field.can_delete_field(@registration_course.id)
        if @applicant_student_addl_field.destroy
          field_deleted = 1
        end
      end
    elsif params[:field_type] == "applicant_attachment"
      @applicant_addl_attachment_field = ApplicantAddlAttachmentField.find(params[:id])
      if @applicant_addl_attachment_field.can_delete_field(@registration_course.id)
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
      @registration_course = RegistrationCourse.find(params[:registration_course_id].to_i)
      field_index = params[:field_index].to_i
      field_order = params[:field_order].to_i
      addl_fields = StudentAdditionalField.find_all_by_id(field_ids)
      field_ids.each do |f|
        ApplicantStudentAddlField.create(:student_additional_field_id=>f.to_i,:section_name=>section_name,:applicant_addl_field_group_id=>field_group_id,:registration_course_id=>@registration_course.id)
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
  
  # DELETE /registration_courses/1
  # DELETE /registration_courses/1.xml
  def destroy
    @registration_course = RegistrationCourse.find(params[:id])
    if @registration_course.destroy
      flash[:notice] = t('deleted_successfully')
    else
      flash[:notice] = @registration_course.errors.full_messages.join('. ')
    end
    redirect_to applicants_admin_path
  end

  def toggle
    @registration_course = RegistrationCourse.find(params[:id])
    @registration_course.update_attributes(:is_active=>!@registration_course.is_active)
    redirect_to(:action=>"index")
  end

  def amount_load
    render :update do |page|
      settings = params[:settings]
      if settings == "0"
        page.replace_html "amount",:partial => "amount"
      elsif settings == "1" or settings.blank?
        page.replace_html "amount",:text => ""
      end
    end
  end

  def settings_load
    render :update do |page|
      settings = params[:settings]
      if settings == "1"
        page.replace_html "extra_settings",:partial => "extra_settings"
      elsif settings == "0" or settings.blank?
        page.replace_html "extra_settings",:text => ""
      end
    end
  end

  def populate_additional_field_list
    @additional_fields = StudentAdditionalField.active.sort_by(&:priority)
    render :update do |page|
      if params[:settings] == "1"
        page.replace_html "additional_fields",:partial => "student_additional_fields"
      else
        page.replace_html "additional_fields",:text => ""
      end
    end
  end
end
