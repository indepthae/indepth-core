class AddIndexToHrTables < ActiveRecord::Migration

  MODEL_LIST = [PayrollCategory, PayrollGroup]
  COLUMNS_LIST = {"PayrollCategory"=>{"entry"=>"code","index_name"=>"pc_code_unique_index"},
    "PayrollGroup"=>{"entry"=>"name","index_name"=>"pg_name_unique_index"}
  }
  
  def self.up
    add_index :employee_payslips, [:employee_id, :employee_type]
    add_index :employee_payslips, [:is_approved, :is_rejected]
    add_index :employee_payslips, [:is_rejected]
    add_index :employee_payslips, [:is_approved]
    add_index :employee_payslips, [:payslips_date_range_id]
    add_index :employee_payslips, [:payslips_date_range_id, :employee_id, :employee_type], :unique => true, :name => "employee_payslip_uniqueness"
    add_index :payslips_date_ranges, [:payroll_group_id]
    add_index :payslips_date_ranges, [:start_date]
    add_index :payslips_date_ranges, [:end_date]
    add_index :payslips_date_ranges, [:start_date, :end_date]
    add_index :payslips_date_ranges, [:payroll_group_id, :start_date, :end_date], :unique => true, :name => "date_range_unique_within_payroll_group"
    add_index :employee_salary_structures, [:employee_id]
    add_index :employee_salary_structures, [:payroll_group_id]
    add_index :employee_additional_leaves, [:employee_id]
    add_index :employee_additional_leaves, [:employee_leave_type_id]
    add_index :leave_reset_logs, [:employee_id]
    add_index :leave_reset_logs, [:leave_reset_id]
    add_index :payroll_groups_payroll_categories, [:payroll_group_id]
    add_index :payroll_groups_payroll_categories, [:payroll_category_id]
    add_index :hr_formulas, [:formula_id, :formula_type]
    add_index :formula_and_conditions, [:hr_formula_id]
    add_index :payroll_group_revisions, [:payroll_group_id]
    add_index :individual_payslip_categories, [:employee_payslip_id]
    add_index :individual_payslip_categories, [:employee_id]
    add_index :employee_salary_structure_components, [:employee_salary_structure_id], :name => 'by_structure_id'
    add_index :employee_salary_structure_components, [:payroll_category_id],:name => 'by_cat_id'
    add_index :employee_payslips, [:finance_transaction_id]
    add_index :employee_payslip_categories, [:employee_payslip_id]
    add_index :employee_payslip_categories, [:payroll_category_id]
    add_index :employee_lops, [:payroll_group_id]
    add_index :employee_attendances, [:apply_leave_id]
    add_index :employee_attendances, [:employee_id]
    add_index :employee_attendances, [:employee_leave_type_id]
    MODEL_LIST.each do |model|
      if (MultiSchool rescue false)
        model.reset_column_information
        unless model.column_names.include?("school_id")
          add_column model.table_name.to_sym,:school_id,:integer
          add_index model.table_name.to_sym,:school_id
        end
        add_index model.table_name.to_sym,[COLUMNS_LIST["#{model}"]["entry"].to_sym,:school_id],:unique=>true, :name=>COLUMNS_LIST["#{model}"]["index_name"].to_sym
      else
        add_index model.table_name.to_sym,COLUMNS_LIST["#{model}"]["entry"].to_sym,:unique=>true, :name=>COLUMNS_LIST["#{model}"]["index_name"].to_sym
      end
    end
  end

  def self.down
    remove_index :employee_payslips, [:employee_id, :employee_type]
    remove_index :employee_payslips, [:is_approved, :is_rejected]
    remove_index :employee_payslips, [:is_rejected]
    remove_index :employee_payslips, [:is_approved]
    remove_index :employee_payslips, [:payslips_date_range_id]
    remove_index :employee_payslips, [:payslips_date_range_id, :employee_id, :employee_type], :unique => true, :name => "employee_payslip_uniqueness"
    remove_index :payslips_date_ranges, [:payroll_group_id]
    remove_index :payslips_date_ranges, [:start_date]
    remove_index :payslips_date_ranges, [:end_date]
    remove_index :payslips_date_ranges, [:start_date, :end_date]
    remove_index :payslips_date_ranges, [:payroll_group_id, :start_date, :end_date], :unique => true, :name => "date_range_unique_within_payroll_group"
    remove_index :employee_salary_structures, [:employee_id]
    remove_index :employee_salary_structures, [:payroll_group_id]
    remove_index :employee_additional_leaves, [:employee_id]
    remove_index :employee_additional_leaves, [:employee_leave_type_id]
    remove_index :leave_reset_logs, [:employee_id]
    remove_index :leave_reset_logs, [:leave_reset_id]
    remove_index :payroll_groups_payroll_categories, [:payroll_group_id]
    remove_index :payroll_groups_payroll_categories, [:payroll_category_id]
    remove_index :hr_formulas, [:formula_id, :formula_type]
    remove_index :formula_and_conditions, [:hr_formula_id]
    remove_index :payroll_group_revisions, [:payroll_group_id]
    remove_index :individual_payslip_categories, [:employee_payslip_id]
    remove_index :individual_payslip_categories, [:employee_id]
    remove_index :employee_salary_structure_components,:name => 'by_structure_id'
    remove_index :employee_salary_structure_components,:name => 'by_cat_id'
    remove_index :employee_payslips, [:finance_transaction_id]
    remove_index :employee_payslip_categories, [:employee_payslip_id]
    remove_index :employee_payslip_categories, [:payroll_category_id]
    remove_index :employee_lops, [:payroll_group_id]
    remove_index :employee_attendances, [:apply_leave_id]
    remove_index :employee_attendances, [:employee_id]
    remove_index :employee_attendances, [:employee_leave_type_id]
    remove_index :payroll_categories, [:code, :school_id], :unique=>true
    remove_index :payroll_groups, [:name, :school_id], :unique=>true


  end
end
