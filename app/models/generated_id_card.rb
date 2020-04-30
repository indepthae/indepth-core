class GeneratedIdCard < ActiveRecord::Base
  xss_terminate :except => [:id_card_html_front, :id_card_html_back]
  belongs_to :id_card_template
  belongs_to :batch
  belongs_to :issued_for, :polymorphic => true
  before_validation :check_for_back_template, :set_issued_on,:valid_issued_for
  has_many :generated_pdfs, :as => :corresponding_pdf, :dependent=>:destroy

  def get_front_preview_html
    if FedenaSetting.s3_enabled?
      html = id_card_html_front
      return  format_s3_urls(html)
    else
      html = id_card_html_front
      return format_urls_in_html_for_pdf(html)
    end
  end
  
  
  def set_issued_on
    self.issued_on = Date.today
  end


  def get_back_preview_html
    if id_card_html_back.present?
      if FedenaSetting.s3_enabled?
        return id_card_html_back
      else
        html = id_card_html_back
        return format_urls_in_html_for_pdf(html)
      end
    else
      return false
    end
  end


  def format_urls_in_html_for_pdf(html)
    if !FedenaSetting.s3_enabled?
      image_urls = html.scan(/<img.*?src=\"(.+?)\"/)
      image_urls.each do |url|
        url=url.first
        #check if redactor url
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
          archived_student = ArchivedStudent.find_by_id(as_id.first.first)
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
    else
    end
    return html
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
  
  def self.convert_to_full_path(html)
    html = webkit_support_for_html(html)
    if !FedenaSetting.s3_enabled?
      image_urls = html.scan(/<img.*?src=\"(.+?)\"/)
      image_urls.each do |url|
        url=url.first
        #check if redactor url
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
          archived_student = ArchivedStudent.find_by_id(as_id.first.first)
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
    else
    end
    return html
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
      
      #check if front background_image
      front_background_image_id =  url.scan(/id_card_templates\/front_background_images\/(\d+)\//)
      if front_background_image_id.present?
        front_image = IdCardTemplate.find_by_id(front_background_image_id.first.first)
        if front_image.present? && front_image.front_background_image.present?
          html =  html.gsub(url, front_image.front_background_image.url(:original,false))
        end
      end
      
      #check if back background_image
      back_background_image_id =  url.scan(/id_card_templates\/back_background_images\/(\d+)\//)
      if back_background_image_id.present?
        back_image = IdCardTemplate.find_by_id(back_background_image_id.first.first)
        if back_image.present? && back_image.back_background_image.present?
          html =  html.gsub(url, back_image.back_background_image.url(:original,false))
        end
      end
    end
    
    return html
  end
  

  def check_for_back_template
    if self.id_card_template.include_back == "no"
      self.id_card_html_back = nil
    end
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
    elsif self.issued_for_type == "Guardian"
      if self.issued_for.present?
        return self.issued_for
      else 
        #check if guardian has been archived - if so convert to guardian
        guardian = Guardian.find_by_sql(["SELECT *, former_id AS id FROM archived_guardians where former_id = ? ",self.issued_for_id]).first
        return guardian
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
      errors.add_to_base(self.issued_for_type == "Student" ? t('student_was_deleted') : self.issued_for_type == "Employee" ? t('employee_was_deleted') : t('guardian_was_deleted'))
      return false
    end
  end
  
  
  def self.get_a4_style(rtl, generation_type)
    file = generation_type == "bulk" ? "a4_size.css" : "single_a4_size.css"
    if rtl
      return " <link rel='stylesheet' type='text/css' href='#{Rails.root}/public/rtl/stylesheets/id_card_templates/#{file}' > "
    else 
      return " <link rel='stylesheet' type='text/css' href='#{Rails.root}/public/stylesheets/id_card_templates/#{file}' > "
    end
  end 
  
  def self.get_card_size_style(rtl, generation_type)
    file = generation_type == "bulk" ? "card_size.css" : "single_card_size.css"
    if rtl
      return " <link rel='stylesheet' type='text/css' href='#{Rails.root}/public/rtl/stylesheets/id_card_templates/#{file}' > "
    else 
      return " <link rel='stylesheet' type='text/css' href='#{Rails.root}/public/stylesheets/id_card_templates/#{file}' > "
    end
  end
  
  
  def self.build_single_generated_pdf(front_html, back_html)
    final_html=''
    final_html = final_html + ' <div class="front_preview exclude_font keep-together"> ' + front_html + '</div> ' 
    if back_html.present?
      final_html = final_html + ' <div class="back_preview exclude_font keep-together"> ' + back_html + '</div> '
    end
    return final_html
  end


end
