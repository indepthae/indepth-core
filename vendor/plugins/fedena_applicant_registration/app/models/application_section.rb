class ApplicationSection < ActiveRecord::Base
  
  serialize :section_fields
  
  belongs_to :registration_course

  DEFAULT_FORM = [{:section_name=>"student_personal_details",:applicant_addl_field_group_id=>nil,:section_order=>1,:fields=>[{:field_type=>"default",:show_field=>"default_true",:field_name=>"first_name",:mandatory=>"default_true",:field_order=>1},
        {:field_type=>"default",:show_field=>true,:field_name=>"middle_name",:mandatory=>false,:field_order=>2},{:field_type=>"default",:show_field=>"default_true",:field_name=>"last_name",:mandatory=>true,:field_order=>3},
        {:field_type=>"default",:show_field=>"default_true",:field_name=>"date_of_birth",:mandatory=>"default_true",:field_order=>4},{:field_type=>"default",:show_field=>"default_true",:field_name=>"gender",:mandatory=>"default_true",:field_order=>5},
        {:field_type=>"default",:show_field=>"default_true",:field_name=>"nationality",:mandatory=>"default_true",:field_order=>6},{:field_type=>"default",:show_field=>true,:field_name=>"student_photo",:mandatory=>false,:field_order=>7},{:field_type=>"default",:show_field=>true,:field_name=>"student_category",:mandatory=>false,:field_order=>8},
        {:field_type=>"default",:show_field=>true,:field_name=>"religion",:mandatory=>false,:field_order=>9},{:field_type=>"default",:show_field=>true,:field_name=>"blood_group",:mandatory=>false,:field_order=>10},
        {:field_type=>"default",:show_field=>true,:field_name=>"birth_place",:mandatory=>false,:field_order=>11},{:field_type=>"default",:show_field=>true,:field_name=>"mother_tongue",:mandatory=>false,:field_order=>12}]},
    {:section_name=>"student_communication_details",:applicant_addl_field_group_id=>nil,:section_order=>2,:fields=>[{:field_type=>"default",:show_field=>true,:field_name=>"address_line_1",:mandatory=>false,:field_order=>1},{:field_type=>"default",:show_field=>true,:field_name=>"address_line_2",:mandatory=>false,:field_order=>2},
        {:field_type=>"default",:show_field=>true,:field_name=>"city",:mandatory=>false,:field_order=>3},{:field_type=>"default",:show_field=>true,:field_name=>"state",:mandatory=>false,:field_order=>4},
        {:field_type=>"default",:show_field=>true,:field_name=>"pin_code",:mandatory=>false,:field_order=>5},{:field_type=>"default",:show_field=>true,:field_name=>"country",:mandatory=>false,:field_order=>6},
        {:field_type=>"default",:show_field=>true,:field_name=>"phone",:mandatory=>false,:field_order=>7},{:field_type=>"default",:show_field=>true,:field_name=>"mobile",:mandatory=>false,:field_order=>8},
        {:field_type=>"default",:show_field=>true,:field_name=>"email",:mandatory=>false,:field_order=>9}]},{:section_name=>"elective_subjects",:applicant_addl_field_group_id=>nil,:section_order=>3,:fields=>[
        {:field_type=>"default",:show_field=>true,:field_name=>"choose_electives",:mandatory=>true,:field_order=>1}]},{:section_name=>"previous_institution_details",:applicant_addl_field_group_id=>nil,:section_order=>4,:fields=>[{:field_type=>"default",:show_field=>true,:field_name=>"institution_name",:mandatory=>false,:field_order=>1},
        {:field_type=>"default",:show_field=>true,:field_name=>"qualifying_exam_name",:mandatory=>false,:field_order=>2},{:field_type=>"default",:show_field=>true,:field_name=>"exam_roll_no",:mandatory=>false,:field_order=>3},
        {:field_type=>"default",:show_field=>true,:field_name=>"final_score",:mandatory=>false,:field_order=>4}]},{:section_name=>"guardian_personal_details",:applicant_addl_field_group_id=>nil,:section_order=>5,:fields=>[{:field_type=>"default",:show_field=>"default_true",:field_name=>"first_name",:mandatory=>"default_true",:field_order=>1},
        {:field_type=>"default",:show_field=>true,:field_name=>"last_name",:mandatory=>false,:field_order=>2},{:field_type=>"default",:show_field=>"default_true",:field_name=>"relation",:mandatory=>"default_true",:field_order=>3},{:field_type=>"default",:show_field=>true,:field_name=>"date_of_birth",:mandatory=>false,:field_order=>4},
        {:field_type=>"default",:show_field=>true,:field_name=>"education",:mandatory=>false,:field_order=>5},{:field_type=>"default",:show_field=>true,:field_name=>"occupation",:mandatory=>false,:field_order=>6},
        {:field_type=>"default",:show_field=>true,:field_name=>"income",:mandatory=>false,:field_order=>7}]},{:section_name=>"guardian_contact_details",:applicant_addl_field_group_id=>nil,:section_order=>6,:fields=>[
        {:field_type=>"default",:show_field=>true,:field_name=>"office_address_line1",:mandatory=>false,:field_order=>1},{:field_type=>"default",:show_field=>true,:field_name=>"office_address_line2",:mandatory=>false,:field_order=>2},
        {:field_type=>"default",:show_field=>true,:field_name=>"city",:mandatory=>false,:field_order=>3},{:field_type=>"default",:show_field=>true,:field_name=>"state",:mandatory=>false,:field_order=>4},
        {:field_type=>"default",:show_field=>true,:field_name=>"country",:mandatory=>false,:field_order=>5},{:field_type=>"default",:show_field=>true,:field_name=>"office_phone1",:mandatory=>false,:field_order=>6},{:field_type=>"default",:show_field=>true,:field_name=>"office_phone2",:mandatory=>false,:field_order=>7},
        {:field_type=>"default",:show_field=>true,:field_name=>"mobile",:mandatory=>false,:field_order=>8},{:field_type=>"default",:show_field=>true,:field_name=>"email",:mandatory=>false,:field_order=>9}]},{:section_name=>"attachments",:applicant_addl_field_group_id=>nil,:section_order=>7,:section_description=>"attachment_section_description",:fields=>[]},{:section_name=>"administration_section",:applicant_addl_field_group_id=>nil,:section_order=>8,:section_description=>"admin_section_description",:fields=>[]}]
  
  
  DEFAULT_FIELDS = {
    :student_personal_details=>{:m_name=>"applicants",:fields=>{:first_name=>{:field_type=>"text_field"},:middle_name=>{:field_type=>"text_field"},:last_name=>{:field_type=>"text_field"},
        :date_of_birth=>{:field_type=>"calendar_date_select",:default_value=>"(@applicant.date_of_birth.blank? ?  I18n.l(Date.today-5.years,:format=>:default): I18n.l(@applicant.date_of_birth,:format=>:default))",:year_range=>"72.years.ago..0.years.ago"},
        :gender=>{:field_type=>"radio_button",:field_options=>'[["m","male"],["f","female"]]'},:nationality=>{:field_attr=>"nationality_id",:field_type=>"select",:field_options=>"Country.all.map {|c| [c.full_name, c.id]}",:selected=>"@applicant.nationality_id || Configuration.default_country"},
        :student_photo=>{:field_attr=>"photo",:field_type=>"paperclip_file_field",:size=>"12",:direct=>true},:student_category=>{:field_attr=>"student_category_id",:field_type=>"select",:field_options=>"StudentCategory.active.map {|c| [c.name, c.id]}",:selected=>"@applicant.student_category_id || nil",:prompt=>"t('select_a_category')"},:religion=>{:field_type=>"text_field"},:blood_group=>{:field_type=>"select",:field_options=>"Student::VALID_BLOOD_GROUPS",:selected=>"@applicant.blood_group || nil",:prompt=>"t('unknown')"},
        :birth_place=>{:field_type=>"text_field"},:mother_tongue=>{:field_attr=>"language",:field_type=>"text_field"}}},
    :student_communication_details=>{:m_name=>"applicants",:fields=>{:address_line_1=>{:field_attr=>"address_line1",:field_type=>"text_field"},:address_line_2=>{:field_attr=>"address_line2",:field_type=>"text_field"},
        :city=>{:field_type=>"text_field"},:state=>{:field_type=>"text_field"},:pin_code=>{:field_type=>"text_field"},:country=>{:field_attr=>"country_id",:field_type=>"select",:field_options=>"Country.all.map {|c| [c.full_name, c.id]}",:selected=>"@applicant.country_id || Configuration.default_country"},
        :phone=>{:field_attr=>"phone1",:field_type=>"text_field"},:mobile=>{:field_attr=>"phone2",:field_type=>"text_field"},:email=>{:field_type=>"text_field"}}},
    :elective_subjects=>{:m_name=>"applicants",:fields=>{:choose_electives=>{:field_attr=>"subject_ids"}}},
    :previous_institution_details=>{:m_name=>"applicant_previous_data",:m_build=>"build_applicant_previous_data",:fields=>{:institution_name=>{:field_attr=>"last_attended_school",:field_type=>"text_field"},:qualifying_exam_name=>{:field_attr=>"qualifying_exam",:field_type=>"text_field"},
        :exam_roll_no=>{:field_attr=>"qualifying_exam_roll",:field_type=>"text_field"},:final_score=>{:field_attr=>"qualifying_exam_final_score",:field_type=>"text_field"}}},
    :guardian_personal_details=>{:m_name=>"applicant_guardians",:m_build=>"applicant_guardians.build",:fields=>{:first_name=>{:field_type=>"text_field"},:last_name=>{:field_type=>"text_field"},:relation=>{:field_type=>"select"},
      :date_of_birth=>{:field_attr=>"dob",:field_type=>"calendar_date_select",:default_value=>"",:year_range=>"100.years.ago..20.years.ago"},:education=>{:field_type=>"text_field"},:occupation=>{:field_type=>"text_field"},:income=>{:field_type=>"text_field"}}},
  :guardian_contact_details=>{:m_name=>"applicant_guardians",:m_build=>"applicant_guardians.build",:fields=>{:office_address_line1=>{:field_type=>"text_field"},:office_address_line2=>{:field_type=>"text_field"},
        :city=>{:field_type=>"text_field"},:state=>{:field_type=>"text_field"},:country=>{:field_attr=>"country_id",:field_type=>"select",:field_options=>"Country.all.map {|c| [c.full_name, c.id]}",:selected=>"Configuration.default_country"},:office_phone1=>{:field_type=>"text_field"},
      :office_phone2=>{:field_type=>"text_field"},:mobile=>{:field_attr=>"mobile_phone",:field_type=>"text_field"},:email=>{:field_type=>"text_field"}}}
  }
  DEFAULT_FIELDS_SECTIONS = {"applicant" => "student_personal_details"}

  before_save :structure_section_fields
  
  def structure_section_fields
    section_hash = {:form_hash=>self.section_fields}
    modified_hash = ApplicationSection.repair_nested_params(section_hash)
    self.section_fields = modified_hash[:form_hash]
  end
  
  def self.repair_nested_params(obj)
    obj.each do |key, value|
      if value.is_a? Hash
        if value.keys.find {|k, _| k =~ /\D/ }
          repair_nested_params(value)
        else
          obj[key] = value.values
          value.values.each {|h| repair_nested_params(h) }
        end
      end
    end
  end

  # find the errors in submission form (applicant registration fix #)
  def self.find_errors_in_form_submission(rg_course_id, params)
    count_array = []
    fields_error_list = []
    section_error_list = []
    addl_fields_error_list = []
    registration_course = RegistrationCourse.find_by_id(rg_course_id)
    application_section = registration_course.application_section
    unless application_section.present?
      application_section = self.find_by_registration_course_id(nil)
    end
    guardian_count =  application_section.present? ? application_section.guardian_count : 1
    (0..guardian_count).each{|c| count_array << c-1 if c != 0}
    section_fields = application_section.present? ? application_section.section_fields : ApplicationSection::DEFAULT_FORM
    section_fields.each do |f|
      case f[:section_name]
      when "student_personal_details"
        if params.nil?
          section_error_list << f[:section_name]
        else
          errors = find_errors_from_student_details(params, f, nil, rg_course_id)
          fields_error_list << errors["field_error_list"]
          addl_fields_error_list << errors["addl_error"]
        end
      when "student_communication_details"
        if params.nil?
          section_error_list << f[:section_name]
        else
          errors = find_errors_from_student_details(params, f, nil, rg_course_id)
          fields_error_list << errors["field_error_list"]
          addl_fields_error_list << errors["addl_error"]
        end  
      when "guardian_personal_details"
        if guardian_count > 0
          validate_params = find_guardian_section_errors(params, count_array, f)
          section_error_list << validate_params["section"]
          fields_error_list <<  validate_params["error"]
        end
      when "guardian_contact_details"
        if guardian_count > 0
          validate_params = find_guardian_section_errors(params, count_array, f) if guardian_count > 0
          section_error_list << validate_params["section"]
          fields_error_list <<  validate_params["error"]
        end
      when "previous_institution_details"
        # if params["applicant_previous_data_attributes"].nil?
        #   section_error_list << f[:section_name]
        # else
          errors = find_errors_from_student_details(params, f, nil, rg_course_id)
          fields_error_list << errors["field_error_list"]
          addl_fields_error_list << errors["addl_error"]
        # end
      when "attachments"
          errors = find_errors_from_student_details(params, f, nil, rg_course_id)
          fields_error_list << errors["field_error_list"]
          addl_fields_error_list << errors["addl_error"]
      else
        addl_fields_error_list << find_missing_section_addl_fields(params, f, registration_course.id) unless f[:section_name].present?
      end
    end 
    return section_error_list.compact.flatten, fields_error_list.compact.flatten, addl_fields_error_list.compact.flatten
  end

  # find the section presence in the form
  def self.find_error_in_student_form_section(params, fields, s_name, g_count)
    sh_fields = []
    missing_fields = []
    addl_keys = []
    if fields.present?
      fields.each do |f|
        if (f["show_field"] == "true" || f["show_field"] == "default_true") and (f["field_type"] != "applicant_additional")
          sh_fields << f["field_name"]
        end
      end
    end
    show_fields = sh_fields.present? ? find_the_default_field_attr(sh_fields, s_name) : []
    section_1 = ["student_communication_details", "student_personal_details"]
    section_2 = ["guardian_personal_details", "guardian_contact_details"]
    section_3 = ["previous_institution_details"]
    section_4 = ["attachments"]
    if section_1.include? s_name
      missing_fields << convert_field_attr_to_field_name(show_fields - params.keys, s_name)
    elsif section_2.include? s_name
      missing_fields = convert_field_attr_to_field_name((show_fields - params["applicant_guardians_attributes"][g_count.to_s].keys), s_name)
    elsif section_3.include? s_name
      missing_fields = convert_field_attr_to_field_name((show_fields - params["applicant_previous_data_attributes"].keys), s_name) if params["applicant_previous_data_attributes"].present?
    elsif section_4.include? s_name
      if show_fields.present?
        unless params["applicant_addl_attachments_attributes"].present?
          addl_keys << []
        else
          params["applicant_addl_attachments_attributes"].map{|k, v| addl_keys << v["applicant_addl_attachment_field_id"] }
        end
      end
      missing_addl_fields = show_fields - addl_keys
      missing_fields = ApplicantAddlAttachmentField.find(missing_addl_fields).collect(&:name)
    end
    return missing_fields
  end

  # fetch the default field attr from default form
  def self.find_the_default_field_attr(fields, section_name)
    o_fields = []
    if DEFAULT_FIELDS.include? section_name.to_sym
      fields.each do |f|
        if ApplicationSection::DEFAULT_FIELDS[section_name.to_sym][:fields].include? f.to_sym and ApplicationSection::DEFAULT_FIELDS[section_name.to_sym][:fields][f.to_sym][:field_attr].present?
          o_fields << ApplicationSection::DEFAULT_FIELDS[section_name.to_sym][:fields][f.to_sym][:field_attr]
        else
          o_fields << f
        end
      end
    else 
      fields.each{ |f| o_fields << f }
    end
    o_fields
  end

  # find missing addl fields from the form
  def self.find_missing_section_addl_fields(params, f, rg_id)
    missing_addl_fields = []
    addl_section_keys = []
    fields = []
    addl_fields = []
    if f["fields"].present?
      f["fields"].each{|f| addl_fields << f["field_name"] if f["show_field"] == "true"}
      addl_fields = addl_fields.map(&:to_s)
      if addl_fields.present? and params["applicant_addl_values_attributes"].present?
        params["applicant_addl_values_attributes"].map{|k, v| addl_section_keys << v["applicant_addl_field_id"] }
        fields = addl_fields - addl_section_keys
        missing = ApplicantAddlField.find_all_by_id(fields).collect(&:field_name)
      elsif addl_fields.present? and params["applicant_additional_details_attributes"].present?
        params["applicant_additional_details_attributes"].map{|k, v| addl_section_keys << v["additional_field_id"] }
        fields = addl_fields - addl_section_keys
        missing_addl_fields = ApplicantStudentAddlField.find_all_by_student_additional_field_id(fields).collect(&:student_additional_field_id)
      end
    end
    missing_addl_fields
  end

  # find missing addl fields from the form
  def self.find_section_addl_fields_errors(params, f, rg_id)
    missing_addl_fields = []
    addl_section_keys = []
    fields = []
    addl_fields = []
    if f["fields"].present?
      f["fields"].each{|f| addl_fields << f["field_name"] if (f["show_field"] == "true" and f["field_type"] == "applicant_additional")} if f["fields"].present?
      addl_fields = addl_fields.map(&:to_s)
      if addl_fields.present? and params["applicant_addl_values_attributes"].present?
        params["applicant_addl_values_attributes"].map{|k, v| addl_section_keys << v["applicant_addl_field_id"] }
        fields = addl_fields - addl_section_keys
      elsif params["applicant_addl_values_attributes"].nil?
        fields = addl_fields
      end
      missing_addl_fields = ApplicantAddlField.find(fields).collect(&:field_name)
    end
    missing_addl_fields
  end

  # find guardian section errors
  def self.find_guardian_section_errors(params, guardian_keys, f)
    section_error_list, fields_error_list = [], []
    unless params["applicant_guardians_attributes"].present? and (params["applicant_guardians_attributes"].keys.sort == guardian_keys.map(&:to_s).sort)
      section_error_list << "guardian"
    else
      guardian_keys.each do |i|
        fields_error_list << find_error_in_student_form_section(params, f[:fields], f[:section_name], i)
      end
    end
    return {'section' => section_error_list, 'error'=> fields_error_list}
  end

  # fetch errors from student details
  def self.find_errors_from_student_details(params, f, guardian_count, rg_course_id)
    field_errors = []
    addl_fields_error_list = []
    field_errors << find_error_in_student_form_section(params, f[:fields], f[:section_name], guardian_count)
    addl_fields_error_list << find_section_addl_fields_errors(params, f, rg_course_id)
    return {'field_error_list' => field_errors, 'addl_error'=> addl_fields_error_list}
  end

  # convert field attr to field name
  def self.convert_field_attr_to_field_name(field_list, section_name)
    field_error_list = field_list - (field_list - ApplicationSection::DEFAULT_FIELDS[section_name.to_sym][:fields].keys.map(&:to_s))
    attr = field_list - ApplicationSection::DEFAULT_FIELDS[section_name.to_sym][:fields].keys.map(&:to_s)
    attr.each do |f|
      ApplicationSection::DEFAULT_FIELDS[section_name.to_sym][:fields].map{|k, v| field_error_list <<  k.to_s if v[:field_attr] == f.to_s}
    end
    field_error_list
  end
end