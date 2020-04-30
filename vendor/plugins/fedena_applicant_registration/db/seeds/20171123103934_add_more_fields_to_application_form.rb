schools = School.all
schools.each do|school|
  MultiSchool.current_school = school
  custom_forms = ApplicationSection.all
  if custom_forms.present?
    puts "Modifying application form for School #{school.id}"
    custom_forms.each do|form|
      form_section = form.section_fields
      personal_details_section = form_section.find{|a| a[:section_name]=="student_personal_details"}
      personal_details_section[:fields].find{|b| b[:field_name] == "last_name"}[:mandatory]=true
      personal_details_section[:fields].find{|b| b[:field_name] == "last_name"}[:show_field]=true
      last_field_order = personal_details_section[:fields].sort_by{|k| k[:field_order]}.last[:field_order].to_i
      [{:field_type=>"default",:show_field=>false,:field_name=>"student_category",:mandatory=>false},
       {:field_type=>"default",:show_field=>false,:field_name=>"religion",:mandatory=>false},
       {:field_type=>"default",:show_field=>false,:field_name=>"blood_group",:mandatory=>false},
       {:field_type=>"default",:show_field=>false,:field_name=>"birth_place",:mandatory=>false},
       {:field_type=>"default",:show_field=>false,:field_name=>"mother_tongue",:mandatory=>false}].each do|h|
       
        last_field_order = last_field_order + 1
        h[:field_order] = last_field_order.to_s
        personal_details_section[:fields] << h unless personal_details_section[:fields].find{|s| s[:field_name] == h[:field_name]}.present?
        
       end
       form.update_attributes(:section_fields=>form_section)
    end
  end
end