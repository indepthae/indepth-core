module StudentRollNumberHelper

  def find_student_alloted(current_values, student, err_msg)
    pre = current_values[student.id.to_s]
    x = current_values.select{|k,v| v == pre }.map{|i| i[0] }
    y = x.delete(student.id.to_s)
    return "#{t('roll_number_already_allotted_to')} #{Student.find(x.first.to_i).first_name}" unless x.empty?
    return "#{err_msg[student.id.to_s]}"
  end
  
end
