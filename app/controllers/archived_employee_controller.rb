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

class ArchivedEmployeeController < ApplicationController
  lock_with_feature :hr_enhancement

  before_filter :login_required,:configuration_settings_for_hr
  filter_access_to :all
#  prawnto :prawn => {:left_margin => 25, :right_margin => 25}

  

  def profile
    @current_user = current_user
    @employee = ArchivedEmployee.find(params[:id])
    @gender = "Male"
    @gender = "Female" if @employee.gender == "f"
    @status = "Active"
    @status = "Inactive" if @employee.status == false
    @reporting_manager = @employee.reporting_manager
    years = @employee.find_experience_years
    months = @employee.find_experience_months
    year = months/12
    month = months%12
    @total_years = years + year
    @total_months = month

  end

  def profile_general
    @employee = ArchivedEmployee.find(params[:id])
    @gender = "Male"
    @gender = "Female" if @employee.gender == false
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
    @employee = ArchivedEmployee.find(params[:id])
    render :partial => "personal"
  end

  def profile_address
    @employee = ArchivedEmployee.find(params[:id])
    @home_country = Country.find(@employee.home_country_id).full_name unless @employee.home_country_id.nil?
    @office_country = Country.find(@employee.office_country_id).full_name unless @employee.office_country_id.nil?
    render :partial => "address"
  end

  def profile_contact
    @employee = ArchivedEmployee.find(params[:id])
    render :partial => "contact"
  end

  def profile_bank_details
    @employee = ArchivedEmployee.find(params[:id])
    @bank_details = ArchivedEmployeeBankDetail.find_all_by_employee_id(@employee.id)
    render :partial => "bank_details"
  end

  def profile_additional_details
    @employee = ArchivedEmployee.find(params[:id])
    @additional_details = ArchivedEmployeeAdditionalDetail.find_all_by_employee_id(@employee.id, :joins => :additional_field, :conditions => ["additional_fields.status = true"])
    render :partial => "additional_details"
  end


  def profile_payroll_details
    @currency_type = currency
    @employee = ArchivedEmployee.find(params[:id],:include => [{:archived_employee_salary_structure => {:archived_employee_salary_structure_components => :payroll_category}}, :payroll_group])
    if @employee.archived_employee_salary_structure
      @earnings = @employee.archived_employee_salary_structure.earning_components
      @deductions = @employee.archived_employee_salary_structure.deduction_components
    end
    render :partial => "payroll_details"
  end

  def profile_pdf
    @employee = ArchivedEmployee.find(params[:id])
    @gender = "Male"
    @gender = "Female" if @employee.gender == "f"
    @status = "Active"
    @status = "Inactive" if @employee.status == false
    @reporting_manager = @employee.reporting_manager unless @employee.reporting_manager_id.nil?
    years = @employee.find_experience_years
    months = @employee.find_experience_months
    year = months/12
    month = months%12
    @total_years = years + year
    @total_months = month
    @home_country = Country.find(@employee.home_country_id).full_name unless @employee.home_country_id.nil?
    @office_country = Country.find(@employee.office_country_id).full_name unless @employee.office_country_id.nil?
    @bank_details = ArchivedEmployeeBankDetail.find_all_by_employee_id(@employee.id)
    @additional_details = ArchivedEmployeeAdditionalDetail.find_all_by_employee_id(@employee.id)
    
      render :pdf => 'profile_pdf'
            

    
  end

  def show
    @employee = ArchivedEmployee.find(params[:id])
    send_data(@employee.photo_data, :type => @employee.photo_content_type, :filename => @employee.photo_filename, :disposition => 'inline')
  end

  def change_to_present
    @employee = ArchivedEmployee.find(params[:id])
    Delayed::Job.enqueue(DelayedRevertArchiveEmployee.new(@employee.id))
    redirect_to :controller => "employee", :action => "hr"
    flash[:notice] = "#{t('employee_text')} - #{@employee.employee_number} #{t('successfully_reverted')}. <a href='/scheduled_jobs?job_object=DelayedRevertArchiveEmployee'>#{t('click_here')}</a>#{t('to_view_the_scheduled_job')}."
  end
  

end
