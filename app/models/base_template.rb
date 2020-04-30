class BaseTemplate < ActiveRecord::Base
  xss_terminate :except => [:template_data]
  attr_accessor :redactor_to_update, :redactor_to_delete

  has_one :barcode_property

  accepts_nested_attributes_for :barcode_property
  before_validation :remove_barcode_for_parent



  TEMPLATE_KEYS = {
    :student=>{
      :full_name=>'full_name',
      :first_name=>'first_name',
      :middle_name=>'middle_name',
      :last_name=>'last_name',
      :date_of_birth=>'date_of_birth',
      :dob_in_words => 'dob_in_words',
      :admission_no=>'admission_no',
      :roll_number=> 'roll_number',
      :admission_date=>'admission_date',
      :admission_date_in_words=>'admission_date_in_words',
      :course=>'course',
      :blood_group=>'blood_group',
      :gender=>'gender',
      :fathers_name=>'fathers_name',
      :fathers_contact_no=>'fathers_contact_no',
      :mothers_name=>'mothers_name',
      :mothers_contact_no=>'mothers_contact_no',
      :nationality=>'nationality',
      :mother_tongue=>'mother_tongue',
      :category=>'category',
      :religion=>'religion',
      :address=>'address',
      :city=>'city',
      :state=>'state',
      :pin_code=>'zip',
      :birth_place=>'birth_place',
      :phone=>'phone',
      :mobile=>'mobile',
      :email=>'email',
      :biometric_id=>'biometric_id',
      :student_photo=>'student_photo',
      :fathers_photo=>'fathers_photo',
      :mothers_photo=>'mothers_photo',
      :immediate_contacts_photo=>'immediate_contacts_photo',
      :joining_course=>'joining_course',
      :last_course=>'last_course',
      :subjects_studied => 'subjects_studied',
      :batch=>'batch',
      :batch_full_name=>'batch_full_name',
      :date_of_leaving => 'date_of_leaving',
      :date_of_leaving_in_words => 'date_of_leaving_in_words',
      :leaving_reason => 'leaving_reason',
      :barcode => 'barcode',
      :immediate_contact => 'immediate_contact',
      :immediate_contact_name => 'immediate_contact_name'
    },
    :parent=>{
      :full_name=> 'full_name',
      :first_name=> 'first_name',
      :last_name=> 'last_name',
      :relation => 'relation',
      :ward_batch_name => 'ward_batch_name',
      :ward_admission_number => 'ward_admission_number',
      :date_of_birth => 'date_of_birth',
      :dob_in_words => 'dob_in_words',
      :email => 'email',
      :office_phone_1 => 'office_phone1',
      :office_phone_2 => 'office_phone2',
      :mobile_phone_no => 'mobile_phone_no',
      :address => 'address',
      :city => 'city',
      :state => 'state',
      :country => 'country',
      :education => 'education',
      :income => 'income',
      :occupation => 'occupation',
      :guardian_photo => 'guardian_photo',
      :ward_photo => 'ward_photo'
    },
    :employee=>{
      :full_name=>'full_name',
      :first_name=>'first_name',
      :middle_name=>'middle_name',
      :last_name=>'last_name',
      :employee_number=>'employee_number',
      :joining_date=>'joining_date',
      :joining_date_in_words=>'joining_date_in_words',
      :department=>'department',
      :category=>'category',
      :position=>'position',
      :grade=> 'grade',
      :job_title=>'job_title',
      :gender=>'gender',
      :email=>'email',
      :qualification=>'qualification',
      :total_experience=>'total_exp',
      :experience_info=>'exp_info',
      :biometric_id=>'biometric_id',
      :date_of_birth=>'date_of_birth',
      :dob_in_words => 'dob_in_words',
      :marital_status=>'marital_status',
      :no_of_children=>'no_of_children',
      :fathers_name=>'fathers_name',
      :mothers_name=>'mothers_name',
      :spouse_name=>'spouse_name',
      :blood_group=>'blood_group',
      :nationality=>'nationality',
      :home_address=>'home_address',
      :home_city=>'home_city',
      :home_state=>'home_state',
      :home_country=>'home_country',
      :home_pin_code=>'home_pin_code',
      :office_address=>'office_address',
      :office_city=>'office_city',
      :office_state=>'office_state',
      :office_country=>'office_country',
      :office_pin_code=>'office_pin_code',
      :office_phone_1=>'office_phone_1',
      :office_phone_2=>'office_phone_2',
      :mobile=>'mobile',
      :home_phone=>"home_phone",
      :fax=>'fax',
      :gross_pay=> 'gross_pay',
      :employee_photo => 'employee_photo',
      :barcode => 'barcode'
    },
    :common=>{
      :date=>'date_text',
      :institution_name=>'institution_name',
      :institution_address=>'institution_address',
      :institution_phone_no=>'institution_phone_no',
      :institution_email=>'institution_email',
      :institution_website=>'institution_website'
    }

  }

  def remove_barcode_for_parent
    if self.template_for == 3
      self.barcode_property.destroy if self.barcode_property.present?
    end
  end

  def get_included_template_keys
    keys={}
    temp = template_data.scan(/\{\{(.*?)\}\}/)
    temp.each{|k| keys=keys.merge({k.first.to_sym=>1})}
    return keys
  end


  def update_redactor
    RedactorUpload.update_redactors(self.redactor_to_update,self.redactor_to_delete)
  end


  def delete_redactors
    RedactorUpload.delete_after_create(self.template_data)
  end

  def self.get_translated_keys(keys)
    new_keys = {}.merge(keys)
    new_keys.each{|key,val| new_keys[key]=t(val)}
    return new_keys
  end


  def self.get_student_keys
    additional_field_keys = {}
    StudentAdditionalField.all.each{|f| additional_field_keys = additional_field_keys.merge({f.name.split.map{|e| e.downcase}.join("_").to_sym => f.name})}
    student_keys = BaseTemplate.get_translated_keys(TEMPLATE_KEYS[:student])
    return student_keys.merge(additional_field_keys)
  end


  def self.get_parent_keys
    return BaseTemplate.get_translated_keys(TEMPLATE_KEYS[:parent])
  end


  def self.get_employee_keys
    additional_field_keys = {}
    AdditionalField.all.each{|f| additional_field_keys = additional_field_keys.merge({f.name.split.map{|e| e.downcase}.join("_").to_sym => f.name})}
    employee_keys = BaseTemplate.get_translated_keys(TEMPLATE_KEYS[:employee])
    return employee_keys.merge(additional_field_keys)
  end


  def self.get_common_keys
    return  BaseTemplate.get_translated_keys(TEMPLATE_KEYS[:common])
  end


  def self.get_student_additional_values(student)
    additional_key_values={}
    student.student_additional_details.each do |e|
      additional_key_values = additional_key_values.merge( {e.student_additional_field.name.split.map{|t| t.downcase}.join("_") => e.additional_info} )
    end
    return additional_key_values
  end

  def self.get_employee_additional_values(employee)
    additional_key_values={}
    employee.employee_additional_details.each do |e|
      additional_key_values = additional_key_values.merge( {e.additional_field.name.split.map{|t| t.downcase}.join("_") => e.additional_info} )
    end
    return additional_key_values
  end


  def get_binding_ready_template
    data = template_data
    barcode_property = self.barcode_property
    if barcode_property.present?
      if barcode_property.rotate == 270
        data = data.gsub "{{barcode}}","<span><img style='max-height:100%; max-width:100%; -webkit-transform: rotate(#{barcode_property.rotate}deg) translate(-100%, 0%); -webkit-transform-origin: 0% 0%;' id='barcode'></img></span>"
      elsif barcode_property.rotate == 90
        data = data.gsub "{{barcode}}","<span><img style='max-height:100%; max-width:100%;  -webkit-transform: rotate(#{barcode_property.rotate}deg) translate(0%, -100%); -webkit-transform-origin: 0% 0%;' id='barcode'></img></span>"
      else
        data = data.gsub "{{barcode}}","<span><img style='max-height:100%; max-width:100%;  -webkit-transform: rotate(#{barcode_property.rotate}deg);' id='barcode'></img></span>"
      end
    else
      data = data.gsub "{{barcode}}","<span><img style='max-height:100%; max-width:100%;' id='barcode'></img></span>"
    end
    photo_keys =["{{student_photo}}", "{{employee_photo}}", "{{guardian_photo}}", "{{fathers_photo}}", "{{mothers_photo}}", "{{immediate_contacts_photo}}","{{ward_photo}}"]
    photo_keys.each do |photo_key|
      if profile_photo_type == "circle"
        data = data.gsub photo_key, "<span><img style='border-radius:1000px; width:#{profile_photo_dimension}px; height:#{profile_photo_dimension}px; ' v-bind:src='#{photo_key[2..-3]}'></img></span>"
      else
        data = data.gsub photo_key, "<span><img  style='width:#{profile_photo_dimension}px; height:#{profile_photo_dimension}px;' v-bind:src='#{photo_key[2..-3]}' ></img></span>"
      end
    end
    return data
  end

  def get_pdf_html
    if FedenaSetting.s3_enabled?
      return self.get_binding_ready_template
    else
      html = self.get_binding_ready_template
      image_urls = html.scan(/<img.*?src=\"(.+?)\"/)
      image_urls.each do |url|
        url=url.first
        #redactor image
        r_id = url.scan(/redactor_uploads\/(\d+)\//)
        if r_id.present?
          path = RedactorUpload.find(r_id.first.first).image.path
          html =  html.gsub(url,File.join(RAILS_ROOT,path))
        end
      end
      return html
    end
  end

  def self.is_key_profile_photo(key)
    key = key.to_sym
    key == :student_photo || key == :mothers_photo || key == :fathers_photo || key == :employee_photo || key == :guardian_photo || key == :immediate_contacts_photo|| key == :ward_photo
  end

end
