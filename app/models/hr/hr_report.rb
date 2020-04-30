class HrReport < ActiveRecord::Base
  serialize :report_columns, Hash
  serialize :report_filters, Hash

  validates_presence_of :name, :report_name
  validates_uniqueness_of :name, :case_sensitive => false

  before_validation :strip_leading_spaces

  Result = Struct.new(:report_name, :row_grouping, :group_count, :column_grouping, :methods, :method_types, :header_title, :values, :grouped_values, :total, :group_values)

  def strip_leading_spaces
    self.name = self.name.strip
  end
  
  def get_template_filters(inputs = {})
    temp_filters = report_filters.keys.map(&:to_sym) if report_filters.present?
    base_template = HrReportBaseTemplate.find_by_name(report_name)
    input_values = self.class.reject_null_values(inputs||{})
    input_values = self.class.convert_input_values(input_values)
    input_values.delete(:payroll_category)
    filters = report_filters||{}
    base_template.structify_template_filters(input_values.merge(filters), temp_filters||{})
  end

  def remaining_filters
    temp_filters = (report_filters.present? ? report_filters.keys.map(&:to_sym) : [])
    base_filters = HrReportBaseTemplate.find_by_name(report_name).filters
    base_filters - temp_filters
  end

  def template_columns
    if report_columns
      columns = self.class.fetch_columns(report_columns)
      headers = self.class.get_table_headers(columns)
      cols = []
      columns.each{|c| cols << headers[c]}
      cols
    end
  end

  class << self

    def get_input_fields(name)
      base_template = HrReportBaseTemplate.find_by_name(name)
      base_template.structify_inputs
    end

    def get_filters(name, inputs = {})
      base_template = HrReportBaseTemplate.find_by_name(name)
      input_values = reject_null_values(inputs||{})
      input_values = convert_input_values(input_values)
      input_values.delete(:payroll_category)
      base_template.structify_filters(input_values)
    end

    def fetch_payroll_category_value
      active_categories = PayrollCategory.active.name_sorted.map{|cat| [cat.name, cat.id]}
      in_active_categories = PayrollCategory.in_active.name_sorted.map{|cat| [cat.name, cat.id]}
      others = [[t('lop'), 'lop'], [t('total_earning'), 'total_earnings'], [t('total_deduction'), 'total_deductions'], [t('net_pay'), 'net_pay']]
      {"Active categories" => active_categories, "Inactive categories" => in_active_categories, "Others" => others}
    end

    def fetch_employee_department_value
      EmployeeDepartment.active_and_ordered.map{|dep| [dep.name, dep.id]}
    end

    def fetch_employee_value(dept_id = nil)
      if dept_id.present?
        EmployeeDepartment.all(:select => "emp.*", :joins => "INNER JOIN ((SELECT id AS emp_id, first_name, last_name, employee_department_id, 'Employee' AS emp_type from employees) UNION ALL (SELECT id AS emp_id, first_name, last_name, employee_department_id, 'ArchivedEmployee' AS emp_type from archived_employees)) emp ON emp.employee_department_id = employee_departments.id", :conditions =>["employee_departments.id = ?", dept_id], :order => "emp.first_name").map{|e| ["#{e.first_name} #{e.last_name}", "#{e.emp_id},#{e.emp_type}"]}
      end
    end

    def fetch_report_type_value
      [[t('employee_department'), 'employee_department_type'], [t('employee_category'), 'employee_category_type'], [t('employee_position'), 'employee_position_type'], [t('payroll_group'), 'payroll_group_type'], [t('pay_frequency'), 'pay_frequency_type']]
    end

    def fetch_pay_period_value(pay_frequency = nil)
      date_ranges = if pay_frequency.present?
        PayslipsDateRange.all(:joins => :payroll_group, :conditions => ["payroll_groups.payment_period = ?",pay_frequency], :group => "start_date, end_date", :include => :payroll_group, :order => 'start_date desc')
      else
        PayslipsDateRange.all(:group => "start_date, end_date", :include => :payroll_group, :order => 'start_date desc')
      end
      date_ranges.map{|pdr| [pdr.date_range, "#{pdr.start_date},#{pdr.end_date}"]}
    end

    def fetch_pay_period_multiple_value(pay_frequency = nil)
      date_ranges = if pay_frequency.present?
        PayslipsDateRange.all(:joins => :payroll_group, :conditions => ["payroll_groups.payment_period = ?",pay_frequency], :group => "start_date, end_date", :include => :payroll_group, :order => 'start_date desc')
      else
        PayslipsDateRange.all(:group => "start_date, end_date", :include => :payroll_group, :order => 'start_date desc')
      end
      date_ranges.map{|pdr| [pdr.date_range, "#{pdr.start_date},#{pdr.end_date}"]}
    end

    def fetch_date_range_value
      [Date.today.beginning_of_month, Date.today.end_of_month]
    end

    def fetch_pay_frequency_value
      PayrollGroup::PAYMENT_PERIOD.map{|key, val| [t(val), key]}
    end

    def fetch_payroll_group_value
      PayrollGroup.ordered.map{|p| [p.name, p.id]}
    end

    def fetch_employee_type_value
      [[t('all'), 'all'], [t('employees_with_lop'), 'with_lop'], [t('employees_without_lop'), 'without_lop']]
    end

    def fetch_range_value
      [[t('datetime.distance_in_words.x_months', {:count => 1}), 1], [t('datetime.distance_in_words.x_months', {:count => 3}), 3], [t('datetime.distance_in_words.x_months', {:count => 6}), 6], [t('datetime.distance_in_words.x_years', {:count => 1}), 12]]
    end

    def fetch_employee_category_value
      EmployeeCategory.active_ordered.map{|p| [p.name, p.id]}
    end

    def get_header_value(field, klass, methods)
      klass.constantize.all.each_with_object({}){|pc, hsh| hsh["#{field}#{pc.id}"] = pc.name if methods.include? "#{field}#{pc.id}"}
    end

    def get_payslip_report(report_name, inputs = {}, filters = {}, columns = [], page_no = 1)
      input_values = reject_null_values(inputs||{})
      filter_values = reject_null_values(filters||{})
      input_values = convert_input_values(input_values)
      page_no = page_no||1
      base_template = HrReportBaseTemplate.find_by_name(report_name)
      column_values = fetch_columns(columns) if columns.present?
      column_values = convert_columns(base_template.default_columns) unless column_values.present?
      date_range_present = input_values.has_key?(:date_range)
      values = HrReportQuery.fetch_result(report_name, page_no, input_values, filter_values, column_values)
      set_additional_details(values, column_values)
      if date_range_present.present?
        grouped_values = values.group_by(&:payslip_range) 
        if grouped_values.present?
          filter_values[:pay_period_multiple] = grouped_values.keys
          group_count = HrReportQuery.fetch_group_count(report_name, input_values, filter_values)
        end
      end
      headers = get_table_headers(column_values)
      method_types = fetch_column_types(column_values)
      Result.new(report_name, date_range_present, group_count, [], column_values, method_types, headers, values, grouped_values)
    end

    def get_payroll_category_wise_report(report_name, inputs = {}, filters = {}, columns = {}, page_no = 1)
      input_values = reject_null_values(inputs||{})
      filter_values = reject_null_values(filters||{})
      input_values = convert_input_values(input_values)
      page_no = page_no||1
      base_template = HrReportBaseTemplate.find_by_name(report_name)
      column_values = fetch_columns(columns.except("leave_type_detials")) if columns.present?
      column_values = convert_columns(base_template.default_columns) unless column_values.present?
      column_values += input_values[:payroll_category]||[]
      column_values += fetch_columns(columns.slice("leave_type_detials")) if columns.present? and columns["leave_type_detials"].present?
      input_values.delete(:payroll_category)
      date_range_present = input_values.has_key?(:date_range)
      values = HrReportQuery.fetch_result(report_name, page_no, input_values, filter_values, column_values)
      set_additional_details(values, column_values)
      if date_range_present.present?
        grouped_values = values.group_by(&:payslip_range)
        if grouped_values.present?
          filter_values[:pay_period_multiple] = grouped_values.keys
          group_count = HrReportQuery.fetch_group_count(report_name, input_values, filter_values)
        end
      end
      headers = get_table_headers(column_values)
      method_types = fetch_column_types(column_values)
      Result.new(report_name, date_range_present, group_count, [], column_values, method_types, headers, values, grouped_values)
    end

    def get_employee_payslip_report(report_name, inputs = {}, filters = {}, columns = {}, page_no = 1)
      input_values = reject_null_values(inputs||{})
      input_values = convert_input_values(input_values)
      page_no = page_no||1
      base_template = HrReportBaseTemplate.find_by_name(report_name)
      column_values = fetch_columns(columns) if columns.present?
      column_values = convert_columns(base_template.default_columns) unless column_values.present?
      values = HrReportQuery.fetch_result(report_name, page_no, input_values, {}, column_values)
      set_additional_details(values, column_values)
      headers = get_table_headers(column_values)
      method_types = fetch_column_types(column_values)
      Result.new(report_name, false, [], [], column_values, method_types, headers, values)
    end

    def get_comparison_report(report_name, inputs = {}, filters = {}, columns = {}, page_no = 1)
      group_values = (inputs||{})[:pay_period_multiple].to_a
      input_values = reject_null_values(inputs||{})
      filter_values = reject_null_values(filters||{})
      input_values = convert_input_values(input_values)
      page_no = page_no||1
      base_template = HrReportBaseTemplate.find_by_name(report_name)
      column_values = fetch_columns(columns) if columns.present?
      column_values = convert_columns(base_template.default_columns) unless column_values.present?
      input_values.delete(:pay_frequency)
      input_values[:pay_period_multiple] = input_values[:pay_period_multiple].to_a
      values = HrReportQuery.fetch_result(report_name, page_no, input_values, filter_values, column_values)
      unless page_no == "all"
        pag_val = values.first
        values = values.last
      end
      grouped_columns = fetch_grouped_columns(column_values)
      set_additional_details(values, column_values)
      grouped_values = values.group_by(&:employee)
      grouped_values.each{|key, val| grouped_values[key] = val.group_by(&:pay_period)}
      headers = get_table_headers(column_values)
      method_types = fetch_column_types(column_values)
      Result.new(report_name, false, [], grouped_columns, column_values, method_types, headers, pag_val, grouped_values, nil,group_values)
    end

    def get_overall_salary_report(report_name, inputs = {}, filters = {}, columns = {}, page_no = 1)
      input_values = reject_null_values(inputs||{})
      filter_values = reject_null_values(filters||{})
      input_values = convert_input_values(input_values)
      page_no = page_no||1
      base_template = HrReportBaseTemplate.find_by_name(report_name)
      column_values = fetch_columns(columns) if columns.present?
      column_values = convert_columns(base_template.default_columns) unless column_values.present?
      values = HrReportQuery.fetch_overall_result(report_name, page_no, input_values, filter_values, column_values)
      values.each{|va| va["name"] = PayrollGroup.payment_period_translation(va["name"])} if inputs[:report_type] == "pay_frequency_type"
      column_values.unshift("name")
      headers = get_table_headers(column_values)
      method_types = fetch_column_types(column_values)
      Result.new(report_name, false, [], [], column_values, method_types, headers, values)
    end

    def get_overall_estimation_report(report_name, inputs = {}, filters = {}, columns = {}, page_no = 1)
      input_values = reject_null_values(inputs||{})
      filter_values = reject_null_values(filters||{})
      input_values = convert_input_values(input_values)
      page_no = page_no||1
      base_template = HrReportBaseTemplate.find_by_name(report_name)
      values = HrReportQuery.fetch_payroll_result(report_name, page_no, input_values, filter_values)
      values.each{|va| va.name = PayrollGroup.payment_period_translation(va.name)} if inputs[:report_type] == "pay_frequency_type"
      column_values = ["name", "gross_salary", "net_pay"]
      headers = get_table_headers(column_values)
      method_types = fetch_column_types(column_values)
      Result.new(report_name, false, [], [], column_values, method_types, headers, values)
    end

    def get_employee_wise_estimation_report(report_name, inputs = {}, filters = {}, columns = {}, page_no = 1)
      input_values = reject_null_values(inputs||{})
      filter_values = reject_null_values(filters||{})
      input_values = convert_input_values(input_values)
      page_no = page_no||1
      base_template = HrReportBaseTemplate.find_by_name(report_name)
      column_values = fetch_columns(columns) if columns.present?
      column_values = convert_columns(base_template.default_columns) unless column_values.present?
      p column_values
      range = input_values[:range]
      values = HrReportQuery.fetch_payroll_result(report_name, page_no, input_values, filter_values, column_values)
      column_values += ["gross_salary", "net_pay"]
      set_additional_details(values, column_values)
      headers = get_table_headers(column_values)
      grouped_values = values.group_by(&:name)
      group_count = HrReportQuery.fetch_group_count(report_name, input_values, filter_values, range)
      method_types = fetch_column_types(column_values)
      Result.new(report_name, true, group_count, [], column_values, method_types, headers, values, grouped_values)
    end

    def define_structure(args)
      Struct.new(*args)
    end

    def fetch_filter_values(values={})
      result = {}
      values.each do |key, value|
        if value.present?
          value = Array(value)
          filters_list = send("fetch_#{key.to_s}_value")
          res = filters_list.map{|l| l.first if value.include? l.last.to_s}.compact.join(", ")
          result[key.to_sym] = res
        end
      end
      result
    end

    def reject_null_values(values)
      if values.present?
        values.reject!{|k,v| !v.present?}
      end
      values
    end

    def convert_input_values(values)
      reject_null_values(values)
      if values.has_key? :pay_period and (values[:pay_period].is_a? String)
        values[:pay_period] = values[:pay_period].split(',')
      end
      if values.has_key? :start_date
        values[:date_range] = [values[:start_date], values[:end_date]]
        values.delete(:start_date)
        values.delete(:end_date)
      end
      if values.has_key? :payroll_category
        methods = values[:payroll_category].map{|p| ((Integer(p) rescue nil) ? "payroll_category_#{p}" : p)}
        values[:payroll_category] = methods
      end
      if values.has_key? :employee
        values[:employee] = values[:employee].split(',')
      end
      values
    end

    def fetch_columns(values)
      methods = []
      methods << values[:columns] if values.has_key? :columns
      if values.has_key? :payslip_details
        if values[:payslip_details].to_s == "true"
          methods << values[:payslip_columns] if values.has_key? :payslip_columns
        else
          methods << values[:summary_columns] if values.has_key? :summary_columns
        end
      end
      if values.has_key? :leave_type_detials
        values[:leave_type_detials] = values[:leave_type_detials].to_a if values[:leave_type_detials].is_a? String
        values[:leave_type_detials][values[:leave_type_detials].index("leave_type_detials")] = EmployeeLeaveType.leave_type_detials if values[:leave_type_detials].include?("leave_type_detials")
        methods << values[:leave_type_detials].flatten
      end
      columns = methods.flatten.compact.uniq
      add_fields = columns.select{|method| method.to_s.match("additional_detail_").present?}
      bank_fields = columns.select{|method| method.to_s.match("bank_detail_").present?}
      cat_fields = columns.select{|method| method.to_s.match("payroll_category_").present?}
      deleted_cols = []
      if add_fields.present?
        add_details = AdditionalField.get_additional_field_methods
        deleted_cols += columns.select{|c| !(c.to_s.match("additional_detail_").present? ? (add_details.include? c): true)}
      end
      if bank_fields.present?
        bank_details = BankField.get_bank_field_methods
        deleted_cols += columns.select{|c| !(c.to_s.match("bank_detail_").present? ? (bank_details.include? c): true)}
      end
      if cat_fields.present?
        category_details = PayrollCategory.get_earnings_methods + PayrollCategory.get_deductions_methods
        deleted_cols += columns.select{|c| !(c.to_s.match("payroll_category_").present? ? (category_details.include? c): true)}
      end
      columns - deleted_cols
    end

    def convert_columns(column_values)
      add_field_index = column_values.index(:additional_details)
      bank_field_index = column_values.index(:bank_details)
      earnings_index = column_values.index(:earnings)
      deductions_index = column_values.index(:deductions)
      column_values[add_field_index] = AdditionalField.get_additional_field_methods if add_field_index
      column_values[bank_field_index] = BankField.get_bank_field_methods if bank_field_index
      column_values[earnings_index] = PayrollCategory.get_earnings_methods if earnings_index
      column_values[deductions_index] = PayrollCategory.get_deductions_methods if deductions_index
      column_values.flatten.map(&:to_s)
    end

    def set_additional_details(values, columns)
      ["additional_detail_", "bank_detail_", "payroll_category_"].each do |field|
        methods = columns.select{|method| method.to_s.match(field).present?}
        if methods.present?
          values.each do |val|
            val.send("get_#{field}value", methods)
          end
        end
      end
    end

    def get_table_headers(columns)
      titles = {}
      {"additional_detail_" => "AdditionalField", "bank_detail_" => "BankField", "payroll_category_" => "PayrollCategory"}.each do |field, klass|
        methods = columns.select{|method| method.to_s.match(field).present?}
        if methods.present?
          titles.merge!(send("get_header_value", field, klass, methods))
        end
      end
      columns.each do |col| 
        titles[col.to_s] = EmployeeLeaveType.leave_type_detials.include?(col.to_s) ?  col : t(col) unless titles.has_key? col.to_s
      end
      titles
    end

    def fetch_grouped_columns(column_values)
      columns = []
      payslip_columns = (HrReportBaseTemplate::DETAILED_PAYSLIP_COLUMNS + HrReportBaseTemplate::SALARY_SUMMARY_COLUMNS).uniq
      column_values.each do |col|
        columns << col.to_s if payslip_columns.include? col.to_sym or col.to_s.match("payroll_category_")
      end
      columns
    end

    def fetch_report_csv(report_name, inputs = {}, filters = {}, columns = {})
      cols = Marshal.load(Marshal.dump(columns))
      range =  inputs["range"]
      input_cols = convert_input_values(inputs)[:payroll_category] if report_name.to_sym == :payroll_category_wise_report
      result = send('get_' + report_name, report_name, inputs, filters, columns, 'all')
      totals = HrReport.get_totals(report_name, range, inputs, filters, cols, input_cols)
      report_values = HrReportQuery.get_paginate_values(inputs, filters||{}, 'all') if [:overall_salary_report, :overall_estimation_report].include? report_name.to_sym
      employee =  get_employee inputs[:employee].join(",") if report_name.to_sym == :employee_payslip_report
      csv_string=FasterCSV.generate do |csv|
        if employee.present?
          csv << [t("employee_name"), "#{employee.full_name} (#{employee.employee_number})"]
          csv << [t("department"), employee.employee_department.try(:name)]
          csv << [t("joining_date"), format_date(employee.joining_date)]
          csv << [t("position"), employee.employee_position.try(:name)]
          csv << [t("payroll_group"), (employee.class == Employee ? employee.employee_salary_structure.try(:payroll_group).try(:name) : employee.archived_employee_salary_structure.try(:payroll_group).try(:name))||"-"]
          csv << [t("grade"), employee.employee_grade.try(:name)]
          csv << []
        end
        methods = result.methods
        grouped_columns = result.column_grouping
        group_values = result.group_values
        header1 = [t('sl_no')]
        header2 = [""]
        unless result.column_grouping.present?
          methods.each do |method|
            header1 << result.header_title[method.to_s]
          end
        else
          methods.each do |method|
            if grouped_columns.include? method.to_s
              group_values.each_with_index do |val, index|
                header1 << (index == 0 ? result.header_title[method.to_s] : "")
                header2 << date_display(val)
              end
            else
              header1 << result.header_title[method.to_s]
              header2 << ""
            end
          end
        end
        csv << header1
        csv << header2 if header2.length > 1
        methods = methods.map{|m| (([:other_earnings, :other_deductions, :salary_summary].include? m.to_sym) ? "#{m}_csv" : m)}
        count = 1
        if result.grouped_values.present?
          if result.row_grouping
            result.grouped_values.each do |key, values|
              total = result.group_count.detect{|c| c.name == key}.try(:total)
              unless report_name == "employee_wise_estimation_report"
                csv << ["#{t('pay_period')} : #{date_display(key)} (#{total} #{t('payslips')})"]
              else
                report_type = inputs[:report_type]
                csv << ["#{t(report_type.gsub('_type',""))} : #{(report_type == "pay_frequency_type" ? PayrollGroup.payment_period_translation(key) : key)} (#{t('total_cost')} : #{total})"]
              end
              values.each do |val|
                row = [count]
                methods.each do |method|
                  row << val.send(method)
                end
                csv << row
                count += 1
              end
            end
          elsif result.column_grouping.present?
            result.grouped_values.each do |key, values|
              res = nil
              values.each{|k,v| res = v.first}
              row = [count]
              methods.each do |method|
                if grouped_columns.include? method.to_s
                  group_values.each do |val|
                    row << (values[val].present? ? values[val].first.send(method) : '-')
                  end
                else
                  row << (res.present? ? res.send(method) : '-')
                end
              end
              csv << row
              count += 1
            end
          end
        else
          unless report_values.present?
            result.values.each do |val|
              row = [count]
              methods.each do |method|
                row << val.send(method)
              end
              csv << row
              count += 1
            end
          else
            values = result.values
            report_values.each do |val|
              res = values.detect{|v| v["id"].to_i == val.id}
              row = [count]
              if res.nil?
                methods.each do |method|
                  row << (method.to_s == 'name' ? val.send(method) : FedenaPrecision.set_and_modify_precision(0))
                end
              else
                methods.each do |method|
                  row << (([:name, :no_of_lop].include? method.to_sym) ? res[method.to_s] : FedenaPrecision.set_and_modify_precision(res[method.to_s]))
                end
              end
              csv << row
              count += 1
            end
          end
        end
        row = [""]
        if totals.present?
          if result.column_grouping.present?
            total_methods = totals.values.first.first.keys.map(&:to_s)
            methods.each do |method|
              if grouped_columns.include? method.to_s
                group_values.each do |val|
                  row << FedenaPrecision.set_and_modify_precision(totals[val].present? ? totals[val].first[method.to_s] : ((total_methods.include? method.to_s) ? '0' : ''))
                end
              else
                row << ""
              end
            end
          else
            total =  totals.first
            methods.each do |method|
              row << FedenaPrecision.set_and_modify_precision(total[method.to_s]||"")
            end
          end
          csv << row
        end
      end
      csv_string
    end

    def get_totals(report_name, range, inputs = {}, filters = {}, columns = {}, input_cols = [])
      column_totals = if [:employee_wise_estimation_report, :overall_estimation_report].include? report_name.to_sym
        ["gross_salary", "net_pay"]
      elsif report_name.to_sym == :payroll_category_wise_report
        input_cols||[]
      else
        columns = (columns||{})
        (columns[:payslip_details].to_s == "true" ? columns[:payslip_totals] : columns[:summary_totals])
      end
      fil_list = (filters||{}).reject{|k, v| k.to_s == "pay_period_multiple"}
      result = HrReportQuery.fetch_totals(report_name, range, inputs||{}, fil_list||{}, column_totals||[]) if column_totals.present?
      (report_name.to_sym == :comparison_report ? result.group_by{|d| d["payslip_range"]} : result) if result.present?
    end

    def fetch_column_types(columns)
      result = {}
      columns.each do |col|
        if col == "date_range"
          result[col] = "date"
        elsif ((["gross_salary",  "total_earnings", "total_deductions", "lop", "net_pay"].include? col) or (col.match("payroll_category_").present?))
          result[col] = "amount"
        else
          result[col] = "text"
        end
      end
      result
    end

    def date_display(date)
      range = date.split(",")
      diff = (range.last.to_date - range.first.to_date).to_i
      if diff == 0
        format_date(range.first)
      elsif (diff > 16)
        format_date(range.first,:format => :month_year)
      else
        format_date(range.first) + " - " + format_date(range.last)
      end
    end

    def get_employee(emp)
      if emp
        employee = emp.split(",")
        return employee.last.constantize.find_by_id employee.first
      end
    end
  end
end
