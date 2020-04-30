class StudentRollNumber

  def self.validate_if_roll_number_already_taken(stud_id, suffix, student_hash, batch_id)
    roll_number = suffix[:roll_number]
    in_student_hash = student_hash.select{|id, val| id != stud_id.to_s && val["roll_number"] == roll_number.to_s && val["roll_number"].present?}
    if in_student_hash.present?
      @err_msg[stud_id] = "Roll Number Already taken"
      @errors << stud_id
    end
  end

  def self.validate_roll_number (roll_number)
    student = Student.new
    student.roll_number = roll_number
    student.valid?
    student.errors['roll_number']
  end

  def self.save(roll_number_prefix, batch_id, student_hash)
    @errors = []
    @current_values = {}
    @err_msg = {}
    if student_hash.present?
      student_hash.each do |stud_id, suffix|
        @current_values[stud_id] = suffix[:roll_number]
        validate_if_roll_number_already_taken(stud_id, suffix, student_hash,batch_id)
      end
      if @errors.empty?
        ActiveRecord::Base.transaction do
          Student.update_all({:roll_number => nil},['batch_id = ?', "#{batch_id}"])
          students = Student.find_all_by_batch_id(batch_id)
          student_hash.each do |stud_id, suffix|
            stud_record = students.detect{|x| x.id.to_s == stud_id}
            stud_record.roll_number = roll_number_prefix + suffix[:roll_number]

            v_errors = validate_roll_number(stud_record.roll_number)
            @current_values[stud_id] = suffix[:roll_number]
            unless v_errors.blank?
              @errors << stud_id
              @err_msg[stud_id] = v_errors
            else
              stud_record.send :update_without_callbacks
            end

          end

          raise ActiveRecord::Rollback unless @errors.blank?

        end
      end
    end
  ensure
    return [] if @errors.empty?
    return [@errors,@current_values,@err_msg]
  end



end