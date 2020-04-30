class IdCardTemplatesController < ApplicationController
  filter_access_to :all

  def rtl?
    if session[:language].nil?
      lan = Configuration.find_by_config_key("Locale").config_value
      lan = "en" unless lan.present?
    else
      lan=session[:language]
    end
    if controller and is_cce_controller?
      return false
    else
      @rtl ||= RTL_LANGUAGES.include? lan.to_sym
    end
  end

  def index
  end


  def id_card_templates
    @student_templates = IdCardTemplate.student_templates.all(:include=>[:generated_id_cards,:bulk_generated_id_cards])
    @employee_templates = IdCardTemplate.employee_templates.all(:include=>[:generated_id_cards,:bulk_generated_id_cards])
    @parent_templates = IdCardTemplate.parent_templates.all(:include=>[:generated_id_cards,:bulk_generated_id_cards])
  end


  def settings
  end


  def new_id_card_template
    @id_card_template = IdCardTemplate.new
    @id_card_template.build_front_template
    @id_card_template.front_template.build_barcode_property
    @id_card_template.build_back_template
    @template_resolutions = IdCardTemplate::TEMPLATE_RESOLUTIONS
    @barcode_orientaions = BarcodeProperty::ORIENTAIONS
    @linked_to_keys = BarcodeProperty.linked_to_keys(1)
  end


  def save_id_card_template
    @id_card_template = IdCardTemplate.new(params[:id_card_template])
    if @id_card_template.save
      flash[:notice] = t("id_card_template_saved")
      render :update do |page|
        page.redirect_to id_card_templates_id_card_templates_path
      end
    else
      @errors = @id_card_template.errors.full_messages
      render :update do |page|
        page.replace_html "error_messages", :partial => "error_messages"
      end
    end
  end


  def edit_id_card_template
    @id_card_template = IdCardTemplate.find(params[:id])
    if !@id_card_template.front_template.barcode_property.present?
      @id_card_template.front_template.build_barcode_property
    end
    @template_resolutions = IdCardTemplate::TEMPLATE_RESOLUTIONS
    @barcode_orientaions = BarcodeProperty::ORIENTAIONS
    @linked_to_keys = BarcodeProperty.linked_to_keys(@id_card_template.user_type)
  end


  def update_id_card_template
    @id_card_template = IdCardTemplate.find(params[:id])
    @id_card_template.attributes = params[:id_card_template]
    if @id_card_template.save
      flash[:notice] = t("id_card_template_updated")
      render :update do |page|
        page.redirect_to id_card_templates_id_card_templates_path
      end
    else
      @errors = @id_card_template.errors.full_messages
      render :update do |page|
        page.replace_html "error_messages", :partial => "error_messages"
      end
    end
  end


  def delete_id_card_template
    @id_card_template = IdCardTemplate.find(params[:id])
    if @id_card_template.destroy
      flash[:notice] = t("id_card_template_deleted")
    end
    redirect_to  id_card_templates_id_card_templates_path
  end


  def id_card_keys
    type = params[:type].to_i
    @keys = {}
    if type == 1
      @keys = IdCardTemplate.get_student_keys
    elsif type == 2
      @keys =  IdCardTemplate.get_employee_keys
    elsif type == 3
      @keys = IdCardTemplate.get_guardian_keys
    else
    end
    #add common keys
    @keys = @keys.merge(IdCardTemplate.get_common_keys)
    @keys=@keys.sort_by{|key,val| val.downcase}
    render :update do |page|
      page.replace_html "id_card_keys_front", :partial => "id_card_keys"
      page.replace_html "id_card_keys_back", :partial => "id_card_keys"
    end
  end


  def download_image
    template=IdCardTemplate.find(params[:id])
    if params[:side]=="back"
      image = template.back_background_image
      type = template.back_background_image_content_type
    else
      image = template.front_background_image
      type = template.front_background_image_content_type
    end

    if params[:style].to_s=="thumb"
      send_file image.path(:thumb), :type => type, :disposition => 'inline'
    else
      send_file image.path, :type => type, :disposition => 'inline'
    end
  end


  def generate_id_card
    @id_card_templates = IdCardTemplate.all
    @academic_years = AcademicYear.all
  end


  def load_id_card_key_form
    @id_card_template = IdCardTemplate.find(params[:id_card_template_id],:include=>[:template_custom_fields, :front_template,:back_template])
    @keys = @id_card_template.get_templpate_keys
    @custom_fields = @id_card_template.template_custom_fields
    render :update do |page|
      page.replace_html "id_card_key_form", :partial => "id_card_key_form"
    end
  end


  def id_card_template_for_generation
    @id_card_template = IdCardTemplate.find params[:id_card_template]
    @back_included = !(@id_card_template.include_back =="no")
    @front_template = @id_card_template.front_template
    @front_template_data = @front_template.get_binding_ready_template
    @back_template = @id_card_template.back_template
    @back_template_data = @back_template.get_binding_ready_template
    @keys = @front_template.template_data.scan(/\{\{(.*?)\}\}/)
    @keys = @keys + @back_template.template_data.scan(/\{\{(.*?)\}\}/)
    @template_resolution = @id_card_template.template_resolution
    render :update do |page|
      page.replace_html "layouts", :partial => "id_card_template_for_generation"
    end
  end


  def save_generated_id_card
    @id_card_template = IdCardTemplate.find(params[:id_card_template_id])
    @single_page_enabled = params[:single_page_enabled]
    @generated_id_card = GeneratedIdCard.new(:id_card_html_front=>params[:id_card_html_front].to_s,:id_card_html_back=>params[:id_card_html_back].to_s,
      :id_card_template_id=>@id_card_template.id, :issued_for_id=>params[:user_id].to_i, :issued_for_type=>@id_card_template.template_for)

    pdf_content = GeneratedIdCard.build_single_generated_pdf(params[:id_card_html_front].to_s, params[:id_card_html_back].to_s)
    pdf_content = GeneratedIdCard.convert_to_full_path(pdf_content)

    #generate pdf and save
    imports = ""
    imports = imports + ' <link href="https://fonts.googleapis.com/css?family=Courgette|Lato|Lora|Playball" rel="stylesheet"> '
    imports = imports + " <link rel='stylesheet' type='text/css' href='#{Rails.root}/public/stylesheets/pdf_normalize.css' > "

    if @id_card_template.front_background_image.present?
      front_img_url = FedenaSetting.s3_enabled? ? @generated_id_card.id_card_template.front_background_image.url(:original,false) : File.join(RAILS_ROOT,@id_card_template.front_background_image.path)
      imports = imports + "<style type='text/css'>#front_preview{background-image: url('"+front_img_url+"') !important;}</style>"
    end
    if @id_card_template.back_background_image.present?
      back_img_url = FedenaSetting.s3_enabled? ? @generated_id_card.id_card_template.back_background_image.url(:original,false) : File.join(RAILS_ROOT,@id_card_template.back_background_image.path)
      imports = imports + "<style type='text/css'>#back_preview{background-image: url('"+back_img_url+"') !important;}</style>"
    end

    a4_imports = imports + GeneratedIdCard.get_a4_style(rtl?,"single")
    card_size_imports = imports + GeneratedIdCard.get_card_size_style(rtl?,"single")

    generated_pdf_a4 = @generated_id_card.generated_pdfs.build
    generated_pdf_a4.set_pdf_content(a4_imports + pdf_content ,"id_card")
    generated_pdf_a4.style = "a4"

    generated_pdf_card_size = @generated_id_card.generated_pdfs.build
    generated_pdf_card_size.set_pdf_content(card_size_imports + pdf_content ,"id_card", {:disable_smart_shrinking=>true, :page_height=>  @id_card_template.template_resolution[:height]*3 ,:page_width=> @id_card_template.template_resolution[:width]*3})
    generated_pdf_card_size.style = "card_size"

    if @generated_id_card.save
      render :update do |page|
        page.redirect_to list_generated_id_cards_id_card_templates_path(:id_card_template_id=>@id_card_template.id, :currently_created_single=> @generated_id_card.id)
      end
    else
      @errors = @generated_id_card.errors.full_messages
      render :update do |page|
        page.replace_html "error_messages", :partial => "error_messages"
      end
    end
  end


  def delete_generated_id_card
    @generated_id_card = GeneratedIdCard.find(params[:id])
    if @generated_id_card.destroy
      redirect_to list_generated_id_cards_id_card_templates_path(:page1=>params[:page], :id_card_template_id=> @generated_id_card.id_card_template_id)
    end
  end


  def generate_id_card_pdf
    @generated_id_card = GeneratedIdCard.find(params[:id])
    @id_card_template = @generated_id_card.id_card_template
    @single_page_enabled = false
    @single_page_enabled = true if params[:single_page_enabled]=="true"
    #provide id_card as pdf
    if @single_page_enabled
      render :pdf=>"id_card_templates/generate_id_card_pdf",:disable_smart_shrinking =>true,:page_width=> @id_card_template.template_resolution[:width]*3, :page_height=> @id_card_template.template_resolution[:height]*3, :margin=>{:left=>0,:right=>0,:top=>0,:bottom=>0},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
    else
      render :pdf=>"id_card_templates/generate_id_card_pdf",:margin=>{:left=>0,:right=>0,:top=>0,:bottom=>0},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
    end
  end


  def generated_id_cards
    @student_templates = IdCardTemplate.student_templates
    @employee_templates = IdCardTemplate.employee_templates
    @parent_templates = IdCardTemplate.parent_templates
  end


  def list_generated_id_cards
    @per_page = 15
    @academic_years = AcademicYear.all
    @id_card_template = IdCardTemplate.find(params[:id_card_template_id])
    @generated_id_cards = @id_card_template.generated_id_cards.paginate(:per_page=>@per_page,:page=>params[:page1],:include=>[:issued_for, :generated_pdfs], :order=>"id desc")
    @bulk_generated_id_cards = @id_card_template.bulk_generated_id_cards.paginate(:per_page=>@per_page,:page=>params[:page2], :order=>"id desc", :include=>[:generated_pdfs])
  end


  def generated_id_cards_list
    @per_page = 15
    @id_card_template = IdCardTemplate.find(params[:id_card_template_id])
    if params[:academic_year_id].present?
      @academic_year = AcademicYear.find(params[:academic_year_id])
      @generated_id_cards = @id_card_template.generated_id_cards.paginate(:joins=>[:batch], :conditions=>["batches.academic_year_id= ? ",@academic_year.id],
         :per_page=>@per_page,:page=>params[:page], :include=>[:issued_for,:generated_pdfs], :order=>"id desc")
    else
      @generated_id_cards = @id_card_template.generated_id_cards.paginate(:per_page=>@per_page,:page=>params[:page],:include=>[:issued_for,:generated_pdfs], :order=>"id desc")
    end
    render :update do |page|
      page.replace_html "generated_id_cards_list", :partial => "generated_id_cards_list"
    end
  end


  def bulk_generated_id_cards_list
    @per_page = 15
    @id_card_template = IdCardTemplate.find(params[:id_card_template_id])
    if params[:academic_year_id].present?
      @academic_year = AcademicYear.find(params[:academic_year_id])
      @bulk_generated_id_cards = @id_card_template.bulk_generated_id_cards.paginate(:conditions=>["academic_year_id= ? ",@academic_year.id],
         :per_page=>@per_page,:page=>params[:page], :order=>"id desc", :include=>[:generated_pdfs])
    else
      @bulk_generated_id_cards = @id_card_template.bulk_generated_id_cards.paginate(:per_page=>@per_page,:page=>params[:page], :order=>"id desc", :include=>[:generated_pdfs])
    end
    render :update do |page|
      page.replace_html "bulk_generated_id_cards_list", :partial => "bulk_generated_id_cards_list"
    end
  end


  def bulk_export
    @academic_years = AcademicYear.all
    @id_card_templates = IdCardTemplate.without_custom_fields
  end


  def bulk_export_group_selector
    #NOTE -- Partial changes the form action for generation based on user type
    @id_card_template = IdCardTemplate.find(params[:id_card_template_id])
    type = @id_card_template.user_type
    if type == 1
      @courses = Course.all(:order=>"course_name", :conditions=>["is_deleted=false"])
      render :update do |page|
        page.replace_html "selector", :partial => "course_selector"
        page.replace_html "id_card_for", ""
      end
    elsif type == 2
      @departments = EmployeeDepartment.all(:order=>"name")
      render :update do |page|
        page.replace_html "selector", :partial => "department_selector"
        page.replace_html "id_card_for", ""
      end
    elsif type == 3
      @courses = Course.all(:order=>"course_name", :conditions=>["is_deleted=false"])
      render :update do |page|
        page.replace_html "selector", :partial => "course_selector_for_parent"
        page.replace_html "id_card_for", ""
      end
    else
    end

  end


  def batch_selector
    @course = Course.find(params[:course_id])
    @batches = @course.batches.all(:include=>[:course], :conditions=>["is_deleted=false"])
    render :update do |page|
      page.replace_html "batch_selector", :partial => "batch_selector"
      page.replace_html "id_card_for", ""
    end
  end


  def batch_students
    @batch = Batch.find(params["batch_id"])
    @students = @batch.effective_students_for_certificate(:active_check=>false).sort{|a,b| a.full_name.downcase <=> b.full_name.downcase}
    render :update do |page|
      page.replace_html "id_card_for", :partial => "batch_students"
    end
  end


  def department_employees
    @department = EmployeeDepartment.find(params["department_id"])
    @employees = @department.employees.all(:order=>"first_name, middle_name, last_name")
    render :update do |page|
      page.replace_html "id_card_for", :partial => "department_employees"
    end
  end


  def generate_bulk_export_pdf_student
    student_ids = []
    archived_student_ids =[]
    @id_card_template = IdCardTemplate.find(params[:id_card_template])
    @single_page_enabled = false
    @single_page_enabled = true if params[:single_page_enabled]=="true"

    # front
    @front_template = @id_card_template.front_template
    @front_template_data = @front_template.get_pdf_html
    #back
    @back_template = @id_card_template.back_template
    @back_template_data = @back_template.get_pdf_html
    @template_resolution = @id_card_template.template_resolution
    @keys = @front_template.get_included_template_keys
    @keys = @keys.merge(@back_template.get_included_template_keys)
    params[:student].each do |key, val|
      student_ids = student_ids << key.to_i  if val.to_i == 1 && params[:type][key] == "Student"
      archived_student_ids = archived_student_ids << key.to_i  if val.to_i == 1 && params[:type][key] == "ArchivedStudent"
    end

    @students = Student.all(:conditions=>["id in (?)", student_ids], :include=>[{:student_additional_details=>:student_additional_field}])
    @archived_students = Student.find_by_sql(["SELECT *, former_id AS id, 'archived' AS current_type FROM archived_students where former_id in (?) ",archived_student_ids])
    @students = @students + @archived_students
    @total_back_count = @id_card_template.total_back_id_card_nos(@students.count)
    if @students.present?
    render :update do |page|
      page.replace_html "hidden_generation", :partial => "generate_bulk_export_pdf_student"
    end
    else
      @errors = [t('student_was_deleted')]
      render :update do |page|
        page.replace_html "error_messages", :partial => "error_messages"
      end
    end
  end


  def generate_bulk_export_pdf_employee
    employee_ids = []
    @single_page_enabled = false
    @single_page_enabled = true if params[:single_page_enabled]=="true"
    @id_card_template = IdCardTemplate.find(params[:id_card_template])
    @front_template = @id_card_template.front_template
    @front_template_data = @front_template.get_pdf_html
    #back
    @back_template = @id_card_template.back_template
    @back_template_data = @back_template.get_pdf_html
    @template_resolution = @id_card_template.template_resolution
    @keys = @front_template.get_included_template_keys
    @keys = @keys.merge(@back_template.get_included_template_keys)
    params[:employee].each do |key, val|
      employee_ids = employee_ids << key.to_i  if val.to_i == 1
    end

    @employees = Employee.all(:conditions=>["id in (?)", employee_ids])
    @total_back_count = @id_card_template.total_back_id_card_nos(@employees.count)
    if @employees.present?
    render :update do |page|
      page.replace_html "hidden_generation", :partial => "generate_bulk_export_pdf_employee"
    end
    else
      @errors = [t('employee_was_deleted')]
      render :update do |page|
        page.replace_html "error_messages", :partial => "error_messages"
      end
    end
  end


  def generate_bulk_export_pdf_guardian
    student_ids = []
    archived_student_ids =[]
    @single_page_enabled = false
    @single_page_enabled = true if params[:single_page_enabled]=="true"
    @id_card_template = IdCardTemplate.find(params[:id_card_template])
    # front
    @front_template = @id_card_template.front_template
    @front_template_data = @front_template.get_pdf_html
    #back
    @back_template = @id_card_template.back_template
    @back_template_data = @back_template.get_pdf_html
    @template_resolution = @id_card_template.template_resolution
    @keys = @front_template.get_included_template_keys
    @keys = @keys.merge(@back_template.get_included_template_keys)
    params[:student].each do |key, val|
      student_ids = student_ids << key.to_i  if val.to_i == 1 && params[:type][key] == "Student"
      archived_student_ids = archived_student_ids << key.to_i  if val.to_i == 1 && params[:type][key] == "ArchivedStudent"
    end
    #students with immediate_contact
    @students = Student.all(:conditions=>["id in (?) and immediate_contact_id IS NOT NULL", student_ids], :include=>[:immediate_contact])
    @archived_students = ArchivedStudent.all(:conditions=>["former_id in (?) and immediate_contact_id IS NOT NULL", archived_student_ids])
    archived_guardian_ids = @archived_students.collect(&:immediate_contact_id).compact
    @archived_guardians =  Guardian.find_by_sql(["SELECT *, former_id AS id FROM archived_guardians where former_id in (?) ",archived_guardian_ids])
    @all_students = @students + @archived_students
    @guardians = @students.compact.collect(&:immediate_contact)
    @guardians = @guardians + @archived_guardians
    @total_back_count = @id_card_template.total_back_id_card_nos(@guardians.count)
      render :update do |page|
        page.replace_html "hidden_generation", :partial => "generate_bulk_export_pdf_guardian"
      end
  end


  def generate_bulk_export_sample_preview
    @id_card_template = IdCardTemplate.find(params[:id_card_template_id],:include=>[:front_template,:back_template])
    @key_names =  @id_card_template.get_key_names
    @back_included = !(@id_card_template.include_back =="no")
    @front_template = @id_card_template.front_template
    @front_template_data = @front_template.get_binding_ready_template
    @back_template = @id_card_template.back_template
    @back_template_data = @back_template.get_binding_ready_template
    @template_resolution = @id_card_template.template_resolution
    @keys = @id_card_template.get_included_template_keys
    render :update do |page|
      page.replace_html "layouts", :partial => "generate_bulk_export_sample_preview"
    end
  end


  def save_bulk_generated_id_card
    @id_card_template = IdCardTemplate.find(params[:id_card_template_id])
    @id_card_template.allow_edit = true
    @single_page_enabled = params[:single_page_enabled]=="true" ?  true : false
    if params[:batch_id].present? && params[:batch_id] != "false"
      @batch = Batch.find(params[:batch_id])
      @academic_year_id = @batch.academic_year.id
    else
      @academic_year_id = nil
    end
    bulk_generated_id_card = @id_card_template.bulk_generated_id_cards.build(:academic_year_id=>@academic_year_id, :issued_on => Date.today, :pdf_content=>params[:pdf_html])
    content = GeneratedIdCard.webkit_support_for_html(params[:pdf_html])
    #generate pdf and save
    imports = ""
    imports = imports + ' <link href="https://fonts.googleapis.com/css?family=Courgette|Lato|Lora|Playball" rel="stylesheet"> '
    imports = imports + " <link rel='stylesheet' type='text/css' href='#{Rails.root}/public/stylesheets/pdf_normalize.css' > "

    a4_imports = imports + GeneratedIdCard.get_a4_style(rtl?,"bulk")
    card_size_imports = imports + GeneratedIdCard.get_card_size_style(rtl?,"bulk")

    generated_pdf_a4 = bulk_generated_id_card.generated_pdfs.build
    generated_pdf_a4.set_pdf_content(a4_imports + content ,"bulk_id_card", :margin => { :left=>0,:right=>0,:top=>4,:bottom=>0 })
    generated_pdf_a4.style = "a4"

    generated_pdf_card_size = bulk_generated_id_card.generated_pdfs.build
    generated_pdf_card_size.set_pdf_content(card_size_imports + content ,"bulk_id_card", {:disable_smart_shrinking=>true, :page_height=>  @id_card_template.template_resolution[:height]*3 ,:page_width=> @id_card_template.template_resolution[:width]*3, :margin => { :left=>0,:right=>0,:top=>0,:bottom=>0 }})
    generated_pdf_card_size.style = "card_size"

    if @id_card_template.save
      render :update do |page|
        page.redirect_to list_generated_id_cards_id_card_templates_path(:id_card_template_id=>@id_card_template.id, :currently_created=> bulk_generated_id_card.id)
      end
    else
      @errors = @id_card_template.errors.full_messages
      render :update do |page|
        page.replace_html "error_messages", :partial => "error_messages"
      end
    end
  end


  def delete_bulk_generated_id_card
    @bulk_generated_id_card = BulkGeneratedIdCard.find(params[:id])
    if @bulk_generated_id_card.destroy
      redirect_to list_generated_id_cards_id_card_templates_path(:page2=>params[:page], :id_card_template_id=> @bulk_generated_id_card.id_card_template_id)
    end
  end


  def generate_bulk_export_pdf
    @bulk_generated_id_card = BulkGeneratedIdCard.find(params[:bulk_generated_id_card_id], :include=>[:id_card_template])
    @id_card_template = @bulk_generated_id_card.id_card_template
    @single_page_enabled = params[:single_page_enabled]=="true" ?  true : false
    if @single_page_enabled
      render :pdf=>"id_card_templates/generate_bulk_export_pdf",:disable_smart_shrinking =>true,:page_width=> @id_card_template.template_resolution[:width]*3, :page_height=> @id_card_template.template_resolution[:height]*3, :margin=>{:left=>0,:right=>0,:top=>0,:bottom=>0},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
    else
      render :pdf=>"id_card_templates/generate_bulk_export_pdf",:margin=>{:left=>0,:right=>0,:top=>0,:bottom=>0},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
    end
  end


end
