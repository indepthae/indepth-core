param = {"query"=>{"find_in_batches"=>{:include=>[{:leave_group_leave_types=>:employee_leave_type}, {:leave_group_employees=>:employee}], :batch_size=>10, :conditions=>{}}}, "model_name"=>"leave_group", "csv_header_order"=>["name", "description", "leave_types_count", "employees_count", "employee_leave_types"], "template"=>"/api/leave_groups/leave_groups_list.xml.erb"}
export_structure = ExportStructure.find_by_model_name(param["model_name"])
unless export_structure.present?
  export_strct = ExportStructure.new(param)
  export_strct.save
end
