module TimetablesHelper

  def data_length_check(tt)
    if tt.present?
      return (tt.batch.full_name.length > 50 or tt.assigned_name.length > 30)
    else
      return false
    end
  end

  def formatted_timetable_cell(tt)
    ## Produces view for one particular timetable entry cell
    unless tt.blank?
      unless tt.entry.blank?
        "#{shorten_string(tt.assigned_name,30)}\n"
      end
    end
  end

  def formatted_timetable_cell_2(tt,emp)
    ## Produces view for one particular timetable entry cell
    unless tt.blank?
      unless tt.subject.blank?
        unless tt.entry_type == 'Subject'
          sub=tt.assigned_subjects.select{|s| s.employees.include?(emp)}
          "#{shorten_string(tt.assigned_name,30)}\n" unless sub.empty?
        else
          "#{shorten_string(tt.assigned_name,30)}\n"
        end
      end
    end
  end

  def subject_name(tt)
    ## Produces view for one particular timetable entry cell
    unless tt.blank?
      unless tt.entry.blank?
        "#{tt.entry.name}\n"
      end
    end
  end

  def timetable_batch(tt)
    ## Produces view for one particular timetable entry cell
    unless tt.blank?
      unless tt.batch.blank?
        "#{shorten_string(tt.batch.full_name,50)}"
      end
    end
  end

  def employee_name(tt)
    ## Produces view for one particular timetable entry cell
    unless tt.blank?
      unless tt.employees.blank?
        "#{tt.employee.first_name}"
      end
    end
  end

  def employee_full_name(tt)
    ## Produces view for one particular timetable entry cell
    unless tt.blank?
      unless tt.employee.blank?
        "#{tt.employee.full_name}"
      end
    end
  end

  def split_str(str, len)
    fragment = /.{#{len}}/
    str.split(/(\s+)/).map! { |word|
      (/\s/ === word) ? word : word.gsub(fragment, '\0<wbr></wbr>')
    }.join
  end
  
  def subject_name_by_settings(object, config_value)
    name_value = ""
    if object.is_a?(Subject)
      case config_value
      when "2"
        name_value = shorten_string(object.code,33)
      when "3"
        name_length = 33 - (object.code.length+3)
        name_value = shorten_string(object.name, name_length) + " (&rlm;" + object.code + ")"      
      when "4"
        name_length = 33 - (object.code.length+3)
        name_value = object.code + " (&rlm;" + shorten_string(object.name, name_length) + ")"
      else ## "1" is default, i.e. subject name
        name_value = shorten_string(object.name,33)
      end
    else
      name_value = shorten_string(object.name,33)
    end
    name_value
  end
  
end