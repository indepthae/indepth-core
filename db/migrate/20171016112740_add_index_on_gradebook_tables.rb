class AddIndexOnGradebookTables < ActiveRecord::Migration
  def self.up
    add_index :assessment_plans, [:academic_year_id]
    add_index :assessment_plans_courses, [:assessment_plan_id]
    add_index :assessment_plans_courses, [:course_id]
    add_index :assessment_terms, [:assessment_plan_id]
    add_index :assessment_groups, [:type]
    add_index :assessment_groups, [:parent_id, :parent_type]
    add_index :assessment_groups, [:assessment_activity_profile_id]
    add_index :assessment_groups, [:grade_set_id]
    add_index :assessment_groups, [:assessment_attribute_profile_id]
    add_index :assessment_groups, [:assessment_plan_id]
    add_index :assessment_groups, [:academic_year_id]
    add_index :assessment_groups, [:is_final_term]
    add_index :assessment_schedules, [:assessment_group_id]
    add_index :assessment_schedules, [:course_id]
    add_index :assessment_schedules, [:schedule_created]
    add_index :subject_assessments, [:assessment_group_batch_id]
    add_index :subject_assessments, [:subject_id]
    add_index :subject_assessments, [:elective_group_id]
    add_index :subject_assessments, [:marks_added]
    add_index :assessment_activities, [:assessment_activity_profile_id]
    add_index :grade_sets, [:direct_grade]
    add_index :grades, [:grade_set_id]
    add_index :assessment_attributes, [:assessment_attribute_profile_id]
    add_index :assessment_group_batches, [:assessment_group_id]
    add_index :assessment_group_batches, [:batch_id]
    add_index :assessment_group_batches, [:course_id]
    add_index :assessment_group_batches, [:marks_added]
    add_index :activity_assessments, [:assessment_group_batch_id]
    add_index :activity_assessments, [:assessment_activity_profile_id]
    add_index :activity_assessments, [:assessment_activity_id]
    add_index :activity_assessments, [:marks_added]
    add_index :assessment_schedules_batches, [:assessment_schedule_id]
    add_index :assessment_schedules_batches, [:batch_id]
    add_index :attribute_assessments, [:assessment_group_batch_id]
    add_index :attribute_assessments, [:subject_id]
    add_index :attribute_assessments, [:assessment_attribute_profile_id]
    add_index :attribute_assessments, [:assessment_attribute_id]
    add_index :attribute_assessments, [:marks_added]
    add_index :batches, [:academic_year_id]
    add_index :assessment_marks, [:student_id]
    add_index :assessment_marks, [:assessment_id, :assessment_type]
    add_index :assessment_marks, [:grade_id]
    add_index :assessment_report_settings, [:assessment_plan_id]
    add_index :derived_assessment_group_settings, [:derived_assessment_group_id], :name => 'index_on_derived_assessment_group_id'
    add_index :converted_assessment_marks, [:markable_id, :markable_type], :name => 'index_on_different_assessments'
    add_index :converted_assessment_marks, [:assessment_group_batch_id]
    add_index :converted_assessment_marks, [:assessment_group_id]
    add_index :converted_assessment_marks, [:student_id]
    add_index :individual_reports, [:reportable_id, :reportable_type]
    add_index :individual_reports, [:student_id]
    add_index :individual_reports, [:generated_report_batch_id]
    add_index :generated_reports, [:report_id, :report_type]
    add_index :generated_reports, [:course_id]
    add_index :generated_report_batches, [:generated_report_id]
    add_index :generated_report_batches, [:batch_id]
    add_index :generated_report_batches, [:generation_status]
    add_index :derived_assessment_groups_associations, [:derived_assessment_group_id], :name => 'index_on_derived_assessment_group_id'
    add_index :derived_assessment_groups_associations, [:assessment_group_id], :name => 'index_on_assessment_group_id'
  end

  def self.down
    remove_index :assessment_plans, [:academic_year_id]
    remove_index :assessment_plans_courses, [:assessment_plan_id]
    remove_index :assessment_plans_courses, [:course_id]
    remove_index :assessment_terms, [:assessment_plan_id]
    remove_index :assessment_groups, [:type]
    remove_index :assessment_groups, [:parent_id, :parent_type]
    remove_index :assessment_groups, [:assessment_activity_profile_id]
    remove_index :assessment_groups, [:grade_set_id]
    remove_index :assessment_groups, [:assessment_attribute_profile_id]
    remove_index :assessment_groups, [:assessment_plan_id]
    remove_index :assessment_groups, [:academic_year_id]
    remove_index :assessment_groups, [:is_final_term]
    remove_index :assessment_schedules, [:assessment_group_id]
    remove_index :assessment_schedules, [:course_id]
    remove_index :assessment_schedules, [:schedule_created]
    remove_index :subject_assessments, [:assessment_group_batch_id]
    remove_index :subject_assessments, [:subject_id]
    remove_index :subject_assessments, [:elective_group_id]
    remove_index :subject_assessments, [:marks_added]
    remove_index :assessment_activities, [:assessment_activity_profile_id]
    remove_index :grade_sets, [:direct_grade]
    remove_index :grades, [:grade_set_id]
    remove_index :assessment_attributes, [:assessment_attribute_profile_id]
    remove_index :assessment_group_batches, [:assessment_group_id]
    remove_index :assessment_group_batches, [:batch_id]
    remove_index :assessment_group_batches, [:course_id]
    remove_index :assessment_group_batches, [:marks_added]
    remove_index :activity_assessments, [:assessment_group_batch_id]
    remove_index :activity_assessments, [:assessment_activity_profile_id]
    remove_index :activity_assessments, [:assessment_activity_id]
    remove_index :activity_assessments, [:marks_added]
    remove_index :assessment_schedules_batches, [:assessment_schedule_id]
    remove_index :assessment_schedules_batches, [:batch_id]
    remove_index :attribute_assessments, [:assessment_group_batch_id]
    remove_index :attribute_assessments, [:subject_id]
    remove_index :attribute_assessments, [:assessment_attribute_profile_id]
    remove_index :attribute_assessments, [:assessment_attribute_id]
    remove_index :attribute_assessments, [:marks_added]
    remove_index :batches, [:academic_year_id]
    remove_index :assessment_marks, [:student_id]
    remove_index :assessment_marks, [:assessment_id, :assessment_type]
    remove_index :assessment_marks, [:grade_id]
    remove_index :assessment_report_settings, [:assessment_plan_id]
    remove_index :derived_assessment_group_settings, :name => 'index_on_derived_assessment_group_id'
    remove_index :converted_assessment_marks, :name => 'index_on_different_assessments'
    remove_index :converted_assessment_marks, [:assessment_group_batch_id]
    remove_index :converted_assessment_marks, [:assessment_group_id]
    remove_index :converted_assessment_marks, [:student_id]
    remove_index :individual_reports, [:reportable_id, :reportable_type]
    remove_index :individual_reports, [:student_id]
    remove_index :individual_reports, [:generated_report_batch_id]
    remove_index :generated_reports, [:report_id, :report_type]
    remove_index :generated_reports, [:course_id]
    remove_index :generated_report_batches, [:generated_report_id]
    remove_index :generated_report_batches, [:batch_id]
    remove_index :generated_report_batches, [:generation_status]
    remove_index :derived_assessment_groups_associations, :name => 'index_on_derived_assessment_group_id'
    remove_index :derived_assessment_groups_associations, :name => 'index_on_assessment_group_id'
  end
end
