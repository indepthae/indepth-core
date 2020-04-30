module IndepthOverrides
  module IndepthFinanceExtensionsController
    def self.included (base)
      base.instance_eval do
        alias_method_chain :pay_all_fees_index, :tmpl
        alias_method_chain :search_students_for_pay_all_fees, :tmpl
        alias_method_chain :join_sql_for_student_fees, :tmpl
        alias_method_chain :pay_all_fees, :tmpl
        alias_method_chain :list_students_by_batch, :tmpl
        alias_method_chain :student_search_autocomplete, :tmpl
        alias_method_chain :delete_multi_fees_transaction, :tmpl
        alias_method_chain :search_student_list_for_structure, :tmpl
        
      end
    end

    def pay_all_fees_index_with_tmpl
      @batches = Batch.find(:all, :conditions => {:is_deleted => false, :is_active => true},
        :joins => :course, :select => "`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",
        :order => "course_full_name")
      render :template=>"indepth_finance_extensions/pay_all_fees_index_with_tmpl"
    end

    def search_students_for_pay_all_fees_with_tmpl
      having="(count(distinct finance_fees.id)>0)"
      having+=" or (count(hostel_fees.id)>0)" if FedenaPlugin.can_access_plugin?("fedena_hostel")
      having+=" or (count(distinct transport_fees.id)>0)" if FedenaPlugin.can_access_plugin?("fedena_transport")
      if params[:query].length >= 3
        @students = Student.paginate(:per_page => 5, :page => params[:page],
          :select => "students.id AS id, students.admission_no AS admission_no, students.roll_number,students.familyid as familyid, students.phone2 as phone1,
                             CONCAT(students.first_name,' ',students.middle_name,' ',students.last_name) AS fullname,
                             CONCAT(courses.code,'-',batches.name) AS batch_full_name,
                             (SELECT SUM(ff.balance) FROM finance_fees ff WHERE  ff.student_id=students.id AND
                              FIND_IN_SET(id,GROUP_CONCAT(distinct finance_fees.id))) AS fee_due,
                             #{transport_fee_due} AS transport_due, #{hostel_fee_due} AS hostel_due,
                             guardians.first_name AS guardian_first_name, guardians.last_name AS guardian_last_name ",
          :joins => join_sql_for_student_fees, :group => "students.id",:having => having,
          :conditions => ["ltrim(students.first_name) LIKE ? OR ltrim(students.middle_name) LIKE ? OR ltrim(students.last_name) LIKE ? OR
                                     admission_no = ? OR students.familyid = ? OR phone1 LIKE ? OR phone2 LIKE ? OR (concat(ltrim(rtrim(students.first_name)), \" \",ltrim(rtrim(students.last_name))) LIKE ? ) OR
                                     (concat(ltrim(rtrim(students.first_name)), \" \", ltrim(rtrim(students.middle_name)), \" \",ltrim(rtrim(students.last_name))) LIKE ? )
                                     OR guardians.mobile_phone LIKE ? OR guardians.first_name LIKE ? OR guardians.last_name LIKE ?",
            "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}", "#{params[:query]}",
            "#{params[:query]}%", "#{params[:query]}%","#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%",
            "#{params[:query]}%", "#{params[:query]}%"],
          :order => "batches.id ASC, students.first_name ASC") unless params[:query] == ''
      else
        @students = Student.paginate(:per_page => 5, :page => params[:page],
          :select => "students.id AS id, students.admission_no AS admission_no, students.roll_number, students.familyid as familyid, students.phone1 as phone1,
                             CONCAT(students.first_name,' ',students.middle_name,' ',students.last_name) AS fullname,
                             CONCAT(courses.code,'-',batches.name) AS batch_full_name,
                             (SELECT SUM(ff.balance) FROM finance_fees ff WHERE  ff.student_id=students.id AND
                              FIND_IN_SET(id,GROUP_CONCAT(DISTINCT finance_fees.id))) AS fee_due,
                             #{transport_fee_due} AS transport_due, #{hostel_fee_due} AS hostel_due,
                             guardians.first_name AS guardian_first_name, guardians.last_name AS guardian_last_name ",
          :joins => join_sql_for_student_fees, :group => "students.id",:having => having,
          :conditions => ["admission_no = ? OR students.familyid = ?", params[:query], params[:query]],
          :order => "batches.id ASC, students.first_name ASC") unless params[:query] == ''
      end      
      render :template=>"indepth_finance_extensions/search_students_for_pay_all_fees_with_tmpl"
    end

    def join_sql_for_student_fees_with_tmpl(batch_id=nil)
      if batch_id.present?
        join_batch_id = (batch_id == "current_batch") ? "students.batch_id" : "#{batch_id}"
        #      if batch_id == "current_batch"
        #        transport_sql = "AND transport_fees.groupable_id=students.batch_id"
        #        hostel_sql = "AND hostel_fees.batch_id=students.batch_id"
        #        finance_sql = "AND finance_fees.batch_id=students.batch_id"
        #      else
        transport_sql = "AND transport_fees.groupable_id=#{join_batch_id}"
        hostel_sql = "AND hostel_fees.batch_id=#{join_batch_id}"
        finance_sql = "AND finance_fees.batch_id=#{join_batch_id}"
        #      end
      else
        transport_sql = hostel_sql = finance_sql=""
      end


      result  = "INNER JOIN batches ON batches.id=students.batch_id
                 INNER JOIN courses ON courses.id=batches.course_id
                 LEFT JOIN finance_fees
                        ON finance_fees.student_id=students.id #{finance_sql}"
      result +=" LEFT JOIN guardians ON guardians.id=students.immediate_contact_id"
      result +=" LEFT JOIN transport_fees
                        ON transport_fees.receiver_id=students.id AND
                           transport_fees.receiver_type='Student' AND
                           transport_fees.is_active=1 #{transport_sql}" if FedenaPlugin.
        can_access_plugin?("fedena_transport")
      result +=" LEFT JOIN hostel_fees
                        ON hostel_fees.student_id=students.id AND
                           hostel_fees.is_active=1 #{hostel_sql}" if FedenaPlugin.
        can_access_plugin?("fedena_hostel")
      result
    end
    
    def pay_all_fees_with_tmpl
      pay_all_data
      financial_year_check      
      particular_paid = false 
      if @financial_year_enabled
        if request.post?
          params[:transactions].each do |k,v|
            particular_paid = true if @disabled_fee_ids.include?(v[:finance_id].try(:to_i)) and 
              v[:finance_type] == 'FinanceFee'      
            break if particular_paid
          end
            params[:transactions].values.each{|t| 
              if (t['wallet_amount_applied'].eql? "true")
                t['amount'] = t['amountt'].to_f  + t['wallet_amount'].to_f 
              else
                t['amount'] = t['amountt'].to_f 
              end
              t.delete("amountt")
            }          
          FinanceTransactionLedger.transaction do        
            if !particular_paid
              status=true
              if params[:wallet_amount_applied]
                params[:multi_fees_transaction][:amount] = params[:multi_fees_transaction][:amount].to_f + params[:wallet_amount].to_f 
              end
              ledger_info = params[:multi_fees_transaction].              
              merge({:transaction_type => 'MULTIPLE', :category_is_income => true, 
                  :current_batch => @current_batch,:is_waiver => false})                       
              transaction_ledger = FinanceTransactionLedger.safely_create(ledger_info, params[:transactions])
              status = transaction_ledger.present?
              FinanceTransaction.send_sms=false                   
              FinanceTransaction.send_sms=true
              if status and !(transaction_ledger.new_record?)
                tids = transaction_ledger.finance_transactions.collect(&:id)
                trans_code=[]
                tids.each do |tid|
                  trans_code << "transaction_id%5B%5D=#{tid}"
                end  
                # send sms for a payall transaction            
                transaction_ledger.send_sms
                transaction_ledger.notify_users
                trans_code=trans_code.join('&')
                flash[:notice] = "#{t('finance.flash14')}.  <a href ='#' onclick='show_print_dialog(#{tids.to_json})'>#{t('print_receipt')}</a>"            
              else
                flash[:notice]="#{t('fee_payment_failed')}"
                raise ActiveRecord::Rollback
              end
            else        
              flash[:notice]="#{t('fee_payment_failed')}"
              raise ActiveRecord::Rollback
            end
          end
          redirect_to :controller => 'finance_extensions', :action => 'pay_all_fees', 
            :batch_id => @current_batch.id and return       
        end
      else
        flash.now[:notice] = t('financial_year_payment_disabled')        
      end
      get_paid_fees(@student.id, @current_batch.id)
      render :template => 'indepth_finance_extensions/pay_all_fees_with_tmpl' and return
    end
    
    def list_students_by_batch_with_tmpl
      if params[:fees_submission][:batch_id].present?
        @batch_id=params[:fees_submission][:batch_id]
        having="(count(distinct finance_fees.id)>0)"
        having+=" or (count(hostel_fees.id)>0)" if FedenaPlugin.can_access_plugin?("fedena_hostel")
        having+=" or (count(distinct transport_fees.id)>0)" if FedenaPlugin.can_access_plugin?("fedena_transport")
        @students=Student.paginate(:per_page => 15, :page => params[:page],
          :select => "students.id AS id, CONCAT(students.first_name,' ',students.middle_name,' ',
                                                                     students.last_name) AS fullname,students.familyid as familyid, students.phone2 as phone1,
                           CONCAT(courses.code,'-',batches.name) AS batch_full_name,
                           students.admission_no AS admission_no,
                           (SELECT SUM(ff.balance) 
                               FROM finance_fees ff 
                             WHERE  ff.student_id=students.id AND 
                                          FIND_IN_SET(id,GROUP_CONCAT(DISTINCT finance_fees.id))
                            ) AS fee_due,
                            guardians.first_name AS guardian_first_name, guardians.last_name AS guardian_last_name,
                            #{transport_fee_due} AS transport_due,
                            #{hostel_fee_due} AS hostel_due,students.roll_number",
          :joins => join_sql_for_student_fees(@batch_id),
          :group => "students.id",
          :having => having,
          :order => "batches.id asc,students.first_name asc"
        )
      else
        @students=[]
      end      
      respond_to do |format|
        format.js { render :template => 'indepth_finance_extensions/list_students_by_batch_with_tmpl.js.erb'}
      end
    end
    
    def student_search_autocomplete_with_tmpl
      having="(count(distinct finance_fees.id)>0)"
      having+=" or (count(hostel_fees.id)>0)" if FedenaPlugin.can_access_plugin?("fedena_hostel")
      having+=" or (count(distinct transport_fees.id)>0)" if FedenaPlugin.can_access_plugin?("fedena_transport")
      students= Student.active.find(:all, :select => "students.*,sum(finance_fees.balance) as fee_due,#{transport_fee_due} as transport_due,#{hostel_fee_due} as hostel_due",
        :joins => join_sql_for_student_fees,
        :conditions => ["(students.admission_no LIKE ? OR students.first_name LIKE ?) and students.id<>#{params[:student_id]}", "%#{params[:query]}%", "%#{params[:query]}%"],
        :group => "students.id",
        :having => having,
        :order => "batches.id asc,students.first_name asc").uniq
      suggestions=students.collect { |s| s.full_name.length+s.admission_no.length > 20 ? s.full_name[0..(18-s.admission_no.length)]+".. "+"(#{s.admission_no})"+" - " : s.full_name+"(#{s.admission_no})" }
      receivers=students.map { |st| "{'receiver': 'Student','id': #{st.id}}" }
      if receivers.present?
        render :json => {'query' => params["query"], 'suggestions' => suggestions, 'data' => receivers}
      else
        render :json => {'query' => params["query"], 'suggestions' => ["#{t('no_users')}"], 'data' => ["{'receiver': #{false}}"]}
      end
    end
  
    def delete_multi_fees_transaction_with_tmpl
      @student=Student.find(params[:id])
      @current_batch= params[:batch_id].present? ? Batch.find(params[:batch_id]) : 
        @student.batch
      @transaction_category_id=FinanceTransactionCategory.find_by_name("Fee").id
      @transaction_date=Date.today_with_timezone
      financial_year_check
      if request.post?
        if params[:type]=='multi_fees_transaction'
          ftl=FinanceTransactionLedger.find(params[:transaction_id],:include => :finance_transactions)
          ftl.mark_cancelled(params[:reason])
          if ftl.is_waiver
            mfd = MultiFeeDiscount.find_by_transaction_ledger_id(ftl.id)
            mfd_fee = mfd.fetch_fees if mfd.present?
            mfd.destroy 
          end
          flash.now[:notice]= (ftl.status == 'CANCELLED' ? "#{t('finance.flash18')}" : 
              "#{t('finance.flash32')}")
        else
          ActiveRecord::Base.transaction do
            ft= FinanceTransaction.find(params[:transaction_id])
            ft.cancel_reason = params[:reason]
            if FedenaPlugin.can_access_plugin?("fedena_pay")
              finance_payment = ft.finance_payment
              unless finance_payment.nil?
                status = Payment.payment_status_mapping[:reverted]
                finance_payment.payment.update_attributes(:status_description => status)
              end
            end
            unless ft.destroy
              raise ActiveRecord::Rollback 
              flash.now[:notice]="#{t('finance.flash32')}"
            else
              flash.now[:notice]="#{t('finance.flash18')}"
            end
          end
        end
        unless params[:si_no].to_i==1
          if params[:si_no].to_i%10==1
            params[:page]=(params[:page].to_i)-1
          end
        end
        get_paid_fees(@student.id, @current_batch.id)
        fetch_all_fees
        @is_tax_present = @finance_fees.map(&:tax_enabled).include?(true)
        #@multi_fee_discounts = MultiFeeDiscount.all(:conditions => {:receiver_id => 
              #@student.id, :receiver_type => "Student"}, :include => :fee)
        @multi_fee_discounts = MultiFeeDiscount.all(:conditions => ["multi_fee_discounts.receiver_id = ? AND
        multi_fee_discounts.receiver_type = 'Student'", @student.id], :include => :fee,
        :joins => "INNER JOIN fee_discounts fd
                           ON fd.multi_fee_discount_id = multi_fee_discounts.id AND fd.batch_id = #{@current_batch.id}",
        :group => "multi_fee_discounts.id")
        render :update do |page|
          #page.replace_html "flash-message", :text => "<p class='flash-msg'>#{flash[:notice]}</p>"
          #page.replace_html "pay_fees", :partial => 'indepth_finance_extensions/pay_fees_form_tmpl'
          page.redirect_to :controller => 'finance_extensions', :action => 'pay_all_fees', :id => @student.id, :batch_id => @student.batch_id
        end
      else      
        flash[:notice] = "#{t('flash_msg6')}"
        redirect_to :controller => 'user', :action => 'dashboard' and return
      end
    end
  
    def search_student_list_for_structure_with_tmpl
    
      if params[:query].length>= 3
        @students = Student.find(:all,
          :select => "students.id AS id, students.admission_no AS admission_no, students.roll_number,
                           students.batch_id AS batch_id,
                           CONCAT(students.first_name,' ',students.middle_name,' ',students.last_name) AS fullname,
                           CONCAT(courses.code,'-',batches.name) AS batch_full_name,
                           (SELECT SUM(ROUND(ff.balance,#{@precision})) FROM finance_fees ff WHERE  ff.student_id=students.id AND 
                            FIND_IN_SET(id,GROUP_CONCAT(distinct finance_fees.id))) AS fee_due,
                           (SELECT COUNT(ff.id) FROM finance_fees ff WHERE  ff.student_id=students.id AND 
                            ff.batch_id = students.batch_id AND 
                            FIND_IN_SET(id,GROUP_CONCAT(distinct finance_fees.id))) AS fee_count,
                           #{transport_fee_count} AS transport_count, #{hostel_fee_count} AS hostel_count,
                           #{transport_fee_due} AS transport_due, #{hostel_fee_due} AS hostel_due",
          :joins => join_sql_for_student_fees("current_batch"), :group => "students.id",
          :conditions => ["ltrim(students.first_name) LIKE ? OR ltrim(students.middle_name) LIKE ? OR ltrim(students.last_name) LIKE ? OR 
                                   admission_no = ? OR (concat(ltrim(rtrim(students.first_name)), \" \",ltrim(rtrim(students.last_name))) LIKE ? ) OR 
                                   (concat(ltrim(rtrim(students.first_name)), \" \", ltrim(rtrim(students.middle_name)), \" \",ltrim(rtrim(students.last_name))) LIKE ? ) ",
            "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}", 
            "#{params[:query]}%", "#{params[:query]}%"],
          :order => "batches.id ASC, students.first_name ASC") unless params[:query] == ''
      else
        @students = Student.find(:all,
          :select => "students.id AS id, students.admission_no AS admission_no, students.roll_number,
                           students.batch_id AS batch_id,
                           CONCAT(students.first_name,' ',students.middle_name,' ',students.last_name) AS fullname,
                           CONCAT(courses.code,'-',batches.name) AS batch_full_name,
                           (SELECT SUM(ROUND(ff.balance,#{@precision})) FROM finance_fees ff WHERE  ff.student_id=students.id AND 
                            FIND_IN_SET(id,GROUP_CONCAT(DISTINCT finance_fees.id))) AS fee_due,
                           (SELECT COUNT(ff.id) FROM finance_fees ff WHERE  ff.student_id=students.id AND 
                            ff.batch_id = students.batch_id AND 
                            FIND_IN_SET(id,GROUP_CONCAT(distinct finance_fees.id))) AS fee_count,
                           #{transport_fee_count} AS transport_count, #{hostel_fee_count} AS hostel_count,
                           #{transport_fee_due} AS transport_due, #{hostel_fee_due} AS hostel_due",
          :joins => join_sql_for_student_fees("current_batch"), :group => "students.id", 
          :conditions => ["admission_no = ? ", params[:query]],
          :order => "batches.id ASC, students.first_name ASC") unless params[:query] == ''
      end
      @search_query = params[:query]
      
      render :layout => false
    end
    
  end
end
