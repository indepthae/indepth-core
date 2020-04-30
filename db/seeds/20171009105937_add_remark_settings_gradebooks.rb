RemarkSetting.reset_column_information
[
  {:target=>'gradebook_term_report',:parameters=>["assessment_term_id","student_id"],:remark_type=>"multiple",:general => true,:load_model=>"assessment_term"},
  {:target=>'gradebook_exam_report',:parameters=>["assessment_group_id","student_id"],:remark_type=>"multiple",:general => true,:load_model=>"assessment_group"}
].each do |param|
  RemarkSetting.find_or_create_by_target(param)
end