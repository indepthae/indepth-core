module IndepthOverrides
  module IndepthStudentController
  	def self.included (base)
      base.instance_eval do
        alias_method_chain :admission1, :tmpl
        alias_method_chain :admission1_2, :tmpl
        alias_method_chain :profile, :tmpl
        alias_method_chain :edit, :tmpl
        alias_method_chain :admission2, :tmpl
        alias_method_chain :edit_guardian, :tmpl
        alias_method_chain :profile_pdf, :tmpl
        alias_method_chain :advanced_search, :tmpl
        alias_method_chain :guardians, :tmpl
        alias_method_chain :add_guardian, :tmpl
        alias_method_chain :fees, :tmpl
        alias_method_chain :search_ajax, :tmpl
        alias_method_chain :advanced_search_pdf, :tmpl

        before_filter :protect_other_student_data, :except =>[:pdf_template_for_guardian,:single_statement]
        before_filter :can_see_single_statement ,:only => [:pdf_template_for_guardian,:single_statement]
      end
    end
    
    def add_guardian_with_tmpl
      @parent_info = @student.guardians.build(params[:parent_info])
      @parent_info.familyid = @student.familyid
      if request.post? and @parent_info.save
        #       @parent_info.update_attribute(:ward_id,@student.guardians.first.ward_id) if @student.guardians.present?
        flash[:notice] = "#{t('flash5')} #{@student.full_name}"
        redirect_to :controller => "student" , :action => "admission3_1", :id => @student.id
      else
        @countries = Country.all
        render :template => "indepth_student/add_guardian_with_tmpl"
      end
    end
    
    def admission1_with_tmpl
      @student = Student.new(params[:student])
      @selected_value = Configuration.default_country
      @application_sms_enabled = SmsSetting.find_by_settings_key("ApplicationEnabled")
      @last_admitted_student = User.last(:select=>"username",:conditions=>["student=?",true])
      @next_admission_no=User.next_admission_no("student")
      @config = Configuration.find_by_config_key('AdmissionNumberAutoIncrement')
      @categories = StudentCategory.active
      @batches = []
      if request.post?
        if params[:course].first.present? && params[:student][:batch_id].present?
          @roll_number_prefix = Batch.find(params[:student][:batch_id]).get_roll_number_prefix
          @selected_batch = params[:student][:batch_id]
          @selected_course = params[:course].first
          @batches = Course.find(@selected_course.to_i).batches.active
        end
        if @config.config_value.to_i == 1
          @exist = Student.first(:conditions => ["admission_no LIKE BINARY(?)",params[:student][:admission_no]])
          if @exist.nil?
            @status = @student.save
          else
            @status = @student.save
          end
        else
          @status = @student.save
        end
        if @status
          if Configuration.find_by_config_key('EnableSibling').present? and Configuration.find_by_config_key('EnableSibling').config_value=="1"
            flash[:notice] = "#{t('flash22')}"
            redirect_to :controller => "student", :action => "admission1_2", :id => @student.id and return
          else
            flash[:notice] = "#{t('flash8')}"
            redirect_to :controller => "student", :action => "admission2", :id => @student.id and return
          end
        else
          transport_admission_data(@student) if FedenaPlugin.can_access_plugin?('fedena_transport')
          render :template => 'indepth_student/admission1_with_tmpl' and return
        end
        render :template => 'indepth_student/admission1_with_tmpl' and return
      end
      render :template => 'indepth_student/admission1_with_tmpl' and return
    end

    def admission1_2_with_tmpl
      if Configuration.find_by_config_key('EnableSibling').present? and Configuration.find_by_config_key('EnableSibling').config_value=="1"
        @batches=Batch.active
        @student=Student.find(params[:id])
        @siblings=@student.siblings
     
        if request.post? and params[:sibling_no].present?
          sibling=Student.find(params[:sibling_no])          
          unless @student.all_siblings.present?
            @student.guardians.each do|guardian|
              guardian.user.destroy if guardian.user.present?
              guardian.destroy
            end
          else
            unless @student.all_siblings.collect(&:immediate_contact_id).include?(@student.immediate_contact_id)              
              @student.immediate_contact.user.destroy if @student.immediate_contact.present?
            end
          end
          @student.update_attributes(:immediate_contact_id=>sibling.immediate_contact_id,
            :familyid => sibling.familyid, :sibling_id=>sibling.sibling_id)
          if params[:configure].present?
            redirect_to :controller => "student", :action => "profile", :id => params[:id]
          else
            redirect_to :controller => "student", :action => "previous_data", :id => params[:id]
          end
        else
          render :template => 'indepth_student/admission1_2_with_tmpl'
        end
      else
        flash[:notice] = "#{t('flash_msg4')}"
        redirect_to :controller => 'user', :action => 'dashboard'
      end
    end
    
    def profile_with_tmpl
      @student = Student.find(params[:id])
      @current_user = current_user
      @address = @student.address_line1.to_s + ' ' + @student.address_line2.to_s
      @sms_module = Configuration.available_modules
      @biometric_id = BiometricInformation.find_by_user_id(@student.user_id).try(:biometric_id)
      @sms_setting = SmsSetting.new
      @previous_data = @student.student_previous_data
      @immediate_contact = @student.immediate_contact
      @assigned_employees = @student.batch.employees
      @additional_details = @student.student_additional_details.find(:all,:include => [:student_additional_field],:conditions => ["student_additional_fields.status = true"],:order => "student_additional_fields.priority ASC")
      @additional_fields_count = StudentAdditionalField.count(:conditions => "status = true")
      render :template => 'indepth_student/profile_with_tmpl'
    end

    def edit_with_tmpl
      @student = Student.find(params[:id])
      @student.gender=@student.gender.downcase
      @student_user = @student.user
      @student_categories = StudentCategory.active
      @student_dependency= @student.student_dependencies_list.empty? ? true:false
      unless @student.student_category.present? and @student_categories.collect(&:name).include?(@student.student_category.name)
        current_student_category=@student.student_category
        @student_categories << current_student_category if current_student_category.present?
      end
      @batches = Batch.active
      @student.biometric_id = BiometricInformation.find_by_user_id(@student.user_id).try(:biometric_id)
      @application_sms_enabled = SmsSetting.find_by_settings_key("ApplicationEnabled")
      if Configuration.enabled_roll_number?
        @roll_number_prefix = @student.batch.get_roll_number_prefix
        @student.roll_number.to_s.slice!(@roll_number_prefix.to_s)
        @roll_number_suffix = @student.roll_number
      end
      if request.put?
        unless params[:student][:image_file].blank?
          unless params[:student][:image_file].size.to_f > 280000
            if @student.update_attributes(params[:student])
              flash[:notice] = "#{t('flash3')}"
              redirect_to :controller => "student", :action => "profile", :id => @student.id
            else
              render :template => 'indepth_student/edit_with_tmpl'
            end
          else
            flash[:notice] = "#{t('flash_msg11')}"
            redirect_to :controller => "student", :action => "edit", :id => @student.id
          end
        else
          if @student.update_attributes(params[:student])
            flash[:notice] = "#{t('flash3')}"
            redirect_to :controller => "student", :action => "profile", :id => @student.id
          else
            render :template => 'indepth_student/edit_with_tmpl'
          end
        end
      else
        render :template => 'indepth_student/edit_with_tmpl'
      end
    end

    def admission2_with_tmpl
      @student = Student.find params[:id]
      @guardian = Guardian.new(params[:guardian])
      if request.post? and @guardian.save
        redirect_to :controller => "student", :action => "admission2", :id => @student.id
      else
        render :template => 'indepth_student/admission2_with_tmpl'
      end
    end

    def edit_guardian_with_tmpl
      @parent = Guardian.find(params[:id])
      params[:student_id].present? ? @student = Student.find(params[:student_id]): @student = Student.find(params[:parent_detail][:ward_id])
      @countries = Country.all
      params[:parent_detail].delete "ward_id" if  params[:parent_detail]
      if request.post? and @parent.update_attributes(params[:parent_detail])
        if @parent.id  == @student.immediate_contact_id
          unless @parent.user.nil?
            User.update(@parent.user.id, :first_name=> @parent.first_name, :last_name=> @parent.last_name, :email=> @parent.email, :role =>"Parent")
          else
            @parent.create_guardian_user(@student)
          end
        end
        flash[:notice] = "#{t('student.flash4')}"
        redirect_to :controller => "student", :action => "guardians", :id => @student.id
      else
        render :template => 'indepth_student/edit_guardian_with_tmpl'
      end
    end

    def profile_pdf_with_tmpl
      @student = Student.find(params[:id])
      @current_user = current_user
      @address = @student.address_line1.to_s + ' ' + @student.address_line2.to_s
      @sms_module = Configuration.available_modules
      @biometric_id = BiometricInformation.find_by_user_id(@student.user_id).try(:biometric_id)
      @sms_setting = SmsSetting.new
      @previous_data = StudentPreviousData.find_by_student_id(@student.id)
      @immediate_contact = @student.immediate_contact
      @assigned_employees = @student.batch.employees
      @additional_details = @student.student_additional_details.find(:all,:include => [:student_additional_field],:conditions => ["student_additional_fields.status = true AND student_additional_fields.input_type != 'photo_file'"],:order => "student_additional_fields.priority ASC")
      render :pdf=>'indepth_student/profile_pdf_with_tmpl' , :template=>'indepth_student/profile_pdf_with_tmpl'
    end

    def advanced_search_with_tmpl
      @search = Student.search(params[:search])
      unless params[:search].present?
        @batches = Batch.all
      else
        if params[:search].present?
          @students = Array.new
          if params[:advv_search].present? and params[:advv_search][:course_id].present?
            unless params[:search][:batch_id_equals].present?
              params[:search][:batch_id_in] = Batch.find_all_by_course_id(params[:advv_search][:course_id]).collect{|b|b.id}
            end
          end
