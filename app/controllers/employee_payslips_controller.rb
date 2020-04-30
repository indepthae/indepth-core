class EmployeePayslipsController < ApplicationController
  filter_access_to :all
  lock_with_feature :hr_enhancement
  before_filter :login_required
  filter_access_to :view_payslip_pdf,:attribute_check => true ,:load_method => lambda {EmployeePayslip.find(params[:id]).employee.user}
  filter_access_to [:payslip_generation_list, :view_all_employee_payslip, :payslip_for_payroll_group, :payslip_for_employees, :view_all_rejected_payslips, :view_payslip, :view_past_payslips, :view_employee_past_payslips], :attribute_check => true ,:load_method => lambda {cur_user = current_user; cur_user.finance_flag = params[:finance].present?; cur_user}

  check_request_fingerprint :create_employee_wise_payslip, :update_payslip

def payslip_for_payroll_group
    @payroll_groups = PayrollGroup.ordered.paginate(:per_page => 10, :page => params[:page],:select => "payroll_groups.id,payroll_groups.name,payroll_groups.salary_type,payroll_groups.payment_period,count(DISTINCT(employee_salary_structures.id)) as emp_count, pdr.start_date, pdr.end_date", :joins => "LEFT OUTER  JOIN employee_salary_structures on employee_salary_structures.payroll_group_id = payroll_groups.id LEFT OUTER JOIN (SELECT payroll_group_id, MAX(start_date) as start_date from payslips_date_ranges GROUP BY payroll_group_id) ranges ON ranges.payroll_group_id = payroll_groups.id LEFT OUTER JOIN payslips_date_ranges pdr ON pdr.start_date = ranges.start_date AND pdr.payroll_group_id = payroll_groups.id" ,:group => "payment_period, payroll_groups.id", :include => {:payslips_date_ranges => :employee_payslips}, :order => "payment_period")
    pg = @payroll_groups.group_by(&:salary_type)
    @hourly_payroll_groups = pg[1].group_by(&:payment_period) unless pg[1].nil?
    @salaried_payroll_groups = pg[2].group_by(&:payment_period) unless pg[2].nil?
  end


  def generate_payslips
    @payroll_group = PayrollGroup.find(params[:id])
    @generated = @not_generated = @lop_employees = @outdated_payroll = @updated_payroll = @employee_count = 0
    @from = ""
    @ranges = []
    if params[:start_date] && params[:end_date]
      @start_date = params[:start_date].to_date
      @end_date = params[:end_date].to_date
      @ranges = @payroll_group.payslips_date_ranges.all(:conditions => ["((start_date  < ? and ? < end_date) or (start_date < ? and ? < end_date))", @start_date, @start_date, @end_date, @end_date]) if @payroll_group.payment_period == 3
      @currency = currency
      @from = params[:from]
      payroll_group_employees = @payroll_group.employees
      @employee_count = payroll_group_employees.count
      where_condition = defined?(MultiSchool) ? "WHERE school_id = #{MultiSchool.current_school.id}" : ""
      generated_employees = EmployeePayslip.group_wise_payslips(@start_date,@end_date,params[:id], where_condition)
      @generated = generated_employees.length

      not_generated =  Employee.without_payslips(@start_date,@end_date,params[:id])
      @not_generated = not_generated.length

      @estimated_cost = generated_employees.present? ? generated_employees.map(&:net_pay).map(&:to_f).sum : 0
      @estimated_cost+= not_generated.present? ? not_generated.map(&:net_pay).map(&:to_f).sum : 0

      outdated_payroll = not_generated.outdated_payroll
      @outdated_payroll = outdated_payroll.count

      lop_employees = (@payroll_group.enable_lop ? not_generated.with_lop : [])
      @lop_employees = lop_employees.length
      @updated_payroll = (not_generated - (outdated_payroll + lop_employees)).length
      if request.xhr?
        render :update do |page|
          page.replace_html 'list_payslip', :partial=> 'list_payslips'
          page.replace_html 'date_range', :partial => 'payslip_date_range'
        end
      end
    end
  end




  def payslip_for_employees
    @departments = EmployeeDepartment.active_and_ordered
    conditions = []
    values = []
    unless params[:dept_id].nil? or params[:dept_id] == "All"
      conditions << "employee_department_id = ?"
      values << params[:dept_id]
    end
    unless params[:name].nil?
      conditions << "(ltrim(first_name) LIKE ? OR employee_number = ?)"
      values += ["#{params[:name]}%", params[:name]]
    end

    if conditions.empty?
      unless params[:archived].present?
        employees_count = Employee.all.count
        @employees_list = Employee.payslips_for_employees.paginate(:per_page => 10, :page => params[:page], :total_entries => employees_count)
      else
        employees_count = ArchivedEmployee.all(:joins => :employee_payslips, :group => "archived_employees.id").count
        @employees_list = ArchivedEmployee.payslips_for_employees.paginate(:per_page => 10, :page => params[:page], :total_entries => employees_count)
      end
    else
      unless params[:archived].present?
        employees = Employee.payslips_for_employees.scoped(:conditions => ([conditions.join(" AND ")] + values))
        @employees_list = employees.paginate(:per_page => 10, :page => params[:page], :total_entries => employees.length)
      else
        employees = ArchivedEmployee.payslips_for_employees.scoped(:conditions => ([conditions.join(" AND ")] + values))
        @employees_list = employees.paginate(:per_page => 10, :page => params[:page], :total_entries => employees.length)
      end
    end
    @archived_employee = ArchivedEmployee.first(:joins => :employee_payslips, :group => "archived_employees.id")
    @payroll_groups = PayrollGroup.ordered
    @employees = @employees_list.group_by(&:dept_name)
    if request.xhr?
      render :update do |page|
        page.replace_html 'employee_list', :partial => "list_employees"
      end
    end
  end

  def payslip_generation_list
    @payroll_group = PayrollGroup.find(params[:id])
    @employee_type = params[:type]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @payslips_date_range = PayslipsDateRange.find_by_start_date_and_end_date_and_payroll_group_id(@start_date.to_date,@end_date.to_date,params[:id])
    if @payslips_date_range.present?
      where_condition = defined?(MultiSchool) ? "WHERE school_id = #{MultiSchool.current_school.id}" : ""
      @employees = EmployeePayslip.group_wise_payslips(@start_date.to_date,@end_date.to_date,params[:id], where_condition)
      status = @employees.status
      @approved = status.approved.to_i
      @pending = status.pending.to_i
      @rejected = status.rejected.to_i
      @outdated_payroll = status.outdated.to_i
      @generated = status.total.to_i
      @normal_employees = status.normal_employees.to_i
      employee_status = params[:employee_status]
      payslip_status = params[:payslip_status]
      if payslip_status.present? and payslip_status != "All"
        @employees = @employees.send(payslip_status+"_payslips")
      end
      if employee_status.present? and employee_status != "All"
        @employees = @employees.send(employee_status)
      end
      @employees = @employees.paginate(:page => params[:page], :per_page => 10, :total_entries => @employees.count)
      if request.xhr?
        render :update do |page|
          page.replace_html 'employees', :partial => 'show_employees'
        end
      end
    else
      case params[:from]
      when 'past_payslips'
        redirect_to :action => :view_past_payslips, :id => @payroll_group.id
      else
        redirect_to :action => :generate_payslips, :id => @payroll_group.id
      end
    end
  end

  def generate_all_payslips
    @payroll_group = PayrollGroup.find(params[:id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @hash = @payroll_group.fetch_employee_payslips(@start_date,@end_date,currency,@payroll_group.id)
    @hash[:theader][:status] = @hash[:tbody].collect{|k,v| v[:status]}.any?.to_s
  end

  def view_outdated_employees
    @employees = Employee.paginate(:page => params[:page], :per_page => 10,:joins => :employee_salary_structure, :conditions => ["employee_salary_structures.current_group = ? AND employee_salary_structures.payroll_group_id = ?",false,params[:id]])
    @flag = true
    render :update do |page|
      page.replace_html 'employees', :partial => 'show_employees'
    end
  end



  def save_employee_payslips
    payslips = JSON.parse(params[:employee_payslips])
    hash = EmployeePayslip.save_payslips(payslips,params[:start_date],params[:end_date],params[:payroll_group_id])
    respond_to do |fmt|
      fmt.json {render :json=> hash}
    end
  end


  def generate_employee_payslip
    @employee = Employee.find(params[:employee_id],:include => {:employee_salary_structure => {:employee_salary_structure_components => :payroll_category}})
    @payroll_group = @employee.payroll_group
    @date_ranges = @payroll_group.calculate_date_ranges(params[:date].nil? ? nil : params[:date].to_date)
    @payslip = @employee.employee_payslips.all(:joins => :payslips_date_range, :conditions => ["payslips_date_ranges.start_date = ? AND payslips_date_ranges.end_date = ?", @date_ranges.first, @date_ranges.last])
    @payslips_date_range = PayslipsDateRange.find_by_start_date_and_end_date_and_payroll_group_id(@date_ranges.first,@date_ranges.last, @payroll_group.id) || PayslipsDateRange.new(:start_date => @date_ranges.first, :end_date => @date_ranges.last, :payroll_group_id => @payroll_group.id, :revision_number => @payroll_group.current_revision)
    @ranges = ((@payroll_group.payment_period == 3 and @payslip.empty?) ? @payroll_group.payslips_date_ranges.all(:conditions => ["(? BETWEEN start_date AND end_date OR ? BETWEEN start_date AND end_date) AND (start_date <> ? AND end_date <> ?)", @date_ranges.first,@date_ranges.last, @date_ranges.first,@date_ranges.last]) : [])
    if (@payslip.empty? or params[:regenerate].present?) and @employee.joining_date <= @date_ranges.last and @ranges.empty?
      @currency_type = currency
      @salary_structure = @employee.employee_salary_structure
      @employee_payslip = @payslips_date_range.employee_payslips.build(:employee_id => @employee.id, :net_pay => @salary_structure.net_pay, :gross_salary => @salary_structure.gross_salary, :revision_number => @salary_structure.revision_number, :payroll_revision_id => @salary_structure.latest_revision_id)
      @employee_payslip.build_payslip_categories(@employee)
      @earnings = @employee_payslip.earning_categories
      @deductions = @employee_payslip.deduction_categories
      @individual_earnings = @employee_payslip.individual_earnings
      @individual_deductions = @employee_payslip.individual_deductions
      @selected_leaves = @additional_leaves = EmployeeAdditionalLeave.employee_additional_leaves(@employee.id)
      @lop_amount = @salary_structure.calculate_lop(@date_ranges.first.month)
      @lop_as_deduction = @payroll_group.employee_lop.lop_as_deduction if @payroll_group.enable_lop
      @payroll_group.employee_lop.calculate_lop_amounts(@lop_amount, @salary_structure, @employee_payslip, @selected_leaves,@date_ranges.first.month) if !@lop_as_deduction and @lop_amount and @additional_leaves.present?
    end
    if request.xhr?
      render :partial => 'employee_payslip_form'
    end
  end

  def create_employee_wise_payslip
    if params[:payslips_date_range].present?
      @payslips_date_range = PayslipsDateRange.find_by_start_date_and_end_date_and_payroll_group_id(params[:payslips_date_range][:start_date],params[:payslips_date_range][:end_date], params[:payslips_date_range][:payroll_group_id])
      if @payslips_date_range.nil?
        @payslips_date_range = PayslipsDateRange.new(params[:payslips_date_range])
      else
        @payslips_date_range.attributes = params[:payslips_date_range]
      end
      @employee = Employee.find(params[:employee_id],:include => {:employee_salary_structure => :employee_salary_structure_components})
      if @payslips_date_range.save
        flash[:notice] = "#{t('employee.flash53', {:employee_name => @employee.first_name})}"
        case params[:from]
        when "view_outdated_employees", "view_regular_employees", "view_employees_with_lop"
          redirect_to :action => 'generate_payslips', :from => params[:from],:id => params[:payslips_date_range][:payroll_group_id], :start_date => params[:payslips_date_range][:start_date], :end_date => params[:payslips_date_range][:end_date]
        else
          redirect_to :action => :payslip_for_employees
        end
      else
        @payroll_group = @employee.payroll_group
        @date_ranges = [@payslips_date_range.start_date, @payslips_date_range.end_date]
        @payslip = @employee.employee_payslips.all(:joins => :payslips_date_range, :conditions => ["payslips_date_ranges.start_date = ? AND payslips_date_ranges.end_date = ?", @date_ranges.first, @date_ranges.last])
        @ranges = ((@payroll_group.payment_period == 3 and @payslip.empty?) ? @payroll_group.payslips_date_ranges.all(:conditions => ["(? BETWEEN start_date AND end_date OR ? BETWEEN start_date AND end_date) AND (start_date <> ? AND end_date <> ?)", @date_ranges.first,@date_ranges.last, @date_ranges.first,@date_ranges.last]) : [])
        @currency_type = currency
        @employee_payslip = @payslips_date_range.employee_payslips.detect{|p| p.employee_id == @employee.id}
        @earnings = @employee_payslip.earning_categories
        @deductions = @employee_payslip.deduction_categories
        @individual_earnings = @employee_payslip.individual_earnings
        @individual_deductions = @employee_payslip.individual_deductions
        @additional_leaves = EmployeeAdditionalLeave.employee_additional_leaves(@employee.id)
        @salary_structure = @employee.employee_salary_structure
        @lop_amount = @salary_structure.calculate_lop(@date_ranges.first.month)
        @selected_leaves = @additional_leaves.select{|l| @employee_payslip.payslip_additional_leaves.collect(&:employee_additional_leave_id).include? l.id}
        @lop_as_deduction = @payroll_group.employee_lop.lop_as_deduction if @payroll_group.enable_lop
        render 'generate_employee_payslip'
      end
    else
      redirect_to :action => 'generate_employee_payslip', :employee_id => params[:employee_id]
    end
  end
  
  def calculate_lop_values
    month = params[:month].to_i
    employee = Employee.find(params[:employee_id],:include => {:employee_salary_structure => {:employee_salary_structure_components => :payroll_category}})
    payroll_group = PayrollGroup.find(params[:payroll_group_id], :include => {:employee_lop => [{:hr_formula => :formula_and_conditions}, {:lop_prorated_formulas => :hr_formula}]})
    employee.employee_salary_structure
    salary_structure = employee.employee_salary_structure
    lop_amount = salary_structure.calculate_lop(month)
    payroll_hash = payroll_group.employee_lop.calculate_lop_amounts(lop_amount, salary_structure, nil, params[:lop_count].to_f, month)
    render :json => payroll_hash
  end

  def view_employee_past_payslips
    @employee = unless params[:archived].present?
      Employee.find params[:employee_id]
    else
      ArchivedEmployee.find params[:employee_id]
    end
    @payroll_group = @employee.payroll_group
    @payslips_list = @employee.employee_payslips.individual_employee_payslips.send((params[:status]||"approved_and_pending")+"_payslips").paginate(:page => params[:page], :per_page => 10)
    @total_cost = @employee.employee_payslips.send((params[:status]||"approved_and_pending")+"_payslips").total_yearly_cost
    @payslips = @payslips_list.group_by(&:year)
    if request.xhr?
      render :update do |page|
        page.replace_html 'past_payslips', :partial => 'employee_past_payslips'
      end
    end
  end

  def view_employee_pending_payslips
    @employee = Employee.find params[:employee_id]
    @payslips_list = @employee.employee_payslips.individual_employee_payslips.pending_and_rejected_payslips.paginate(:page => params[:page], :per_page => 10)
    @payslips = @payslips_list.group_by(&:year)
    if request.xhr?
      render :update do |page|
        page.replace_html 'past_payslips', :partial => 'employee_past_payslips'
      end
    end
  end

  def view_past_payslips
    @payroll_group = PayrollGroup.find(params[:id])
    @payslips_list = @payroll_group.payslips_date_ranges.paginate(:select =>  "count(case is_approved when true then 1 else null end) as approved,count(case is_rejected when true then 1 else null end) as rejected,count(case is_approved or is_rejected when false then 1 else null end) as pending,count(employee_payslips.id) as generated,payslips_date_ranges.*, employee_payslips.employee_id, SUM(case is_rejected when true then 0 else employee_payslips.net_pay end) AS net_pay, employee_payslips.payslips_date_range_id, YEAR(payslips_date_ranges.start_date) AS year", :joins => [:employee_payslips], :group => "payslips_date_ranges.id", :page => params[:page], :per_page => 10, :order => "payslips_date_ranges.start_date desc")
    @payslips = @payslips_list.group_by(&:year)
    if request.xhr?
      render :update do |page|
        page.replace_html 'past_payslips', :partial => 'past_payslips'
      end
    end
  end

  def view_all_employee_payslip
    @start_date = params[:start_date].to_date
    @end_date = params[:end_date].to_date
    where_condition = defined?(MultiSchool) ? "WHERE school_id = #{MultiSchool.current_school.id}" : ""
    @payslips = EmployeePayslip.group_wise_payslips(@start_date, @end_date, params[:id], where_condition)
    status = @payslips.status
    updated_payslips = status.normal_employees.to_i
    @payslips_date_range = PayslipsDateRange.find_by_start_date_and_end_date_and_payroll_group_id(@start_date, @end_date, params[:id])
    if updated_payslips > 0
      @payroll_group = PayrollGroup.find(params[:id])
      if @payroll_group.current_revision == @payslips_date_range.revision_number
        @categories = @payroll_group.payroll_categories
      else
        revision = @payroll_group.payroll_group_revisions.find_by_revision_number(@payslips_date_range.revision_number)
        @categories = PayrollCategory.find(revision.categories)
      end
      @earnings = @categories.select{|c| c.is_deduction == false}
      @deductions = @categories.select{|c| c.is_deduction == true}
      @approved = status.approved.to_i
      @pending = status.pending.to_i
      @rejected = status.rejected.to_i
      @outdated_payroll = status.outdated.to_i
      @payslips = @payslips.updated_structure_payslips
      @payslips = @payslips.send(params[:employees]) if params[:employees].present? and params[:employees] != 'all'
      @approved_payslips = @payslips.select{|p| p.is_approved and p.current_group}
      unless params[:finance].present?
        @pending_payslips = @payslips.select{|p| !p.is_approved and !p.is_rejected and p.current_group}
      else
        @pending_payslips = @payslips.select{|p| !p.is_approved and !p.is_rejected and p.current_group and p.employee_type == 'Employee'}
      end
      @payslips_list = @payslips.send((params[:status]||"approved_and_pending")+"_payslips").load_payslips_categories.paginate(:per_page => 10, :page => params[:page])
      if request.xhr?
        render :update do |page|
          page.replace_html 'payslip_table', :partial => "list_all_employee_payslips"
        end
      end
    else
      if @payslips.present?
        redirect_to :action => 'payslip_generation_list', :start_date => @start_date, :end_date => @end_date, :id => params[:id], :finance => params[:finance], :from => params[:from]
      else
        redirect_to :action => 'generate_payslips', :start_date => @start_date, :end_date => @end_date, :id => params[:id], :finance => params[:finance], :from => params[:from]
      end
    end
  end


  def view_payslip
    @employee_payslip = EmployeePayslip.find(params[:id], :include => [:employee, {:payslips_date_range => :payroll_group}, {:employee_payslip_categories => :payroll_category}])
    @individual_payslips = @employee_payslip.individual_payslip_categories
    @employee = @employee_payslip.employee
    @payroll_revision = @employee_payslip.payroll_revision.payroll_details if @employee_payslip.deducted_from_categories and @employee_payslip.payroll_revision.present?
    @attendance_details = @employee.fetch_attendance_details(@employee_payslip)
    @currency_type = currency
    @info = @employee.prev_lops_present(@employee_payslip)
  end

  def view_payslip_pdf
    @employee_payslip = EmployeePayslip.find(params[:id])
    @payslip_categories = EmployeePayslip.get_payslip_categories(params[:id])
    @employee = @employee_payslip.employee
    @employee = ArchivedEmployee.find_by_former_id @employee_payslip.employee_id if @employee.nil?
    @sections = PayslipSetting::DEFAULT_SETTINGS.collect{|ps| ps.keys}.flatten
    @employee_details =  if @employee_payslip.employee_details.present?
      @employee_payslip.employee_details["employee_details"]
    else
      @employee.employee_settings(@employee_payslip.id)
    end    
    @start_date = @employee_payslip.payslips_date_range.start_date
    @end_date = @employee_payslip.payslips_date_range.end_date
    @header = []
    @att_details = []
    @footnote = @employee_payslip.employee_details.present? ?  @employee_payslip.employee_details["footnote"] : PayslipSetting.footnote
    @info = @employee.prev_lops_present(@employee_payslip)
    @sections.each do |section|
      temp = @employee_details.select{|k,x| x if k == section }
      v = temp.present? ? temp[0][1] : nil
      unless v.nil?
        v.each do |value|
          value.each do |x,y|
            if section == :attendance_details
              @att_details << {:label => t(x) ,:text => y}
            else
              @header << {:label => (section == :bank_details or section == :additional_details) ? x : t(x) ,:text => y}
            end
          end
        end
      end
    end
    render :pdf => "#{@employee.employee_number} - #{format_date(@start_date)}", :show_as_html => params[:d].present? ,:zoom => 1,:margin =>{:bottom => 5,:left=>5,:right=>5, :top => 45}, :header => {:html => { :template=> 'employee_payslips/_payslip_pdf_header.html.erb'}}, :footer => {:html => { :content=> ''}}
  end


  def revert_employee_payslip
    employee_payslip = EmployeePayslip.find(params[:id])
    if EmployeePayslip.revert_pending_payslips([params[:id]])
      employee_payslip.payslips_date_range.destroy if employee_payslip.payslips_date_range.employee_payslips.empty?
      flash[:notice] = "#{t('employee.flash54', {:employee_name => employee_payslip.employee.first_name})}"
      case params[:from]
      when "payslip_generation_list", "past_payslips"
        redirect_to :action => 'payslip_generation_list', :id => employee_payslip.payslips_date_range.payroll_group_id, :start_date => employee_payslip.payslips_date_range.start_date, :end_date => employee_payslip.payslips_date_range.end_date, :from => params[:from]
      when "assigned_employees" , "assign_employees"
        redirect_to :action => "view_employee_pending_payslips", :employee_id => employee_payslip.employee_id, :from => params[:from]
      when 'view_all_employee_payslip'
        render :text => true
      when 'rejected_payslips'
        redirect_to :action => 'rejected_payslips', :id => params[:pg_id], :start_date => params[:start_date], :end_date => params[:end_date]
      when 'payslip_reports'
        redirect_to :controller => 'finance', :action => 'view_monthly_payslip', :hr => 1
      when 'employee_payslips_archived'
        redirect_to :action => 'view_employee_past_payslips', :employee_id => employee_payslip.employee_id, :archived => 1
      when 'view_all_rejected_payslips'
        redirect_to :action => 'view_all_rejected_payslips'
      else
        redirect_to :action => 'view_employee_past_payslips', :employee_id => employee_payslip.employee_id
      end
    end
  end

  def revert_all_payslips
    ids = params[:payslip_ids].split(',')
    date_range = PayslipsDateRange.find_by_start_date_and_end_date_and_payroll_group_id(params[:start_date], params[:end_date], params[:payroll_group_id])
    count = EmployeePayslip.revert_pending_payslips(ids)
    if count
      date_range.destroy if date_range.employee_payslips.empty?
      render :text => count
    end
  end


  def edit_payslip
    @employee_payslip = EmployeePayslip.find(params[:id], :include => {:employee_payslip_categories => :payroll_category})
    if @employee_payslip.is_rejected
      @employee = @employee_payslip.employee
      edit_payslips_fetch_data
      @prev_action = "edit_payslip"
    end
  end

  def update_payslip
    @employee_payslip = EmployeePayslip.find(params[:id], :include => {:employee_payslip_categories => :payroll_category})
    pg_id = @employee_payslip.payslips_date_range.payroll_group_id
    @employee = @employee_payslip.employee
    if @employee_payslip.update_attributes(params[:employee_payslip].merge(:is_regeneration => true))
      flash[:notice] = "#{t('employee.flash53', {:employee_name => @employee.first_name})}"
      case params[:from]
      when "assigned_employees", "assign_employees"
        redirect_to :action => "view_employee_pending_payslips", :employee_id => @employee_payslip.employee_id, :from => params[:from]
      when 'payslip_generation_list', 'past_payslips'
        redirect_to :action => 'payslip_generation_list', :id => pg_id, :start_date => @employee_payslip.payslips_date_range.start_date.to_date, :end_date => @employee_payslip.payslips_date_range.end_date.to_date, :from => params[:from]
      when 'rejected_payslips'
        redirect_to :action => 'rejected_payslips', :id => pg_id, :start_date => @employee_payslip.payslips_date_range.start_date.to_date, :end_date => @employee_payslip.payslips_date_range.end_date.to_date
      else
        redirect_to :action => "view_all_rejected_payslips"
      end
    else
      @employee_payslip.is_rejected = true
      edit_payslips_fetch_data
      render 'edit_payslip'
    end
  end



  def rejected_payslips
    @payroll_group = PayrollGroup.find(params[:id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @payslips_date_range = PayslipsDateRange.find_by_start_date_and_end_date_and_payroll_group_id(@start_date, @end_date, params[:id])
    all_rejected_payslips = EmployeePayslip.count(:conditions => ["is_rejected = 1 AND payslips_date_ranges.start_date = ? AND payslips_date_ranges.end_date = ?", @start_date, @end_date], :joins => :payslips_date_range)
    @employees  = Employee.with_payslips(@start_date,@end_date,params[:id]).rejected_payslips.paginate(:per_page => 10, :page => params[:page], :total_entries => all_rejected_payslips)
  end

  def view_employees_with_lop
    @payroll_group = PayrollGroup.find(params[:id])
    if @payroll_group.enable_lop
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      employees = Employee.without_payslips(@start_date,@end_date,params[:id]).with_lop
      @employees = employees.paginate(:page => params[:page], :per_page => 10, :total_entries => employees.length)
    else
      page_not_found
    end
  end

  def view_regular_employees
    @payroll_group = PayrollGroup.find(params[:id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    employees = Employee.without_payslips(@start_date,@end_date,params[:id])
    lop_employees = (@payroll_group.enable_lop ? employees.with_lop : [])
    employees = employees - lop_employees - employees.outdated_payroll
    @employees = employees.paginate(:page => params[:page], :per_page => 10)
  end

  def view_outdated_employees
    @payroll_group = PayrollGroup.find(params[:id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    employees = Employee.without_payslips(@start_date,@end_date,params[:id]).outdated_payroll.scoped(:include => :employee_additional_leaves)
    @employees = employees.paginate(:page => params[:page], :per_page => 10, :total_entries => employees.length)
  end

  def view_all_rejected_payslips
    @payroll_groups = PayrollGroup.ordered.all(:select => "payroll_groups.name, payroll_groups.id", :joins => {:payslips_date_ranges => :employee_payslips}, :conditions  => "employee_payslips.is_rejected = true", :group => "payroll_groups.id")
    @departments = EmployeeDepartment.active_and_ordered.all(:select => "employee_departments.id, employee_departments.name", :joins => {:employees => :employee_payslips}, :conditions  => "employee_payslips.is_rejected = true", :order => 'employee_departments.name', :group => "employee_departments.id")
    conditions=["employee_payslips.is_rejected = true"]
    conditions << "payslips_date_ranges.payroll_group_id = #{params[:pg_id]}" if params[:pg_id].present? and params[:pg_id] != 'All'
    conditions << "employees.employee_department_id = #{params[:dpt_id]}" if params[:dpt_id].present? and params[:dpt_id] != 'All'
    @employees = EmployeePayslip.paginate(:joins => "INNER JOIN payslips_date_ranges ON payslips_date_ranges.id = employee_payslips.payslips_date_range_id INNER JOIN payroll_groups ON payroll_groups.id = payslips_date_ranges.payroll_group_id INNER JOIN employees ON employees.id =  employee_payslips.employee_id AND employee_payslips.employee_type = 'Employee' INNER JOIN employee_departments ON employees.employee_department_id = employee_departments.id", :select =>"employee_payslips.id, employees.first_name, employees.last_name, employees.employee_number, payslips_date_ranges.start_date,payslips_date_ranges.end_date, payroll_groups.name as pg_name,employee_departments.name, employee_payslips.reason, employee_payslips.payslips_date_range_id, employee_payslips.payslips_date_range_id", :conditions => conditions.join(' AND '), :include => {:payslips_date_range => :payroll_group}, :order => "employees.first_name", :per_page => 10, :page => params[:page])
    if request.post?
      render :update do |page|
        page.replace_html 'employees', :partial => 'rejected_employee_list'
      end
    end
  end

  def approve_payslips
    total_ranges = PayslipsDateRange.all(:select => "CONCAT(payslips_date_ranges.start_date, '-',payslips_date_ranges.end_date) AS date_range_text", :group => 'date_range_text', :order => 'date_range_text')
    @payslips_date_ranges = PayslipsDateRange.paginate(:select => "payslips_date_ranges.payroll_group_id,payslips_date_ranges.id, payslips_date_ranges.start_date AS start_date, payslips_date_ranges.end_date AS end_date, CONCAT(payslips_date_ranges.start_date, '-',payslips_date_ranges.end_date) AS date_range_text, YEAR(payslips_date_ranges.start_date) AS year, SUM(case is_rejected when true then 0 else employee_payslips.net_pay end) AS total_cost, COUNT(employee_payslips.id) AS generated, COUNT(CASE WHEN (employee_payslips.is_approved = 0 AND employee_payslips.is_rejected = 0) THEN 1 ELSE NULL END) AS pending, COUNT(CASE WHEN(employee_payslips.is_approved = 1) THEN 1 ELSE NULL END) AS approved, COUNT(CASE WHEN (employee_payslips.is_rejected = 1) THEN 1 ELSE NULL END) AS rejected",:joins=> :employee_payslips, :group => 'date_range_text desc', :include => [:employee_payslips, :payroll_group], :order => 'payslips_date_ranges.start_date desc', :page => params[:page], :per_page => 10, :total_entries => total_ranges.count)
    @ranges = @payslips_date_ranges.group_by(&:year)
    @employees_count = PayslipsDateRange.all(:select => "CONCAT(payslips_date_ranges.start_date, '-',payslips_date_ranges.end_date) AS date_range_text, COUNT(ess.id) AS employees, payslips_date_ranges.id", :joins=> "LEFT OUTER JOIN payroll_groups pg ON pg.id = payslips_date_ranges.payroll_group_id LEFT OUTER JOIN employee_salary_structures ess ON (pg.id = ess.payroll_group_id)", :group => 'date_range_text', :order => 'date_range_text')
  end

  def approve_payslips_range
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @payslips_date_range = PayslipsDateRange.find_by_start_date_and_end_date(@start_date.to_date,@end_date.to_date)
    @payroll_groups = PayrollGroup.paginate(:select => "payroll_groups.id, payroll_groups.name, payroll_groups.payment_period, payroll_groups.salary_type, SUM(employee_payslips.net_pay) AS total_cost, COUNT(employee_payslips.id) AS generated, COUNT(CASE WHEN (employee_payslips.is_approved = 0 AND employee_payslips.is_rejected = 0) THEN 1 ELSE NULL END) AS pending, COUNT(CASE WHEN(employee_payslips.is_approved = 1) THEN 1 ELSE NULL END) AS approved, COUNT(CASE WHEN (employee_payslips.is_rejected = 1) THEN 1 ELSE NULL END) AS rejected", :joins => {:payslips_date_ranges => :employee_payslips}, :conditions => ["payslips_date_ranges.start_date = ? AND payslips_date_ranges.end_date = ?", @start_date, @end_date], :group => 'payslips_date_ranges.payroll_group_id', :include => :employees, :page => params[:page], :per_page => 10, :order => "name")
  end

  def payslip_settings
    @default_settings = PayslipSetting::DEFAULT_SETTINGS
    @settings = []
    @bank_details = BankField.active
    @additional_details = AdditionalField.active
    @default_settings.each do |section|
      @settings << PayslipSetting.find_or_create_by_section(:section => section.keys[0].to_s , :fields => section.values[0].sort)
    end
    @payslip_footnote = PayslipSetting.find_or_create_by_section(:section => 'footnote')
  end

  def update_payslip_settings
    @errors = {}
    @settings = []
    @sections = PayslipSetting::DEFAULT_SETTINGS.collect{|x| x.keys}.flatten
    ActiveRecord::Base.transaction do
      @sections.each do |section|
        setting = PayslipSetting.find_by_section section.to_s
        @settings << setting
        ids = []
        unless params[:payslip_setting][section].nil?
          params[:payslip_setting][section].each do |field, val|
            ids << field.to_i if val == "1"
          end

          setting.fields = ids.sort.uniq
          @errors[section] = setting.errors.map{|attr, msg| msg} unless setting.save
        end
      end

      @payslip_footnote = PayslipSetting.find_by_section 'footnote'
      @payslip_footnote.fields = params[:payslip_setting][:footnote_text].nil? ? nil : [params[:payslip_setting][:footnote_text]]
      @errors['footnote'] = @payslip_footnote.errors.map{|attr, msg| msg} unless @payslip_footnote.save

      unless @errors.empty?
        @bank_details = BankField.active
        @additional_details = AdditionalField.active
        flash[:notice] = "#{t('payslip_settings_not_saved')}"
        raise ActiveRecord::Rollback
      else
        flash[:notice] = "#{t('payslip_settings_saved')}"
        redirect_to :action => "payslip_settings" and return
      end
    end
    render 'payslip_settings'
  end

  def view_sample_payslip
    @employee = Employee.new
    @employee_details = @employee.employee_settings
    @sections = PayslipSetting::DEFAULT_SETTINGS.collect{|ps| ps.keys}.flatten
    @header = []
    @att_details = []
    @footnote = PayslipSetting.footnote

    @sections.each do |section|
      temp = @employee_details.select{|k,x| x if k == section }
      v = temp.present? ? temp[0][1] : nil
      unless v.nil?
        v.each do |value|
          value.each do |x,y|
            if section == :attendance_details
              @att_details << {:label => t(x) ,:text => y}
            else
              @header << {:label => (section == :bank_details or section == :additional_details) ? x : t(x) ,:text => y}
            end
          end
        end
      end
    end

    render :pdf => "view_sample_pdf", :show_as_html =>false ,:zoom=>1 ,:margin =>{:bottom=>0,:left=>5,:right=>5}, :header => {:html => { :content=> ''}}, :footer => {:html => { :content=> ''}}
  end
  private
  def edit_payslips_fetch_data
    @salary_structure = @employee.employee_salary_structure
    @payroll_group = @employee_payslip.payslips_date_range.payroll_group
    @payslip_date_range = @employee_payslip.payslips_date_range
    @start_date = @payslip_date_range.start_date
    @end_date = @payslip_date_range.end_date
    @earnings = @employee_payslip.earning_categories
    @deductions = @employee_payslip.deduction_categories
    @individual_earnings = @employee_payslip.individual_earnings
    @individual_deductions = @employee_payslip.individual_deductions
    @currency = currency
    @attendance_details = @employee.fetch_attendance_details(@employee_payslip)
    @additional_leaves = @employee_payslip.all_additional_leave
    @selected_leaves = @employee_payslip.payslip_additional_leaves.present? ? @additional_leaves.select{|l| @employee_payslip.payslip_additional_leaves.collect(&:employee_additional_leave_id).include? l.id} : []
  end
end

