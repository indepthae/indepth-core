class TemplatesController < ApplicationController
  filter_access_to :all
  
  def load_template_key_form
    @base_template = BaseTemplate.find(params[:base_template_id])
    @combine_template = BaseTemplate.find(params[:combine_template_id]) if params[:combine_template_id].present?
    @keys = @base_template.get_included_template_keys
    if @combine_template.present?
      @keys = @keys.merge(@combine_template.get_included_template_keys)
    end
    if @base_template.template_for == 1
      @courses = Course.all(:order=>:course_name, :conditions=>["is_deleted=false"])
      render :update do |page|
        page.replace_html "template_key_form", :partial => "student_template_key_form"
      end
    elsif @base_template.template_for == 2
      @employees = Employee.all(:order=>"first_name asc, middle_name asc, last_name asc")
      render :update do |page|
        page.replace_html "template_key_form", :partial => "employee_template_key_form"
      end
    elsif @base_template.template_for == 3
      @courses = Course.all(:order=>:course_name, :conditions=>["is_deleted=false"])
      render :update do |page|
        page.replace_html "template_key_form", :partial => "guardian_template_key_form"
      end
    else
    end
  end

  def batch_list
    @course = Course.find(params[:course_id])
    @base_template_id = params[:base_template_id]
    if params[:academic_year].present? && (params[:academic_year]!="undefined")
      @batches = @course.batches.all(:conditions=>["is_deleted=false and academic_year_id = ?",params[:academic_year]], :order=>:name)
    else
      @batches = @course.batches.all(:order=>:name, :conditions=>["is_deleted=false"])
    end
    @combine_template_id = params[:combine_template_id] if params[:combine_template_id].present?

    render :update do |page|
      page.replace_html "batch_list", :partial => "batch_list"
    end
  end
  
  
  def batch_list_for_guardian
    @course = Course.find(params[:course_id])
    @base_template_id = params[:base_template_id]
    if params[:academic_year].present? && (params[:academic_year]!="undefined")
      @batches = @course.batches.all(:conditions=>["is_deleted=false and academic_year_id = ?",params[:academic_year]], :order=>:name)
    else
      @batches = @course.batches.all(:order=>:name, :conditions=>["is_deleted=false"])
    end
    @combine_template_id = params[:combine_template_id] if params[:combine_template_id].present?

    render :update do |page|
      page.replace_html "batch_list_for_guardian", :partial => "batch_list_for_guardian"
    end
  end


  def student_list
    @batch = Batch.find(params[:batch_id])
    @students = @batch.effective_students_for_certificate(:active_check=>false).sort{|a,b| a.full_name.downcase <=> b.full_name.downcase}
    @base_template_id = params[:base_template_id]
    @combine_template_id = params[:combine_template_id] if params[:combine_template_id].present?
    render :update do |page|
      page.replace_html "student_list", :partial => "student_list"
    end
  end
  
  
  def student_list_for_guardian
    @batch = Batch.find(params[:batch_id])
    @students = @batch.effective_students_for_certificate(:active_check=>false).sort{|a,b| a.full_name.downcase <=> b.full_name.downcase}
    @base_template_id = params[:base_template_id]
    @combine_template_id = params[:combine_template_id] if params[:combine_template_id].present?
    render :update do |page|
      page.replace_html "student_list_for_guardian", :partial => "student_list_for_guardian"
    end
  end
  
  
  def guardian_list
    @base_template_id = params[:base_template_id]
    if params[:type] == "ArchivedStudent"
      @archived_student = ArchivedStudent.find_by_former_id(params[:student_id])
      @guardians = @archived_student.archived_guardians.all(:order=>"first_name asc, last_name asc")
    elsif params[:type] == "Student"
      @student = Student.find(params[:student_id])
      @guardians = @student.guardians.all(:order=>"first_name asc, last_name asc")
    else 
    end
    @combine_template_id = params[:combine_template_id] if params[:combine_template_id].present?
    render :update do |page|
      page.replace_html "guardian_list", :partial => "guardian_list"
    end
  end
  

  def barcode_linked_to_list
    @linked_to_keys = BarcodeProperty.linked_to_keys(params[:type].to_i)
  end


  def set_student_keys
    if (params[:type]=="ArchivedStudent")
      @student = Student.find_by_sql(["SELECT *, former_id AS id, 'archived' as current_type FROM archived_students where former_id = ? ",params[:student_id]]).first
      @archived_student = ArchivedStudent.find_by_former_id(params[:student_id])
    else
      @student = Student.find(params[:student_id])
    end
    @combine_template = BaseTemplate.find(params[:combine_template_id]) if params[:combine_template_id].present?
    @base_template = BaseTemplate.find(params[:base_template_id], :include=>[:barcode_property])
    @keys = @base_template.get_included_template_keys
    @additional_field_values = BaseTemplate.get_student_additional_values(@student)
    if @combine_template.present?
      @keys = @keys.merge(@combine_template.get_included_template_keys)
    end
  end


  def set_employee_keys
    @employee = Employee.find(params[:employee_id])
    @base_template = BaseTemplate.find(params[:base_template_id])
    @combine_template = BaseTemplate.find(params[:combine_template_id]) if params[:combine_template_id].present?
    @keys = @base_template.get_included_template_keys
    @additional_field_values = BaseTemplate.get_employee_additional_values(@employee)
    if @combine_template.present?
      @keys = @keys.merge(@combine_template.get_included_template_keys)
    end
  end


  def set_guardian_keys
    @student = Student.find(params[:student_id])    
    if (params[:type]=="ArchivedGuardian")
      @guardian = Guardian.find_by_sql(["SELECT *, former_id AS id FROM archived_guardians where former_id = ? ",params[:guardian_id]]).first
      @archived_guardian = ArchivedGuardian.find_by_former_id(params[:guardian_id])
    else
      @guardian = Guardian.find(params[:guardian_id])      
    end
    @base_template = BaseTemplate.find(params[:base_template_id])
    @combine_template = BaseTemplate.find(params[:combine_template_id]) if params[:combine_template_id].present?
    @keys = @base_template.get_included_template_keys
    if @combine_template.present?
      @keys = @keys.merge(@combine_template.get_included_template_keys)
    end
  end

end
