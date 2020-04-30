 student_model = ExportStructure.find_by_model_name('student')
 unless student_model.nil?
    student_model.csv_header_order.insert(1,"roll_number") unless student_model.csv_header_order.include?("roll_number")
    student_model.save
 end


 attendance_model = ExportStructure.find_by_model_name('attendance')
 unless attendance_model.nil?
    attendance_model.csv_header_order.insert(1,"roll_number") unless attendance_model.csv_header_order.include?("roll_number")
    attendance_model.save
 end



 exam_score_model = ExportStructure.find_by_model_name('exam_score')
 unless exam_score_model.nil?
    exam_score_model.csv_header_order.insert(1,"roll_number") unless exam_score_model.csv_header_order.include?("roll_number")
    exam_score_model.save
 end