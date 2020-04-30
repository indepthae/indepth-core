module TcTemplateGenerateCertificatesHelper
  include ApplicationHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::CaptureHelper
  include DateToWord
  
  def get_stylesheet_for_tc
    stylesheets=[]
    if rtl?
      stylesheets<<'rtl/tc_template_generate_certificates/transfer_certificate_download.css'
    else
      stylesheets<<'tc_template_generate_certificates/transfer_certificate_download.css'
    end
    stylesheets=[stylesheets,{:media=>"all"}]
  end
  
  def get_child_field_ids(parent_id)
    parent = TcTemplateField.find parent_id.to_i
    parent.child_field_ids
  end
  
  def extract_prefix(string, prefix)
    string.sub(/^#{prefix}/, "")
  end
  
  def get_date_in_words(date)
    date = date.to_s
    lang = I18n.locale.to_s.split('-').first.strip
    if lang == "en"
      DateToWord.date_to_words(Date.parse(date))
    else
      return ""
    end
  end
  
  def get_record_of_student(student)
    TcTemplateRecord.find_by_student_id(student.id)
  end
  def get_all_subjects(student)
    normal_subjects(student) + electives(student)
  end
  
  def electives(student)
    subjects = student.students_subjects.select{|sub| sub.batch_id == student.batch.id}.map{|x|x.subject}
    return subjects.select{|sub| sub.is_deleted == false}
  end
  def normal_subjects(student)
    student.batch.subjects.all(:conditions=>["elective_group_id IS NULL and is_deleted=?",false])
  end
 
  def get_field_type_and_value(field,student)
    if field[:field_format] == "text_area"
      if field[:field_format_value] == "subjects_studied"
        field_format = "text_area"
        value_1 = field[:field_value][:value_1] if field[:field_value]
        value_2 = get_all_subjects(student).collect(&:name).join(", ") 
        value_2 = value_2.chomp(",")
      else
        field_format= "text_area"
        value_1 = field[:field_value][:value_1] if field[:field_value]
        value_2 = nil
      end
    elsif field[:field_format_value] == "working_days" || field[:field_format_value] == "student_present_days"
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      config = Configuration.find_by_config_key('StudentAttendanceType')
      batch = Batch.find(student.batch.id)
      start_date = batch.start_date.to_date
      end_date=default_time_zone_present_time
      unless config.config_value == 'Daily'
        academic_days=batch.subject_hours(start_date, end_date.to_date, 0).values.flatten.compact.count.to_f
        grouped = batch.subject_leaves.find(:all,  :conditions =>{:batch_id=>batch.id,:month_date => start_date..end_date.to_date}).group_by(&:student_id)
        if grouped[student.former_id].nil?
          leaves=0
        else
          leaves=grouped[student.former_id].count
        end
        leaves_total = (academic_days - leaves).to_f
      else
        academic_days=batch.academic_days.count.to_f
        leaves_forenoon=Attendance.count(:all,:conditions=>{:batch_id=>batch.id,:forenoon=>true,:afternoon=>false,:month_date => start_date..end_date.to_date},:group=>:student_id)
        leaves_afternoon=Attendance.count(:all,:conditions=>{:batch_id=>batch.id,:forenoon=>false,:afternoon=>true,:month_date => start_date..end_date.to_date},:group=>:student_id)
        leaves_full=Attendance.count(:all,:conditions=>{:batch_id=>batch.id,:forenoon=>true,:afternoon=>true,:month_date => start_date..end_date.to_date},:group=>:student_id)
        leaves_total=academic_days-leaves_full[student.former_id].to_f-(0.5*(leaves_forenoon[student.former_id].to_f+leaves_afternoon[student.former_id].to_f))
      end
      if field[:field_format_value] == "working_days"
        value_2 = academic_days
      elsif field[:field_format_value] == "student_present_days"
        value_2 = leaves_total
      end
    elsif field[:field_format] == "yes_or_no_radio"
      field_format="radio"
      value_1 =  field[:field_value][:value_1] if field[:field_value]
      value_2 = nil
    elsif field[:field_type] == "custom" && (field[:field_format] == "text_field" || field[:field_format] == "text_field_numeric")
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      value_2 = nil
    elsif  field[:field_format] == "multiple_type"
      if field[:field_type] == "system"
        field_format = "date_of_birth"
        value_1 =student.date_of_birth
        value_2 =student.date_of_birth
      else
        field_format = "calander"
        value_1 = field[:field_value][:value_1].to_date if field[:field_value]
        value_2 = field[:field_value][:value_2] if field[:field_value]
      end
    elsif field[:field_format_value] == "student_name"
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      value_2 = student.full_name
    elsif field[:field_format_value] == "birth_place"
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      value_2 = student.birth_place
    elsif field[:field_format_value] == "mother_tongue"
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      value_2 = student.language
    elsif field[:field_format_value] == "guardian_name"
      guardians = student.archived_guardians
      if guardians.present?
        g = guardians.first(:conditions=>{:relation=>"father"})
        unless g.present?
          g = guardians.select{|s| s.relation!="mother"}.first
        end
        p = g.present? ? g.full_name : ""
      else 
        p = ""     
      end
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      value_2 = p
    elsif field[:field_format_value] == "mother_name"
      g = student.archived_guardians.first(:conditions=>{:relation=>"mother"})
      if g.present?
        p = g.full_name
      else 
        p = ""     
      end
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      value_2 = p
    elsif field[:field_format_value] == "nationality"
      c= Country.find(student.nationality_id)
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      if c.name == "India"
        value_2 = "Indian"
      else
        value_2 = c.name
      end
    elsif field[:field_format_value] == "religion_and_cast"
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      value_2 = student.religion
    elsif field[:field_format_value] == "student_category"
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      value_2 = student.student_category.name if student.student_category
    elsif field[:field_format_value] == "admission_number"
      field_format = "text_field"
      value_1 = student.admission_no
      value_2 = student.admission_no
    elsif field[:field_format] == "admission_date"
      field_format = "admission_date"
      value_1 = student.admission_date
      value_2 = student.admission_date
    elsif field[:field_format_value] == "last_batch_and_course"
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      value_2 = "#{student.batch.full_name}"
    elsif field[:field_type] == "system" && field[:field_format_value] == "reason_for_leaving"
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      value_2 = student.status_description
    elsif field[:field_format_value] == "leaving_date"
      field_format = "date_of_leaving"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      value_2 = student.date_of_leaving
    elsif field[:field_format] == "select_box"
      field_format = "select_box"
      value_1 = field[:additional_field]
      value_2 = field[:field_value][:value_1] || nil if field[:field_value]
    elsif field[:field_type] == "system" && field[:field_format_value] == "gender"
      field_format = "radio"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      value_2 = student.gender
    elsif field[:field_format] == "additional_field"
      field_format = "text_field"
      value_1 = field[:field_value][:value_1] if field[:field_value]
      additional_field = StudentAdditionalDetail.find_by_student_id_and_additional_field_id(student.former_id.to_i,field[:value].to_i)
      value_2 = additional_field.additional_info if additional_field.present?
      value_2 = "" if additional_field.nil?
    end
    return field_format, value_1,value_2
  end
  
  def default_time_zone_present_time
    server_time = Time.now
    server_time_to_gmt = server_time.getgm
    @local_tzone_time = server_time
    time_zone = Configuration.find_by_config_key("TimeZone")
    unless time_zone.nil?
      unless time_zone.config_value.nil?
        zone = TimeZone.find_by_id(time_zone.config_value)
        if zone.present?
          if zone.difference_type=="+"
            @local_tzone_time = server_time_to_gmt + zone.time_difference
          else
            @local_tzone_time = server_time_to_gmt - zone.time_difference
          end
        end
      end
    end
    return @local_tzone_time
  end
end
