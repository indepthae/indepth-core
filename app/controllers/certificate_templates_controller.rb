class CertificateTemplatesController < ApplicationController
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


  def certificate_templates
    @student_templates = CertificateTemplate.student_templates.all(:include=>[:generated_certificates,:bulk_generated_certificates])
    @employee_templates = CertificateTemplate.employee_templates.all(:include=>[:generated_certificates,:bulk_generated_certificates])
  end


  def settings
  end


  def new_certificate_template
    @certificate_template = CertificateTemplate.new
    @certificate_template.build_base_template
    @certificate_template.base_template.build_barcode_property
    @certificate_template.manual_serial_no = false
    @template_resolutions = CertificateTemplate::TEMPLATE_RESOLUTIONS
    @barcode_orientaions = BarcodeProperty::ORIENTAIONS
    @linked_to_keys = BarcodeProperty.linked_to_keys(1)
  end


  def save_certificate_template
    @certificate_template = CertificateTemplate.new(params[:certificate_template])
    if @certificate_template.save
      flash[:notice] = t("certificate_template_saved")
      render :update do |page|
        page.redirect_to certificate_templates_certificate_templates_path
      end
    else
      @errors = @certificate_template.errors.full_messages
      render :update do |page|
        page.replace_html "error_messages", :partial => "error_messages"
      end
    end
  end


  def edit_certificate_template
    @certificate_template = CertificateTemplate.find(params[:id])
    @template_resolutions = CertificateTemplate::TEMPLATE_RESOLUTIONS
    if !@certificate_template.base_template.barcode_property.present?
      @certificate_template.base_template.build_barcode_property
    end
    @barcode_orientaions = BarcodeProperty::ORIENTAIONS
    @linked_to_keys = BarcodeProperty.linked_to_keys(@certificate_template.user_type)
  end


  def update_certificate_template
    @certificate_template = CertificateTemplate.find(params[:id])
    @certificate_template.attributes = params[:certificate_template]
    if @certificate_template.save
      flash[:notice] = t("certificate_template_updated")
      render :update do |page|
        page.redirect_to certificate_templates_certificate_templates_path
      end
    else
      @errors = @certificate_template.errors.full_messages
      render :update do |page|
        page.replace_html "error_messages", :partial => "error_messages"
      end
    end
  end


  def delete_certificate_template
    @certificate_template = CertificateTemplate.find(params[:id])
    if @certificate_template.destroy
      flash[:notice] = t("certificate_template_deleted")
    end
    redirect_to  certificate_templates_certificate_templates_path
  end


  def certificate_keys
    type = params[:type].to_i
    @keys = {}
    if type == 1
      @keys = CertificateTemplate.get_student_keys
    elsif type == 2
      @keys = CertificateTemplate.get_employee_keys
    else
    end
    #add common keys
    @keys = @keys.merge(CertificateTemplate.get_common_keys)
    
    @keys=@keys.sort_by{|key,val| val.downcase}
    render :update do |page|
      page.replace_html "certificate_keys", :partial => "certificate_keys"
    end
  end


  def download_image
    file=CertificateTemplate.find(params[:id])
    if params[:style].to_s=="thumb"
      send_file file.background_image.path(:thumb), :type => file.background_image_content_type, :disposition => 'inline'
    else
      send_file file.background_image.path, :type => file.background_image_content_type, :disposition => 'inline'
    end
  end


  def generate_certificate
    @certificate_templates = CertificateTemplate.all
    @academic_years = AcademicYear.all
  end


  def certificate_template_for_generation
    @certificate_template = CertificateTemplate.find params[:certificate_template]
    @base_template = @certificate_template.base_template
    @base_template_data = @base_template.get_binding_ready_template
    @template_resolution = @certificate_template.template_resolution
    @get_next_serial_no = GeneratedCertificate.get_next_serial_no(@certificate_template)
    @prefix = @certificate_template.serial_no_prefix
    @keys = @base_template.template_data.scan(/\{\{(.*?)\}\}/)
    render :update do |page|
      page.replace_html "preview", :partial => "certificate_template_for_generation"
    end
  end


  def load_certificate_key_form
    @certificate_template = CertificateTemplate.find(params[:certificate_template_id],:include=>[:template_custom_fields, :base_template])
    @keys = @certificate_template.base_template.get_included_template_keys
    @custom_fields = @certificate_template.template_custom_fields
    render :update do |page|
      page.replace_html "certificate_key_form", :partial => "certificate_key_form"
    end
  end


  def save_generated_certificate
    @certificate_template = CertificateTemplate.find(params[:certificate_template_id])
    @prefix = @certificate_template.serial_no_prefix.to_s
    if @certificate_template.manual_serial_no == true
      full_serial_no = params[:serial_no].to_s
      auto_serial_no = nil
    else
      full_serial_no = "#{@prefix}#{params[:serial_no]}"
      auto_serial_no = params[:serial_no].to_i
    end
    @generated_certificate = GeneratedCertificate.new(:certificate_html=>params[:certificate_html],
       :certificate_template_id=>@certificate_template.id, :issued_for_id=>params[:user_id].to_i, :issued_for_type=>@certificate_template.template_for,:serial_no=>auto_serial_no, :manual_serial_no => full_serial_no)
    #generate pdf and save
    imports = ""
    imports = imports + ' <link href="https://fonts.googleapis.com/css?family=Courgette|Lato|Lora|Playball" rel="stylesheet"> '
    imports = imports + " <link rel='stylesheet' type='text/css' href='#{Rails.root}/public/stylesheets/pdf_normalize.css' > "
    if rtl?
      imports = imports + " <link rel='stylesheet' type='text/css' href='#{Rails.root}/public/rtl/stylesheets/certificate_templates/generate_certificate_pdf.css' > "
    else 
      imports = imports + " <link rel='stylesheet' type='text/css' href='#{Rails.root}/public/stylesheets/certificate_templates/generate_certificate_pdf.css' > "
    end
    if @certificate_template.background_image.present? 
      img_url = FedenaSetting.s3_enabled? ? @certificate_template.background_image.url(:original,false) : File.join(RAILS_ROOT,@certificate_template.background_image.path) 
      imports = imports + "<style type='text/css'>
      #preview{
      background-image: url('"+img_url+"') !important;
      box-sizing: border-box;
      background-size: cover;
      line-height: 1.5;     
    }
    </style>"
  end
    generated_pdf = @generated_certificate.build_generated_pdf
    certificate_content = GeneratedCertificate.convert_to_full_path(params[:certificate_html])
    generated_pdf.set_pdf_content(imports+certificate_content,"certificate",{:page_height=>  @certificate_template.template_resolution[:height] ,:page_width=> @certificate_template.template_resolution[:width]}) 
    
    if @generated_certificate.save
      @next_serial_no = GeneratedCertificate.get_next_serial_no(@certificate_template)
      render :update do |page|
        page.redirect_to list_generated_certificates_certificate_templates_path(:certificate_template_id=>@certificate_template.id, :currently_created_single=> @generated_certificate.id)
      end
    else
      @errors = @generated_certificate.errors.full_messages
      render :update do |page|
        page.replace_html "error_messages", :partial => "error_messages"
      end
    end
  end
  
  
  def delete_generated_certificate
    @generated_certificate = GeneratedCertificate.find(params[:id])
    if @generated_certificate.destroy 
      redirect_to list_generated_certificates_certificate_templates_path(:page1=>params[:page], :certificate_template_id=> @generated_certificate.certificate_template_id)
    end
  end


  def generated_certificates
    @student_templates = CertificateTemplate.student_templates
    @employee_templates = CertificateTemplate.employee_templates
    @parent_templates = CertificateTemplate.parent_templates
  end


  def generate_certificate_pdf
    @generated_certificate = GeneratedCertificate.find(params[:id])
    #provide certificate as pdf
    render :pdf=>"certificate_templates/generate_certificate_pdf",:margin=>{:left=>0,:right=>0,:top=>0,:bottom=>0},:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
  end


  def list_generated_certificates
    @per_page = 15
    @academic_years = AcademicYear.all
    @certificate_template = CertificateTemplate.find(params[:certificate_template_id])
    @prefix = @certificate_template.serial_no_prefix
    @generated_certificates = @certificate_template.generated_certificates.individually_generated_certificates.paginate(:per_page=>@per_page,:page=>params[:page1],:include=>[:issued_for,:generated_pdf], :order=>"id desc")
    @bulk_generated_certificates = @certificate_template.bulk_generated_certificates.paginate(:per_page=>@per_page,:page=>params[:page2], :order=>"id desc", :include=>[:generated_pdf])
  end


  def generated_certificates_list
    @per_page = 15
    @certificate_template = CertificateTemplate.find(params[:certificate_template_id])
    if params[:academic_year_id].present?
      @academic_year = AcademicYear.find(params[:academic_year_id])
      @generated_certificates = @certificate_template.generated_certificates.individually_generated_certificates.all.paginate(:joins=>[:batch], :conditions=>["batches.academic_year_id= ? ",@academic_year.id],
         :per_page=>@per_page,:page=>params[:page], :include=>[:issued_for, :generated_pdf], :order=>"id desc")
    else
      @generated_certificates = @certificate_template.generated_certificates.individually_generated_certificates.all.paginate(:per_page=>@per_page,:page=>params[:page],:include=>[:issued_for, :generated_pdf], :order=>"id desc")
    end
    render :update do |page|
      page.replace_html "generated_certificates_list", :partial => "generated_certificates_list"
    end
  end
  
  
  def bulk_generated_certificates_list
    @per_page = 15
    @certificate_template = CertificateTemplate.find(params[:certificate_template_id])
    if params[:academic_year_id].present?
      @academic_year = AcademicYear.find(params[:academic_year_id])
      @bulk_generated_certificates = @certificate_template.bulk_generated_certificates.paginate(:conditions=>["academic_year_id= ? ",@academic_year.id],
         :per_page=>@per_page,:page=>params[:page], :order=>"id desc", :include=>[:generated_pdf])
    else
      @bulk_generated_certificates = @certificate_template.bulk_generated_certificates.paginate(:per_page=>@per_page,:page=>params[:page], :order=>"id desc", :include=>[:generated_pdf])
    end
    render :update do |page|
      page.replace_html "bulk_generated_certificates_list", :partial => "bulk_generated_certificates_list"
    end
  end


  def bulk_export
    @certificate_templates = CertificateTemplate.bulk_exportable
  end


  def bulk_export_group_selector
    #NOTE -- Partial changes the form action for generation based on user type
    @certificate_template = CertificateTemplate.find(params[:certificate_template_id])
    type = @certificate_template.user_type
    if type == 1
      @courses = Course.all(:order=>"course_name", :conditions=>["is_deleted=false"])
      render :update do |page|
        page.replace_html "selector", :partial => "course_selector"
        page.replace_html "certificate_for", ""
      end
    elsif type == 2
      @departments = EmployeeDepartment.all(:order=>"name")
      render :update do |page|
        page.replace_html "selector", :partial => "department_selector"
        page.replace_html "certificate_for", ""
      end
    else
    end

  end
  
  
  def batch_selector
    @course = Course.find(params[:course_id])
    @batches = @course.batches.all(:include=>[:course], :conditions=>["is_deleted=false"])
    render :update do |page|
      page.replace_html "batch_selector", :partial => "batch_selector"
      page.replace_html "certificate_for", ""
    end
  end


  def batch_students
    @batch = Batch.find(params["batch_id"])
    @students = @batch.effective_students_for_certificate(:active_check=>false).sort{|a,b| a.full_name.downcase <=> b.full_name.downcase}
    render :update do |page|
      page.replace_html "certificate_for", :partial => "batch_students"
    end
  end


  def department_employees
    @department = EmployeeDepartment.find(params["department_id"])
    @employees = @department.employees.all(:order=>"first_name, middle_name, last_name")
    render :update do |page|
      page.replace_html "certificate_for", :partial => "department_employees"
    end
  end


  def generate_bulk_export_pdf_student
    student_ids = []
    archived_student_ids =[]
    @certificate_template = CertificateTemplate.find(params[:certificate_template])
    @base_template = @certificate_template.base_template
    @base_template_data = @base_template.get_pdf_html
    @template_resolution = @certificate_template.template_resolution
    @keys = @base_template.get_included_template_keys
    params[:student].each do |key, val|
      student_ids = student_ids << key.to_i  if val.to_i == 1 && params[:type][key] == "Student"
      archived_student_ids = archived_student_ids << key.to_i  if val.to_i == 1 && params[:type][key] == "ArchivedStudent" 
    end
    
    #serial no
    @next_serial_no = GeneratedCertificate.get_next_serial_no(@certificate_template)
    @prefix = @certificate_template.serial_no_prefix
    
    @students = Student.all(:conditions=>["id in (?)", student_ids])
    @archived_students = Student.find_by_sql(["SELECT *, former_id AS id, 'archived' AS current_type FROM archived_students where former_id in (?) ",archived_student_ids])
    @students = @students + @archived_students
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
    @certificate_template = CertificateTemplate.find(params[:certificate_template])
    @base_template = @certificate_template.base_template
    @base_template_data = @base_template.get_pdf_html
    @template_resolution = @certificate_template.template_resolution
    @keys = @base_template.get_included_template_keys
    params[:employee].each do |key, val|
      employee_ids = employee_ids << key.to_i  if val.to_i == 1 
    end
    
    #serial no
    @next_serial_no = GeneratedCertificate.get_next_serial_no(@certificate_template)
    @prefix = @certificate_template.serial_no_prefix

    @employees = Employee.all(:conditions=>["id in (?)", employee_ids])
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
  
  
  def generate_bulk_export_sample_preview
    @certificate_template = CertificateTemplate.find(params[:certificate_template_id])
    @key_names =  @certificate_template.get_key_names
    @base_template = @certificate_template.base_template
    @base_template_data = @base_template.get_binding_ready_template
    @template_resolution = @certificate_template.template_resolution
    @keys = @base_template.get_included_template_keys
    render :update do |page|
      page.replace_html "preview", :partial => "generate_bulk_export_sample_preview"
    end
  end
  
  
  def save_bulk_generated_certificate
    @certificate_template = CertificateTemplate.find(params[:certificate_template_id])
    @certificate_template.allow_edit = true
    if params[:batch_id].present? && params[:batch_id] != "false"
      @batch = Batch.find(params[:batch_id])
      @academic_year_id = @batch.academic_year.id
    else
      @academic_year_id = nil
    end
    bulk_generated_certificate = @certificate_template.bulk_generated_certificates.build(:academic_year_id=>@academic_year_id, :issued_on => Date.today)
    
    @prefix = @certificate_template.serial_no_prefix
    #build individual generated_certificate
    params[:pdf_html].each_with_index do |single_certificate_html,index|
      auto_serial_no = params[:serial_nos][index].to_i
      full_serial_no = "#{@prefix}#{auto_serial_no}"
      bulk_generated_certificate.generated_certificates.build(:certificate_html=>single_certificate_html, :issued_for_id=>params[:issued_for_ids][index].to_i, :issued_for_type=> @certificate_template.template_for,
        :issued_on=>Date.today,:manual_serial_no=>full_serial_no, :serial_no=>auto_serial_no, :certificate_template_id=> @certificate_template.id )
    end
    #generate pdf and save
    imports = ""
    imports = imports + ' <link href="https://fonts.googleapis.com/css?family=Courgette|Lato|Lora|Playball" rel="stylesheet"> '
    imports = imports + " <link rel='stylesheet' type='text/css' href='#{Rails.root}/public/stylesheets/pdf_normalize.css' > "
    if rtl?
      imports = imports + " <link rel='stylesheet' type='text/css' href='#{Rails.root}/public/rtl/stylesheets/certificate_templates/generate_bulk_export_pdf.css' > "
    else 
      imports = imports + " <link rel='stylesheet' type='text/css' href='#{Rails.root}/public/stylesheets/certificate_templates/generate_bulk_export_pdf.css' > "
    end
    content = params[:pdf_html].join(' ')
    content = GeneratedCertificate.webkit_support_for_html(content)    
    generated_pdf = bulk_generated_certificate.build_generated_pdf
    generated_pdf.set_pdf_content(imports+(content) ,"bulk_certificate",{:page_height=>  @certificate_template.template_resolution[:height] ,:page_width=> @certificate_template.template_resolution[:width]})
    if @certificate_template.save
      render :update do |page|
        page.redirect_to list_generated_certificates_certificate_templates_path(:certificate_template_id=>@certificate_template.id, :currently_created=> bulk_generated_certificate.id)
      end
    else 
      @errors = @certificate_template.errors.full_messages
      render :update do |page|
        page.replace_html "error_messages", :partial => "error_messages"
      end
    end   
  end
  
  
  def delete_bulk_generated_certificate
    @bulk_generated_certificate = BulkGeneratedCertificate.find(params[:id])
    if @bulk_generated_certificate.destroy 
      redirect_to list_generated_certificates_certificate_templates_path(:page2=>params[:page], :certificate_template_id=> @bulk_generated_certificate.certificate_template_id)
    end
  end
  
  
  def generate_bulk_export_pdf
    @bulk_generated_certificate = BulkGeneratedCertificate.find(params[:bulk_generated_certificate_id], :include=>[:generated_certificates])
    render :pdf=>"certificate_templates/generate_bulk_export_pdf",:margin=>{:left=>0,:right=>0,:top=>0,:bottom=>0}, :show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
  end
  
end
