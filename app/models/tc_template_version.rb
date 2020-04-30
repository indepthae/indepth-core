class TcTemplateVersion < ActiveRecord::Base
  has_many :tc_template_records, :dependent=>:destroy
  has_and_belongs_to_many :tc_template_fields
  has_and_belongs_to_many :tc_template_field_headers, :association_foreign_key => 'tc_template_field_id', :join_table=> 'tc_template_fields_tc_template_versions'
  has_and_belongs_to_many :tc_template_field_footers, :association_foreign_key => 'tc_template_field_id', :join_table=> 'tc_template_fields_tc_template_versions'
  has_and_belongs_to_many :tc_template_field_student_details_main_fields, :association_foreign_key => 'tc_template_field_id', :join_table=> 'tc_template_fields_tc_template_versions', :class_name => "TcTemplateFieldStudentDetail" ,:order => "tc_template_fields.priority ASC", :conditions=>'tc_template_fields.parent_field_id is NULL'
  has_and_belongs_to_many :tc_template_field_student_details, :association_foreign_key => 'tc_template_field_id', :join_table=> 'tc_template_fields_tc_template_versions', :class_name => "TcTemplateFieldStudentDetail"
  validates_numericality_of :header_space, :less_than_or_equal_to => 100, :greater_than_or_equal_to=> 0 ,:allow_nil => true

  SYSTEM_FIELDS = {
    1 => {:field=>"student_name",:type=>"text_field",:name=>"student_name"},
    2 => {:field=>"date_of_birth",:type=>"date",:name=>"date_of_birth"},
    3 => {:field=>"guardian_name",:type=>"text_field",:name=>"guardian_name"},
    4 => {:field=>"mother_name",:type=>"text_field",:name=>"mother_name"},
    5 => {:field=>"gender",:type=>"radio",:name=>"gender"},
    6 => {:field=>"religion_and_cast",:type=>"religion",:name=>"religion"},
    7 => {:field=>"nationality",:type=>"text_field",:name=>"nationality"},
    8 => {:field=>"birth_place",:type=>"text_field",:name=>"birth_place"},
    9 => {:field=>"mother_tongue",:type=>"text_field",:name=>"mother_tongue"},
    10 => {:field=>"student_category",:type=>"text_field",:name=>"student_category"},
    11 => {:field=>"admission_number",:type=>"text_field",:name=>"admission_no"},
    12 => {:field=>"last_batch_and_course",:type=>"text_field",:name=>"last_batch_and_course"},
    13 => {:field=>"reason_for_leaving",:type=>"text_field",:name=>"reason_for_leaving"},
    14 => {:field=>"admission_date",:type=>"admission_date",:name=>"admission_date"},
    15 => {:field=>"subjects_studied",:type=>"text_area",:name=>"subjects_studied"},
    16 => {:field=>"working_days",:type=>"text_field",:name=>"working_days"},
    17 => {:field=>"student_present_days",:type=>"text_field",:name=>"student_present_days"},
    18 => {:field=>"leaving_date",:type=>"text_field",:name=>"leaving_date"}
  }

  CUSTOM_FIELDS = {
    1 => {:field=>"text_box-Alphanumerics(A-Z,0-9)",:type=>"text_field",:name=>"#{t('text_box-alphanumerics')}"},
    2 => {:field=>"text_box-Only_numerics(0-9,...)",:type=>"text_field_numeric",:name=>"#{t('text_box-numerics')}"},
    3 => {:field=>"yes_or_no",:type=>"yes_or_no_radio",:name=>"#{t('yes_or_no')}"},
    4 => {:field=>"multiple_options",:type=>"select_box",:name=>"#{t('multiple_options')}"},
    5 => {:field=>"date",:type=>"date",:name=>"#{t('date_format')}"},
    6 => {:field=>"text_area",:type=>"text_area",:name=>"#{t('text_area')}"}
  }

  class << self

    def current
      TcTemplateVersion.find_by_is_active(true)
    end

    def initialize_sub_fields
      field = TcTemplateVersion.current.tc_template_field_student_details.find_by_field_name("Whether qualified for promotion to the higher class")
      TcTemplateVersion.current.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('which_class')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom",:field_format_value=>"text_box-Alphanumerics(A-Z,0-9)",:field_format=>"text_field"),:priority=>14,:parent_field_id=>field.id)
    end

    def initialize_first_template
      school = MultiSchool.current_school
      template = TcTemplateVersion.find_or_create_by_is_active(:is_active => true,:header_settings_edit=>false)

      #----------------Header Settings-------------------#
      template.tc_template_field_headers << TcTemplateFieldHeader.find_or_create_by_field_name(:field_name=>"InstitutionName",:field_info=>TcTemplateFieldRecord.new(:value=>"#{school.configurations.get_config_value("InstitutionName")}", :is_enabled=>true))
      template.tc_template_field_headers << TcTemplateFieldHeader.find_or_create_by_field_name(:field_name=>"Address",:field_info=>TcTemplateFieldRecord.new(:value=>"#{school.configurations.get_config_value("InstitutionAddress")}", :is_enabled=>true))
      template.tc_template_field_headers << TcTemplateFieldHeader.find_or_create_by_field_name(:field_name=>"Email",:field_info=>TcTemplateFieldRecord.new(:value=>"#{school.configurations.get_config_value("InstitutionEmail")}",:is_enabled=>true))
      template.tc_template_field_headers << TcTemplateFieldHeader.find_or_create_by_field_name(:field_name=>"Phone",:field_info=>TcTemplateFieldRecord.new(:value=>"#{school.configurations.get_config_value("InstitutionPhoneNo")}",:is_enabled=>true))
      template.tc_template_field_headers << TcTemplateFieldHeader.find_or_create_by_field_name(:field_name=>"Website",:field_info=>TcTemplateFieldRecord.new(:value=>"#{school.configurations.get_config_value("InstitutionWebsite")}",:is_enabled=>true))
      template.tc_template_field_headers << TcTemplateFieldHeader.find_or_create_by_field_name(:field_name=>"AlignInstitutionDetail",:field_info=>TcTemplateFieldRecord.new(:value=>"left"))
      template.tc_template_field_headers << TcTemplateFieldHeader.find_or_create_by_field_name(:field_name=>"InstitutionLogo",:field_info=>TcTemplateFieldRecord.new(:value=>"left", :is_enabled=>true))
      template.tc_template_field_headers << TcTemplateFieldHeader.find_or_create_by_field_name(:field_name=>"CertificateName",:field_info=>TcTemplateFieldRecord.new(:value=>"SCHOOL RELIEVING CERTIFICATE"))
      template.tc_template_field_headers << TcTemplateFieldHeader.find_or_create_by_field_name(:field_name=>"CertificateSerialNumber",:field_info=>TcTemplateFieldRecord.new(:value=>"Manual"))
      template.tc_template_field_headers << TcTemplateFieldHeader.find_or_create_by_field_name(:field_name=>"SerialPrefix",:field_info=>TcTemplateFieldRecord.new(:value=>""))
      template.tc_template_field_headers << TcTemplateFieldHeader.find_or_create_by_field_name(:field_name=>"SerialStartingCount",:field_info=>TcTemplateFieldRecord.new(:value=>""))
      template.tc_template_field_headers << TcTemplateFieldHeader.find_or_create_by_field_name(:field_name=>"DateOfIssue",:field_info=>TcTemplateFieldRecord.new(:is_enabled=>true, :value=>""))

      #------------------student Details----------------#
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('name_of_student')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"system", :field_format_value=>"student_name",:field_format=>"text_field"),:priority=>1)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('mother_name')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"system",:field_format_value=>"mother_name",:field_format=>"text_field"),:priority=>2)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('guardian_name')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"system",:field_format_value=>"guardian_name",:field_format=>"text_field"),:priority=>3)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('nationality')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"system",:field_format_value=>"nationality",:field_format=>"text_field"),:priority=>4)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('whether_sc_st')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom",:field_format_value=>"yes_or_no",:field_format=>"yes_or_no_radio"),:priority=>5)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('date_of_first_admission')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"system",:field_format_value=>"admission_date",:field_format=>"admission_date", :is_in_figures_enabled=> true, :is_in_words_enabled=>true),:priority=>6)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('date_of_birth_in_register')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"system",:field_format_value=>"date_of_birth",:field_format=>"multiple_type", :is_in_figures_enabled=> true, :is_in_words_enabled=>true),:priority=>7)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('place_of_birth')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"system",:field_format_value=>"birth_place",:field_format=>"text_field"),:priority=>8)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('last_studied_class')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"system",:field_format_value=>"last_batch_and_course",:field_format=>"text_field"),:priority=>9)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('last_taken_exam')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom", :field_format_value=>"text_box-Alphanumerics(A-Z,0-9)",:field_format=>"text_field"),:priority=>10)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('whether_failed')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom",:field_format_value=>"text_box-Alphanumerics(A-Z,0-9)",:field_format=>"text_field"),:priority=>11)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('subjects_studied')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"system",:field_format_value=>"subjects_studied",:field_format=>"text_area"),:priority=>12)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('whether_qualified_to_higher_class')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom",:field_format_value=>"yes_or_no",:field_format=>"yes_or_no_radio"),:priority=>13)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('month_of_paid_fees')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom",:field_format_value=>"text_box-Alphanumerics(A-Z,0-9)",:field_format=>"text_field"),:priority=>14)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('fee_concession')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom",:field_format_value=>"text_box-Alphanumerics(A-Z,0-9)",:field_format=>"text_field"),:priority=>15)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('total_working_days')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"system",:field_format_value=>"working_days",:field_format=>"text_field"),:priority=>16)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('student_present_days')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"system",:field_format_value=>"student_present_days",:field_format=>"text_field"),:priority=>17)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('whether_ncc_scout_guide')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom",:field_format_value=>"yes_or_no",:field_format=>"yes_or_no_radio"),:priority=>18)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('games_played')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom",:field_format_value=>"text_area",:field_format=>"text_area"),:priority=>19)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('general_conduct')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom",:field_format_value=>"text_box-Alphanumerics(A-Z,0-9)",:field_format=>"text_field"),:priority=>20)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('date_of_application')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom",:field_format_value=>"date",:field_format=>"multiple_type", :is_in_figures_enabled=> true, :is_in_words_enabled=>true),:priority=>21)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('date_of_issue_certificate')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom",:field_format_value=>"date",:field_format=>"multiple_type", :is_in_figures_enabled=> true, :is_in_words_enabled=>true),:priority=>22)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('reason_for_leaving_school')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"system",:field_format_value=>"reason_for_leaving",:field_format=>"text_field"),:priority=>23)
      template.tc_template_field_student_details << TcTemplateFieldStudentDetail.find_or_create_by_field_name(:field_name=>"#{t('other_remarks')}",:field_info=>TcTemplateFieldRecord.new(:field_type=>"custom",:field_format_value=>"text_box-Alphanumerics(A-Z,0-9)",:field_format=>"text_field"),:priority=>24)


      #----------------Footer Settings------------------#
      signature = TcTemplateFieldRecord.new(:value=>"#{t('signature_of_class_teacher')}", :field_type=>"sign", :priority=>1)
      object = TcTemplateFieldRecord.new
      object.additional_field << signature
      template.tc_template_field_footers << TcTemplateFieldFooter.find_or_create_by_field_name(:field_name=>"Signature",:field_info=>object)
      template.tc_template_field_footers << TcTemplateFieldFooter.find_or_create_by_field_name(:field_name=>"Clause",:field_info=>TcTemplateFieldRecord.new(:value=>"", :text_size=>"small", :text_color=>"grey"))
    end
  end

  def get_current_preview_settings
    tc_data = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    student_details = TcTemplateFieldStudentDetail.get_current_student_details
    header = TcTemplateFieldHeader.get_header_settings(self)
    header.each_pair do |k, v|
      tc_data["Header"][k] = v
    end
    footer = TcTemplateFieldFooter.get_footer_settings(self)
    footer.each_pair do |k,v|
      tc_data["Footer"][k] = v
    end
    tc_data["StudentDetailsData"]["student_details_ids"] =  self.tc_template_field_student_details_main_field_ids
    student_details.each_pair do |k,v|
      tc_data["StudentDetailsField"][k] = v
    end
    tc_data["Header"]["header_space"] = self.header_space.to_i
    tc_data["Header"]["header_enabled"] = self.header_enabled?
    tc_data["Footer"]["footer_enabled"] = self.footer_enabled?
    tc_data["Header"]["serial_number"] = ""
    tc_data["Header"]["date_of_issue"] = "dd/mm/yy" if self.doi_enabled?
    tc_data["StudentDetailsData"]["font_value"] = self.font_value
    return tc_data
  end

  def doi_enabled?
    obj = self.tc_template_fields.find_by_field_name("DateOfIssue")
    if obj.field_info.is_enabled
      return true
    else
      return false
    end
  end

  def header_enabled?
    if self.header_space
      return false
    else
      return true
    end
  end

  def footer_enabled?
    return !self.footer_space
  end

  def check_header_changes(value, space)
    header_status =  change_value(value, space)
    self.header_space = header_status
    if self.header_space_changed?
      if self.tc_template_records.count > 0
        field_ids = current_template.tc_template_field_ids
        self.update_attributes(:is_active=>false, :header_space=>header_space_was)
        version = TcTemplateVersion.new(:is_active=>true, :header_space=>header_status)
        if version.save
          current_template.tc_template_field_ids += field_ids
        end
        return version
      else
        self.save
        return self
      end
    else
      return self
    end
  end

  def check_footer_changes(value)
    footer_status = change_value(value)
    self.footer_space = footer_status
    if self.footer_space_changed?
      if self.tc_template_records.count > 0
        field_ids = current_template.tc_template_field_ids
        self.update_attributes(:is_active=>false, :footer_space=>footer_space_was)
        TcTemplateVersion.create(:is_active=>true, :footer_space=>footer_status)
        current_template.tc_template_field_ids += field_ids
      else
        self.save!
      end
    end
  end

  def change_value(value, space = 0)
    if value == "true"
      return nil
    else
      space = 0 if space.to_i == 0
      return space
    end
  end

  def current_template
    TcTemplateVersion.current
  end

  def define_new_version(space)
    self.update_attributes(:is_active=>false)
    TcTemplateVersion.create(:is_active=>true, :header_space=>space)
  end

  def add_new_version(font_size)
    header_settings = current_template.header_settings_edit
    space = current_template.header_space
    self.update_attributes(:is_active=>false)
    TcTemplateVersion.create(:is_active=>true, :font_value=>font_size, :header_space=>space, :header_settings_edit=>header_settings )
  end
  
  def update_font_for_existing_version(font_size)
    self.update_attributes(:font_value=>font_size)
  end

end
