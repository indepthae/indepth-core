module AdvancePaymentFeesHelper

    def make_payment_params
        fields = user_payment_hash.collect do |key, value|
            make_hidden_field(key, value)
        end
    end

    def user_payment_hash
        gateway_params = @custom_gateway.gateway_parameters
        random_token = rand(36**25).to_s(36)
        generate_gateway_request(random_token,@custom_gateway)
        variable_params = Hash.new
        variable_params[gateway_params[:variable_fields][:amount].to_sym] = @student_payment.advance_fee_amount if gateway_params[:variable_fields][:amount].present?
        variable_params[gateway_params[:variable_fields][:redirect_url].to_sym] = redirect_url(random_token) if gateway_params[:variable_fields][:redirect_url].present?
        variable_params[gateway_params[:variable_fields][:item_name].to_sym] = transaction_name if gateway_params[:variable_fields][:item_name].present?
        variable_params[gateway_params[:variable_fields][:firstname].to_sym] = @current_user.first_name if gateway_params[:variable_fields][:firstname].present?
        variable_params[gateway_params[:variable_fields][:lastname].to_sym] = @current_user.last_name if gateway_params[:variable_fields][:lastname].present?
        variable_params[gateway_params[:variable_fields][:email].to_sym] = @current_user.email if gateway_params[:variable_fields][:email].present?
        variable_params[gateway_params[:variable_fields][:phone].to_sym] = @current_user.student_record.phone2 if (gateway_params[:variable_fields][:phone].present? and @current_user.student?)
        variable_params[gateway_params[:variable_fields][:phone].to_sym] = @current_user.guardian_entry.mobile_phone if (gateway_params[:variable_fields][:phone].present? and @current_user.parent?)
        student_record = @current_user.parent? ? @current_user.parent_record : @current_user.student_record
        variable_params[gateway_params[:variable_fields][:admission_no].to_sym] = student_record.admission_no if gateway_params[:variable_fields][:admission_no].present?
        variable_params[gateway_params[:variable_fields][:student_full_name].to_sym] = student_record.full_name if gateway_params[:variable_fields][:student_full_name].present?
        variable_params[gateway_params[:variable_fields][:batch_name].to_sym] = student_record.batch.full_name if gateway_params[:variable_fields][:batch_name].present?
        variable_params[gateway_params[:variable_fields][:fee_name].to_sym] = t('advance_payment_descr') if gateway_params[:variable_fields][:fee_name].present?
        variable_params[gateway_params[:variable_fields][:roll_no].to_sym] = (student_record.batch.roll_number_enabled? ? student_record.roll_number : "") if gateway_params[:variable_fields][:roll_no].present?
        if gateway_params[:variable_fields][:student_additional_fields].present?
            gateway_params[:variable_fields][:student_additional_fields].each_pair do|k,v|
                st_addl_field = StudentAdditionalField.find_by_name_and_status(k,true)
                if st_addl_field.present?
                    st_detail = student_record.student_additional_details.first(:conditions=>{:additional_field_id=>st_addl_field.id})
                    variable_params[v.to_sym] = st_detail.present? ? st_detail.additional_info : ""
                end
            end
        end
        variable_params
    end

    def make_hidden_field(name, value)
        content_tag(:input, nil, :type => 'hidden', :value => value, :name => name, :readonly => true)
    end

    def transaction_name
        t('advance_payment_descr') + " " +@student_payment.advance_fee_payee.full_name.to_s + "(#{@student_payment.advance_fee_payee.try(:admission_no)})"
    end

    def generate_gateway_request(token, gateway)
    GatewayRequest.create(:gateway=>gateway, :transaction_reference=>token)
    end

    def redirect_url(token)
        url_for(
          :controller => "advance_payment_fees",
          :action => "start_transaction",
          :id => @student_payment.advance_fee_payee.id,
          :identification_token => @student_payment.identification_token,
          :create_transaction => 1,
          :transaction_ref=>token,
          :only_path => false
        )
    end

    def receipt_options(advance_fee_collection_ids)
      result = ""
      pdf_link_text = content_tag(:span, "", :class => "pdf_icon_img")
      print_link_text = content_tag(:span, "", :class => "print_icon_img")
      result += link_to(pdf_link_text, {:controller => :advance_payment_fees, :action => "advance_fees_receipt_pdf",
                                        :advance_fee_collection_id => advance_fee_collection_ids}, {:target => '_blank', :tooltip => I18n.t('view_pdf_receipt')})
      (@hide_print_options) ? result : (result += link_to_function print_link_text,
                                                                                             "show_print_dialog(#{advance_fee_collection_ids.to_json})", :tooltip => I18n.t('print_receipt'))
    end

    def fetch_receipt_no(collection_id)
        collection = AdvanceFeeCollection.find_by_id(collection_id)
        receipt_no = collection.receipt_data.receipt_no
        return receipt_no
    end

    def fetch_course_name(course)
        course = Course.find_by_id(course)
        return course.course_name
    end

    def fetch_student_name(student_id)
        student = Student.find_by_id(student_id)
        return student.full_name
    end

end
