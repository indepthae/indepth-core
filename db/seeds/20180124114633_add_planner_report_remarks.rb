RemarkSetting.reset_column_information
[
  {:target=>'gradebook_plan_report',:parameters=>["assessment_plan_id","student_id"],:remark_type=>"multiple",:general => true,:load_model=>"assessment_plan"}
].each do |param|
  RemarkSetting.find_or_create_by_target(param)
end