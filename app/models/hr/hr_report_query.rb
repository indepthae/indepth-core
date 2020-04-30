class HrReportQuery
  attr_reader :name, :select, :joins, :conditions, :include, :group, :order

  QUERY_OPTIONS = [
    {
      :name => :pay_period,
      :joins => "INNER JOIN payslips_date_ranges ON payslips_date_ranges.id = employee_payslips.payslips_date_range_id",
      :conditions => "payslips_date_ranges.start_date = ? AND payslips_date_ranges.end_date = ?"
    },
    {
      :name => :date_range,
      :joins => :pay_frequency,
      :conditions => "payslips_date_ranges.start_date BETWEEN ? AND ?",
      :select =>  "CONCAT(payslips_date_ranges.start_date , ',', payslips_date_ranges.end_date) AS payslip_range, payroll_groups.payment_period",
      :order => "payslips_date_ranges.start_date, payslips_date_ranges.end_date"
    },
    {
      :name => :employee,
      :conditions => "employee_payslips.employee_id = ? AND employee_payslips.employee_type = ?"
    },
    {
      :name => :pay_period_multiple,
      :select => "CONCAT(payslips_date_ranges.start_date,',',payslips_date_ranges.end_date) AS pay_period, employee_payslips.payslips_date_range_id",
      :joins => :pay_period,
      :conditions => "CONCAT(payslips_date_ranges.start_date,',',payslips_date_ranges.end_date) IN (?)",
      :include => :employee,
      :order => "payslips_date_ranges.start_date, payslips_date_ranges.end_date"
    },
    #######
    {
      :name => :employee_department,
      :joins => "INNER JOIN ((SELECT id AS emp_id, first_name, last_name, middle_name, employee_number, employee_department_id, employee_category_id, employee_position_id, employee_grade_id, 'Employee' AS emp_type from employees) UNION ALL (SELECT id AS emp_id,first_name, last_name, middle_name, employee_number, employee_department_id, employee_category_id, employee_position_id, employee_grade_id, 'ArchivedEmployee' AS emp_type from archived_employees)) emp ON emp.emp_id=employee_payslips.employee_id AND employee_type = emp_type",
      :conditions => "emp.employee_department_id IN (?)",
      :order => "emp.first_name"
    },
    {
      :name => :employee_category,
      :joins => :employee_department,
      :conditions => "emp.employee_category_id IN (?)",
      :order => :employee_department
    },
    {
      :name => :employee_position,
      :joins => :employee_department,
      :conditions => "emp.employee_position_id IN (?)",
      :order => :employee_department
    },
    {
      :name => :payroll_group,
      :joins => :pay_period,
      :conditions => "payslips_date_ranges.payroll_group_id IN (?)",
      :order => "payslips_date_ranges.start_date, payslips_date_ranges.end_date"
    },
    {
      :name => :pay_frequency,
      :joins => [:pay_period, "INNER JOIN payroll_groups ON payroll_groups.id = payslips_date_ranges.payroll_group_id"],
      :conditions => "payroll_groups.payment_period IN (?)",
      :order => "payslips_date_ranges.start_date, payslips_date_ranges.end_date"
    },
    {
      :name => :with_lop,
      :conditions => "lop IS NOT NULL"
    },
    {
      :name => :without_lop,
      :conditions => "lop IS NULL"
    },
    #######
    {
      :name => :employee_name,
      :joins => :employee_department,
      :select => "CONCAT(emp.first_name, ' ', emp.last_name) AS employee_name",
      :order => :employee_department
    },
    {
      :name => :employee_number,
      :joins => :employee_department,
      :select => "emp.employee_number",
      :order => :employee_department
    },
    {
      :name => :employee_department_name,
      :joins => [:employee_department, "INNER JOIN employee_departments ON employee_departments.id = emp.employee_department_id"],
      :select => "employee_departments.name AS employee_department_name",
      :order => :employee_department
    },
    {
      :name => :employee_category_name,
      :joins => [:employee_department, "INNER JOIN employee_categories ON employee_categories.id = emp.employee_category_id"],
      :select => "employee_categories.name AS employee_category_name",
      :order => :employee_department
    },
    {
      :name => :employee_position_name,
      :joins => [:employee_department, "INNER JOIN employee_positions ON employee_positions.id = emp.employee_position_id"],
      :select => "employee_positions.name AS employee_position_name",
      :order => :employee_department
    },
    {
      :name => :employee_grade_name,
      :joins => [:employee_department, "LEFT OUTER JOIN employee_grades ON employee_grades.id = emp.employee_grade_id"],
      :select => "employee_grades.name AS employee_grade_name",
      :order => :employee_department
    },
    {
      :name => :additional_details,
      :include => {:employee => :employee_additional_details}
    },
    {
      :name => :bank_details,
      :include => {:employee => :employee_bank_details}
    },
    {
      :name => :additional_and_bank_details,
      :include => {:employee => [:employee_additional_details, :employee_bank_details]}
    },
    {
      :name => :date_range_text,
      :include => {:payslips_date_range => :payroll_group}
    },
    {
      :name => :payslip_categories,
      :include => :employee_payslip_categories
    },
    {
      :name => :other_earnings,
      :include => :individual_payslip_categories
    },
    {
      :name => :other_deductions,
      :include => :other_earnings
    },
    {
      :name => :total_earnings,
      :include => [:payslip_categories, :other_earnings]
    },
    {
      :name => :total_deductions,
      :include => :total_earnings
    },
    {
      :name => :salary_summary,
      :include => {:employee_payslip_categories => :payroll_category}
    },
    {
      :name => :employee_department_type,
      :select => "emp.employee_department_id AS id, employee_departments.name AS name",
      :joins => [:employee_department_name, "INNER JOIN employee_payslip_categories ON employee_payslip_categories.employee_payslip_id = employee_payslips.id"],
      :group => "employee_payslips.id",
      :order => :employee_department
    },
    {
      :name => :employee_category_type,
      :select => "emp.employee_category_id AS id, employee_categories.name AS name",
      :joins => [:employee_category_name, "INNER JOIN employee_payslip_categories ON employee_payslip_categories.employee_payslip_id = employee_payslips.id"],
      :group => "employee_payslips.id",
      :order => :employee_department
    },
    {
      :name => :employee_position_type,
      :select => "emp.employee_position_id AS id, employee_positions.name AS name",
      :joins => [:employee_position_name, "INNER JOIN employee_payslip_categories ON employee_payslip_categories.employee_payslip_id = employee_payslips.id"],
      :group => "employee_payslips.id",
      :order => :employee_department
    },
    {
      :name => :payroll_group_type,
      :select => "payroll_groups.id AS id, payroll_groups.name AS name",
      :joins => [:pay_frequency, "INNER JOIN employee_payslip_categories ON employee_payslip_categories.employee_payslip_id = employee_payslips.id"],
      :group => "employee_payslips.id",
      :order => "payslips_date_ranges.start_date, payslips_date_ranges.end_date"
    },
    {
      :name => :pay_frequency_type,
      :select => "payroll_groups.payment_period AS id, payroll_groups.payment_period AS name",
      :joins => [:pay_frequency, "INNER JOIN employee_payslip_categories ON employee_payslip_categories.employee_payslip_id = employee_payslips.id"],
      :group => "employee_payslips.id",
      :order => "payslips_date_ranges.start_date, payslips_date_ranges.end_date"
    },
    ######
    {
      :name => :employee_department_filter,
      :select => "emp.employee_department_id AS id, employee_departments.name AS name",
      :joins => :employee_department_name,
      :group => "employee_departments.id",
      :order => :employee_department
    },
    {
      :name => :employee_category_filter,
      :select => "emp.employee_category_id AS id, employee_categories.name AS name",
      :joins => :employee_category_name,
      :group => "employee_categories.id",
      :order => :employee_department
    },
    {
      :name => :payroll_group_filter,
      :select => "payroll_groups.id AS id, payroll_groups.name AS name",
      :joins => :pay_frequency,
      :group => "payroll_groups.id",
      :order => "payslips_date_ranges.start_date, payslips_date_ranges.end_date"
    },
    {
      :name => :pay_frequency_filter,
      :select => "payroll_groups.id AS id, payroll_groups.payment_period AS name",
      :joins => :pay_frequency,
      :group => "payroll_groups.payment_period",
      :order => "payslips_date_ranges.start_date, payslips_date_ranges.end_date"
    },
    {
      :name => :employee_type_filter,
      :select => "IF(lop IS NULL, 0, 1) lop_exist",
      :group => "lop_exist"
    },
  ]

  PAYROLL_QUERY = [
    {
      :name => :employee_name,
      :joins => "INNER JOIN employees ON employees.id = employee_salary_structures.employee_id",
      :select => "CONCAT(employees.first_name, ' ', employees.last_name) AS employee_name",
      :order => "employees.first_name"
    },
    {
      :name => :employee_number,
      :joins => :employee_name,
      :select => "employees.employee_number",
      :order => :employee_name
    },
    {
      :name => :employee_department_name,
      :joins => [:employee_name, "INNER JOIN employee_departments ON employee_departments.id = employees.employee_department_id"],
      :select => "employee_departments.name AS employee_department_name",
      :order => :employee_name
    },
    {
      :name => :employee_category_name,
      :joins => [:employee_name, "INNER JOIN employee_categories ON employee_categories.id = employees.employee_category_id"],
      :select => "employee_categories.name AS employee_category_name",
      :order => :employee_name
    },
    {
      :name => :employee_position_name,
      :joins => [:employee_name, "INNER JOIN employee_positions ON employee_positions.id = employees.employee_position_id"],
      :select => "employee_positions.name AS employee_position_name",
      :order => :employee_name
    },
    {
      :name => :employee_grade_name,
      :joins => [:employee_name, "LEFT OUTER JOIN employee_grades ON employee_grades.id = employees.employee_grade_id"],
      :select => "employee_grades.name AS employee_grade_name",
      :order => :employee_name
    },
    {
      :name => :additional_details,
      :include => {:employee => :employee_additional_details}
    },
    {
      :name => :bank_details,
      :include => {:employee => :employee_bank_details}
    },
    {
      :name => :additional_and_bank_details,
      :include => {:employee => [:employee_additional_details, :employee_bank_details]}
    },
    {
      :name => :employee_department_type,
      :select => "employees.employee_department_id AS id, employee_departments.name AS name, payroll_groups.payment_period",
      :joins => [:employee_department_name, :payroll_group_type],
      :group => "employee_departments.id",
      :order => "employee_departments.name"
    },
    {
      :name => :employee_category_type,
      :select => "employees.employee_category_id AS id, employee_categories.name AS name, payroll_groups.payment_period",
      :joins => [:employee_category_name, :payroll_group_type],
      :group => "employee_categories.id",
      :order => "employee_categories.name"
    },
    {
      :name => :employee_position_type,
      :select => "employees.employee_position_id AS id, employee_positions.name AS name, payroll_groups.payment_period",
      :joins => [:employee_position_name, :payroll_group_type],
      :group => "employee_positions.id",
      :order => "employee_positions.name"
    },
    {
      :name => :payroll_group_type,
      :select => "payroll_groups.id AS id, payroll_groups.name AS name, payroll_groups.payment_period",
      :joins => "INNER JOIN payroll_groups ON payroll_groups.id = employee_salary_structures.payroll_group_id",
      :group => "payroll_groups.id",
      :order => "payroll_groups.name"
    },
    {
      :name => :pay_frequency_type,
      :select => "payroll_groups.payment_period AS id, payroll_groups.payment_period AS name, payroll_groups.payment_period",
      :joins => :payroll_group_type,
      :group => "payroll_groups.payment_period",
      :order => "payroll_groups.payment_period"
    },
    {
      :name => :employee_department,
      :joins => :employee_name,
      :conditions => "employees.employee_department_id IN (?)",
      :order => :employee_name
    },
    {
      :name => :employee_category,
      :joins => :employee_name,
      :conditions => "employees.employee_category_id IN (?)",
      :order => :employee_name
    },
    {
      :name => :employee_position,
      :joins => :employee_name,
      :conditions => "employees.employee_position_id IN (?)",
      :order => :employee_name
    },
    {
      :name => :payroll_group,
      :conditions => "employee_salary_structures.payroll_group_id IN (?)"
    },
    {
      :name => :pay_frequency,
      :joins => :payroll_group_type,
      :conditions => "payroll_groups.payment_period IN (?)"
    },
    {
      :name => :employee_department_filter,
      :select => "employees.employee_department_id AS id, employee_departments.name AS name",
      :joins => :employee_department_name,
      :group => "employee_departments.id"
    },
    {
      :name => :employee_category_filter,
      :select => "employees.employee_category_id AS id, employee_categories.name AS name",
      :joins => :employee_category_name,
      :group => "employee_categories.id",
      :order => :employee_name
    },
    {
      :name => :payroll_group_filter,
      :select => "payroll_groups.id AS id, payroll_groups.name AS name",
      :joins => :payroll_group_type,
      :group => "payroll_groups.id"
    },
    {
      :name => :pay_frequency_filter,
      :select => "payroll_groups.id AS id, payroll_groups.payment_period AS name",
      :joins => :payroll_group_type,
      :group => "payroll_groups.payment_period"
    }
  ]

  MODELS = {:employee_payslip => ['payslip_report', 'payroll_category_wise_report', 'employee_payslip_report', 'comparison_report', 'overall_salary_report'], :employee_salary_structure => ['overall_estimation_report', 'employee_wise_estimation_report']}
  OVERALL_REPORT = {:employee_department_type => "EmployeeDepartment", :employee_category_type => 'EmployeeCategory', :employee_position_type => 'EmployeePosition', :payroll_group_type => 'PayrollGroup'}
  PaymentPeriodStruct = Struct.new(:id, :name)

  def initialize(*args)
    opts = args.extract_options!
    @name = opts[:name]
    @select = self.class.make_options(:select, opts[:select], opts[:payroll])
    @joins = self.class.make_options(:joins, opts[:joins], opts[:payroll])
    @conditions = self.class.make_options(:conditions, opts[:conditions], opts[:payroll])
    @include = self.class.make_options(:include, opts[:include], opts[:payroll])
    @group = self.class.make_options(:group, opts[:group], opts[:payroll])
    @order = self.class.make_options(:order, opts[:order], opts[:payroll])
  end

  class << self
    def find_by_name(name)
      query_options = QUERY_OPTIONS
      query_option = query_options.detect{|t| t[:name] == name.to_sym}
      new(query_option) if query_option
    end

    def all
      query_options = QUERY_OPTIONS
      all_list = []
      query_options.each{ |t| all_list << new(t)}
      all_list
    end

    def find_all_by_name(names)
      names = Array(names).flatten.compact.uniq
      all_list = []
      names.each{ |t| all_list << find_by_name(t)}
      all_list.compact
    end

    def make_options(option, value, payroll)
      option = option.to_sym
      values = []
      values << value
      result = []
      values.flatten.uniq.each do |val|
        if val.is_a? Symbol
          dep = unless payroll
            find_by_name(val)
          else
            find_payroll_by_name(val)
          end
          if dep.present?
            result << dep.send(option)
          else
            result << val
          end
        else
          result << val
        end
      end
      result.flatten.compact.uniq
    end

    def find_payroll_by_name(name)
      query_options = PAYROLL_QUERY
      query_option = query_options.detect{|t| t[:name] == name.to_sym}
      if query_option
        query_option[:payroll] = true
        new(query_option)
      end
    end

    def find_all_payroll_by_name(names)
      names = Array(names).flatten.compact.uniq
      all_list = []
      names.each{ |t| all_list << find_payroll_by_name(t)}
      all_list.compact
    end

    def fetch_result(report_name, page_no, inputs = {}, filters = {}, columns = [])
      model_name = get_model(report_name)
      columns << :employee_name if report_name.to_s == "comparison_report" and !(columns.map(&:to_s).include? :employee_name) and page_no != 'all'
      names = get_names(inputs) + get_names(filters) + get_names(columns)
      query_objects = find_all_by_name(names)
      select = ["#{model_name.table_name}.*"] + query_objects.collect(&:select)
      select = select.flatten.uniq.join(', ')
      joins = query_objects.collect(&:joins).flatten.uniq.join(' ')
      conditions = fetch_conditions(query_objects, inputs.merge(filters), true)
      include = query_objects.collect(&:include).flatten.uniq
      group = query_objects.collect(&:group).flatten.uniq
      if report_name.to_s == "comparison_report" and page_no != 'all'
        comp_select = select
        comp_group = Marshal.load(Marshal.dump(group))
        select = "employee_payslips.*, CONCAT(employee_payslips.employee_id, ',', employee_payslips.employee_type) AS employee_text, employee_payslips.payslips_date_range_id"
        group << "CONCAT(employee_payslips.employee_id, ',', employee_payslips.employee_type)"
      end
      order = query_objects.collect(&:order).flatten.uniq.join(', ')
      options = {:select => select, :joins => joins, :conditions => conditions, :include => include, :group => group.join(', '), :order => order}
      options.reject!{|k,v| !v.present?}
      result = if page_no == 'all'
        model_name.all(options)
      else
        options[:per_page] = 10
        options[:page] = page_no
        model_name.paginate(options)
      end
      if report_name.to_s == "comparison_report" and page_no != 'all'
        conditions[0] = conditions.first + "AND CONCAT(employee_payslips.employee_id, ',', employee_payslips.employee_type) IN (?)"
        conditions << result.collect(&:employee_text)
        options = {:select => comp_select, :joins => joins, :conditions => conditions, :include => include, :group => comp_group.join(', '), :order => order}
        options.reject!{|k,v| !v.present?}
        comp_result = model_name.all(options)
        columns.pop
        [result, comp_result]
      else
        result
      end
    end

    def fetch_overall_result(report_name, page_no, inputs = {}, filters = {}, columns = [])
      report_type = inputs[:report_type]
      model_name = get_model(report_name)
      filters = convert_filters(inputs, filters, page_no) unless page_no == 'all'
      names = get_names(inputs) + get_names(filters)
      query_objects = find_all_by_name(names)
      type_object = query_objects.detect{|obj| obj.name == report_type.to_sym}
      table_name = model_name.table_name
      assc_table_name = (table_name == "employee_payslips" ? "employee_payslip_categories" : "employee_salary_structure_components")
      select = get_overall_select_options(table_name, assc_table_name, type_object, columns)
      joins = query_objects.collect(&:joins).flatten.uniq.join(' ')
      conditions = fetch_overall_conditions(query_objects, inputs.merge(filters), table_name)
      group = query_objects.collect(&:group).flatten.uniq.join(', ')
      query = "SELECT #{select.last} FROM (SELECT #{select.first} FROM #{table_name} #{joins} WHERE #{conditions} GROUP BY #{group}) result GROUP BY id"
      ActiveRecord::Base.connection.execute(query).all_hashes
    end

    def fetch_totals(report_name, range, inputs = {}, filters ={}, columns = [])
      report_type = inputs[:report_type]
      model_name = get_model(report_name)
      table_name = model_name.table_name
      assc_table_name = (table_name == "employee_payslips" ? "employee_payslip_categories" : "employee_salary_structure_components")
      names = get_names(inputs) + get_names(filters) + get_names(columns)
      query_objects = unless ['overall_estimation_report', 'employee_wise_estimation_report'].include? report_name
        find_all_by_name(names)
      else
        find_all_payroll_by_name(names)
      end
      select = get_total_select_options(report_name, table_name, assc_table_name, columns)
      joins = query_objects.collect(&:joins).flatten.uniq
      joins << [(table_name == "employee_payslips" ? "INNER JOIN employee_payslip_categories ON employee_payslip_categories.employee_payslip_id = employee_payslips.id" : "INNER JOIN employee_salary_structure_components ON employee_salary_structure_components.employee_salary_structure_id = employee_salary_structures.id")] unless report_type.present?
      conditions = fetch_overall_conditions(query_objects, inputs.merge(filters), table_name)
      group = "#{table_name}.id"
      result_group = (report_name.to_sym == :comparison_report ? "GROUP BY payslip_range" :"")
      query = "SELECT #{select.last} FROM (SELECT #{select.first} FROM #{table_name} #{joins.join(' ')} WHERE #{conditions} GROUP BY #{group}) result #{result_group}"
      result = ActiveRecord::Base.connection.execute(query).all_hashes
      if ['overall_estimation_report', 'employee_wise_estimation_report'].include? report_name
        result.each{|l| l["net_pay"] = l["net_pay"].to_f * range.to_i ; l["gross_salary"] = l["gross_salary"].to_f * range.to_i}
      end
      result
    end

    def get_model(name)
      models = MODELS
      model = models.detect { |k, v|  v.include? name.to_s}
      model.first.to_s.camelize.constantize if model.present?
    end

    def get_names(values)
      names = []
      values.each do |val|
        if val.is_a? Array
          int = Integer(val.last) rescue nil
          names << ((val.last.is_a? Array or int) ? val.first : val.last)
        else
          if val == :additional_details || val.to_s.match("additional_detail_").present?
            names << :additional_details
          elsif val == :bank_details || val.to_s.match("bank_detail_").present?
            names << :bank_details
          elsif val == :earnings || val == :deductions || val.to_s.match("payroll_category_").present?
            names << :payslip_categories
          else
            names << val
          end
        end
      end
      names.uniq!
      if ((names.include? :additional_details) && (names.include? :bank_details))
        names.delete(:additional_details)
        names.delete(:bank_details)
        names.push(:additional_and_bank_details)
      end
      names
    end

    def fetch_conditions(objects, values, payslip)
      conditions = (payslip ? ["employee_payslips.is_approved = true"] : [])
      con_values = []
      objects.each do |obj|
        if obj.conditions.present?
          conditions << obj.conditions
          if [:date_range, :pay_period, :employee].include? obj.name
            con_values << values[obj.name.to_s].first << values[obj.name.to_s].last if values.has_key? obj.name.to_s
          else
            con_values << values[obj.name.to_s] if values.has_key? obj.name.to_s
          end
        end
      end
      [conditions.flatten.uniq.join(" AND ")] + con_values
    end

    def fetch_filter_value(report_name, filter, inputs)
      unless ['overall_estimation_report', 'employee_wise_estimation_report'].include? report_name
        model_name = get_model(report_name)
        names = get_names(inputs).push("#{filter}_filter")
        query_objects = find_all_by_name(names)
        select = query_objects.collect(&:select).flatten.uniq.join(', ')
        joins = query_objects.collect(&:joins).flatten.uniq.join(' ')
        conditions = fetch_conditions(query_objects, inputs, true)
        include = query_objects.collect(&:include).flatten.uniq
        group = query_objects.detect{|obj| obj.name == "#{filter}_filter".to_sym}.try(:group).flatten.uniq.join(', ')
        options = {:select => select, :joins => joins, :conditions => conditions, :include => include, :group => group}
        options.reject!{|k,v| !v.present?}
        result = model_name.all(options)
        case filter.to_sym
        when :pay_frequency
          result.map{|r| [PayrollGroup.payment_period_translation(r.name), r.name]}
        when :employee_type
          lop_exist = result.collect(&:lop_exist)
          values = [[I18n.t('all'), 'all']]
          values << [I18n.t('employees_with_lop'), 'with_lop'] if lop_exist.include? "1"
          values << [I18n.t('employees_without_lop'), 'without_lop'] if lop_exist.include? "0"
          values
        else
          result.map{|r| [r.name, r.id]}
        end
      else
        fetch_payroll_filter_value(report_name, filter, inputs)
      end
    end

    def get_overall_select_options(table_name, assc_table_name, type_object, columns)
      select = type_object.select
      grouped_select = ["id, name"]
      columns.each do|col|
        match = col.to_s.match("payroll_category_")
        if match.present?
          select << "SUM(IF(#{assc_table_name}.payroll_category_id = #{match.post_match}, #{assc_table_name}.amount, 0)) AS #{col.to_s}"
        elsif col.to_s == "no_of_lop"
          select << "#{table_name}.days_count AS no_of_lop"
        else
          select << "#{table_name}.#{col.to_s}"
        end
        grouped_select << "SUM(#{col.to_s}) AS #{col.to_s}"
      end
      [select.join(", "), grouped_select.join(", ")]
    end

    def get_total_select_options(report_name, table_name, assc_table_name, columns)
      unless report_name == "overall_estimation_report"
        select = (report_name.to_sym == :comparison_report ? ["CONCAT(payslips_date_ranges.start_date , ',', payslips_date_ranges.end_date) AS payslip_range"] :[])
        grouped_select = (report_name.to_sym == :comparison_report ? ["payslip_range"] :[])
        columns.each do|col|
          match = col.to_s.match("payroll_category_")
          if match.present?
            select << "SUM(IF(#{assc_table_name}.payroll_category_id = #{match.post_match}, #{assc_table_name}.amount, 0)) AS #{col.to_s}"
          else
            select << "#{table_name}.#{col.to_s} AS #{col.to_s}"
          end
          grouped_select << "SUM(#{col.to_s}) AS  #{col.to_s}"
        end
        [select.join(", "), grouped_select.join(", ")]
      else
        ["SUM(CASE WHEN payment_period = 1 THEN 30 * net_pay WHEN payment_period = 2 THEN 4 * net_pay WHEN payment_period = 3 || payment_period = 4 THEN 2 * net_pay ELSE net_pay END) AS net_pay, SUM(CASE WHEN payment_period = 1 THEN 30 * gross_salary WHEN payment_period = 2 THEN 4 * gross_salary WHEN payment_period = 3 || payment_period = 4 THEN 2 * gross_salary ELSE gross_salary END) AS gross_salary", "SUM(gross_salary) AS gross_salary, SUM(net_pay) AS net_pay" ]
      end
    end

    def fetch_overall_conditions(objects, values, table_name)
      con_values = fetch_conditions(objects, values, (table_name == "employee_payslips"))
      conditions = con_values.first
      con_values.shift
      conditions = unless conditions.match(/\?/).present?
        conditions
      else
        conditions.gsub!(/\?/).each_with_index{|k,i| ((con_values[i].is_a? Array) ? con_values[i].map{|l| "'#{l}'"}.join(',') : "'#{con_values[i]}'")}
      end
      school_cond = "#{table_name}.school_id = #{MultiSchool.current_school.id}"
      (conditions.present? ? "#{conditions} AND #{school_cond}" : school_cond)
    end

    def convert_filters(inputs, filters, page_no)
      report_type = inputs[:report_type]
      case report_type.to_sym
      when :pay_frequency_type
        pay_frequencies = PayrollGroup::PAYMENT_PERIOD.keys
        filters[:pay_frequency] = filters[:pay_frequency]||pay_frequencies
      else
        model_name = OVERALL_REPORT[report_type.to_sym]
        model = model_name.constantize
        field = model_name.underscore.to_sym
        ids = if filters.has_key? field
          model.paginate(:per_page => 10, :page => page_no, :conditions => ["id IN (?)", filters[field]]).collect(&:id)
        else
          model.paginate(:per_page => 10, :page => page_no).collect(&:id)
        end
        filters[field] = ids
      end
      filters
    end

    def get_paginate_values(inputs, filters, page_no)
      report_type = inputs[:report_type]
      case report_type.to_sym
      when :pay_frequency_type
        result = []
        val = if filters[:pay_frequency].present?
          PayrollGroup::PAYMENT_PERIOD.select { |k,v|  filters[:pay_frequency].include? k.to_s}
        else
          PayrollGroup::PAYMENT_PERIOD
        end
        val.each do |k,v|
          result << PaymentPeriodStruct.new(k, I18n.t(v))
        end
        unless page_no == 'all'
          result.paginate(:per_page => 10, :page => page_no, :order => "name")
        else
          result
        end
      else
        model_name = OVERALL_REPORT[report_type.to_sym]
        model = model_name.constantize
        field = model_name.underscore.to_sym
        unless page_no == 'all'
          result = if filters.has_key? field
            model.paginate(:per_page => 10, :page => page_no, :conditions => ["id IN (?)", filters[field]], :order => "name")
          else
            model.paginate(:per_page => 10, :page => page_no, :order => "name")
          end
        else
          result = if filters.has_key? field
            model.all(:conditions => ["id IN (?)", filters[field]], :order => "name")
          else
            model.all
          end
        end
        result
      end
    end

    def fetch_payroll_result(report_name, page_no, inputs = {}, filters = {}, columns = [])
      model_name = get_model(report_name)
      report_type = inputs[:report_type]
      range = inputs.delete(:range)
      names = get_names(inputs) + get_names(filters) + get_names(columns)
      query_objects = find_all_payroll_by_name(names)
      select = if report_name.to_s == 'overall_estimation_report'
        ["SUM(CASE WHEN payment_period = 1 THEN 30 * net_pay WHEN payment_period = 2 THEN 4 * net_pay  WHEN payment_period = 3 || payment_period = 4 THEN 2 * net_pay ELSE net_pay END) AS net_pay, SUM(CASE WHEN payment_period = 1 THEN 30 * gross_salary WHEN payment_period = 2 THEN 4 * gross_salary WHEN payment_period = 3 || payment_period = 4 THEN 2 * gross_salary ELSE gross_salary END) AS gross_salary"]
      else
        ["#{model_name.table_name}.*"]
      end
      select += query_objects.collect(&:select)
      select = select.flatten.uniq.join(', ')
      joins = query_objects.collect(&:joins).flatten.uniq.join(' ')
      conditions = fetch_conditions(query_objects, inputs.merge(filters), false)
      include = query_objects.collect(&:include).flatten.uniq
      group = if report_name.to_s == 'overall_estimation_report'
        query_objects.collect(&:group).flatten.uniq.join(', ')
      else
        query_objects.map{|o| o.group unless o.name == report_type.to_sym}.compact.flatten.uniq.join(', ')
      end
      order = query_objects.collect(&:order).flatten.uniq.join(', ')
      options = {:select => select, :joins => joins, :conditions => conditions, :include => include, :group => group, :order => order}
      options.reject!{|k,v| !v.present?}
      result = unless page_no == 'all'
        options[:per_page] = 10
        options[:page] = page_no
        model_name.paginate(options)
      else
        model_name.all(options)
      end
      result.each{|l| l.net_pay = l.net_pay.to_f * range.to_i ; l.gross_salary = l.gross_salary.to_f * range.to_i}
    end

    def fetch_payroll_filter_value(report_name, filter, inputs)
      model_name = get_model(report_name)
      names = get_names(inputs).push("#{filter}_filter")
      query_objects = find_all_payroll_by_name(names)
      select = query_objects.collect(&:select).flatten.uniq.join(', ')
      joins = query_objects.collect(&:joins).flatten.uniq.join(' ')
      conditions = fetch_conditions(query_objects, inputs, false)
      include = query_objects.collect(&:include).flatten.uniq
      group = query_objects.detect{|obj| obj.name == "#{filter}_filter".to_sym}.try(:group).flatten.uniq.join(', ')
      options = {:select => select, :joins => joins, :conditions => conditions, :include => include, :group => group}
      options.reject!{|k,v| !v.present?}
      result = model_name.all(options)
      case filter.to_sym
      when :pay_frequency
        result.map{|r| [PayrollGroup.payment_period_translation(r.name), r.name]}
      else
        result.map{|r| [r.name, r.id]}
      end
    end

    def fetch_group_count(report_name, inputs, filters, range = nil)
      model_name = get_model(report_name)
      report_type = inputs[:report_type]
      table_name = model_name.table_name
      names = get_names(inputs) + get_names(filters)
      query_objects = unless report_name == 'employee_wise_estimation_report'
        find_all_by_name(names)
      else
        find_all_payroll_by_name(names)
      end
      type_object = query_objects.detect{|obj| obj.name == report_type.to_sym} if report_type.present?
      select = ((report_name == 'employee_wise_estimation_report') ? "SUM(gross_salary) AS total, #{type_object.select}" : "COUNT(employee_payslips.id) AS total, CONCAT(payslips_date_ranges.start_date , ',', payslips_date_ranges.end_date) AS name")
      joins = query_objects.collect(&:joins).flatten.uniq.join(' ')
      conditions = fetch_overall_conditions(query_objects, inputs.merge(filters), table_name)
      group = ((report_name == 'employee_wise_estimation_report') ? "#{type_object.group}" : "CONCAT(payslips_date_ranges.start_date , ',', payslips_date_ranges.end_date)")
      options = {:select => select, :joins => joins, :conditions => conditions, :group => group}
      options.reject!{|k,v| !v.present?}
      result = model_name.all(options)
      if report_name == 'employee_wise_estimation_report'
        result.each{|l| l.total = l.total.to_f * range.to_i}
      end
      result
    end
  end

end