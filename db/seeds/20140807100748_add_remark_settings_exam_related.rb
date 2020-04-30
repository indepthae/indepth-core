RemarkSetting.reset_column_information
[
  {:target=>'exam_wise',:parameters=>["exam_group_id","exam_id","student_id"],:remark_type=>"simple",:general => false,:load_model=>"subject", :table_name=>"exam_scores",:field_name=>"remarks"},
  {:target=>'grouped_exam_general',:parameters=>["batch_id","student_id"],:remark_type=>"multiple",:general => true,:load_model=>"batch"},
  {:target=>'student_transcript_general',:parameters=>["batch_id","student_id"],:remark_type=>"multiple",:general => true,:load_model=>"batch"},
  {:target=>'exam_wise_general',:parameters=>["exam_group_id","student_id"],:remark_type=>"multiple",:general => true,:load_model=>"batch"},
  {:target=>'student_transcript',:parameters=>["batch_id","student_id","subject_id"],:remark_type=>"simple",:general => false,:load_model=>"subject"},
  {:target=>'custom_remark',:parameters=>["batch_id","student_id"],:remark_type=>"multiple",:general => true}
].each do |param|
  RemarkSetting.find_or_create_by_target(param)
end