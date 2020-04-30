class HrReportBaseTemplate
  attr_reader :name, :input_fields, :multi_select, :multi_select_filters, :filters, :columns, :default_columns, :templates

  TEMPLATES = [
    { :name => 'payslip_report',
      :input_fields => :pay_period_or_date_range,
      :filters => [:employee_department, :employee_category, :payroll_group, :employee_type],
      :multi_select_filters => [:employee_department, :employee_category, :payroll_group],
      :columns => [:employee_details, :payslip_details, :leave_type_detials],
      :default_columns => [:employee_name, :employee_number, :employee_department_name, :date_range_text, :total_earnings, :total_deductions, :net_pay],
      :templates => [:employee_department, :employee_category, :payroll_group, :employee_type]
    },
    {
      :name => 'payroll_category_wise_report',
      :input_fields => [:payroll_category, :pay_period_or_date_range],
      :multi_select => :payroll_category,
      :filters => [:employee_department, :employee_category, :payroll_group, :pay_frequency, :employee_type],
      :multi_select_filters => [:employee_department, :employee_category, :payroll_group, :pay_frequency],
      :columns => [:employee_details, :leave_type_detials],
      :default_columns => [:employee_name, :employee_number, :employee_department_name, :employee_category_name],
      :templates => [:employee_department, :employee_category, :payroll_group, :pay_frequency, :employee_type]
    },
    {
      :name => 'employee_payslip_report',
      :input_fields => [:employee_department_from_employee, :date_range],
      :columns => :payslip_details,
      :default_columns => [:date_range_text, :total_earnings, :total_deductions, :net_pay]
    },
    {
      :name => 'comparison_report',
      :input_fields => :pay_frequency_from_pay_period_multiple,
      :multi_select => :pay_period_multiple,
      :filters => [:employee_department, :employee_category, :payroll_group],
      :multi_select_filters => [:employee_department, :employee_category, :payroll_group],
      :columns => [:employee_details, :payslip_details],
      :default_columns => [:employee_name, :employee_number, :employee_department_name, :employee_category_name, :total_earnings, :total_deductions, :net_pay],
      :templates => [:employee_department, :employee_category, :payroll_group]
    },
    {
      :name => 'overall_salary_report',
      :input_fields => [:report_type, :pay_period_or_date_range],
      :filters => [:employee_department, :employee_category, :payroll_group, :pay_frequency],
      :multi_select_filters => [:employee_department, :employee_category, :payroll_group, :pay_frequency],
      :columns => :payslip_details,
      :default_columns => [:total_earnings, :total_deductions, :net_pay],
      :templates => [:employee_department, :employee_category, :payroll_group, :pay_frequency]
    },
    {
      :name => 'overall_estimation_report',
      :input_fields => [:report_type, :range],
      :filters => [:employee_department, :employee_category, :payroll_group, :pay_frequency],
      :multi_select_filters => [:employee_department, :employee_category, :payroll_group, :pay_frequency],
      :templates => [:employee_department, :employee_category, :payroll_group, :pay_frequency]
    },
    {
      :name => 'employee_wise_estimation_report',
      :input_fields => [:report_type, :range],
      :filters => [:employee_department, :employee_category, :payroll_group, :pay_frequency],
      :multi_select_filters => [:employee_department, :employee_category, :payroll_group, :pay_frequency],
      :columns => :employee_details,
      :default_columns => [:employee_name, :employee_number, :employee_department_name, :employee_category_name],
      :templates => [:employee_department, :employee_category, :payroll_group, :pay_frequency]
    }
  ]

  EMPLOYEE_COLUMNS = [:employee_name, :employee_number, :employee_department_name, :employee_category_name, :employee_position_name, :employee_grade_name]
  DETAILED_PAYSLIP_COLUMNS = [:date_range_text, :earnings, :other_earnings, :total_earnings, :deductions, :lop, :other_deductions, :total_deductions, :net_pay]
  SALARY_SUMMARY_COLUMNS = [:date_range_text, :salary_summary, :total_earnings, :total_deductions, :net_pay]
  PAYSLIP_TOTAL_COLUMNS = [:earnings, :total_earnings, :deductions, :lop, :total_deductions, :net_pay]
  LEAVE_DATA = [:no_of_working_days, :no_of_days_present, :leave_type_detials , :total_leave , :no_of_lop]
  DETAILED_OVERALL_REPORT_COLUMNS = [:earnings, :total_earnings, :deductions, :lop, :total_deductions, :net_pay, :no_of_lop]
  SUMMARY_OVERALL_REPORT_COLUMNS = [:total_earnings, :total_deductions, :net_pay]
  InputFieldStructure = Struct.new(:report_name, :name, :field_type, :multiselect, :child, :dependent, :dependent_field, :value)
  FilterStructure = Struct.new(:report_name, :name, :field_type, :value)
  
  def initialize(*args)
    opts = args.extract_options!
    @name = opts[:name]
    @input_fields = Array(opts[:input_fields]).flatten.uniq
    @multi_select = Array(opts[:multi_select]).flatten.uniq
    @filters = Array(opts[:filters]).flatten.uniq
    @multi_select_filters = Array(opts[:multi_select_filters]).flatten.uniq
    @columns = Array(opts[:columns]).flatten.uniq
    @default_columns = Array(opts[:default_columns]).flatten.uniq
    @templates = Array(opts[:templates]).flatten.uniq
  end

  def structify_inputs
    structures = []
    simplified_fields = convert_input_fields
    simplified_fields.each do |input_field|
      if input_field.is_a? Hash
        structures = structures + structify_each_input(input_field)
      else
        structures << structify_each_input(input_field)
      end
    end
    structures
  end

  def structify_filters(inputs)
    structures = []
    filters.each do |filter|
      structures << structify_each_filter(filter, inputs)
    end
    structures
  end

  def structify_template_filters(inputs, temp_filters)
    structures = []
    filters.each do |filter|
      structures << structify_each_filter(filter, inputs) unless temp_filters.include? filter.to_sym
    end
    structures
  end

  def structify_templates
    structures = []
    templates.each do |template|
      value = HrReport.send("fetch_#{template.to_s}_value")
      structures << FilterStructure.new(template.to_s, template.to_s, filter_type(template), value)
    end
    structures
  end

  def structify_each_input(input, dependent = false, dependent_field = nil)
    if input.is_a? Array
      structr = []
      input.each do |field|
        structr << structify_each_input(field)
      end
      return structr
    elsif input.is_a? Hash
      structr = []
      value = (dependent ? [] : HrReport.send("fetch_#{input.keys.first.to_s}_value"))
      structr << InputFieldStructure.new(name.to_s, input.keys.first.to_s, input_type(input.keys.first), is_multi_select?(input.keys.first), true, dependent, dependent_field, value)
      structr << structify_each_input(input.values.first, true, input.keys.first.to_s)
      return structr.flatten
    else
      value = (dependent ? [] : HrReport.send("fetch_#{input.to_s}_value"))
      structr = InputFieldStructure.new(name.to_s, input.to_s, input_type(input), is_multi_select?(input) , false, dependent, dependent_field, value)
      return structr
    end
  end

  def structify_each_filter(filter, inputs)
    value = HrReportQuery.send("fetch_filter_value", name.to_s, filter, inputs)
    FilterStructure.new(name.to_s, filter.to_s, filter_type(filter), value)
  end

  def structify_particular_input(input, child = false, dependent = false, dependent_field = nil, *args)
    value = HrReport.send("fetch_#{input.to_s}_value", args)
    [InputFieldStructure.new(name.to_s, input.to_s, input_type(input), is_multi_select?(input), child, dependent, dependent_field, value)]
  end


  def is_multi_select?(name)
    name.to_sym == :date_range ? false : (multi_select.include? name.to_sym)
  end

  def input_type(name)
    name.to_sym == :date_range ? 'date_range' : (multi_select.include? name.to_sym) ? 'multi_select' : 'select'
  end

  def filter_type(name)
    (multi_select_filters.include? name.to_sym) ? 'multi_select' : 'select'
  end

  def convert_input_fields
    temp = []
    input_fields.each do |input_field|
      temp << self.class.convert_name(input_field)
    end
    temp
  end

  class << self
    def find_by_name(name)
      templates = TEMPLATES
      template = templates.detect{|t| t[:name] == name}
      new(template) if template
    end

    def all
      templates = TEMPLATES
      all_list = []
      templates.each{ |t| all_list << new(t)}
      return all_list
    end

    def convert_name(name)
      match1 = name.to_s.match('_or_')
      match2 = name.to_s.match('_from_')
      if match1.nil? and match2.nil?
        return name.to_s
      elsif match1.nil?
        name = name.to_s.split('_from_', 2)
        return {name.first.to_s => convert_name(name.last)}
      else
        name = name.to_s.split('_or_')
        temp = []
        name.each do |n|
          temp << convert_name(n)
        end
        return temp
      end
    end
  end

end
