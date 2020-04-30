class GeneratedCertificate < ActiveRecord::Base
  xss_terminate :except => [:certificate_html]
  belongs_to :issued_for, :polymorphic => true
  belongs_to :certificate_template
  belongs_to :batch
  has_one :generated_pdf, :as=> :corresponding_pdf, :dependent=>:destroy

  before_validation :set_issued_on
  before_validation :valid_issued_for

  validates_presence_of :certificate_html, :issued_for_id, :certificate_template_id, :issued_on, :manual_serial_no
  validates_uniqueness_of :manual_serial_no
  named_scope :individually_generated_certificates, :conditions => ["bulk_generated_certificate_id is null"]
  
  
  HUMANIZED_ATTRIBUTES = {
    :manual_serial_no => "#{t('serial_no')}"
  }

 def self.human_attribute_name(attr)
   HUMANIZED_ATTRIBUTES[attr.to_sym] || super
 end
  

  def set_issued_on
    self.issued_on = Date.today
  end


  def self.get_next_serial_no(certificate_template)
    return GeneratedCertificate.maximum('serial_no',:conditions=>["certificate_template_id = ?",certificate_template.id]).to_i+1
  end

  def get_serial_no
    certificate_template = self.certificate_template
    if certificate_template.manual_serial_no == false
      #get prefix
      prefix = certificate_template.serial_no_prefix
      return "#{prefix}#{self.serial_no}"
    else
      return "#{self.manual_serial_no}"
    end
  end

  def set_auto_set_serial_no
    certificate_template = self.certificate_template
    if certificate_template.manual_serial_no == false
      self.serial_no = self.get_next_serial_no
    end
  end

  def get_pdf_html
    if FedenaSetting.s3_enabled?
      html = self.certificate_html
      html = format_s3_urls(html)
      return html
    else
      html = self.certificate_html
      image_urls = html.scan(/<img.*?src=\"(.+?)\"/)
      image_urls.each do |url|
        url=url.first
        #redactor image
        r_id = url.scan(/redactor_uploads\/(\d+)\//)
        if r_id.present?
          path = RedactorUpload.find(r_id.first.first).image.path
          html =  html.gsub(url,File.join(RAILS_ROOT,path))
        end
        #check if student_photo
        s_id = url.scan(/students\/(\d+)\//)
        if s_id.present?
          student = Student.find_by_id(s_id.first.first)
          student = Student.find_by_sql(["SELECT *, former_id AS id FROM archived_students where former_id = ? ",s_id.first.first]).first if !student.present?
          if student.present? && student.photo.present?
            html =  html.gsub(url,File.join(RAILS_ROOT, student.photo.path))
          end
        end
        #check if archived_student_photo
        as_id = url.scan(/archived_students\/(\d+)\//)
        if as_id.present?
          archived_student = ArchivedStudent.find_by_id(as_id)
          if archived_student.present? && archived_student.photo.present?
            html =  html.gsub(url,File.join(RAILS_ROOT, archived_student.photo.path))
          end
        end
        #check if employee_photo
        e_id = url.scan(/employees\/(\d+)\//)
        if e_id.present?
          employee = Employee.find(e_id.first.first)
          if employee.present? && employee.photo.present?
            html =  html.gsub(url, File.join(RAILS_ROOT, employee.photo.path))
          end
        end
        #check if guardian_photo
        g_id = url.scan(/guardians\/(\d+)\//)
        if g_id.present?
          guardian = Guardian.find_by_id(g_id.first.first)
          guardian = Guardian.find_by_sql(["SELECT *, former_id AS id FROM archived_guardians where former_id = ? ",g_id.first.first]).first if !guardian.present?
          if guardian.present? && guardian.photo.present?
            html =  html.gsub(url, File.join(RAILS_ROOT, guardian.photo.path))
          end 
        end
        
        #check if archived_guardian_photo
        a_id = url.scan(/archived_guardians\/(\d+)\//)
        if a_id.present?
          archived_guardian = ArchivedGuardian.find_by_id(a_id.first.first)
          if archived_guardian.present? && archived_guardian.photo.present?
            html =  html.gsub(url, File.join(RAILS_ROOT, archived_guardian.photo.path))
          end
        end
      end
      return html
    end
  end
  
  def self.webkit_support_for_html(html)
    #add support to -webkit properties 
    styles = html.scan(/style=".+?"/)
    styles.each do |style|
      webkit_enabled_style=style
      webkit_enabled_style = style.gsub("transform","-webkit-transform") unless style.match(/text-transform/)
      html = html.gsub(style, webkit_enabled_style )
    end
    return html
  end
  
  
  def self.convert_to_full_path(html_content)
    html_content = webkit_support_for_html(html_content)
    if FedenaSetting.s3_enabled?
      html = html_content
      return html
    else
      html = html_content
      image_urls = html.scan(/<img.*?src=\"(.+?)\"/)
      image_urls.each do |url|
        url=url.first
        #redactor image
        r_id = url.scan(/redactor_uploads\/(\d+)\//)
        if r_id.present?
          path = RedactorUpload.find(r_id.first.first).image.path
          html =  html.gsub(url,File.join(RAILS_ROOT,path))
        end
        #check if student_photo
        s_id = url.scan(/students\/(\d+)\//)
        if s_id.present?
          student = Student.find_by_id(s_id.first.first)
          student = Student.find_by_sql(["SELECT *, former_id AS id FROM archived_students where former_id = ? ",s_id.first.first]).first if !student.present?
          if student.present? && student.photo.present?
            html =  html.gsub(url,File.join(RAILS_ROOT, student.photo.path))
          end
        end
        #check if archived_student_photo
        as_id = url.scan(/archived_students\/(\d+)\//)
        if as_id.present?
          archived_student = ArchivedStudent.find_by_id(as_id)
          if archived_student.present? && archived_student.photo.present?
            html =  html.gsub(url,File.join(RAILS_ROOT, archived_student.photo.path))
          end
        end
        #check if employee_photo
        e_id = url.scan(/employees\/(\d+)\//)
        if e_id.present?
          employee = Employee.find(e_id.first.first)
          if employee.present? && employee.photo.present?
            html =  html.gsub(url, File.join(RAILS_ROOT, employee.photo.path))
          end
        end
        #check if guardian_photo
        g_id = url.scan(/guardians\/(\d+)\//)
        if g_id.present?
          guardian = Guardian.find_by_id(g_id.first.first)
          guardian = Guardian.find_by_sql(["SELECT *, former_id AS id FROM archived_guardians where former_id = ? ",g_id.first.first]).first if !guardian.present?
          if guardian.present? && guardian.photo.present?
            html =  html.gsub(url, File.join(RAILS_ROOT, guardian.photo.path))
          end 
        end
        
        #check if archived_guardian_photo
        a_id = url.scan(/archived_guardians\/(\d+)\//)
        if a_id.present?
          archived_guardian = ArchivedGuardian.find_by_id(a_id.first.first)
          if archived_guardian.present? && archived_guardian.photo.present?
            html =  html.gsub(url, File.join(RAILS_ROOT, archived_guardian.photo.path))
          end
        end
      end
      return html
    end
  end
  
  
  def format_s3_urls(pdf_html)
    # S3 urls have expiry - regenerate them 
    html = pdf_html
    image_urls = html.scan(/<img.*?src=\"(.+?)\"/)
    image_urls.each do |url|
      url=url.first
    
      #check if student_photo
      s_id = url.scan(/students\/photos\/(\d+)\//)
      if s_id.present?
        student = Student.find_by_id(s_id.first.first)
        student = Student.find_by_sql(["SELECT *, former_id AS id FROM archived_students where former_id = ? ",s_id.first.first]).first if !student.present?
        if student.present? && student.photo.present?
          html =  html.gsub(url, student.photo.url(:original,false))
        end
      end
      #check if archived_student_photo
      as_id = url.scan(/archived_students\/photos\/(\d+)\//)
      if as_id.present?
        archived_student = ArchivedStudent.find_by_id(as_id)
        if archived_student.present? && archived_student.photo.present?
          html =  html.gsub(url, archived_student.photo.url(:original,false))
        end
      end
      #check if employee_photo
      e_id = url.scan(/employees\/photos\/(\d+)\//)
      if e_id.present?
        employee = Employee.find(e_id.first.first)
        if employee.present? && employee.photo.present?
          html =  html.gsub(url, employee.photo.url(:original,false))
        end
      end
      #check if guardian_photo
      g_id = url.scan(/guardians\/photos\/(\d+)\//)
      if g_id.present?
        guardian = Guardian.find_by_id(g_id.first.first)
        guardian = Guardian.find_by_sql(["SELECT *, former_id AS id FROM archived_guardians where former_id = ? ",g_id.first.first]).first if !guardian.present?
        if guardian.present? && guardian.photo.present?
          html =  html.gsub(url, guardian.photo.url(:original,false))
        end 
      end
      
      #check if archived_guardian_photo
      a_id = url.scan(/archived_guardians\/photos\/(\d+)\//)
      if a_id.present?
        archived_guardian = ArchivedGuardian.find_by_id(a_id.first.first)
        if archived_guardian.present? && archived_guardian.photo.present?
          html =  html.gsub(url, archived_guardian.photo.url(:original,false))
        end
      end
    end
    
    image_urls = html.scan(/url\(&quot;(.+?)&quot;\)/)
    image_urls.each do |url|
      url=url.first
      
      #check if background_image
      background_image_id =  url.scan(/certificate_templates\/background_images\/(\d+)\//)
      if background_image_id.present?
        image = CertificateTemplate.find_by_id(background_image_id.first.first)
        if image.present? && image.background_image.present?
          html =  html.gsub(url, image.background_image.url(:original,false))
        end
      end
  
    end
    return html
  end
  
  
  def self.generate_pdf_and_save (pdf_content)
    
  end

  def get_issued_for
    if self.issued_for_type == "Student"
      if self.issued_for.present?
        return self.issued_for
      else
        #check if student has been archived - if so convert to student
        student = Student.find_by_sql(["SELECT *, former_id AS id FROM archived_students where former_id = ? ",self.issued_for_id]).first
        return student
      end
    else
      return self.issued_for
    end
  end
  
  def valid_issued_for
    user = get_issued_for
    if user.present?
      return true
    else
      errors.add_to_base(self.issued_for_type == "Student" ? t('student_was_deleted') : t('employee_was_deleted') )
      return false
    end
  end
end
