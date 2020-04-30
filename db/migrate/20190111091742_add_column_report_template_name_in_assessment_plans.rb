class AddColumnReportTemplateNameInAssessmentPlans < ActiveRecord::Migration
  def self.up
    add_column :assessment_plans,  :report_template_name, :string
  end

  def self.down
    remove_column :assessment_plans, :report_template_name
  end
end
