IcseWeightage.all.each do |iw|
  if iw.grade_type.nil?
    grade_type=iw.is_grade? ? "Grade" : "GradeAndMark"
    iw.update_attribute(:grade_type,grade_type)
  end
end