#          if params[:search][:name_or_admssn_no_as].present?
#            params[:search][:family_name_admssn_no] = params[:search].delete(:name_or_admssn_no_as)
#            params.with_indifferent_access
#          end
          if params[:search][:is_active_equals]=="true"
            @students = Student.ascend_by_first_name.search(params[:search]).paginate(:page => params[:page],:per_page => 30)
          elsif params[:search][:is_active_equals]=="false"
            @students = ArchivedStudent.ascend_by_first_name.search(params[:search]).paginate(:page => params[:page],:per_page => 30)
          else
            @students = [{:student => {:search_options => params[:search], :order => :first_name}},{:archived_student => {:search_options => params[:search], :order => :first_name}}].model_paginate(:page => params[:page],:per_page => 30)#.sort!{|m, n| m.first_name.capitalize <=> n.first_name.capitalize}
          end
          @searched_for = ''
          @searched_for += "<span>#{t('name')}/#{t('admission_no')}: " + params[:search][:name_or_admssn_no_as].to_s + "</span>" if params[:search][:name_or_admssn_no_as].present?
          @searched_for += "<span>#{t('name')}: " + params[:search][:student_name_as].to_s + "</span>" if params[:search][:student_name_as].present?
          @searched_for += " <span>#{t('admission_no')}: " + params[:search][:admission_no_equals].to_s + "</span>" if params[:search][:admission_no_equals].present?
          if params[:advv_search].present? and params[:advv_search][:course_id].present?
            course = Course.find(params[:advv_search][:course_id])
            batch = Batch.find(params[:search][:batch_id_equals]) unless (params[:search][:batch_id_equals]).blank?
            @searched_for += "<span>#{t('course_text')}: " + course.full_name + "</span>"
            @searched_for += "<span>#{t('batch')}: " + batch.full_name + "</span>" if batch.present?
          end
          @searched_for += "<span>#{t('category')}: " + StudentCategory.find(params[:search][:student_category_id_equals]).name.to_s + "</span>" if params[:search][:student_category_id_equals].present?
          if  params[:search][:gender_equals].present?
            if  params[:search][:gender_equals] == 'm'
              @searched_for += "<span>#{t('gender')}: #{t('male')}</span>"
            elsif  params[:search][:gender_equals] == 'f'
              @searched_for += " <span>#{t('gender')}: #{t('female')}</span>"
            else
              @searched_for += " <span>#{t('gender')}: #{t('all')}</span>"
            end
          end
          @searched_for += "<span>#{t('blood_group')}: " + params[:search][:blood_group_like].to_s + "</span>" if params[:search][:blood_group_like].present?
          @searched_for += "<span>#{t('nationality')}: " + Country.find(params[:search][:nationality_id_equals]).full_name.to_s + "</span>" if params[:search][:nationality_id_equals].present?
          @searched_for += "<span>#{t('year_of_admission')}: " +  params[:advv_search][:doa_option].to_s + ' '+ params[:adv_search][:admission_date_year].to_s + "</span>" if  params[:advv_search].present? and params[:advv_search][:doa_option].present?
          @searched_for += "<span>#{t('year_of_birth')}: " +  params[:advv_search][:dob_option].to_s + ' ' + params[:adv_search][:birth_date_year].to_s + "</span>" if  params[:advv_search].present? and params[:advv_search][:dob_option].present?
          if params[:search][:is_active_equals]=="true"
            @searched_for += "<span>#{t('present_student')}</span>"
          elsif params[:search][:is_active_equals]=="false"
            @searched_for += "<span>#{t('former_student')}</span>"
          else
            @searched_for += "<span>#{t('all_students')}</span>"
          end
        end
      end
      render :template => 'indepth_student/advanced_search_with_tmpl'
    end

    def fees_with_tmpl
      @batches=@student.all_batches.reverse
      # @dates=@student.fees_list
      @enable_all_fee = PaymentConfiguration.find_by_config_key("enabled_pay_all").try(:config_value) || "true" if FedenaPlugin.can_access_plugin?("fedena_pay")
      @advance_fee_config = Configuration.advance_fee_payment_enabled?
      @dates=[]
      if @student.has_paid_fees
        @flash_notice=t('do_not_create_fee_collections_from_now_on')
      elsif @student.has_paid_fees_for_batch
        @flash_notice=t('do_not_create_fee_collections_for_this_student_in_the_current_batch')
      else
        @flash_notice=nil
      end
      @student_batch_fees = {}
      order = "finance_fees.is_paid ASC , finance_fee_collections.due_date ASC"
      @batches.map { |batch| @student_batch_fees[batch.id] = @student.fees_list_by_batch(batch.id,order) } if @batches.present?
      render :template => 'indepth_student/fees_with_tmpl'
    end


    def guardians_with_tmpl
      @parents = @student.guardians
      render :template => 'indepth_student/guardians_with_tmpl'
    end

    def advanced_search_pdf_with_tmpl
      @data_hash = Student.fetch_student_advance_search_result(params)
      render :pdf=>'indepth_student/advanced_search_pdf_with_tmpl' , :template=>'indepth_student/advanced_search_pdf_with_tmpl', :margin =>{:top=>50,:bottom=>30,:left=>5,:right=>5}
    end

    def single_statement
      @single_statement_header = SingleStatementHeader.first
      @studentfs = Student.find(params[:id])
      
      @date = Date.today
      @guardian = @studentfs.immediate_contact
      @family_id = !@guardian.nil? ? @guardian.familyid : @studentfs.familyid
      @family_code = @family_id.to_s.last(5).to_i.to_s

      data = Student.fetch_single_statement_data @family_code
      
      @financial_year_start = data[:financial_year_start]
      @financial_year_end = data[:financial_year_end]
      @transactions = data[:transactions]
      @collected_fee_particulars = data[:particular_names]
      @collected_fee_discounts = data[:discount_names]
      
      @students = data[:students]
      
      @collected_fee_details = data[:student_particulars]
      @students_with_discount = data[:student_discounts]
      @fee_fines = data[:student_fines]
      @transactions = data[:transactions]
      @t_array = [] # TO DO 
      
      @total_payment = @transactions.map {|x| x.amount.to_f }.sum
      
      @total = data[:total]
      @total += @fee_fines.values.sum.to_f
      @total_payable = @total - @total_payment
      @total_paid = data[:total_paid]
      @opening_journal = data[:opening_journal]
      
      @col_count = 7  +  @collected_fee_particulars.count + @collected_fee_discounts.count
      @col_count += 1 if @fee_fines.keys.present?
      
      render :template => 'indepth_student/single_statement'
    end
    

    def pdf_template_for_guardian
      @single_statement_header = SingleStatementHeader.first
      @studentfs = Student.find(params[:id])
      
      @date = Date.today
      @guardian = @studentfs.immediate_contact#Guardian.find_by_user_id @current_user.id
      @family_id = !@guardian.nil? ? @guardian.familyid : @studentfs.familyid
      @family_code = @family_id.to_s.last(5).to_i.to_s  #split('0')[-1]

      data = Student.fetch_single_statement_data @family_code
      
      @financial_year_start = data[:financial_year_start]
      @financial_year_end = data[:financial_year_end]
      @transactions = data[:transactions]
      @collected_fee_particulars = data[:particular_names]
      @collected_fee_discounts = data[:discount_names]
      
      @students = data[:students]
      
      @collected_fee_details = data[:student_particulars]
      @students_with_discount = data[:student_discounts]
      @fee_fines = data[:student_fines]
      @transactions = data[:transactions]
      @t_array = [] # TO DO 
      
      @total_payment = @transactions.map {|x| x.amount.to_f }.sum

      @total = data[:total]
      @total += @fee_fines.values.sum.to_f
      @total_payable = @total - @total_payment
      @total_paid = data[:total_paid]
      @opening_journal = data[:opening_journal]
      
      @col_count = 7  +  @collected_fee_particulars.count + @collected_fee_discounts.count
      @col_count += 1 if @fee_fines.keys.present?
      
      if @col_count > 14
        orientation = 'Landscape'
      else
        orientation = 'Portrait'
      end
      render :pdf=>'indepth_student/pdf_template_for_guardian' , 
        :template=>'indepth_student/pdf_template_for_guardian',
        :orientation => orientation,:margin=>{:left=>10,:right=>10,:top=>5,:bottom=>5},
        :show_as_html=>params.key?(:d),:header => {:html => nil},:footer => {:html => nil}
    end
        
    def search_ajax_with_tmpl
      if params[:option] == "active" or params[:option]=="sibling"    
        if params[:query].length>= 3
          @students = Student.find(:all,
            :conditions => ["ltrim(rtrim(familyid)) LIKE ? OR ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                            OR admission_no = ? OR (concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? )
                              OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ? ) ",
              "#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%",
              "#{params[:query]}", "#{params[:query]}%", "#{params[:query]}%" ],
            :order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}]) unless params[:query] == ''
        else
          @students = Student.find(:all,
            :conditions => ["ltrim(rtrim(familyid)) LIKE ? OR admission_no = ? " ,"#{params[:query]}%", params[:query]],
            :order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}]) unless params[:query] == ''
        end
        @students.reject!{|r| r.immediate_contact_id.nil?} if @students.present? and params[:option]=="sibling"
        render :template=> "indepth_student/search_ajax" , :layout => false
      else
        if params[:query].length>= 3
          @archived_students = ArchivedStudent.find(:all,
            :conditions => ["ltrim(rtrim(familyid)) LIKE ? OR ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                            OR admission_no = ? OR (concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? )
                              OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ? ) ",
              "#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%",
              "#{params[:query]}", "#{params[:query]}", "#{params[:query]}" ],
            :order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}]) unless params[:query] == ''
        else
          @archived_students = ArchivedStudent.find(:all,
            :conditions => ["ltrim(rtrim(familyid)) LIKE ? OR admission_no = ? " ,"#{params[:query]}%", params[:query]],
            :order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}]) unless params[:query] == ''
        end
        render :partial => "indepth_student/search_ajax"
      end
    end
  end
end 
