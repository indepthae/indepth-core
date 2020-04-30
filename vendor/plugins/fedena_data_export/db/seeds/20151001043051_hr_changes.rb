cat_structure = ExportStructure.find_by_model_name 'payroll_category'
if cat_structure.present?
  data_exports = DataExport.find_by_sql("select * from data_exports where export_structure_id = #{cat_structure.id}")
  data_exports.each do |export|
    MultiSchool.current_school = School.find(export.school_id)
    export.destroy
  end
  cat_structure.destroy
end
