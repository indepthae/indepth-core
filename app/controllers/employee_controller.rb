#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class EmployeeController < ApplicationController
  lock_with_feature :hr_enhancement
  before_filter :login_required,:configuration_settings_for_hr
  filter_access_to :all
  filter_access_to [:profile_general,:profile_personal,:profile_address,:profile_contact,:profile_bank_details,:profile_payroll_details,
    :profile_additional_details,:view_payslip,:view_attendance,:profile,:activities,:profile_pdf,
    :change_reporting_manager,:remove,:delete,:remove_subordinate_employee,:change_to_former
  ],:attribute_check => true ,:load_method => lambda {Employee.find(params[:id]||params[:emp_id]).user}
  filter_access_to :update_monthly_payslip,:attribute_check => true ,:load_method => lambda {EmployeePayslip.find(params[:employee_payslip_id]).employee.user}
  before_filter :set_precision
  before_filter :protect_unauthorized_views, :only => [:view_attendance]
  check_request_fingerprint :admission1


  def add_category
    @categories = EmployeeCategory.find(:all,:order => "name asc",:conditions=>'status = 1')
    @inactive_categories = EmployeeCategory.find(:all,:conditions=>'status = 0')
    @category = EmployeeCategory.new(params[:category])
    if request.post? and @category.save
      flash[:notice] = t('flash1')
      redirect_to :controller => "employee", :action => "add_category"
    end
  end

  def edit_category
    @category = EmployeeCategory.find(params[:id])
    employees = Employee.find(:all ,:conditions=>"employee_category_id = #{params[:id]}")
    if request.post?
      if (params[:category][:status] == 'false' and employees.blank?) or params[:category][:status] == 'true'

        if @category.update_attributes(params[:category])
          unless @category.status
            position = EmployeePosition.find_all_by_employee_category_id(@category.id)
            position.each do |p|
              p.update_attributes(:status=> '0')
            end
          end
          flash[:notice] = t('flash2')
          redirect_to :action => "add_category"
        end
      else
        flash[:warn_notice] = "<p>#{t('flash47')}</p>"
      end

    end
  end

  def delete_category
    employees = Employee.find(:all ,:conditions=>"employee_category_id = #{params[:id]}")
    if employees.empty?
      employees = ArchivedEmployee.find(:all ,:conditions=>"employee_category_id = #{params[:id]}")
    end
    category_position = EmployeePosition.find(:all, :conditions=>"employee_category_id = #{params[:id]}")
    if employees.empty? and category_position.empty?
      EmployeeCategory.find(params[:id]).destroy
      @categories = EmployeeCategory.find :all
      flash[:notice]=t('flash3')
      redirect_to :action => "add_category"
    else
      flash[:warn_notice]=t('flash4')
      redirect_to :action => "add_category"
    end
  end

  def add_position
    @positions = EmployeePosition.find(:all,:order => "name asc",:conditions=>'status = 1')
    @inactive_positions = EmployeePosition.find(:all,:order => "name asc",:conditions=>'status = 0')
    @categories = EmployeeCategory.find(:all,:order => "name asc",:conditions=> 'status = 1')
    @position = EmployeePosition.new(params[:position])
    if request.post? and @position.save
      flash[:notice] = t('flash5')
      redirect_to :controller => "employee", :action => "add_position"
    end
  end

  def edit_position
    @categories = EmployeeCategory.find(:all)
    @position = EmployeePosition.find(params[:id])
    employees = Employee.find(:all ,:conditions=>"employee_position_id = #{params[:id]}")
    if request.post?
      if (params[:position][:status] == 'false' and employees.blank?) or params[:position][:status] == 'true'
        if @position.update_attributes(params[:position])
          flash[:notice] = t('flash6')
          redirect_to :action => "add_position"
        end
      else
        flash[:warn_notice]="<p>#{t('flash48')}</p>"
      end
    end

  end

  def delete_position
    employees = Employee.find(:all ,:conditions=>"employee_position_id = #{params[:id]}")
    if employees.empty?
      employees = ArchivedEmployee.find(:all ,:conditions=>"employee_position_id = #{params[:id]}")
    end
    if employees.empty?
      EmployeePosition.find(params[:id]).destroy
      @positions = EmployeePosition.find :all
      flash[:notice]=t('flash3')
      redirect_to :action => "add_position"
    else
      flash[:warn_notice]=t('flash4')
      redirect_to :action => "add_position"
    end
  end

  def add_department
    @departments = EmployeeDepartment.active_and_ordered
    @inactive_departments = EmployeeDepartment.inactive_and_ordered
    @department = EmployeeDepartment.new(params[:department])
    if request.post? and @department.save
      flash[:notice] =  t('flash7')
      redirect_to :controller => "employee", :action => "add_department"
    end
  end

  def edit_department
    @department = EmployeeDepartment.find(params[:id])
    employees = Employee.find(:all ,:conditions=>"employee_department_id = #{params[:id]}")
    if request.post?
      if (params[:department][:status] == 'false' and employees.blank?) or params[:department][:status] == 'true'
        if @department.update_attributes(params[:department])
          flash[:notice] = t('flash8')
          redirect_to :action => "add_department"
        end
      else
        flash[:warn_notice]="<p>#{t('flash50')}</p>"
      end
    end
  end

  def delete_department
    employees = Employee.find(:all ,:conditions=>"employee_department_id = #{params[:id]}")
    if employees.empty?
      employees = ArchivedEmployee.find(:all ,:conditions=>"employee_department_id = #{params[:id]}")
    end
    if employees.empty?
      EmployeeDepartment.find(params[:id]).destroy
      @departments = EmployeeDepartment.ordered
      flash[:notice]=t('flash3')
      redirect_to :action => "add_department"
    else
      flash[:warn_notice]=t('flash4')
      redirect_to :action => "add_department"
    end
  end

  def add_grade
    @grades = EmployeeGrade.find(:all,:order => "name asc",:conditions=>'status = 1')
    @inactive_grades = EmployeeGrade.find(:all,:order => "name asc",:conditions=>'status = 0')
    @grade = EmployeeGrade.new(params[:grade])
    if request.post? and @grade.save
      flash[:notice] =  t('flash9')
      redirect_to :controller => "employee", :action => "add_grade"
    end
  end

  def edit_grade
    @grade = EmployeeGrade.find(params[:id])
    employees = Employee.find(:all ,:conditions=>"employee_grade_id = #{params[:id]}")
    if request.post?
      if (params[:grade][:status] == 'false' and employees.blank?) or params[:grade][:status] == 'true'
        if @grade.update_attributes(params[:grade])
          flash[:notice] = t('flash10')
          redirect_to :action => "add_grade"
        end
      else
        flash[:warn_notice]="<p>#{t('flash49')}</p>"
      end
    end
  end

  def delete_grade
    employees = Employee.find(:all ,:conditions=>"employee_grade_id = #{params[:id]}")
    if employees.empty?
      employees = ArchivedEmployee.find(:all ,:conditions=>"employee_grade_id = #{params[:id]}")
    end
    if employees.empty?
      EmployeeGrade.find(params[:id]).destroy
      @grades = EmployeeGrade.find :all
      flash[:notice]=t('flash3')
      redirect_to :action => "add_grade"
    else
      flash[:warn_notice]=t('flash4')
      redirect_to :action => "add_grade"
    end
  end

  def add_bank_details
    @bank_details = BankField.find(:all,:order => "name asc",:conditions=>{:status => true})
    @inactive_bank_details = BankField.find(:all,:order => "name asc",:conditions=>{:status => false})
    @bank_field = BankField.new(params[:bank_field])
    if request.post? and @bank_field.save
      flash[:notice] =t('flash11')
      redirect_to :controller => "employee", :action => "add_bank_details"
    end
  end

  def edit_bank_details
    @bank_details = BankField.find(params[:id])
    if request.post? and @bank_details.update_attributes(params[:bank_details])
      flash[:notice] = t('flash12')
      redirect_to :action => "add_bank_details"
    end
  end
  def delete_bank_details
    employees = EmployeeBankDetail.find(:all ,:conditions=>"bank_field_id = #{params[:id]}")
    if employees.empty?
      BankField.find(params[:id]).destroy
      @bank_details = BankField.find(:all)
      flash[:notice]=t('flash3')
      redirect_to :action => "add_bank_details"
    else
      flash[:warn_notice]=t('flash4')
      redirect_to :action => "add_bank_details"
    end
  end

  def add_additional_details
    @all_details = AdditionalField.find(:all,:order=>"priority ASC")
    @additional_details = AdditionalField.find(:all, :conditions=>{:status=>true},:order=>"priority ASC")
    @inactive_additional_details = AdditionalField.find(:all, :conditions=>{:status=>false},:order=>"priority ASC")
    @additional_field = AdditionalField.new
    @additional_field_option = @additional_field.additional_field_options.build
    if request.post?
      priority = 1
      unless @all_details.empty?
        last_priority = @all_details.map{|r| r.priority}.compact.sort.last
        priority = last_priority + 1
      end
      @additional_field = AdditionalField.new(params[:additional_field])
      @additional_field.priority = priority
      if @additional_field.save
        flash[:notice] = t('flash13')
        redirect_to :controller => "employee", :action => "add_additional_details"
      end
    end
  end

  def change_field_priority
    @additional_field = AdditionalField.find(params[:id])
    priority = @additional_field.priority
    @additional_fields = AdditionalField.find(:all, :conditions=>{:status=>true}, :order=> "priority ASC").map{|b| b.priority.to_i}
    position = @additional_fields.index(priority)
    if params[:order]=="up"
      prev_field = AdditionalField.find_by_priority(@additional_fields[position - 1])
    else
      prev_field = AdditionalField.find_by_priority(@additional_fields[position + 1])
    end
    @additional_field.update_attributes(:priority=>prev_field.priority)
    prev_field.update_attributes(:priority=>priority.to_i)
    @additional_field = AdditionalField.new
    @additional_details = AdditionalField.find(:all, :conditions=>{:status=>true},:order=>"priority ASC")
    @inactive_additional_details = AdditionalField.find(:all, :conditions=>{:status=>false},:order=>"priority ASC")
    render(:update) do|page|
      page.replace_html "category-list", :partial=>"additional_fields"
    end
  end

  def edit_additional_details
    @additional_details = AdditionalField.find(:all, :conditions=>{:status=>true},:order=>"priority ASC")
    @inactive_additional_details = AdditionalField.find(:all, :conditions=>{:status=>false},:order=>"priority ASC")
    @additional_field = AdditionalField.find(params[:id])
    @additional_field_option = @additional_field.additional_field_options
    if request.get?
      render :action=>'add_additional_details'
    else
      if @additional_field.update_attributes(params[:additional_field])
        flash[:notice] = t('flash14')
        redirect_to :action => "add_additional_details"
      else
        render :action=>"add_additional_details"
      end
    end
  end

  def delete_additional_details
    if params[:id]
      employees = EmployeeAdditionalDetail.find(:all ,:conditions=>"additional_field_id = #{params[:id]}")
      if employees.empty?
        AdditionalField.find(params[:id]).destroy
        @additional_details = AdditionalField.find(:all)
        flash[:notice]=t('flash3')
        redirect_to :action => "add_additional_details"
      else
        flash[:warn_notice]=t('flash4')
        redirect_to :action => "add_additional_details"
      end
    else
      redirect_to :action => "add_additional_details"
    end
  end

  def admission1
    @user = current_user
    @user_name = @user.username
    @employee1 = @user.employee_record
    @categories = EmployeeCategory.find(:all,:order => "name asc",:conditions => "status = true")
    @positions = []
    @grades = EmployeeGrade.find(:all,:order => "name asc",:conditions => "status = true")
    @departments = EmployeeDepartment.active_and_ordered
    @nationalities = Country.all
    @employee = Employee.new(params[:employee])
    @selected_value = Configuration.default_country
    @last_admitted_employee = User.last(:select=>"username",:conditions=>["employee=? and username <> ?",true,'admin'])
    @next_admission_no=User.next_admission_no("employee")
    @config = Configuration.find_by_config_key('EmployeeNumberAutoIncrement')

    if request.post?

      unless params[:employee][:employee_number].to_i ==0
        @employee.employee_number=params[:employee][:employee_number].to_s
      end
      unless @employee.employee_number.to_s.downcase == 'admin'
        if @employee.save
          flash[:notice] = "#{t('flash15')} #{@employee.first_name} #{t('flash16')}"
          redirect_to :controller =>"employee" ,:action => "admission2", :id => @employee.id
        else
          fetch_transport_data
        end
      else
        @employee.errors.add(:employee_number, "#{t('should_not_be_admin')}")
        fetch_transport_data
      end
      @positions = EmployeePosition.find_all_by_employee_category_id(params[:employee][:employee_category_id])
    end
  end

  def update_positions
    category = EmployeeCategory.find(params[:category_id])
    @positions = EmployeePosition.find_all_by_employee_category_id(category.id,:conditions=>'status = 1')
    render :update do |page|
      page.replace_html 'positions1', :partial => 'positions', :object => @positions
    end
  end

  def edit1
    @categories = EmployeeCategory.find(:all,:order => "name asc", :conditions => "status = true")
    @positions = EmployeePosition.find(:all)
    @grades = EmployeeGrade.find(:all,:order => "name asc", :conditions => "status = true")
    @departments = EmployeeDepartment.active_and_ordered
    @employee = Employee.find(params[:id])
    unless @employee.gender.nil?
      @employee.gender=@employee.gender.downcase
    end
    @employee_user = @employee.user
    @employee.biometric_id = BiometricInformation.find_by_user_id(@employee.user_id).try(:biometric_id)
    if request.post?
      #@employee.biometric_id = params[:employee][:biometric_id]
      if  params[:employee][:employee_number].downcase != 'admin' or @employee_user.admin
        if @employee.update_attributes(params[:employee])
          flash[:notice] = "#{t('flash15')}  #{@employee.first_name} #{t('flash17')}"
          redirect_to :controller =>"employee" ,:action => "profile", :id => @employee.id
        end
      else
        @employee.errors.add(:employee_number, "#{t('should_not_be_admin')}")
      end
    end
  end

  def edit_personal
    @nationalities = Country.all
    @employee = Employee.find(params[:id])
    if request.put?
      size = 0
      size =  params[:employee][:image_file].size.to_f unless  params[:employee][:image_file].nil?
      if size < 280000
        if @employee.update_attributes(params[:employee])
          flash[:notice] = "#{t('flash15')}  #{@employee.first_name} #{t('flash18')}"
          redirect_to :controller =>"employee" ,:action => "profile", :id => @employee.id
        end
      else
        flash[:notice] = t('flash19')
        redirect_to :controller => "employee", :action => "edit_personal", :id => @employee.id
      end
    end
  end

  def admission2
    @countries = Country.find(:all)
    @employee = Employee.find(params[:id])
    @selected_value = Configuration.default_country
    if request.post? and @employee.update_attributes(params[:employee])
      #      sms_setting = SmsSetting.new()
      #      if sms_setting.application_sms_active and sms_setting.employee_sms_active
      #        recipient = ["#{@employee.mobile_phone}"]
      #        message = "#{t('employee_admission_done_for')} #{@employee.first_name} #{@employee.last_name}. #{t('username_is')} #{@employee.employee_number}, #{t('guardian_password_is')} #{@employee.employee_number}123. #{t('thanks')}"
      #        Delayed::Job.enqueue(SmsManager.new(message,recipient))
      #      end
      flash[:notice] = "#{t('flash20')} #{ @employee.first_name}"
      redirect_to :action => "admission3", :id => @employee.id
    end
  end

  def edit2
    @employee = Employee.find(params[:id])
    @countries = Country.find(:all)
    if request.post? and @employee.update_attributes(params[:employee])
      flash[:notice] = "#{t('flash21')} #{ @employee.first_name}"
      redirect_to :action => "profile", :id => @employee.id
    end
  end

  def edit_contact
    @employee = Employee.find(params[:id])
    if request.post? and @employee.update_attributes(params[:employee])
      User.update(@employee.user.id, :email=> @employee.email, :role=>@employee.user.role_name)
      flash[:notice] = "#{t('flash22')} #{ @employee.first_name}"
      redirect_to :action => "profile", :id => @employee.id
    end
  end


  def admission3
    @employee = Employee.find(params[:id])
    @bank_fields = BankField.find(:all, :conditions=>"status = true")
    if @bank_fields.empty?
      redirect_to :action => "admission3_1", :id => @employee.id
    end
    if request.post?
      params[:employee_bank_details].each_pair do |k, v|
        EmployeeBankDetail.create(:employee_id => params[:id],
          :bank_field_id => k,:bank_info => v['bank_info'])
      end
      flash[:notice] = "#{t('flash23')} #{@employee.first_name}"
      redirect_to :action => "admission3_1", :id => @employee.id
    end
  end

  def edit3
    @employee = Employee.find(params[:id])
    @bank_fields = BankField.find(:all, :conditions=>"status = true")
    if @bank_fields.empty?
      flash[:notice] = "#{t('flash35')}"
      redirect_to :action => "profile", :id => @employee.id
    end
    if request.post?
      params[:employee_bank_details].each_pair do |k, v|
        row_id= EmployeeBankDetail.find_by_employee_id_and_bank_field_id(@employee.id,k)
        unless row_id.nil?
          bank_detail = EmployeeBankDetail.find_by_employee_id_and_bank_field_id(@employee.id,k)
          EmployeeBankDetail.update(bank_detail.id,:bank_info => v['bank_info'])
        else
          EmployeeBankDetail.create(:employee_id=>@employee.id,:bank_field_id=>k,:bank_info=>v['bank_info'])
        end
      end
      flash[:notice] = "#{t('flash15')}#{' '}#{@employee.first_name} #{t('flash12')}"
      redirect_to :action => "profile", :id => @employee.id
    end
  end

  #  def admission3_1
  #    @employee = Employee.find(params[:id])
  #    @additional_fields = AdditionalField.find(:all, :conditions=>"status = true")
  #    if @additional_fields.empty?
  #      redirect_to :action => "edit_privilege", :id => @employee.employee_number
  #    end
  #    if request.post?
  #      params[:employee_additional_details].each_pair do |k, v|
  #        EmployeeAdditionalDetail.create(:employee_id => params[:id],
  #          :additional_field_id => k,:additional_info => v['additional_info'])
  #      end
  #      flash[:notice] = "#{t('flash25')}#{@employee.first_name}"
  #      redirect_to :action => "edit_privilege", :id => @employee.employee_number
  #    end
  #  end

  def admission3_1
    @employee = Employee.find(params[:id])
    @employee_additional_details = EmployeeAdditionalDetail.find_all_by_employee_id(@employee.id)
    @additional_fields = AdditionalField.find(:all, :conditions=> "status = true", :order=>"priority ASC")
    if @additional_fields.empty?
      redirect_to :action => "edit_privilege", :id => @employee.employee_number
    end
    if request.post?
      @error=false
      mandatory_fields = AdditionalField.find(:all, :conditions=>{:is_mandatory=>true, :status=>true})
      mandatory_fields.each do|m|
        unless params[:employee_additional_details][m.id.to_s.to_sym].present?
          @employee.errors.add_to_base("#{m.name} must contain atleast one selected option.")
          @error=true
        else
          if params[:employee_additional_details][m.id.to_s.to_sym][:additional_info]==""
            @employee.errors.add_to_base("#{m.name} cannot be blank.")
            @error=true
          end
        end
      end
      unless @error==true
        additional_field_ids_posted = []
        additional_field_ids = @additional_fields.map(&:id)
        if params[:employee_additional_details].present?
          params[:employee_additional_details].each_pair do |k, v|
            addl_info = v['additional_info']
            additional_field_ids_posted << k.to_i
            addl_field = AdditionalField.find_by_id(k)
            if addl_field.input_type == "has_many"
              addl_info = addl_info.join(", ")
            end
            prev_record = EmployeeAdditionalDetail.find_by_employee_id_and_additional_field_id(params[:id], k)
            unless prev_record.nil?
              unless addl_info.present?
                prev_record.destroy
              else
                prev_record.update_attributes(:additional_info => addl_info)
              end
            else
              addl_detail = EmployeeAdditionalDetail.new(:employee_id => params[:id],
                :additional_field_id => k,:additional_info => addl_info)
              addl_detail.save if addl_detail.valid?
            end
          end
        end
        if additional_field_ids.present?
          EmployeeAdditionalDetail.find_all_by_employee_id_and_additional_field_id(params[:id],(additional_field_ids - additional_field_ids_posted)).each do |additional_info|
            additional_info.destroy unless additional_info.additional_field.is_mandatory == true
          end
        end

        unless params[:edit_request].present?
          flash[:notice] = "#{t('flash25')}#{@employee.first_name}"
          redirect_to :action => "edit_privilege", :id => @employee.employee_number
        else
          flash[:notice] = "#{t('flash15')}#{' '}#{@employee.first_name} #{t('flash14')}"
          redirect_to :action => "profile", :id => @employee.id
        end
      end
    end
  end

  def edit_privilege
    user_name = params[:user_name].join('/')
    @user = User.active.first(:conditions => ["username LIKE BINARY(?)",user_name])
    @employee = @user.employee_record
    @finance = Configuration.find_by_config_value("Finance")
    @sms_setting = SmsSetting.application_sms_status
    @hr = Configuration.find_by_config_value("HR")
    @privilege_tags = {}
    privilege_tags=PrivilegeTag.find(:all, :joins => :privileges, :include => :privileges, :order=>"priority ASC", :group => "privilege_tags.id")
    privilege_tags.each do |pt|
      @privilege_tags[pt] = pt.privileges.all(:conditions=>"name<>'FinanceControl'",:order=>"priority ASC").select{|p| p.applicable?}
    end
    @privilege_tags = @privilege_tags.sort_by{|k,v| k.priority}
    @user_privileges=@user.privileges
    if request.post?
      new_privileges = params[:user][:privilege_ids] if params[:user]
      new_privileges ||= []
      @user.privileges = Privilege.find_all_by_id(new_privileges)
      @user.clear_menu_cache
      redirect_to :action => 'admission4',:id => @employee.id
    end
  end

  def edit3_1
    @employee = Employee.find(params[:id])
    @additional_fields = AdditionalField.find(:all, :conditions=>"status = true")
    if @additional_fields.empty?
      flash[:notice] = "#{t('flash37')}"
      redirect_to :action => "profile", :id => @employee.id
    end
    if request.post?
      params[:employee_additional_details].each_pair do |k, v|
        row_id= EmployeeAdditionalDetail.find_by_employee_id_and_additional_field_id(@employee.id,k)
        unless row_id.nil?
          additional_detail = EmployeeAdditionalDetail.find_by_employee_id_and_additional_field_id(@employee.id,k)
          EmployeeAdditionalDetail.update(additional_detail.id,:additional_info => v['additional_info'])
        else
          EmployeeAdditionalDetail.create(:employee_id=>@employee.id,:additional_field_id=>k,:additional_info=>v['additional_info'])
        end
      end
      flash[:notice] = "#{t('flash15')}#{@employee.first_name} #{t('flash14')}"
      redirect_to :action => "profile", :id => @employee.id
    end
  end

  def admission4
    @departments = EmployeeDepartment.ordered
    @categories  = EmployeeCategory.find(:all)
    @positions   = EmployeePosition.find(:all)
    @grades      = EmployeeGrade.find(:all)
    if request.post?
      @employee = Employee.find(params[:id])
      manager=Employee.find_by_id(params[:employee][:reporting_manager_id])
      if manager.present?
        Employee.update(@employee, :reporting_manager_id => manager.user_id)
      end
      flash[:notice]=t('flash25')
      redirect_to :controller => "payroll", :action => "manage_payroll", :id=>@employee.id, :from => 'employee_admission'
    end

  end

  def view_rep_manager
    @employee= Employee.find(params[:id])
    @reporting_manager = @employee.reporting_manager.first_name unless @employee.reporting_manager_id.nil?
    render :partial => "view_rep_manager"
  end

  def change_reporting_manager
    @departments = EmployeeDepartment.ordered
    @categories  = EmployeeCategory.find(:all)
    @positions   = EmployeePosition.find(:all)
    @grades      = EmployeeGrade.find(:all)
    @emp = Employee.find(params[:id])
    @reporting_manager = @emp.reporting_manager
    if request.post?
      manager = Employee.find_by_id(params[:employee][:reporting_manager_id])
      if manager.present?
        @emp.update_attributes(:reporting_manager_id => manager.user_id)
      else
        @emp.update_attributes(:reporting_manager_id => nil)
      end
      flash[:notice]=t('flash26')
      redirect_to :action => "profile", :id=>@emp.id
    end
  end

  def update_reporting_manager_name
    employee = Employee.find_by_id(params[:employee_reporting_manager_id])
    render :text => employee.first_name + ' ' + employee.last_name
  end

  def search
    @departments = EmployeeDepartment.active_and_ordered
    @categories  = EmployeeCategory.active.find(:all,:order=>'name ASC')
    @positions   = EmployeePosition.active.find(:all,:order=>'name ASC')
    @grades      = EmployeeGrade.active.find(:all,:order=>'name ASC')
  end

  def search_ajax
    if params[:query].present?
      other_conditions = ""
    else
      other_conditions = "1"
    end 
    other_conditions += " AND employee_department_id = '#{params[:employee_department_id]}'" unless params[:employee_department_id] == ""
    other_conditions += " AND  employee_category_id = '#{params[:employee_category_id]}'" unless params[:employee_category_id] == ""
    other_conditions += " AND employee_position_id = '#{params[:employee_position_id]}'" unless params[:employee_position_id] == ""
    other_conditions += " AND employee_grade_id = '#{params[:employee_grade_id]}'" unless params[:employee_grade_id] == ""
    if params[:query].present?
      @employee = Employee.find(:all,
        :conditions => ["(ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                        OR employee_number = ? OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(last_name))) LIKE ? )
                          OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \", ltrim(rtrim(last_name))) LIKE ? ))"+ other_conditions,
          "#{params[:query]}%","#{params[:query]}%","#{params[:query]}%",
          "#{params[:query]}", "#{params[:query]}%", "#{params[:query]}%" ],
        :order => "employee_department_id asc,first_name asc",:include=>"employee_department") unless params[:query] == ''
    else
      @employee = Employee.find(:all,
        :conditions => [other_conditions],
        :order => "employee_department_id asc,first_name asc",:include=>"employee_department")
    end
    render :update do |page|
      page.replace_html 'information' , :partial => 'search_ajax'
    end
  end

  def select_reporting_manager
    other_conditions = ""
    other_conditions += " AND employee_department_id = '#{params[:employee_department_id]}'" unless params[:employee_department_id] == ""
    other_conditions += " AND employee_category_id = '#{params[:employee_category_id]}'" unless params[:employee_category_id] == ""
    other_conditions += " AND employee_position_id = '#{params[:employee_position_id]}'" unless params[:employee_position_id] == ""
    other_conditions += " AND employee_grade_id = '#{params[:employee_grade_id]}'" unless params[:employee_grade_id] == ""
    if params[:query].length>= 3
      @employee = Employee.find(:all,
        :conditions => ["(first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ?
                       OR employee_number = ? OR (concat(first_name, \" \", last_name) LIKE ? ))"+ other_conditions,
          "#{params[:query]}%","#{params[:query]}%","#{params[:query]}%",
          "#{params[:query]}", "#{params[:query]}" ],
        :order => "employee_department_id asc,first_name asc") unless params[:query] == ''
    else
      @employee = Employee.find(:all,
        :conditions => ["(employee_number = ? )"+ other_conditions, "#{params[:query]}"],
        :order => "employee_department_id asc,first_name asc",:include=>"employee_department") unless params[:query] == ''
    end
    render :layout => false
  end

  def profile
    @current_user = current_user
    @employee = Employee.find(params[:id])
    @gender = "Male"
    @gender = "Female" if @employee.gender.downcase == "f"
    @status = "Active"
    @status = "Inactive" if @employee.status == false
    @reporting_manager = @employee.reporting_manager
    @biometric_id = BiometricInformation.find_by_user_id(@employee.user_id).try(:biometric_id)
    years = @employee.find_experience_years
    months = @employee.find_experience_months
    year = months/12
    month = months%12
    @total_years = years + year
    @total_months = month

  end

  def profile_general
    @employee = Employee.find(params[:id])
    @gender = "Male"
    @gender = "Female" if @employee.gender.downcase == "f"
    @status = "Active"
    @status = "Inactive" if @employee.status == false
    @reporting_manager = @employee.reporting_manager
    years = @employee.find_experience_years
    months = @employee.find_experience_months
    year = months/12
    month = months%12
    @total_years = years + year
    @total_months = month
    render :partial => "general"
  end

  def profile_personal
    @employee = Employee.find(params[:id])
    render :partial => "personal"
  end

  def profile_address
    @employee = Employee.find(params[:id])
    @home_country = @employee.home_country.try(:full_name)#Country.find(@employee.home_country_id).name unless @employee.home_country_id.nil?
    @office_country = @employee.office_country.try(:full_name)#Country.find(@employee.office_country_id).name unless @employee.office_country_id.nil?
    render :partial => "address"
  end

  def profile_contact
    @employee = Employee.find(params[:id])
    render :partial => "contact"
  end

  def profile_bank_details
    @employee = Employee.find(params[:id])
    @bank_details = EmployeeBankDetail.find_all_by_employee_id(@employee.id)
    render :partial => "bank_details"
  end

  def profile_additional_details
    @employee = Employee.find(params[:id])
    @additional_details = AdditionalField.find(:all, :conditions=>{:status=>true},:order=>"priority ASC")
    #    @additional_details = EmployeeAdditionalDetail.find_all_by_employee_id(@employee.id).select{|a| a.additional_field.status==true}
    render :partial => "additional_details"
  end


  def profile_payroll_details
    @employee = Employee.find(params[:id], :include => [{:employee_salary_structure => {:employee_salary_structure_components => :payroll_category}}, :payroll_group])
    if @employee.employee_salary_structure
      @earnings = @employee.employee_salary_structure.earning_components
      @deductions = @employee.employee_salary_structure.deduction_components
    end
    render :partial => "payroll_details"
  end

  def profile_pdf
    @employee = Employee.find(params[:id])
    @gender = "Male"
    @gender = "Female" if @employee.gender.downcase == "f"
    @status = "Active"
    @status = "Inactive" if @employee.status == false
    @reporting_manager = @employee.reporting_manager unless @employee.reporting_manager_id.nil?
    years = @employee.find_experience_years
    months = @employee.find_experience_months
    year = months/12
    month = months%12
    @total_years = years + year
    @total_months = month
    @home_country = @employee.home_country.try(:full_name)
    @office_country = @employee.office_country.try(:full_name)
    @bank_details = EmployeeBankDetail.find_all_by_employee_id(@employee.id)
    @additional_details = EmployeeAdditionalDetail.find_all_by_employee_id(@employee.id).select{|a| a.additional_field.status==true}
    @biometric_id = BiometricInformation.find_by_user_id(@employee.user_id).try(:biometric_id)
    render :pdf => 'profile_pdf'


    #    respond_to do |format|
    #      format.pdf { render :layout => false }
    #    end
  end

  def view_all
    @departments = EmployeeDepartment.active_and_ordered
  end

  def employees_list
    department_id = params[:department_id]
    @employees = Employee.find_all_by_employee_department_id(department_id,:order=>'first_name ASC')

    render :update do |page|
      page.replace_html 'employee_list', :partial => 'employee_view_all_list', :object => @employees
    end
  end

  def show
    @employee = Employee.find(params[:id])
    send_data(@employee.photo_data, :type => @employee.photo_content_type, :filename => @employee.photo_filename, :disposition => 'inline')
  end

  def view_payslip
    @employee = Employee.find(params[:id])
    @salary_dates =EmployeePayslip.all(:conditions => ["employee_id = ? and is_approved = ? and employee_type = 'Employee'", params[:id],true], :joins => :payslips_date_range, :include => {:payslips_date_range => :payroll_group}, :select => "payslips_date_ranges.start_date, payslips_date_ranges.end_date, employee_payslips.payslips_date_range_id, employee_payslips.id", :order => "payslips_date_ranges.start_date desc")
    render :partial => "select_dates"
  end

  def update_monthly_payslip
    @currency_type = currency
    @current_user = current_user
    unless params[:employee_payslip_id]==nil
      @employee_payslip = EmployeePayslip.find( params[:employee_payslip_id])
      @employee = @employee_payslip.employee
      @payslip_date_range = @employee_payslip.payslips_date_range
      @start_date = @payslip_date_range.start_date
      @end_date = @payslip_date_range.end_date
      @monthly_payslips = @employee_payslip.employee_payslip_categories.all(:include => :payroll_category)
      @individual_payslip_category = @employee_payslip.individual_payslip_categories
      @net_amount = @employee_payslip.net_pay
      render :update do |page|
        page.replace_html "payslip_view", :partial => "view_payslip"
      end
    else
      flash[:notice]="#{t('flash_msg4')}"
      redirect_to :controller => 'user', :action => 'dashboard'
    end
  end

  def view_attendance
    @employee = Employee.find(params[:id])
    @attendance_report = EmployeeAttendance.find_all_by_employee_id(@employee.id)
    @leave_types = EmployeeLeaveType.find(:all, :conditions => "creation_status = 2")
    @leave_count = EmployeeLeave.find_all_by_employee_id(@employee,:joins=>:employee_leave_type,:conditions=>"creation_status = 2")
    render :partial => "attendance_report"
  end

  def employee_leave_count_edit
    @leave_count = EmployeeLeave.find_by_id(params[:id])
    @leave_type = EmployeeLeaveType.find_by_id(params[:leave_type])

    render :update do |page|
      page.replace_html 'profile-infos', :partial => 'edit_leave_count'
    end
  end

  def employee_leave_count_update
    available_leave = params[:leave_count][:leave_count]
    leave = EmployeeLeave.find_by_id(params[:id])
    leave.update_attributes(:leave_count => available_leave.to_f)
    @employee = Employee.find(leave.employee_id)
    @attendance_report = EmployeeAttendance.find_all_by_employee_id(@employee.id)
    @leave_types = EmployeeLeaveType.find(:all, :conditions => "creation_status = 2")
    @leave_count = EmployeeLeave.find_all_by_employee_id(@employee,:joins=>:employee_leave_type,:conditions=>"creation_status = 2")
    @total_leaves = 0
    @leave_types.each do |lt|
      leave_count = EmployeeAttendance.find_all_by_employee_id_and_employee_leave_type_id(@employee.id,lt.id).size
      @total_leaves = @total_leaves + leave_count
    end
    render :update do |page|
      page.replace_html 'profile-infos',:partial => "attendance_report"
    end
  end

  def subject_assignment
    @batches = Batch.active
    if params[:batch_id].present?
      batch = Batch.find(params[:batch_id])
      @subjects = Subject.find_all_by_batch_id(batch.id,:conditions=>"is_deleted=false",:order=>'name ASC')
    else
      @subjects = []
    end
  end

  def update_subjects
    unless params[:batch_id] == ""
      batch = Batch.find(params[:batch_id])
      @subjects = Subject.find_all_by_batch_id(batch.id,:conditions=>"is_deleted=false",:order=>'name ASC')
    end
    render :update do |page|
      page.replace_html 'subjects1', :partial => 'subjects', :object => @subjects unless params[:batch_id]==""
      page.replace_html 'subjects1', :partial => 'subjects', :object => @subjects=[] if params[:batch_id]==""
      page.replace_html 'department-select',  ''
      page.replace_html 'flash_msg_div',''
    end
  end

  def select_department
    unless params[:subject_id]==""
      @subject = Subject.find(params[:subject_id])
      @assigned_employee = EmployeesSubject.find_all_by_subject_id(@subject.id).sort_by{|s| s.employee.full_name.downcase}
    end
    @departments = EmployeeDepartment.active_and_ordered
    render :update do |page|
      page.replace_html 'department-select', :partial => 'select_department' unless params[:subject_id]==""
      page.replace_html 'department-select', '' if params[:subject_id]==""
      page.replace_html 'flash_msg_div','' if (params[:subject_id] !="" and @assigned_employee.count!=0) or params[:subject_id]==""
      # page.replace_html 'flsh',''
    end
  end

  def update_employees
    @subject = Subject.find(params[:subject_id])
    assigned_employee = EmployeesSubject.find_all_by_subject_id(@subject.id, :select => :employee_id).map(&:employee_id)
    if assigned_employee.present?
      @employees = Employee.find_all_by_employee_department_id(params[:department_id],:include=>:user,:conditions=>["users.admin=? AND employees.id NOT in (#{assigned_employee.join(',')})",false]).sort_by{|s| s.full_name.downcase}
    else
      @employees = Employee.find_all_by_employee_department_id(params[:department_id]).sort_by{|s| s.full_name.downcase}
    end
    @department_id = params[:department_id]
    render :update do |page|
      page.replace_html 'employee-list', :partial => 'employee_list'
    end
  end

  def assign_employee
    @departments = EmployeeDepartment.active_and_ordered
    @subject = Subject.find(params[:id1])
    EmployeesSubject.create(:employee_id => params[:id], :subject_id => params[:id1])
    @department_id = Employee.find(params[:id]).employee_department_id
    @assigned_employee = EmployeesSubject.find_all_by_subject_id(@subject.id).sort_by{|s| s.employee.full_name.downcase}
    if @assigned_employee.present?
      @employees = Employee.find_all_by_employee_department_id(@department_id, :include => :user, :conditions => ["users.admin=? AND employees.id NOT in (#{@assigned_employee.map(&:employee_id).join(',')})",false]).sort_by{|s| s.full_name.downcase}
    else
      @employees = Employee.find_all_by_employee_department_id(@department_id, :include => :user, :conditions => ["users.admin=?",false]).sort_by{|s| s.full_name.downcase}
    end
    @show_employees = true
    flash[:notice]="#{t('subject_assigned_successfully')}"
    render :update do |page|
      page.replace_html 'department-select', :partial => 'select_department'
      page.replace_html 'employee-list', :partial => 'employee_list'
      page.replace_html 'flash_msg_div', ''
    end
  end

  def remove_employee
    @department_id = Employee.find(params[:id]).employee_department_id
    @departments = EmployeeDepartment.active_and_ordered
    @subject = Subject.find(params[:id1])
    if TimetableEntry.find_all_by_subject_id_and_employee_id(@subject.id,params[:id]).blank?
      EmployeesSubject.find_by_employee_id_and_subject_id(params[:id], params[:id1]).destroy
      flash[:notice]="#{t('subject_de_assigned_successfully')}"
    else
      flash.now[:warn_notice]="<p>#{t('employee.flash41')}</p> <p>#{t('employee.flash42')}</p> "
    end
    @assigned_employee = EmployeesSubject.find_all_by_subject_id(@subject.id).sort_by{|s| s.employee.full_name.downcase}
    if @assigned_employee.present?
      @employees = Employee.find_all_by_employee_department_id(@department_id, :include => :user, :conditions => ["users.admin=? AND employees.id NOT in (#{@assigned_employee.map(&:employee_id).join(',')})",false]).sort_by{|s| s.full_name.downcase}
    else
      @employees = Employee.find_all_by_employee_department_id(@department_id, :include => :user, :conditions => ["users.admin=?",false]).sort_by{|s| s.full_name.downcase}
    end
    render :update do |page|
      page.replace_html 'flash_msg_div',:text=>"<p class='flash-msg'>#{t('no_employee_assigned')}</p>" unless @assigned_employee.present?
      page.replace_html 'department-select', :partial => 'select_department'
      page.replace_html 'employee-list', :partial => 'employee_list'
    end
  end

  #HR Management special methods...

  def hr
    user = current_user
    @employee = user.employee_record
  end
  #
  #  def leave_management
  #    user = current_user
  #    @employee = user.employee_record
  #    @all_employee = Employee.find(:all)
  #    @reporting_employees = Employee.find_all_by_reporting_manager_id(@employee.user_id)
  #    @leave_types = EmployeeLeaveType.find(:all)
  #    @total_leave_count = 0
  #    @reporting_employees.each do |e|
  #      @app_leaves = ApplyLeave.count(:conditions=>["employee_id =? AND viewed_by_manager =?", e.id, false])
  #      @total_leave_count = @total_leave_count + @app_leaves
  #    end
  #    @all_employee_total_leave_count = 0
  #    @all_employee.each do |a|
  #      @all_emp_app_leaves = ApplyLeave.count(:conditions=>["employee_id =? AND viewed_by_manager =?" , a.id, false])
  #      @all_employee_total_leave_count = @all_employee_total_leave_count + @all_emp_app_leaves
  #    end
  #
  #    @leave_apply = ApplyLeave.new(params[:leave_apply])
  #    if request.post? and @leave_apply.save
  #      leaves_half_day = ApplyLeave.count(:all,:conditions=>{:employee_id=>params[:leave_apply][:employee_id],:start_date=>params[:leave_apply][:start_date],:end_date=>params[:leave_apply][:end_date],:is_half_day=>true})
  #      leaves = ApplyLeave.count(:all,:conditions=>{:approved => true, :employee_id=>params[:leave_apply][:employee_id],:start_date=>params[:leave_apply][:start_date],:end_date=>params[:leave_apply][:end_date]})
  #      already_apply = ApplyLeave.count(:all,:conditions=>{:approved => nil, :employee_id=>params[:leave_apply][:employee_id],:start_date=>params[:leave_apply][:start_date],:end_date=>params[:leave_apply][:end_date]})
  #      if(leaves == 0 and already_apply == 0) or (leaves <= 1 and leaves_half_day < 2)
  #        unless leaves_half_day == 1 and params[:leave_apply][:is_half_day]=='0'
  #          if @leave_apply.save
  #            ApplyLeave.update(@leave_apply, :approved=> nil, :viewed_by_manager=> false)
  #            flash[:notice]=t('flash30')
  #            redirect_to :controller => "employee", :action=> "leave_management", :id=>@employee.id
  #          end
  #        else
  #          @leave_apply.errors.add_to_base("#{t('half_day_alredy_applied')}")
  #        end
  #      else
  #        @leave_apply.errors.add_to_base("#{t('already_applied')}")
  #      end
  #    end
  #  end

  def all_employee_leave_applications

    @employee = Employee.find(params[:id])
    @departments = EmployeeDepartment.ordered
    @employees = []
    #   render :partial=> "all_employee_leave_applications"
  end

  def update_employees_select
    @employee = params[:emp_id]
    department_id = params[:department_id]
    @employees = Employee.find_all_by_employee_department_id(department_id)

    render :update do |page|
      page.replace_html 'employees_select', :partial => 'employee_select', :object => @employees
    end
  end

  def leave_list
    if params[:employee_id] == ""
      render :update do |page|
        page.replace_html "leave-list", :text => "none"
      end
      return
    end
    @employee = params[:emp_id]
    @pending_applied_leaves = ApplyLeave.find_all_by_employee_id(params[:employee_id], :conditions=> "approved = false AND viewed_by_manager = false", :order=>"start_date DESC")
    @applied_leaves = ApplyLeave.find_all_by_employee_id(params[:employee_id], :conditions=> "viewed_by_manager = true", :order=>"start_date DESC")
    @all_leave_applications = ApplyLeave.find_all_by_employee_id(params[:employee_id])
    render :update do |page|
      page.replace_html "leave-list", :partial => "leave_list"
    end
  end

  def advanced_search
    @search = Employee.search(params[:search])
    @sort_order=""
    @sort_order=params[:sort_order] if  params[:sort_order]
    if params[:search]
      if params[:search][:status_equals]=="true"
        @employees = Employee.ascend_by_first_name.search(params[:search]).paginate(:page => params[:page], :per_page => 30)
        #        @employees1 = @search.all
        #        @employees2 = []
      elsif params[:search][:status_equals]=="false"
        @employees = ArchivedEmployee.ascend_by_first_name.search(params[:search]).paginate(:page => params[:page], :per_page => 30)
        #        @employees1 = @search.all
        #        @employees2 = []
      else
        @employees = [{:employee => {:search_options => params[:search], :order => :first_name}}, {:archived_employee => {:search_options => params[:search], :order => :first_name}}].model_paginate(:page => params[:page],:per_page => 30)
        #        @search1 = Employee.search(params[:search]).all
        #        @search2 = ArchivedEmployee.search(params[:search]).all
        #        @employees1 = @search1
        #        @employees2 = @search2
      end
    end
  end

  def list_doj_year
    doj_option = params[:doj_option]
    if doj_option == "equal_to"
      render :update do |page|
        page.replace_html 'doj_year', :partial=>"equal_to_select"
      end
    elsif doj_option == "less_than"
      render :update do |page|
        page.replace_html 'doj_year', :partial=>"less_than_select"
      end
    else
      render :update do |page|
        page.replace_html 'doj_year', :partial=>"greater_than_select"
      end
    end
  end

  def doj_equal_to_update
    year = params[:year]
    @start_date = "#{year}-01-01".to_date
    @end_date = "#{year}-12-31".to_date
    render :update do |page|
      page.replace_html 'doj_year_hidden', :partial=>"equal_to_doj_select"
    end
  end

  def doj_less_than_update
    year = params[:year]
    @start_date = "1900-01-01".to_date
    @end_date = "#{year}-01-01".to_date
    render :update do |page|
      page.replace_html 'doj_year_hidden', :partial=>"less_than_doj_select"
    end
  end

  def doj_greater_than_update
    year = params[:year]
    @start_date = "2100-01-01".to_date
    @end_date = "#{year}-12-31".to_date
    render :update do |page|
      page.replace_html 'doj_year_hidden', :partial=>"greater_than_doj_select"
    end
  end

  def list_dob_year
    dob_option = params[:dob_option]
    if dob_option == "equal_to"
      render :update do |page|
        page.replace_html 'dob_year', :partial=>"equal_to_select_dob"
      end
    elsif dob_option == "less_than"
      render :update do |page|
        page.replace_html 'dob_year', :partial=>"less_than_select_dob"
      end
    else
      render :update do |page|
        page.replace_html 'dob_year', :partial=>"greater_than_select_dob"
      end
    end
  end

  def dob_equal_to_update
    year = params[:year]
    @start_date = "#{year}-01-01".to_date
    @end_date = "#{year}-12-31".to_date
    render :update do |page|
      page.replace_html 'dob_year_hidden', :partial=>"equal_to_dob_select"
    end
  end

  def dob_less_than_update
    year = params[:year]
    @start_date = "1900-01-01".to_date
    @end_date = "#{year}-01-01".to_date
    render :update do |page|
      page.replace_html 'dob_year_hidden', :partial=>"less_than_dob_select"
    end
  end

  def dob_greater_than_update
    year = params[:year]
    @start_date = "2100-01-01".to_date
    @end_date = "#{year}-12-31".to_date
    render :update do |page|
      page.replace_html 'dob_year_hidden', :partial=>"greater_than_dob_select"
    end
  end

  def remove
    @employee = Employee.find(params[:id])
    if current_user == @employee.user
      flash[:notice] = "You cannot delete your own profile"
      redirect_to :controller => "user", :action => "dashboard" and return
    else
      associate_employee = Employee.find(:all, :conditions=>["reporting_manager_id=#{@employee.user_id}"])
      unless associate_employee.blank?
        flash[:notice] = t('flash35')
        redirect_to :action=>'remove_subordinate_employee', :id=>@employee.id
      end
    end
  end

  def remove_subordinate_employee
    @current_manager = Employee.find(params[:id])
    @associate_employee = Employee.find(:all, :conditions=>["reporting_manager_id=#{@current_manager.user_id}"])
    @departments = EmployeeDepartment.ordered
    @categories  = EmployeeCategory.find(:all)
    @positions   = EmployeePosition.find(:all)
    @grades      = EmployeeGrade.find(:all)
    if request.post?
      manager = Employee.find_by_id(params[:employee][:reporting_manager_id])
      @associate_employee.each do |e|
        if manager.present?
          e.update_attributes(:reporting_manager_id => manager.user_id)
        else
          e.update_attributes(:reporting_manager_id => nil)
        end
      end
      redirect_to :action => "remove", :id=>@current_manager.id
    end
  end

  def change_to_former
    @employee = Employee.find(params[:id])
    @dependency = @employee.former_dependency
    @payslip_dependency = @employee.check_pending_and_rejected_payslips
    if request.post?
      if current_user == @employee.user
        flash[:notice] = "You cannot delete your own profile"
        redirect_to :controller => "user", :action => "dashboard" and return
      else
        Delayed::Job.enqueue(DelayedArchiveEmployee.new(@employee.id, params[:remove][:status_description], params[:leaving_date]))
        flash[:notice] = "#{t('employee_text')} - #{@employee.employee_number} #{t('flash46')}. <a href='/scheduled_jobs?job_object=DelayedArchiveEmployee'>#{t('click_here')}</a>#{t('to_view_the_scheduled_job')}."
        if can_access_request?("hr".to_sym,@current_user,:context=>"employee".to_sym)
          redirect_to :action => "hr"
        else
          redirect_to :controller => "user",:action => "dashboard"
        end
      end
    end
  end

  def delete
    employee = Employee.find(params[:id])
    if current_user == employee.user
      flash[:notice] = "You cannot delete your own profile"
      redirect_to :controller => "user", :action => "dashboard" and return
    else
      unless employee.has_dependency
        employee_subject=EmployeesSubject.destroy_all(:employee_id=>employee.id)
        employee.leave_group_employee.destroy if employee.leave_group_employee.present?
        emp = employee
        emp_user = employee.user
        emp_user.privileges.destroy
        emp_user.reload
        employee.user.destroy
        emp.reload
        employee.destroy
        flash[:notice] = "#{t('flash32')} #{employee.employee_number}."
        redirect_to :controller => 'user', :action => 'dashboard'
      else
        flash[:notice] = "#{t('flash56')}"
        redirect_to  :action => 'remove' ,:id=>employee.id
      end
    end
  end

  def advanced_search_pdf
    @data_hash = Employee.fetch_employee_advance_search_data(params)
    render :pdf => 'employee_advanced_search_pdf',:show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
  end

  def activities
    @employee = Employee.find(params[:id])
    weekday_id = Date.parse(Date.today.to_s).strftime("%w")
    batch_id = Employee.find(params[:id]).subjects.collect{|e| e.batch_id}
    classrooms = Classroom.all
    buildings = Building.all
    hash = {}
    i = 1
    allocations = TimetableEntry.find(:all,:joins => :timetable,:include =>[:allocated_classrooms, :entry,:batch,:class_timing],:conditions => ["timetable_entries.weekday_id = ? and timetable_entries.batch_id IN (?) and timetables.start_date <= ? and timetables.end_date >= ?",weekday_id,batch_id,Date.today.to_s,Date.today.to_s],:order => "timetable_entries.class_timing_id")
    allocations.each do |a|
      unless a.entry_type == "ElectiveGroup"
        @assigned = a.employee_ids.include? @employee.id  #EmployeesSubject.find_by_employee_id_and_subject_id(@employee.id,a.entry_id)
        next if !@assigned #.nil?
        hash[i] = {}
        hash[i]["class_timing"] = a.class_timing.start_time.strftime("%I:%M %P") + " - " + a.class_timing.end_time.strftime("%I:%M %P")
        hash[i]["subject"] = a.assigned_name
        hash[i]["batch"] = a.batch.full_name
        hash[i]["classroom"] = []
        hash[i]["building"] = []
        a.allocated_classrooms.each do |c|
          hash[i]["classroom"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => classrooms.select{|cr| cr.id == c.classroom_id }.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
          hash[i]["building"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => buildings.select{|b| b.id == classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.building_id}.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
        end
        i+= 1
      end
      if a.entry_type == "ElectiveGroup"
        s = a.entry.subjects.all(:joins => :employees,:conditions=> "employees.id = #{params[:id]}")
        #        s = Subject.find(:all,:joins => :employees,:conditions=> "subjects.elective_group_id = #{a.subject.elective_group_id} and employees.id = #{params[:id]}")
        s.each do |sub|
          @assigned = EmployeesSubject.find_by_employee_id_and_subject_id(@employee.id,sub.id)
          next if @assigned.nil?
          allocation = a.allocated_classrooms.select{|alloc| alloc.subject_id == sub.id }
          hash[i] = {}
          hash[i]["class_timing"] = a.class_timing.start_time.strftime("%I:%M %P") + " - " + a.class_timing.end_time.strftime("%I:%M %P")
          hash[i]["subject"] = sub.name
          hash[i]["batch"] = a.batch.full_name
          hash[i]["classroom"] = []
          hash[i]["building"] = []
          hash[i]["date"] = []
          allocation.each do |c|
            hash[i]["classroom"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
            hash[i]["building"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => buildings.select{|b| b.id == classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.building_id}.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
          end
          i+=1
        end
      end
    end
    @allocations = hash.sort
  end

  def employee_attendance
    @current_user = current_user
  end

  def edit_leave_balance
    @employee = Employee.find(params[:id])
    @employee_leaves = @employee.employee_leaves.active.all(:joins => :employee_leave_type, :conditions => ["employee_leave_types.is_active = ?",true], :select => "employee_leaves.id, employee_leaves.employee_leave_type_id, employee_leave_types.name, employee_leaves.leave_count, employee_leaves.is_additional")
    active_leave_ids = EmployeeLeaveType.active.collect(&:id)
    @remaining_leave_types = active_leave_ids - @employee_leaves.collect(&:employee_leave_type_id)
    @leave_group = @employee.leave_group
    @apply_leaves = ApplyLeave.all(:joins => "LEFT OUTER JOIN employee_leaves ON employee_leaves.employee_leave_type_id = apply_leaves.employee_leave_type_id AND employee_leaves.employee_id = apply_leaves.employee_id", :conditions => ["apply_leaves.employee_id = ? and apply_leaves.start_date >= employee_leaves.reset_date AND apply_leaves.created_at >= employee_leaves.reseted_at", @employee.id]).group_by(&:employee_leave_type_id)
    emp_attendances = EmployeeAttendance.all(:joins => "LEFT OUTER JOIN employee_leaves ON employee_leaves.employee_leave_type_id = employee_attendances.employee_leave_type_id AND employee_leaves.employee_id = employee_attendances.employee_id", :conditions => ["employee_attendances.employee_id = ? and attendance_date >= employee_leaves.reset_date AND employee_attendances.created_at >= employee_leaves.reseted_at", @employee.id])
    @employee_attendances = emp_attendances.group_by(&:employee_leave_type_id)
    @additional_leaves = EmployeeAdditionalLeave.all(:joins => "LEFT OUTER JOIN employee_leaves ON employee_leaves.employee_leave_type_id = employee_additional_leaves.employee_leave_type_id AND employee_leaves.employee_id = employee_additional_leaves.employee_id", :conditions => ["employee_additional_leaves.employee_id = ? and attendance_date >= employee_leaves.reset_date AND employee_additional_leaves.created_at >= employee_leaves.reseted_at", @employee.id]).group_by(&:employee_leave_type_id)
    if request.post?
      leave_count = params[:leave_count]
      lc_id = params[:el_id]
      @employee_leave = EmployeeLeave.find(lc_id)
      leave_taken = @employee_leave.leave_taken
      current_leave_count = @employee_leave.leave_count
      if leave_count.to_f >= leave_taken
        @employee_leave.leave_count = leave_count
        if @employee_leave.save
          emp = Employee.find_by_id(@employee_leave.employee_id)
          employee_leave_balance = emp.employee_leave_balances.select{|elb| elb.employee_leave_type_id == @employee_leave.employee_leave_type_id}.last
          if employee_leave_balance.present?
            employee_leave_balance.leaves_added = leave_count.to_f - employee_leave_balance.leave_balance.to_f
            employee_leave_balance.save
          end
          render(:update) { |page| 
            page.replace_html "leave_count_#{lc_id}", :text => leave_count 
            page.replace_html "error_div_", :text => ""}
        end
      else
        render(:update) { |page| page.replace_html "error_div_", :text => "<div id='errorExplanation' class='errorExplanation'><p>#{t('leave_count_cant_be_less_than_leave_taken')}</p></div>" }
      end
    end
  end
  
  def add_individual_leave
    @employee_leave = EmployeeLeave.new(params[:employee_leave])
    @employee = Employee.find(params[:id])
    employee_leave_ids = @employee.employee_leaves.active.collect(&:employee_leave_type_id)
    @leave_types = EmployeeLeaveType.active.all(:conditions => (employee_leave_ids.present? ? ["id NOT IN (?)", employee_leave_ids] : []))
    emp_lev = @employee.employee_leaves.detect{|l| l.employee_leave_type_id == @employee_leave.employee_leave_type_id}
    leave_balance = 0.0
    leaves_taken = 0.0
    addl_leaves = 0.0
    leaves_added = @employee_leave.leave_count
    if emp_lev.present?
      leave_balance = emp_lev.leave_count - emp_lev.leave_taken
      leaves_taken = emp_lev.leave_taken
      addl_leaves = emp_lev.additional_leaves
      leaves_added = @employee_leave.leave_count - leave_balance
      emp_lev.attributes = {:additional_leaves => 0, :is_additional => true, :leave_group_id => nil, :reseted_at => Time.now, :leave_taken => 0, :leave_count => @employee_leave.leave_count, :reset_date => (@employee_leave.reset_date < @employee_leave.employee_leave_type.reset_date ? @employee_leave.employee_leave_type.reset_date : @employee_leave.reset_date), :is_active => true}
      @employee_leave = emp_lev
    end
    if request.post? and @employee_leave.save
      emp_leave_balance = EmployeeLeaveBalance.new({:employee_id => @employee.id, 
          :employee_leave_type_id => @employee_leave.employee_leave_type_id, :leave_balance => leave_balance, 
          :reset_date => (@employee_leave.reset_date < @employee_leave.employee_leave_type.reset_date ? @employee_leave.employee_leave_type.reset_date : @employee_leave.reset_date),
          :leaves_added => leaves_added, :is_inactivated => false, :leaves_taken => leaves_taken, :additional_leaves => addl_leaves})
      emp_leave_balance.save
      flash[:notice] = "#{t('flash57')}"
      render :update do |page|
        page.redirect_to({:controller => :employee, :action => :edit_leave_balance, :id => @employee.id})
      end
    else
      render :update do |page|
        page << "build_modal_box({'title' : '#{t('add_a_special_leave_type')}', 'popup_class' : 'add_leave_type'})" unless params[:employee_leave].present?
        page.replace_html 'popup_content', :partial => 'add_individual_leave'
      end
    end
  end
  
  def remove_individual_leave
    @employee_leave = EmployeeLeave.find(params[:id])
    apply_leaves = ApplyLeave.all(:conditions => ["employee_id = ? and start_date >= ? and employee_leave_type_id = ?", @employee_leave.employee_id, @employee_leave.reset_date, @employee_leave.employee_leave_type_id])
    employee_attendances = EmployeeAttendance.all(:conditions => ["employee_id = ? and attendance_date >= ? and employee_leave_type_id = ?", @employee_leave.employee_id, @employee_leave.reset_date, @employee_leave.employee_leave_type_id])
    additional_leaves = EmployeeAdditionalLeave.all(:conditions => ["employee_id = ? and attendance_date >= ? and employee_leave_type_id = ?", @employee_leave.employee_id, @employee_leave.reset_date, @employee_leave.employee_leave_type_id])
    leave_balance = @employee_leave.leave_count - @employee_leave.leave_taken + @employee_leave.additional_leaves
    emp_leave_taken = @employee_leave.leave_taken
    emp_addl_leaves = @employee_leave.additional_leaves
    if !apply_leaves.present? and !employee_attendances.present? and !additional_leaves.present? and @employee_leave.inactivate
      leaves_added = 0.to_f - leave_balance
      emp_leave_balance = EmployeeLeaveBalance.new({:employee_id => @employee_leave.employee_id, 
          :employee_leave_type_id => @employee_leave.employee_leave_type_id, :leave_balance => leave_balance, 
          :reset_date => (@employee_leave.reset_date < @employee_leave.employee_leave_type.reset_date ? @employee_leave.employee_leave_type.reset_date : @employee_leave.reset_date),
          :leaves_added => leaves_added, :is_inactivated => true, :leaves_taken => emp_leave_taken, :additional_leaves => emp_addl_leaves})
      emp_leave_balance.save
      flash[:notice] = "#{t('flash58')}"
    else
      flash[:notice] = "#{t('flash59')}"
    end
    redirect_to :controller => :employee, :action => :edit_leave_balance, :id => @employee_leave.employee_id
  end

  def update_activities
    @employee = Employee.find(params[:id])
    weekday_id = Date.parse(params[:date]).strftime("%w")
    batch_id = Employee.find(params[:id]).subjects.collect{|e| e.batch_id}
    classrooms = Classroom.all
    buildings = Building.all
    hash = {}
    i = 1
    allocations = TimetableEntry.find(:all,:joins => :timetable,:include =>[:allocated_classrooms, :entry,:batch,:class_timing],
      :conditions => ["timetable_entries.weekday_id = ? and timetable_entries.batch_id IN (?)
 and timetables.start_date <= ? and timetables.end_date >= ?", weekday_id,batch_id,params[:date],params[:date]],
      :order => "timetable_entries.class_timing_id"
    )
    allocations.each do |a|
      unless a.entry_type == "ElectiveGroup"
        @assigned = a.employee_ids.include? @employee.id
        #        @assigned = EmployeesSubject.find_by_employee_id_and_subject_id(@employee.id,a.subject.id)
        next if !@assigned
        hash[i] = {}
        hash[i]["class_timing"] = a.class_timing.start_time.strftime("%I:%M %P") + " - " + a.class_timing.end_time.strftime("%I:%M %P")
        hash[i]["subject"] = a.assigned_name
        hash[i]["batch"] = a.batch.full_name
        hash[i]["classroom"] = []
        hash[i]["building"] = []
        a.allocated_classrooms.each do |c|
          hash[i]["classroom"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => classrooms.select{|cr| cr.id == c.classroom_id }.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
          hash[i]["building"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => buildings.select{|b| b.id == classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.building_id}.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
        end
        i+= 1
      end
      if a.entry_type == "ElectiveGroup"
        s = a.entry.subjects.all(:joins => :employees,:conditions=> "employees.id = #{params[:id]}")
        #        s = Subject.find(:all,:joins => :employees,:conditions=> "subjects.elective_group_id = #{a.subject.elective_group_id} and employees.id = #{params[:id]}")
        s.each do |sub|
          @assigned = EmployeesSubject.find_by_employee_id_and_subject_id(@employee.id,sub.id)
          next if @assigned.nil?
          allocation = a.allocated_classrooms.select{|alloc| alloc.subject_id == sub.id }
          hash[i] = {}
          hash[i]["class_timing"] = a.class_timing.start_time.strftime("%I:%M %P") + " - " + a.class_timing.end_time.strftime("%I:%M %P")
          hash[i]["subject"] = sub.name
          hash[i]["batch"] = a.batch.full_name
          hash[i]["classroom"] = []
          hash[i]["building"] = []
          allocation.each do |c|
            hash[i]["classroom"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
            hash[i]["building"] << {ClassroomAllocation.find(c.classroom_allocation_id).allocation_type => buildings.select{|b| b.id == classrooms.select{|cr| cr.id == c.classroom_id.to_i }.first.building_id}.first.name, "date" => (c.date.to_date.to_s if c.date.present?)}
          end
          i+=1
        end
      end
    end
    @allocations = hash
    render(:update) { |page| page.replace_html 'list', :partial => 'list_activities' }
  end
  
  private
  
  def fetch_transport_data
    transport_admission_data(@employee) if FedenaPlugin.can_access_plugin?('fedena_transport')
  end

end
private
def is_number?(num)
  /^[\d]+(\.[\d]+){0,1}$/ === num.to_s
end
