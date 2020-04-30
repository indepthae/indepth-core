class BulkGeneratedIdCard < ActiveRecord::Base
  xss_terminate :except => [:pdf_content]
  belongs_to :id_card_template
  belongs_to :academic_year
  has_many :generated_pdfs, :as => :corresponding_pdf, :dependent=>:destroy
  
  
  def get_pdf_content
    html =  self.pdf_content
    if FedenaSetting.s3_enabled?
      return  format_s3_urls(html)
    else
      return format_urls_in_html_for_pdf(html)
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
  
end
