module ApplicantsHelper
  include ApplicantAdditionalFieldsHelper

  def attr_pair(label,value)
    content_tag(:div,:class => :attr_pair) do
      content_tag(:div,label,:class => :attr_label) + content_tag(:div,value,:class => :attr_value)
    end
  end
  
  def generate_input(form,field,options=[])
    if field.field_type=="text"
      text_field_tag "applicant[addl_fields[#{field.id}]]",form.object.addl_fields["#{field.id}"] 
    elsif field.field_type=="belongs_to"
      select_tag "applicant[addl_fields[#{field.id}]]", "<option value=\"\">Select</option>" + options_from_collection_for_select(options,"id","option",form.object.addl_fields["#{field.id}"].to_i)
    elsif field.field_type=="has_many"
      ss = ""
      options.each{|opt| ss += "#{check_box_tag "applicant[addl_fields[#{field.id}]][]",opt.id,form.object.addl_fields["#{field.id}"].to_a.include?("#{opt.id}")} <div class=\"coption\"> #{opt.option}</div>"}
      ss
    end
  end

  def link_to_add_addl_attachment(name, f, association,addl_options={})
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, h("add_addl_attachment(this, \"#{association}\", \"#{escape_javascript(fields)}\")"),{:class=>"add_button_img"}.merge(addl_options))
  end

  def course_pin_system_registered_for_course(course_id)
    course_pin = CoursePin.find_by_course_id(course_id)
    if course_pin.nil?
      return true
    else
      return false if course_pin.is_pin_enabled?
    end
    return true
  end

  def latest_subject_name(code,course_id)
    Subject.find_all_by_code_and_batch_id(code,Batch.find_all_by_course_id(course_id)).last.name
  end

  def applicant_custom_gateway_pay_button(applicant,active_gateway,amount,item_name,redirect_url,paid_fees = Array.new,button_style = String.new)
    @active_gateway = active_gateway
    @custom_gateway = CustomGateway.find(@active_gateway)
    gateway_params = @custom_gateway.gateway_parameters
    @paid_fees = paid_fees
    @button_style = button_style
    @variable_params = Hash.new
    @variable_params[gateway_params[:variable_fields][:amount].to_sym] = amount if gateway_params[:variable_fields][:amount].present?
    @variable_params[gateway_params[:variable_fields][:redirect_url].to_sym] = redirect_url if gateway_params[:variable_fields][:redirect_url].present?
    @variable_params[gateway_params[:variable_fields][:item_name].to_sym] = item_name if gateway_params[:variable_fields][:item_name].present?
    @variable_params[gateway_params[:variable_fields][:firstname].to_sym] = applicant.first_name if gateway_params[:variable_fields][:firstname].present?
    @variable_params[gateway_params[:variable_fields][:lastname].to_sym] = applicant.last_name if gateway_params[:variable_fields][:lastname].present?
    @variable_params[gateway_params[:variable_fields][:email].to_sym] = applicant.email if gateway_params[:variable_fields][:email].present?
    @variable_params[gateway_params[:variable_fields][:phone].to_sym] = applicant.phone2 if gateway_params[:variable_fields][:phone].present?
    @variable_params[gateway_params[:variable_fields][:admission_no].to_sym] = applicant.reg_no if gateway_params[:variable_fields][:admission_no].present?
    @variable_params[gateway_params[:variable_fields][:student_full_name].to_sym] = applicant.full_name if gateway_params[:variable_fields][:student_full_name].present?
    @variable_params[gateway_params[:variable_fields][:fee_name].to_sym] = "Registration Fee" if gateway_params[:variable_fields][:fee_name].present?

    render :partial => "gateway_payments/custom/custom_gateway_form"
  end

end
