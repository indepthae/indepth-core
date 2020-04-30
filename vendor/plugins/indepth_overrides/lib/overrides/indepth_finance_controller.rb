module IndepthOverrides
  module IndepthFinanceController
  	def self.included (base)
      base.instance_eval do
#        alias_method_chain :receipt_settings, :tmpl
#        alias_method_chain :fees_student_dates, :tmpl
#        alias_method_chain :fees_submission_student, :tmpl
#        alias_method_chain :fees_submission_save, :tmpl
      end
    end
#    def receipt_settings_with_tmpl
#      render :template => 'indepth_finance/receipt_settings_with_tmpl'
#    end
    def single_statement_header_settings
      @single_statement_header = SingleStatementHeader.first || SingleStatementHeader.new
      if request.post?
        if @single_statement_header.nil?
          # @single_statement_header = SingleStatementHeader.new
        end
        @single_statement_header.logo = params[:single_statement_header]["logo"] if params[:single_statement_header].present? and params[:single_statement_header][:logo].present?
        @single_statement_header.title = params[:single_statement_header]["title"]
        @single_statement_header.is_empty = params[:single_statement_header]["is_empty"]
        @single_statement_header.space_height = params[:single_statement_header]["space_height"]
        @single_statement_header.save
      else
      end
      if !@single_statement_header.nil?
        if @single_statement_header.is_empty
          @checked_val = true
        else
          @checked_val = false
        end
      else
        @checked_val = false
      end
      puts @checked_val.inspect
      @space_height = @single_statement_header.nil? ? 0  : @single_statement_header.space_height
      @title = @single_statement_header.nil? ? ""  : @single_statement_header.title
      @logo = @single_statement_header.nil? ? ""  : @single_statement_header.logo
      render :template => 'indepth_finance/single_statement_header_settings'
    end
    
    def fees_student_dates_with_tmpl
      @student = Student.find(params[:id])
      @dates=FinanceFeeCollection.find(:all, 
        :joins => "INNER JOIN collection_particulars on 
                              collection_particulars.finance_fee_collection_id=finance_fee_collections.id 
                        INNER JOIN finance_fee_particulars on 
                              finance_fee_particulars.id=collection_particulars.finance_fee_particular_id 
                        INNER JOIN finance_fees on 
                              finance_fees.fee_collection_id=finance_fee_collections.id", 
        :conditions => "finance_fees.student_id='#{@student.id}' and 
                                finance_fee_collections.is_deleted=#{false} and 
                                ((finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=finance_fees.batch_id) or 
                                 (finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id='#{@student.id}') or 
                                 (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=finance_fees.student_category_id))"
      ).uniq
      render :template => 'indepth_finance/fees_student_dates_with_tmpl'
    end
    
    def fees_submission_student_with_tmpl
      if params[:date].present?
        @date = @fee_collection = FinanceFeeCollection.find(params[:date])
        @transaction_date= params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : Date.today_with_timezone.to_date
        @target_action='fees_submission_student'
        @target_controller='finance'
        @student = Student.find(params[:id])
        @fee = @student.finance_fee_by_date(@date)
        unless @fee.nil?
          @particular_wise_paid = (@date.discount_mode != "OLD_DISCOUNT" && @fee.finance_transactions.map(&:trans_type).include?("particular_wise"))
          #        @particular_wise_paid = @fee.finance_transactions.map(&:trans_type).include?("particular_wise")
          flash.now[:notice]="#{t('particular_wise_paid_fee_payment_disabled')}" if @particular_wise_paid
          @batch = @fee.batch
          @financefee = @student.finance_fee_by_date @date
          @due_date = @fee_collection.due_date
          @paid_fees = @fee.finance_transactions
          @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted = false"])
          @fine=nil
          @fine=params[:fine][:fee] if (params[:fine].present? and params[:fine][:fee].present?)
          particular_and_discount_details
          bal=(@total_payable-@total_discount).to_f
          days=(@transaction_date-@date.due_date.to_date).to_i
          auto_fine=@date.fine 
          if days > 0 and auto_fine
            @fine=params[:fine][:fee] .to_f  if params[:fine].present? and params[:fine][:fee].present? and params[:fine][:fee].to_f > 0.0
            @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
            @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
            if @fine_rule and @financefee.balance==0
              @fine_amount=@fine_amount-@financefee.finance_transactions.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:fine_amount)
            end
          end
          @fine_amount=0 if @financefee.is_paid
          render :update do |page|
            if params[:add_fine].present?
              page.replace_html 'modal-box', :partial => 'finance/individual_fine_submission'
              page << "Modalbox.show($('modal-box'), {title: ''});"
            elsif @fine.nil? or @fine.to_f > 0
              page.replace_html "fee_submission", :partial => "indepth_finance/fees_submission_form_tmpl", :with => @fine
              page << "Modalbox.hide();"
            elsif @fine.to_f <=0
              page.replace_html 'modal-box', :text => 'finance/fine_submission'
              page.replace_html 'form-errors', :text=>"<div id='error-box'><ul><li>#{t('finance.flash24')}</li></ul></div>"
            end
          end
        else
          render :update do |page|
            page.replace_html "fee_submission", :text => '<p class="flash-msg">No students have been assigned this fee.</p>'
          end
        end
      else
        render :update do |page|
          page.replace_html "fee_submission", :text => ''
        end
      end  

    end
    
    def particular_and_discount_details
      include_particular_associations = @financefee.tax_enabled ? [] : [:collection_tax_slabs]
      @fee_particulars = @date.finance_fee_particulars.all(:conditions => "batch_id=#{@financefee.batch_id}",
        :include => include_particular_associations).select do |par| 
        (par.receiver_type=='Student' and 
            par.receiver_id==@student.id)? par.receiver=@student : par.receiver;(par.receiver.present?) and 
          (par.receiver==@student or par.receiver==@financefee.student_category or 
            par.receiver==@financefee.batch) 
      end
      @categorized_particulars=@fee_particulars.group_by(&:receiver_type)
      if @financefee.tax_enabled?
        @tax_collections = @financefee.tax_collections.all(:include => :tax_slab)        
        #      (:select => "distinct tax_collections.*,
        #                        ctxs.tax_slab_id as tax_slab_id, ffp.name as particular_name",
        #        :include => :tax_slab,
        #        :joins => "INNER JOIN collectible_tax_slabs ctxs
        #                                    ON ctxs.collectible_entity_type = tax_collections.taxable_entity_type AND 
        #                                          ctxs.collectible_entity_id = tax_collections.taxable_entity_id AND
        #                                          ctxs.collection_id = #{@financefee.fee_collection_id} AND
        #                                          ctxs.collection_type = 'FinanceFeeCollection'
        #                        INNER JOIN tax_slabs 
        #                                    ON tax_slabs.id = ctxs.tax_slab_id
        #                        INNER JOIN finance_fee_particulars ffp 
        #                                    ON ffp.id=tax_collections.taxable_entity_id")
      
        @total_tax = @tax_collections.map do |x| 
          FedenaPrecision.set_and_modify_precision(x.tax_amount).to_f
        end.sum.to_f
      
        #      @tax_slabs = @tax_collections.map {|tax_col| tax_col.tax_slab }.uniq
      
        #      @tax_slabs =  TaxSlab.all(:conditions => {:id => @tax_collections.keys })      
        @tax_slabs = @tax_collections.group_by {|x| x.tax_slab }
      
        @tax_config = Configuration.get_multiple_configs_as_hash(['FinanceTaxIdentificationLabel',
            'FinanceTaxIdentificationNumber']) if @tax_slabs.present?
      end
      @discounts=@date.fee_discounts.all(:conditions => "batch_id=#{@financefee.batch_id}").
        select do |par| 
        (par.receiver.present?) and 
          ((par.receiver==@financefee.student or 
              par.receiver==@financefee.student_category or 
              par.receiver==@financefee.batch) and 
            (par.master_receiver_type!='FinanceFeeParticular' or 
              (par.master_receiver_type=='FinanceFeeParticular' and 
                (par.master_receiver.receiver.present? and 
                  @fee_particulars.collect(&:id).include? par.master_receiver_id) and 
                (par.master_receiver.receiver==@financefee.student or 
                  par.master_receiver.receiver==@financefee.student_category or 
                  par.master_receiver.receiver==@financefee.batch)))) 
      end
      @categorized_discounts=@discounts.group_by(&:master_receiver_type)
      @total_discount = 0
      @total_payable=@fee_particulars.map { |s| s.amount }.sum.to_f
      @total_discount =@discounts.map do |d| 
        d.master_receiver_type=='FinanceFeeParticular' ? 
          (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) : 
          @total_payable * d.discount.to_f/(d.is_amount? ? @total_payable : 100) 
      end.sum.to_f unless @discounts.nil?
    end
    
    def fees_submission_save_with_tmpl
      @target_action='fees_submission_student'
      @target_controller='finance'
      @student = Student.find(params[:student])
      @date = @fee_collection = FinanceFeeCollection.find(params[:date])
      @financefee = @date.fee_transactions(@student.id)

      @due_date = @fee_collection.due_date
      @fee_category = FinanceFeeCategory.find(@fee_collection.fee_category_id, :conditions => ["is_deleted IS NOT NULL"])
      particular_and_discount_details
      total_fees = @financefee.balance.to_f+FedenaPrecision.set_and_modify_precision(params[:special_fine]).to_f
      unless params[:fine].nil?
        total_fees += FedenaPrecision.set_and_modify_precision(params[:fine]).to_f
      end
    
      @transaction_date= request.post? ? Date.today_with_timezone : Date.parse(params[:transaction_date])
      if request.post?
        unless params[:fees][:fees_paid].to_f <= 0
          unless params[:fees][:payment_mode].blank?
            unless FedenaPrecision.set_and_modify_precision(params[:fees][:fees_paid]).to_f > FedenaPrecision.set_and_modify_precision(total_fees).to_f
              transaction = FinanceTransaction.new
              ActiveRecord::Base.transaction do 
                #              begin
                (@financefee.balance.to_f > params[:fees][:fees_paid].to_f) ? transaction.title = "#{t('receipt_no')}. (#{t('partial')}) F#{@financefee.id}" : transaction.title = "#{t('receipt_no')}. F#{@financefee.id}"
                transaction.category = FinanceTransactionCategory.find_by_name("Fee")
                transaction.payee = @student
                transaction.finance = @financefee
                transaction.fine_included = true unless params[:fine].nil?
                transaction.amount = params[:fees][:fees_paid].to_f
                transaction.fine_amount = params[:fine].to_f
                transaction.transaction_type = 'SINGLE'
                if params[:special_fine] and total_fees==params[:fees][:fees_paid].to_f
                  # transaction.fine_amount = params[:fine].to_f+params[:special_fine].to_f
                  # transaction.fine_included = true
                  @fine_amount=0
                end
                transaction.transaction_date = params[:transaction_date]
                transaction.payment_mode = params[:fees][:payment_mode]
                transaction.reference_no = params[:fees][:reference_no]
                transaction.cheque_date = params[:fees][:cheque_date] if params[:fees][:cheque_date].present?
                transaction.bank_name = params[:fees][:bank_name] if params[:fees][:bank_name].present? 
                transaction.payment_note = params[:fees][:payment_note]
                transaction.save            
                if transaction.errors.present?
                  flash[:notice]="#{t('fee_payment_failed')}"
                  transaction.errors.full_messages.each do |err_msg|
                    @financefee.errors.add_to_base(err_msg)
                  end
                  raise ActiveRecord::Rollback 
                else
                  flash[:warning] = "#{t('finance.flash14')}.  <a href ='#' onclick='show_print_dialog(#{transaction.id})'>#{t('print_receipt')}</a>"                  
                end
                #              rescue Exception => e
                #                puts e.inspect
                #                raise ActiveRecord::Rollback
                #              end
              end
              @financefee.reload
              # is_paid = @financefee.balance==0 ? true : false
              # @financefee.update_attributes(:is_paid => is_paid)
              # flash[:warning] = "#{t('flash14')}.  <a href ='http://#{request.host_with_port}/finance/generate_fee_receipt_pdf?transaction_id=#{transaction.id}' target='_blank'>#{t('print_receipt')}</a>"

              flash[:notice]=nil
            else
              flash[:warning]=nil
              flash[:notice] = "#{t('flash19')}"
            end
          else
            flash[:warning]=nil
            flash[:notice] = "#{t('select_one_payment_mode')}"
          end
        else
          flash[:warning]=nil
          flash[:notice] = "#{t('flash23')}"
        end
      end
      @paid_fees = @financefee.finance_transactions.all(:include => :transaction_ledger)
      bal=(@total_payable-@total_discount).to_f
      days=(@transaction_date - @date.due_date.to_date).to_i
      auto_fine=@date.fine
      if days > 0 and auto_fine
        @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
        @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule and @financefee.is_paid==false
        if @fine_rule and @financefee.balance==0
          @fine_amount=@fine_amount.to_f-@financefee.paid_auto_fine
        end
      end

      @fine_amount=0 if @financefee.is_paid
      @transaction_date = Date.today_with_timezone if request.post?
      render :update do |page|
        page.replace_html "fee_submission", :partial => "indepth_finance/fees_submission_form_tmpl"
      end
    end
    
  end
end