class FinanceExtensionsController < FinanceController
  include FinancePaidFees
  lock_with_feature :finance_multi_receipt_data_updation
  filter_access_to [:generate_overall_fee_receipt_pdf], :attribute_check => true, 
    :load_method => lambda { FinanceTransactionLedger.find_by_id_and_payee_id(params[:transaction_id], params[:student_id]) }
  check_request_fingerprint :particular_wise_fee_payment, :create_instant_particular, :create_instant_discount,
                            :pay_defall_fees, :update_collection_discount, :update_collection_particular,
                            :delete_student_particular, :pay_all_fees, :delete_multi_fees_transaction
  filter_access_to [:generate_overall_fee_receipt_pdf], :attribute_check => true,
                   :load_method => lambda { FinanceTransactionLedger.find_by_id_and_payee_id(params[:transaction_id], params[:student_id]) }
  check_request_fingerprint :particular_wise_fee_payment, :create_instant_particular, :create_instant_discount, :pay_defall_fees, :update_collection_discount,
                            :update_collection_particular, :delete_student_particular, :pay_all_fees
  around_filter :lock_particular_wise_auto_creation, :only => :particular_wise_fee_payment
  before_filter :invoice_number_enabled?, :only => [:view_fees_structure, :fees_structure_for_student,
                                                    :generate_overall_fee_receipt_pdf, :fee_structure_pdf]

  before_filter :student_fees_structure, :only => [:view_fees_structure, :student_fees_structure_pdf]

  require 'lib/override_errors'
  helper OverrideErrors

  # particular-wise payment page
  def pay_fees_in_particular_wise
    @student = Student.find(params[:id])
    @dates=FinanceFeeCollection.find(:all,
                                     # :from => "finance_fee_collections USE INDEX FOR JOIN (index_by_fee_account_id)",
                                     :joins => "LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
                 INNER JOIN collection_particulars
                         ON collection_particulars.finance_fee_collection_id=finance_fee_collections.id
                 INNER JOIN finance_fee_particulars
                         ON finance_fee_particulars.id=collection_particulars.finance_fee_particular_id
                 INNER JOIN finance_fees
                         ON finance_fees.fee_collection_id=finance_fee_collections.id",
                                     :conditions => "finance_fees.student_id='#{@student.id}' AND #{active_account_conditions} AND
                      finance_fee_collections.is_deleted= false AND
                      ((finance_fee_particulars.receiver_type='Batch' AND
                        finance_fee_particulars.receiver_id=finance_fees.batch_id) OR
                       (finance_fee_particulars.receiver_type='Student' AND
                        finance_fee_particulars.receiver_id='#{@student.id}') OR
                       (finance_fee_particulars.receiver_type='StudentCategory' AND
                        finance_fee_particulars.receiver_id='#{@student.student_category_id}'))").uniq
    # (finance_fee_collections.fee_account_id IS NULL OR
    #  (finance_fee_collections.fee_account_id IS NOT NULL AND fa.is_deleted = false)) AND
    render "finance_extensions/particular_wise_payment/pay_fees_in_particular_wise"
  end

  # submit particular-wise fee
  def particular_wise_fee_payment
    @target_action='particular_wise_fee_payment'
    @target_controller='finance_extensions'
    @transaction_date=params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : 
      Date.today_with_timezone
    financial_year_check
    if params[:date].present?
      @student = Student.find(params[:id])
      @date = @fee_collection = FinanceFeeCollection.find_by_id(params[:date],
                                                                :from => "finance_fee_collections USE INDEX FOR JOIN (index_by_fee_account_id)",
                                                                # :conditions => "(finance_fee_collections.fee_account_id IS NULL OR
                                                                #                  (finance_fee_collections.fee_account_id IS NOT NULL AND fa.is_deleted = false))",
                                                                :conditions => "#{active_account_conditions}",
                                                                :joins => "LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id",
                                                                :include => [:fee_category,
                                                                             {:finance_fee_particulars => :particular_payments}, :fee_discounts])
      if @date.present?

        @financefee = FinanceFee.find_by_fee_collection_id_and_student_id(@date.id, @student.id,
                                                                          :include => [:finance_transactions, {:particular_payments =>
                                                                                                                   [:particular_discounts, :finance_fee_particular]}])
        # @linking_required = @fee_collection.has_linked_unlinked_masters(false, @student.id) if @student.present? and !@financefee.is_paid
        @collection_wise_paid = @financefee.finance_transactions.map(&:trans_type).include?("collection_wise")
        if @financefee.tax_enabled?
          @error = true
          flash.now[:notice]="#{t('particular_wise_payment_disabled')}"
        elsif @collection_wise_paid
          @error = true
          flash.now[:notice]="#{t('collection_wise_paid_fee_payment_disabled')}"
        else
          @due_date = @fee_collection.due_date
          @fee_category = @fee_collection.fee_category
          @transaction_category_id=FinanceTransactionCategory.find_by_name("Fee").id
          particular_and_discount_details
          bal=(@total_payable-@total_discount).to_f
          @transaction_date = request.post? ? Date.today_with_timezone : @transaction_date
          days=(@transaction_date-@date.due_date.to_date).to_i
          auto_fine=@date.fine
          if days > 0 and auto_fine and !@financefee.is_fine_waiver
            @fine_rule=auto_fine.fine_rules.find(:last,
                                                 :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],
                                                 :order => 'fine_days ASC')
            if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && !@financefee.is_paid? && !@financefee.balance_fine.nil? 
              @fine_amount = @financefee.balance_fine
            else
            @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
            end
          end
          @paid_fine = @fine_amount
          @fine_amount = 0 if @financefee.is_paid_with_fine?

          if request.post?
            if params[:is_fine_waiver].present?
              @financefee.update_attributes(:is_fine_waiver=>params[:is_fine_waiver], :is_paid=>true)
            else
              FinanceTransaction.transaction do
                transaction=FinanceTransaction.new(params[:fees])
                if transaction.save
                  finance_transaction_hsh={"finance_transaction_id" => transaction.id}
                  if params[:particular_payment].present?
                    params[:particular_payment][:particular_payments_attributes].values.each { |hsh| hsh.merge!(finance_transaction_hsh) }
                    @financefee.update_attributes(params[:particular_payment])
                  end
                  flash.now[:notice] = "#{t('finance.flash14')}.  <a href ='#' onclick='show_print_dialog(#{transaction.id})'>#{t('print_receipt')}</a>"
                  @error=false
                else
                  flash.now[:notice]="#{t('fee_payment_failed')}"
                end
                # trigger for particular wise paid fee transactions
                TransactionReportSync.create_for_transaction(transaction)
                flash.now[:notice] = "#{t('finance.flash14')}.  <a href ='#' onclick='show_print_dialog(#{transaction.id})'>#{t('print_receipt')}</a>"              
                @error=false
              end
              @transaction_date = Date.today_with_timezone
            end
          end

          @financefee.reload
          if Configuration.is_fine_settings_enabled? && @financefee.balance <= 0 && !@financefee.is_paid? && !@financefee.balance_fine.nil?
              @fine_amount = @financefee.balance_fine
              @paid_fine = @fine_amount
          end
          @paid_fees = @financefee.finance_transactions.all(
              :include => [:transaction_ledger, {:particular_payments =>
                                                     [:finance_fee_particular, :particular_discounts]}])

          paid_fine = @paid_fees.select do |fine_transaction|
            fine_transaction.description =='fine_amount_included'
          end.sum(&:fine_amount).to_f
          @fine_amount = @fine_amount.to_f - paid_fine
          @fine_amount = 0 if @financefee.is_paid
          @applied_discount = FedenaPrecision.set_and_modify_precision(
              ParticularDiscount.find(:all,
                                      :joins => [{:particular_payment => [:finance_fee, :finance_transaction]}],
                                      :conditions => "finance_fees.id = #{@financefee.id}").sum(&:discount)).to_f
        end
        
        # calculating total collected advance fee amount
        @advance_fee_used = @financefee.finance_transactions.sum(:wallet_amount).to_f
        
      else
        @error = true
        # @account_deleted = true
        flash[:notice] = "#{t('flash_msg5')}"
      end
    else
      @error = true
    end

    render "finance_extensions/particular_wise_payment/particular_wise_fee_payment"
  end

  def particular_wise_fee_pay_pdf
    @fine_amount=params[:fine_amount]
    @paid_fine=@fine_amount
    @student = Student.find(params[:id])
    @date = @fee_collection = FinanceFeeCollection.find_by_id(params[:date],
                                                              :from => "finance_fee_collections USE INDEX FOR JOIN (index_by_fee_account_id)",
                                                              # :conditions => "(finance_fee_collections.fee_account_id IS NULL OR
                                                              #                  (finance_fee_collections.fee_account_id IS NOT NULL AND fa.is_deleted = false))",
                                                              :conditions => "#{active_account_conditions}",
                                                              :joins => "#{active_account_joins}",
                                                              :include => [:fee_category, {:finance_fee_particulars => :particular_payments}, :fee_discounts])

    unless @date.present? # belongs to deleted account
      flash[:notice] = "#{t('flash_msg5')}"
      redirect_to :controller => "user", :action => "dashboard"
    else
      @financefee = FinanceFee.find_by_fee_collection_id_and_student_id(@date.id, @student.id,
                                                                        :include => [:finance_transactions, {:particular_payments => [:particular_discounts, :finance_fee_particular]}])
      @due_date = @fee_collection.due_date
      @fee_category = @fee_collection.fee_category
      @transaction_category_id = FinanceTransactionCategory.find_by_name("Fee").id
      particular_and_discount_details
      @paid_fees=@financefee.finance_transactions.all(
          :include => [:transaction_ledger, {:particular_payments => [:finance_fee_particular, :particular_discounts]}])
      @applied_discount=ParticularDiscount.find(:all,
                                                :joins => [{:particular_payment => :finance_fee}],
                                                :conditions => "finance_fees.id=#{@financefee.id}").sum(&:discount).to_f
      @fine_amount=0 if @financefee.is_paid
      @transaction_date = params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : Date.today_with_timezone
      days=(@transaction_date-@date.due_date.to_date).to_i
      auto_fine=@date.fine
      if days > 0 and auto_fine
        @fine_rule=auto_fine.fine_rules.find(:last,
                                             :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"],
                                             :order => 'fine_days ASC')
      end
      render :pdf => 'particular_wise_fee_pay_pdf'
    end
  end

  # fetch data for pay all payment page as per params
  def pay_all_data(filter = false, exclude = [], exclude_fees_with_ids = {})
    @student ||= Student.find(params[:id])
    @transaction_date = params[:transaction_date].present? ? Date.parse(params[:transaction_date]) :
        params[:multi_fees_transaction].present? ? Date.parse(params[:multi_fees_transaction][:transaction_date]) :
            Date.today_with_timezone.to_date
    @current_batch = params[:batch_id].present? ? Batch.find(params[:batch_id]) : @student.batch
    @all_batches = (@student.previous_batches+[@student.batch]).uniq
    @not_paid_batch = @student.finance_fees.select{|m| !m.transaction_id.present? and m.is_paid == false}.collect(&:batch_id) +
                      @student.hostel_fees.select{|m| !m.finance_transaction_id.present?}.collect(&:batch_id) + 
                      @student.transport_fees.select{|m| !m.transaction_id.present?}.collect(&:groupable_id)
    @not_paid_batch = @not_paid_batch.uniq - [@student.batch.id]
    fetch_all_fees(filter, exclude, exclude_fees_with_ids)
    @is_tax_present = @finance_fees.map(&:tax_enabled).include?(true)
    @multi_fee_discounts = MultiFeeDiscount.all(:conditions => ["multi_fee_discounts.receiver_id = ? AND
        multi_fee_discounts.receiver_type = 'Student'", @student.id], :include => :fee,
        :joins => "INNER JOIN fee_discounts fd
                           ON fd.multi_fee_discount_id = multi_fee_discounts.id AND fd.batch_id = #{@current_batch.id}",
        :group => "multi_fee_discounts.id") unless current_user.student?
    if FedenaPlugin.can_access_plugin?('fedena_transport')
      @multi_fee_discounts += MultiFeeDiscount.all(:conditions => ["multi_fee_discounts.receiver_id = ? AND
        multi_fee_discounts.receiver_type = 'Student'", @student.id], :include => :fee,
        :joins => "INNER JOIN transport_fee_discounts tfd
                           ON tfd.multi_fee_discount_id = multi_fee_discounts.id
                   INNER JOIN transport_fees tf 
                           ON tf.id = tfd.transport_fee_id 
                   INNER JOIN students st
                           ON st.id = tf.receiver_id AND st.batch_id = #{@current_batch.id}",
        :group => "multi_fee_discounts.id") unless current_user.student?
    end
    @multi_fee_discounts = @multi_fee_discounts.uniq if @multi_fee_discounts.present?
  end

  # fetch all fees as per filters
  # finance fee / transport fee / hostel fee
  def fetch_all_fees(filter_paid_fees= false, exclude_fees = [], exclude_fees_with_ids = {})
    search_hostel_fees = !(exclude_fees.include? "hostel")
    search_transport_fees = !(exclude_fees.include? "transport")
    fee_transaction_category_id = FinanceTransactionCategory.find_by_name("Fee").id
    hostel_transaction_category_id = FinanceTransactionCategory.find_by_name("Hostel").
        try(:id) if search_hostel_fees
    transport_transaction_category_id = FinanceTransactionCategory.find_by_name("Transport").
        try(:id) if search_transport_fees
    precision_count = FedenaPrecision.get_precision_count
    finance_fee_conditions = exclude_fees_with_ids["finance_fee"].present? ?
        " AND finance_fees.id not in (#{exclude_fees_with_ids["finance_fee"].join(',')}) " : ""

    # finance_fee_conditions += " AND (finance_fee_collections.fee_account_id IS NULL OR
    #                                  (finance_fee_collections.fee_account_id IS NOT NULL AND fa.is_deleted = false))"
    finance_fee_conditions += " AND #{active_account_conditions}"
    master_fees_sql = <<-SQL
      SELECT distinct finance_fee_collections.name AS collection_name, 
                  finance_fee_collections.due_date As collection_due_date,
                  #{fee_transaction_category_id} as transaction_category_id,
                  finance_fees.is_paid,
                  finance_fees.balance,
                  finance_fees.balance_fine as balance_fine,
                  finance_fees.is_fine_waiver as is_fine_waiver,
                  finance_fees.id AS id,
                  'FinanceFee' as fee_type,
                  (IFNULL((particular_total - discount_amount),
                              finance_fees.balance + 
                              (SELECT IFNULL(SUM(finance_transactions.amount - 
                                                               finance_transactions.fine_amount),
                                                       0)
                                  FROM finance_transactions
                                WHERE finance_transactions.finance_id=finance_fees.id AND 
                                            finance_transactions.finance_type='FinanceFee'
                              ) - 
                              IF(finance_fees.tax_enabled,finance_fees.tax_amount,0)
                    ) 
                  ) AS actual_amount,
                  (SELECT IFNULL(SUM(IF(f_t.auto_fine = 0, f_t.fine_amount, f_t.auto_fine)),0)
                      FROM finance_transactions f_t
                    WHERE f_t.finance_id=finance_fees.id AND 
                                f_t.finance_type='FinanceFee' AND 
                                f_t.description= 'fine_amount_included'
                  ) AS paid_fine,
                  (SELECT IFNULL(SUM(IF(f_t.description = 'fine_amount_included',
                                                       IF(f_t.auto_fine = 0, 0, f_t.fine_amount - f_t.auto_fine), 
                                                       f_t.fine_amount)
                                                   ),0)
                      FROM finance_transactions f_t
                    WHERE f_t.finance_id=finance_fees.id AND 
                                f_t.finance_type='FinanceFee' AND 
                                f_t.fine_included = true
                  ) AS manual_paid_fine,
                  fine_rules.fine_amount AS fine_amount,
                  IF(finance_fees.tax_enabled,
                      (SELECT SUM(ROUND(tax_amount,#{precision_count}))
                          FROM tax_collections tc
                        WHERE tc.taxable_fee_type = 'FinanceFee' AND
                                    tc.taxable_fee_id = finance_fees.id),
                     '-'
                  ) AS tax_amount,
                  finance_fees.tax_enabled,
                  fine_rules.is_amount
       FROM `finance_fees`
       INNER JOIN `finance_fee_collections` ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id
        LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
       INNER JOIN `fee_collection_batches` ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id
       INNER JOIN `collection_particulars` ON (`finance_fee_collections`.`id` = `collection_particulars`.`finance_fee_collection_id`)
       INNER JOIN `finance_fee_particulars` ON (`finance_fee_particulars`.`id` = `collection_particulars`.`finance_fee_particular_id`)
         LEFT JOIN `finance_transactions` 
                ON (`finance_transactions`.`finance_id` = `finance_fees`.`id` AND 
                    `finance_transactions`.`finance_type` = 'FinanceFee')
         LEFT JOIN `fines` 
                ON `fines`.id = `finance_fee_collections`.fine_id AND 
                    fines.is_deleted is false
         LEFT JOIN `fine_rules` 
                ON  fine_rules.fine_id = fines.id  AND 
                    fine_rules.id= (
                           SELECT id 
                             FROM fine_rules ffr 
                            WHERE ffr.fine_id=fines.id AND 
                                  ffr.created_at <= finance_fee_collections.created_at AND 
                                  ffr.fine_days <= DATEDIFF(
                                           COALESCE(Date('#{@transaction_date}'),CURDATE()),
                                          finance_fee_collections.due_date) 
                         ORDER BY ffr.fine_days DESC LIMIT 1
                         )
    SQL

    #                                                                  hf.balance > 0 and 
    if (FedenaPlugin.can_access_plugin?("fedena_hostel") and search_hostel_fees)
      hostel_fee_conditions = exclude_fees_with_ids["hostel_fee"].present? ?
          " WHERE hf.id not in (#{exclude_fees_with_ids["hostel_fee"].join(',')}) " : ""
      hostel_fee_conditions += hostel_fee_conditions.present? ? " AND " : " WHERE "
      # hostel_fee_conditions += "(fc.fee_account_id IS NULL OR
      #                               (fc.fee_account_id IS NOT NULL AND fa.is_deleted = false))"
      hostel_fee_conditions += "#{active_account_conditions(true, 'fc')}"
      hostel_fees_sql="UNION ALL 
                       (SELECT fc.name as collection_name, fc.due_date As collection_due_date,
                               #{hostel_transaction_category_id} as transaction_category_id,
                               if(hf.balance > 0,false,true) is_paid,
                               hf.balance balance, 
                               NULL as balance_fine,
                               NULL as is_fine_waiver,
                               hf.id as id,
                               'HostelFee' as fee_type, hf.rent actual_amount,
                               0 as paid_fine,
                               (SELECT IFNULL(SUM(finance_transactions.fine_amount),0)
                                  FROM finance_transactions
                                 WHERE finance_transactions.finance_id=hf.id AND 
                                       finance_transactions.finance_type='HostelFee' AND 
                                       description IS NULL
                               ) AS manual_paid_fine, 
                               0 fine_amount,
                               IF(hf.tax_enabled,hf.tax_amount,'-') AS tax_amount, 
                               hf.tax_enabled, 0 is_amount
                         FROM `hostel_fees` hf
                        INNER JOIN `hostel_fee_collections` fc 
                                ON `fc`.id = `hf`.hostel_fee_collection_id and 
                                   fc.is_deleted=0 and 
                                   hf.student_id='#{@student.id}' and
                                   hf.batch_id=#{@current_batch.id} and
                                   is_active is true
                         LEFT JOIN fee_accounts fa ON fa.id = fc.fee_account_id
                         LEFT JOIN `finance_transactions` 
                                ON (`finance_transactions`.`finance_id` = hf.`id` AND
                                    `finance_transactions`.`finance_type` = 'HostelFee')
 #{hostel_fee_conditions} GROUP BY hf.id )"
    else
      hostel_fees_sql = ''
    end

    if (FedenaPlugin.can_access_plugin?("fedena_transport") and search_transport_fees)
      #                                                                tf.receiver_type='Student' and tf.balance > 0 and 
      transport_fee_conditions = exclude_fees_with_ids["transport_fee"].present? ?
          " WHERE tf.id not in (#{exclude_fees_with_ids["transport_fee"].join(',')}) " : ""
      transport_fee_conditions += transport_fee_conditions.present? ? " AND " : " WHERE "
      # transport_fee_conditions += "(tc.fee_account_id IS NULL OR
      #                               (tc.fee_account_id IS NOT NULL AND fa.is_deleted = false))"
      transport_fee_conditions += "#{active_account_conditions(true, 'tc')}"
      transport_fees_sql="UNION ALL 
                          (SELECT tc.name as collection_name, tc.due_date As collection_due_date,
                                  #{transport_transaction_category_id} as transaction_category_id,
                                  tf.is_paid as is_paid, tf.balance balance, tf.balance_fine as balance_fine,
                                  tf.is_fine_waiver as is_fine_waiver,
                                  tf.id as id, 'TransportFee' as fee_type,
                                  (tf.bus_fare - 
                                   IFNULL((SELECT SUM(IF(is_amount, discount,(discount * tf.bus_fare * 0.01))) AS discount 
                                             FROM transport_fee_discounts 
                                            WHERE transport_fee_discounts.transport_fee_id = tf.id 
                                         GROUP BY transport_fee_discounts.transport_fee_id),0)) 
                                  as actual_amount,
                                  (SELECT IFNULL(SUM(finance_transactions.auto_fine),0)
                                     FROM finance_transactions
                                    WHERE finance_transactions.finance_id=tf.id AND 
                                          finance_transactions.finance_type='TransportFee' AND 
                                          description= 'fine_amount_included') as paid_fine,
                                  (SELECT IFNULL(SUM(IF(f_t.description = 'fine_amount_included',
                                                                       IF(f_t.auto_fine = 0, 0, f_t.fine_amount - f_t.auto_fine), 
                                                                           f_t.fine_amount)
                                                                          ),0)
                                      FROM finance_transactions f_t
                                    WHERE f_t.finance_id=tf.id AND 
                                                f_t.finance_type='TransportFee' AND 
                                                f_t.fine_included = true
                                  ) AS manual_paid_fine,
                                  fine_rules.fine_amount AS fine_amount,
                                  IF(tf.tax_enabled,tf.tax_amount,'-') AS tax_amount, 
                                  tf.tax_enabled, 
                                  fine_rules.is_amount
                             FROM `transport_fees` tf
                       INNER JOIN `transport_fee_collections` tc 
                               ON `tc`.id = `tf`.transport_fee_collection_id and 
                                   tc.is_deleted=0 and 
                                   tf.receiver_id='#{@student.id}' and 
                                   tf.groupable_type='Batch' and 
                                   tf.groupable_id=#{@current_batch.id} and 
                                   tf.receiver_type='Student' and is_active is true
                        LEFT JOIN fee_accounts fa ON fa.id = tc.fee_account_id
                        LEFT JOIN `finance_transactions` ON (`finance_transactions`.`finance_id` = tf.`id`)
                  LEFT OUTER JOIN `fines` ON `fines`.id = tc.fine_id AND fines.is_deleted is false
                  LEFT OUTER JOIN `fine_rules` ON  fine_rules.fine_id = fines.id  AND 
                                   fine_rules.id= (
                                      SELECT id 
                                        FROM fine_rules ffr 
                                       WHERE ffr.fine_id=fines.id AND 
                                             ffr.created_at <= tc.created_at AND 
                                             ffr.fine_days <= DATEDIFF(
                                                COALESCE(Date('#{@transaction_date}'),CURDATE()),
                                                tc.due_date) 
                                    ORDER BY ffr.fine_days DESC LIMIT 1) 
       #{transport_fee_conditions}
                                    GROUP BY tf.id
                                 )"
    else
      transport_fees_sql=''
    end
    #        finance_fees.is_paid=false and
    @finance_fees=FinanceFee.find_by_sql(<<-SQL

#{master_fees_sql} WHERE
      ( 
      finance_fees.student_id=#{@student.id} and
        finance_fees.batch_id=#{@current_batch.id} and
        finance_fee_collections.is_deleted=0 and
        (
          (
            finance_fee_particulars.receiver_type='Batch' and
            finance_fee_particulars.receiver_id=finance_fees.batch_id
          ) or
          (
            finance_fee_particulars.receiver_type='Student' and
            finance_fee_particulars.receiver_id=finance_fees.student_id
          ) or
          (
            finance_fee_particulars.receiver_type='StudentCategory' and
            finance_fee_particulars.receiver_id=finance_fees.student_category_id
          )
        ) #{finance_fee_conditions}
      ) GROUP BY finance_fees.id  #{transport_fees_sql}  #{hostel_fees_sql} ORDER BY fee_type, id
    SQL
    )

    @disabled_fee_ids = FinanceFee.find_all_by_id(@finance_fees.map(&:id),
                                                  :joins => "INNER JOIN finance_fee_collections ffc
                                  ON ffc.id = finance_fees.fee_collection_id AND 
                                        ffc.discount_mode <> 'OLD_DISCOUNT'
                      INNER JOIN finance_transactions fts 
                                  ON fts.trans_type = 'particular_wise' AND 
                                        fts.finance_type = 'FinanceFee' AND 
                                        fts.finance_id = finance_fees.id").map(&:id)
    # @unlinked_disabled = FinanceFee.all(
    #     :select => "SUM(IF(ffp.master_fee_particular_id IS NULL,1,0)) as unlinked_particulars,
    #                 SUM(IF(ffp.master_fee_particular_id IS NOT NULL,1,0)) as linked_particulars,
    #                 SUM(IF(fd.master_fee_discount_id IS NULL,1,0)) as unlinked_discounts,
    #                 SUM(IF(fd.master_fee_discount_id IS NOT NULL,1,0)) as linked_discounts,
    #                 finance_fees.id ff_id",
    #     :conditions => ["finance_fees.student_id = ? and finance_fees.batch_id = ?", @student.id, @current_batch.id],
    #     :joins => "INNER JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id
    #                 LEFT JOIN collection_particulars cp ON cp.finance_fee_collection_id = ffc.id
    #                 LEFT JOIN collection_discounts cd ON cd.finance_fee_collection_id = ffc.id
    #                 LEFT JOIN finance_fee_particulars ffp ON ffp.id = cp.finance_fee_particular_id
    #                 LEFT JOIN fee_discounts fd ON fd.id = cd.fee_discount_id",
    #     :group => "finance_fees.id"
    # )

    if filter_paid_fees
      @finance_fees = @finance_fees.reject do |finance_fee|
        (finance_fee.is_paid? ? 0 :
            (finance_fee.is_amount? ? finance_fee.fine_amount :
                (finance_fee.actual_amount.to_f)*(finance_fee.fine_amount.to_f/100))).to_f -
            (finance_fee.paid_fine.to_f) < 0.0
      end
      #To remove paid fee from finance fee list
      @finance_fees = @finance_fees.reject do |finance_fee|
        (finance_fee.is_paid? or (finance_fee.balance.to_f + (finance_fee.is_paid? ? 0 :
            (finance_fee.is_amount? ? finance_fee.fine_amount :
                (finance_fee.actual_amount.to_f)*(finance_fee.fine_amount.to_f/100))).to_f -
            (finance_fee.paid_fine.to_f) == 0.0))
      end
    end
  end

  # render pay all fee page
  def pay_all_fees
    pay_all_data
    #    @student ||=Student.find(params[:id])
    #    @transaction_date=params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : 
    #      Date.today_with_timezone.to_date
    #    @current_batch= params[:batch_id].present? ? Batch.find(params[:batch_id]) : @student.batch
    #    @all_batches= (@student.previous_batches+[@student.batch]).uniq
    #    fetch_all_fees
    #    #    @finance_fees = @finance_fees.reject do |finance_fee| 
    #    #      (finance_fee.is_paid? ? 0 : 
    #    #          (finance_fee.is_amount? ? finance_fee.fine_amount : 
    #    #            (finance_fee.actual_amount.to_f)*(finance_fee.fine_amount.to_f/100))).to_f - 
    #    #        (finance_fee.paid_fine.to_f) < 0.0
    #    #    end
    #    #To remove paid fee from finance fee list
    #    #    @finance_fees = @finance_fees.reject  do |finance_fee|
    #    #      ( finance_fee.is_paid? or (finance_fee.balance.to_f + (finance_fee.is_paid? ? 0 : 
    #    #              (finance_fee.is_amount? ? finance_fee.fine_amount : 
    #    #                (finance_fee.actual_amount.to_f)*(finance_fee.fine_amount.to_f/100))).to_f - 
    #    #            (finance_fee.paid_fine.to_f) == 0.0))
    #    #    end
    #    @is_tax_present = @finance_fees.map(&:tax_enabled).include?(true)
    #    @multi_fee_discounts = MultiFeeDiscount.all(:conditions => {:receiver_id => @student.id, 
    #        :receiver_type => "Student"}, :include => :fee)
    financial_year_check
    particular_paid = false
    if @financial_year_enabled
      if request.post?
        params[:transactions].each do |k, v|
          particular_paid = true if @disabled_fee_ids.include?(v[:finance_id].try(:to_i)) and
              v[:finance_type] == 'FinanceFee'
          break if particular_paid
        end
        params[:transactions].values.each{|t| t.delete("amountt")}
        FinanceTransactionLedger.transaction do
          if !particular_paid
            status=true
            # puts params[:multi_fees_transaction].class.name
            if params[:wallet_amount_applied]
              params[:multi_fees_transaction][:amount] = params[:multi_fees_transaction][:amount].to_f + params[:wallet_amount].to_f 
            end
            ledger_info = params[:multi_fees_transaction].
                #              except(:cheque_date, :bank_name).
                merge({:transaction_type => 'MULTIPLE', :category_is_income => true,
                       :current_batch => @current_batch,:is_waiver => false})
            transaction_ledger = FinanceTransactionLedger.safely_create(ledger_info, params[:transactions])
            status = transaction_ledger.present?

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
                    :batch_id => @current_batch.id
      end
    else
      flash.now[:notice] = t('financial_year_payment_disabled')
    end
    get_paid_fees(@student.id, @current_batch.id)
  end

  # transaction history
  def paginate_paid_fees
    @student=Student.find params[:id]
    @current_batch= params[:batch_id].present? ? Batch.find(params[:batch_id]) :
        @student.batch
    get_paid_fees(@student.id, @current_batch.id)
    render :update do |page|
      page.replace_html "pay_fees1", :partial => 'recently_paid_fees'
    end
  end

  # delete transaction ledger from pay all page
  def delete_multi_fees_transaction
    @student=Student.find(params[:id])
    @current_batch= params[:batch_id].present? ? Batch.find(params[:batch_id]) :
        @student.batch
    @transaction_category_id=FinanceTransactionCategory.find_by_name("Fee").id
    @transaction_date=Date.today_with_timezone
    financial_year_check
    if request.post?
      if params[:type]=='multi_fees_transaction'
        ftl=FinanceTransactionLedger.find(params[:transaction_id], :include => :finance_transactions)
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
      @multi_fee_discounts = MultiFeeDiscount.all(:conditions => ["multi_fee_discounts.receiver_id = ? AND
        multi_fee_discounts.receiver_type = 'Student'", @student.id], :include => :fee,
        :joins => "INNER JOIN fee_discounts fd
                           ON fd.multi_fee_discount_id = multi_fee_discounts.id AND fd.batch_id = #{@current_batch.id}",
        :group => "multi_fee_discounts.id")

      render :update do |page|
        page.replace_html "flash-message", :text => "<p class='flash-msg'>#{flash[:notice]}</p>"
        page.replace_html "pay_fees", :partial => "finance_extensions/pay_all_form/pay_fees_form"
      end
    else
      flash[:notice] = "#{t('flash_msg6')}"
      redirect_to :controller => 'user', :action => 'dashboard' and return
    end
  end

  # get print summary for pay all page for respective student
  def pay_all_fees_receipt_pdf
    #    @student=Student.find(params[:id])
    #    @current_batch= Batch.find(params[:batch_id])
    #    fetch_all_fees
    pay_all_data
    fee_types = "'FinanceFee'"
    #    fee_types = ["FinanceFee"]#, "HostelFee", "TransportFee"]    
    fee_types += ", 'HostelFee'" if FedenaPlugin.can_access_plugin?("fedena_hostel")
    fee_types += ", 'TransportFee'" if FedenaPlugin.can_access_plugin?("fedena_transport")
    @is_tax_present = @finance_fees.map(&:tax_enabled).include?(true)
    @tax_config = Configuration.get_multiple_configs_as_hash(['FinanceTaxIdentificationLabel',
                                                              'FinanceTaxIdentificationNumber']) if @is_tax_present
    @paid_fees = @student.finance_transaction_ledgers.active_transactions.all(
        :select => "DISTINCT finance_transaction_ledgers.*",
        :joins => "INNER JOIN finance_transactions ON finance_transactions.transaction_ledger_id = finance_transaction_ledgers.id
                    LEFT JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id
                    LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
        # :conditions => "finance_transactions.finance_type in (#{fee_types}) AND
        #                 (ftrr.id is NOT NULL AND (ftrr.fee_account_id IS NULL OR
        #                                           (ftrr.fee_account_id IS NULL AND fa.is_deleted = false)))",
        :conditions => "finance_transactions.finance_type in (#{fee_types}) AND #{active_account_conditions(true, 'ftrr')}",

        :include => {:finance_transactions => [:transaction_receipt, {:finance_transaction_receipt_record => :fee_account}]})
    @transactions = Hash.new
    @paid_fees.each do |ledger|
      @transactions[ledger.id] = ledger.finance_transactions.select do |x|
        ftrr = x.finance_transaction_receipt_record
        fee_types.include?(x.finance_type) and (ftrr.fee_account == nil or (ftrr.fee_account.present? and !ftrr.fee_account.is_deleted))
      end
    end
    #    @paid_fees=@student.multi_fees_transactions
    #    @other_transactions=FinanceTransaction.find(:all, :select => "distinct finance_transactions.*", 
    #      :joins => "LEFT OUTER JOIN `multi_fees_transactions_finance_transactions` ON `multi_fees_transactions_finance_transactions`.finance_transaction_id = `finance_transactions`.id 
    #                      LEFT OUTER JOIN `multi_fees_transactions` ON `multi_fees_transactions`.id = `multi_fees_transactions_finance_transactions`.multi_fees_transaction_id", 
    #      :conditions => "payee_id='#{@student.id}' and multi_fees_transactions.id is NULL and finance_type in (#{fees})")
    @multi_transaction_fines = MultiTransactionFine.all(:select => "multi_transaction_fines.*, 
       ft.finance_id AS finance_id, ft.finance_type AS finance_type",
                                                        :conditions => "receiver_type = 'Student' AND receiver_id = #{@student.id} AND
                              ft.batch_id = #{@current_batch.id}",
                                                        :joins => "INNER JOIN finance_transaction_fines ftf
                         ON ftf.multi_transaction_fine_id = multi_transaction_fines.id 
                 INNER JOIN finance_transactions ft 
                         ON ft.id = ftf.finance_transaction_id") unless current_user.student?
    render :pdf => 'pay_all_fees_receipt_pdf',
           :margin => {:left => 15, :right => 15},
           :show_as_html => params.key?(:debug)
  end

  # render manage (finance) fee collection page
  def discount_particular_allocation
    @batches = Batch.active
    @dates = []
  end

  # fetch and renders particulars as per various types for selected collection
  # [in manage (finance) fee collection page]
  def particulars_with_tabs
    if params[:collection_id].present?
      @fee_collection = @finance_fee_collection = FinanceFeeCollection.find(params[:collection_id])

      # @linking_required = FinanceFeeParticular.has_unlinked_particulars?(@finance_fee_collection.fee_category_id)

      # unless @linking_required
        finance_fee_category = @finance_fee_collection.fee_category
        paid_fees = FinanceFee.find(:all, :joins => :finance_transactions,
                                    :conditions => ["fee_collection_id='#{@finance_fee_collection.id}' AND
                                 finance_fees.batch_id= ?", params[:batch_id]])

        paid_student_ids = (paid_fees.collect(&:student_id)<<0).compact.uniq
        paid_student_category_ids = (paid_fees.collect(&:student_category_id)<<0).compact.uniq

        if @finance_fee_collection.tax_enabled?
          particular_joins = " LEFT JOIN collectible_tax_slabs cts
                                               ON cts.collectible_entity_id = finance_fee_particulars.id AND
                                                     cts.collectible_entity_type = 'FinanceFeeParticular' AND
                                                     cts.collection_id = #{@finance_fee_collection.id} AND
                                                     cts.collection_type = 'FinanceFeeCollection'
                                     LEFT JOIN tax_slabs ts ON ts.id = cts.tax_slab_id"
          particular_include_associations = [:tax_slabs, :particular_wise_discounts]
          particular_tax_select = ",IFNULL(ts.name,'-') as slab_name"
        else
          particular_joins = ""
          particular_include_associations = [:particular_wise_discounts]
          particular_tax_select = ""
        end
        @particulars = FinanceFeeParticular.find(:all,
                                                 :select => "DISTINCT finance_fee_particulars.*,
                           IF(batches.id is null,
                               IF(student_categories.id is NULL,
                                   concat(students.first_name,\" (\",
                                               students.admission_no,\" )\"),
                                               student_categories.name
                                ),''
                            ) as receiver_name,
                            IF(#{paid_fees.present? and params[:type]=='Batch'},
                               true,
                               IF(#{paid_fees.present? and params[:type]=='Student'} and 
                                   finance_fee_particulars.receiver_id in (#{paid_student_ids.join(',')}),
                                   true,
                                   IF(#{paid_fees.present? and params[:type]=='StudentCategory'} and 
                                       finance_fee_particulars.receiver_id in (#{paid_student_category_ids.join(',')}),
                                       true,false
                                    )
                                )
                            ) as disabled#{particular_tax_select}",
                                                 :include => particular_include_associations,
                                                 :joins => "LEFT JOIN batches
                                  ON batches.id=finance_fee_particulars.receiver_id AND 
                                        finance_fee_particulars.receiver_type='Batch' 
                       LEFT JOIN students 
                                 ON students.id=finance_fee_particulars.receiver_id AND 
                                       finance_fee_particulars.receiver_type='Student' 
                       LEFT JOIN student_categories 
                                 ON student_categories.id=finance_fee_particulars.receiver_id AND 
                                       finance_fee_particulars.receiver_type='StudentCategory'
                                       #{particular_joins}",
                                                 :conditions => "finance_fee_particulars.is_instant=false and
                        finance_fee_particulars.batch_id='#{params[:batch_id]}' and 
                        finance_fee_category_id='#{finance_fee_category.id}' and 
                        finance_fee_particulars.receiver_type='#{params[:type]}'")
        # check if pay all discount is added on certain collection fee
        @multi_discounts = MultiFeeDiscount.all(:conditions => "fd.batch_id = #{params[:batch_id]}",
                                                :select => "sc.id AS student_category_id, fd.id, fd.name, fd.batch_id, fd.master_receiver_type, fd.master_receiver_id,
                  multi_fee_discounts.id, fd.receiver_type, fd.receiver_id",
                                                :joins => "INNER JOIN fee_discounts fd ON fd.multi_fee_discount_id = multi_fee_discounts.id
                 INNER JOIN collection_discounts cd
                         ON cd.finance_fee_collection_id = #{@finance_fee_collection.id} AND cd.fee_discount_id = fd.id
                  LEFT JOIN students s ON s.id = fd.master_receiver_id AND fd.master_receiver_type = 'Student'
                  LEFT JOIN student_categories sc ON sc.id = s.student_category_id")

        multi_discount_on_particular_ids = @multi_discounts.map { |x| x.master_receiver_id.to_i if x.master_receiver_type == 'FinanceFeeParticular' }.compact.uniq
        multi_discount_student_category_ids = @multi_discounts.map { |x| x.student_category_id.to_i }.compact.uniq

        multi_discount_student_ids = @multi_discounts.map { |x| x.master_receiver_id.to_i if x.master_receiver_type == 'Student' }.compact.uniq
        @discounted_particular_ids = @particulars.map do |particular|
          if multi_discount_on_particular_ids.include?(particular.id)
            particular.id
          elsif (particular.receiver_type == 'StudentCategory' and multi_discount_student_category_ids.include?(particular.receiver_id))
            particular.id
          elsif (particular.receiver_type == 'Student' and multi_discount_student_ids.include?(particular.receiver_id))
            particular.id
          elsif (particular.receiver_type == 'Batch' and multi_discount_student_ids.present?)
            particular.id
          end
        end.compact

        @collection_particular_ids = @finance_fee_collection.collection_particulars.
            collect(&:finance_fee_particular_id)
        @partial = 'particulars'
        @particular_details = FinanceFeeParticular.find(:all,
                                                        :select => "count(distinct finance_fee_particulars.id) as total,
                          count(IF(finance_fee_particulars.receiver_type='Student',1,NULL)) as student_wise,
                          count(IF(finance_fee_particulars.receiver_type='StudentCategory',1,NULL)) as category_wise,
                          count(IF(finance_fee_particulars.receiver_type='Batch',1,NULL)) as batch_wise",
                                                        :joins => :collection_particulars,
                                                        :conditions => "finance_fee_particulars.is_instant=false and
                                collection_particulars.finance_fee_collection_id='#{@finance_fee_collection.id}' and 
                                finance_fee_particulars.batch_id='#{params[:batch_id]}'").first
        render :update do |page|
          page.hide "loader_collection"
          page.replace_html "receivers", :partial => 'batches_and_fee_collections'
          page.replace_html "particular-wise-discount", :text => ""
          page.replace_html "financial_year_details", :partial => 'finance/financial_year_info'
        end
      # else
      #   render :update do |page|
      #     page.hide "loader_collection"
      #     page.replace_html "receivers", :partial => 'finance/fees_payment/notice_link_particulars'
      #     page.replace_html "particular-wise-discount", :text => ""
      #     page.replace_html "financial_year_details", :partial => 'finance/financial_year_info'
      #   end
      # end
    else
      render :update do |page|
        page.hide "loader_collection"
        page.replace_html "receivers", :text => ''
        page.replace_html "particular-wise-discount", :text => ""
        page.replace_html "financial_year_details", :partial => 'finance/financial_year_info'
      end
    end
  end

  # fetch and renders various discounts on choosing discount radio or discount tab
  # [in manage (finance) fee collection page]
  def show_discounts
    @finance_fee_collection = FinanceFeeCollection.find_by_id(params[:collection_id])
    if @finance_fee_collection.present?
      finance_fee_category = @finance_fee_collection.fee_category
      paid_fees=FinanceFee.find(:all, :joins => :finance_transactions,
                                :conditions => ["fee_collection_id='#{@finance_fee_collection.id}' AND
                       finance_fees.batch_id= ?", params[:batch_id]])

      paid_student_ids = (paid_fees.collect(&:student_id)<<0).compact
      paid_student_category_ids = (paid_fees.collect(&:student_category_id)<<0).compact
      @discounts = FeeDiscount.find(:all,
                                    :select => "fee_discounts.*,
                  IF(batches.id is null,
                     IF(student_categories.id is NULL,
                        IF(finance_fee_particulars.id is NULL,
                           IF(students.id is NULL,
                              concat(archived_students.first_name,\" (\",archived_students.admission_no,
                              \" )\"),
                              concat(students.first_name,\" (\",students.admission_no,\" )\")
                              ),
                              finance_fee_particulars.name
                           ),student_categories.name),'') as receiver_name,
                        if(#{paid_fees.present? } and fee_discounts.receiver_type='Batch',
                           true,
                           if(#{paid_fees.present? } and fee_discounts.receiver_type='Student' and 
                              fee_discounts.receiver_id in (#{paid_student_ids.join(',')}),
                              true,
                              if(#{paid_fees.present?} and fee_discounts.receiver_type='StudentCategory' and 
                                 fee_discounts.receiver_id in (#{paid_student_category_ids.join(',')}),
                               true,false))) as disabled",
                                    :joins => "LEFT JOIN batches
                        ON batches.id=fee_discounts.master_receiver_id and 
                           fee_discounts.master_receiver_type='Batch' 
                 LEFT JOIN archived_students 
                        ON archived_students.former_id=fee_discounts.master_receiver_id and 
                           fee_discounts.master_receiver_type='Student' 
                 LEFT JOIN students 
                        ON students.id=fee_discounts.master_receiver_id and 
                           fee_discounts.master_receiver_type='Student' 
                 LEFT JOIN student_categories 
                        ON student_categories.id=fee_discounts.master_receiver_id and 
                           fee_discounts.master_receiver_type='StudentCategory' 
                 LEFT JOIN finance_fee_particulars 
                        ON finance_fee_particulars.id=fee_discounts.master_receiver_id and 
                           fee_discounts.master_receiver_type='FinanceFeeParticular'",
                                    :conditions => "fee_discounts.is_instant=false and fee_discounts.batch_id='#{params[:batch_id]}' and
                      fee_discounts.finance_fee_category_id='#{finance_fee_category.id}' and 
                      fee_discounts.master_receiver_type='#{params[:type]}'")

      @collection_discount_ids = @finance_fee_collection.collection_discounts.collect(&:fee_discount_id)
      @discount_details = FeeDiscount.find(:all, :joins => :collection_discounts,
                                           :select => "count(distinct fee_discounts.id) as total,
                  count(IF(fee_discounts.master_receiver_type='Student',1,NULL)) as student_wise,
                  count(IF(fee_discounts.master_receiver_type='StudentCategory',1,NULL)) as category_wise,
                  count(IF(fee_discounts.master_receiver_type='Batch',1,NULL)) as batch_wise,
                  count(IF(fee_discounts.master_receiver_type='FinanceFeeParticular',1,NULL)) as particular_wise",
                                           :conditions => "fee_discounts.is_instant=false and
                      collection_discounts.finance_fee_collection_id='#{@finance_fee_collection.id}' and 
                      fee_discounts.batch_id='#{params[:batch_id]}'").first
    end
    render :update do |page|
      page.hide "loader_collection"
      page.replace_html "flash-div", :text => @flash if @flash.present?
      page.replace_html "particular-wise-discount",
                        :text => "#{link_to_function t('particular')+'-'+t('wise'), 'select_tab(this);' }"
      page.replace_html "right-panel", :partial => 'discounts'
      page.replace_html "financial_year_details", :partial => 'finance/financial_year_info'
    end

  end

  # fetch and renders various particulars on choosing particular radio or particular tab
  # [in manage (finance) fee collection page]
  def show_particulars
    @finance_fee_collection = FinanceFeeCollection.find_by_id(params[:collection_id])

    if @finance_fee_collection.present?
      if @finance_fee_collection.tax_enabled?
        particular_joins = " LEFT JOIN collectible_tax_slabs cts
                                  ON cts.collectible_entity_id = finance_fee_particulars.id AND
                                     cts.collectible_entity_type = 'FinanceFeeParticular' AND
                                     cts.collection_id = #{@finance_fee_collection.id} AND
                                     cts.collection_type = 'FinanceFeeCollection'
                           LEFT JOIN tax_slabs ts ON ts.id = cts.tax_slab_id"
        particular_include_associations = [:tax_slabs, :particular_wise_discounts]
        particular_tax_select = ",IFNULL(ts.name,'-') as slab_name"
      else
        particular_joins = ""
        particular_include_associations = [:particular_wise_discounts]
        particular_tax_select = ""
      end
      finance_fee_category=@finance_fee_collection.fee_category
      paid_fees = FinanceFee.find(:all, :joins => :finance_transactions,
                                  :conditions => ["fee_collection_id = ? and finance_fees.batch_id = ?", @finance_fee_collection.id, params[:batch_id]])


      paid_student_ids=(paid_fees.collect(&:student_id)<<0).compact.uniq
      paid_student_category_ids=(paid_fees.collect(&:student_category_id)<<0).compact.uniq
      @particulars = FinanceFeeParticular.find(:all,
                                               :select => "DISTINCT finance_fee_particulars.*,
                         IF(batches.id is NULL,
                             IF(student_categories.id IS NULL,
                                 CONCAT(students.first_name,\" (\",students.admission_no,\" )\"),
                                               student_categories.name),'') AS receiver_name,
                         IF(#{paid_fees.present? and params[:type]=='Batch'},
                             true,IF(#{paid_fees.present? and params[:type]=='Student'} and 
                                        finance_fee_particulars.receiver_id IN (#{paid_student_ids.join(',')}),
                                        true,
                                        IF(#{paid_fees.present? and params[:type]=='StudentCategory'} and 
                                            finance_fee_particulars.receiver_id IN (#{paid_student_category_ids.join(',')}),
                                            true,false))) AS disabled#{particular_tax_select}",
                                               :include => particular_include_associations,
                                               :joins => "LEFT JOIN batches
                        ON batches.id=finance_fee_particulars.receiver_id AND 
                           finance_fee_particulars.receiver_type='Batch' 
                 LEFT JOIN students 
                        ON students.id=finance_fee_particulars.receiver_id AND 
                           finance_fee_particulars.receiver_type='Student' 
                 LEFT JOIN student_categories 
                        ON student_categories.id=finance_fee_particulars.receiver_id AND 
                           finance_fee_particulars.receiver_type='StudentCategory'
                       #{particular_joins}",
                                               :conditions => "finance_fee_particulars.is_instant=false AND
                      finance_fee_particulars.batch_id='#{params[:batch_id]}' AND 
                      finance_fee_category_id='#{finance_fee_category.id}' AND 
                      finance_fee_particulars.receiver_type='#{params[:type]}'")
      # check if pay all discount is added on certain collection fee
      @multi_discounts = MultiFeeDiscount.all(:conditions => "fd.batch_id = #{params[:batch_id]}",
                                              :select => "sc.id AS student_category_id, fd.id, fd.name, fd.batch_id, fd.master_receiver_type, fd.master_receiver_id,
                  multi_fee_discounts.id, fd.receiver_type, fd.receiver_id",
                                              :joins => "INNER JOIN fee_discounts fd ON fd.multi_fee_discount_id = multi_fee_discounts.id
                 INNER JOIN collection_discounts cd
                         ON cd.finance_fee_collection_id = #{@finance_fee_collection.id} AND cd.fee_discount_id = fd.id
                  LEFT JOIN students s ON s.id = fd.master_receiver_id AND fd.master_receiver_type = 'Student'
                  LEFT JOIN student_categories sc ON sc.id = s.student_category_id")

      multi_discount_on_particular_ids = @multi_discounts.map { |x| x.master_receiver_id.to_i if x.master_receiver_type == 'FinanceFeeParticular' }.compact.uniq
      multi_discount_student_category_ids = @multi_discounts.map { |x| x.student_category_id.to_i }.compact.uniq

      multi_discount_student_ids = @multi_discounts.map { |x| x.master_receiver_id.to_i if x.master_receiver_type == 'Student' }.compact.uniq
      @discounted_particular_ids = @particulars.map do |particular|
        if multi_discount_on_particular_ids.include?(particular.id)
          particular.id
        elsif (particular.receiver_type == 'StudentCategory' and multi_discount_student_category_ids.include?(particular.receiver_id))
          particular.id
        elsif (particular.receiver_type == 'Student' and multi_discount_student_ids.include?(particular.receiver_id))
          particular.id
        elsif (particular.receiver_type == 'Batch' and multi_discount_student_ids.present?)
          particular.id
        end
      end.compact

      # @particulars=FinanceFeeParticular.find(:all,:select=>"finance_fee_particulars.*,IF(batches.id is null,IF(student_categories.id is NULL,concat(students.first_name,\" (\",students.admission_no,\" )\"),student_categories.name),'') as receiver_name",:joins=>"LEFT JOIN batches on batches.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='Batch' LEFT JOIN students on students.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='Student' LEFT JOIN student_categories on student_categories.id=finance_fee_particulars.receiver_id and finance_fee_particulars.receiver_type='StudentCategory'",:conditions=>"finance_fee_particulars.batch_id='#{params[:batch_id]}' and finance_fee_category_id='#{finance_fee_category.id}' and finance_fee_particulars.receiver_type='#{params[:type]}'")
      # @particulars=finance_fee_category.fee_particulars.all(:conditions => {:batch_id => params[:batch_id], :receiver_type => params[:type]})
      @collection_particular_ids=@finance_fee_collection.collection_particulars.
          collect(&:finance_fee_particular_id)
      @particular_details=FinanceFeeParticular.find(:all, :joins => :collection_particulars,
                                                    :select => "count(distinct finance_fee_particulars.id) as total,
                  count(IF(finance_fee_particulars.receiver_type='Student',1,NULL)) as student_wise,
                  count(IF(finance_fee_particulars.receiver_type='StudentCategory',1,NULL)) as category_wise,
                  count(IF(finance_fee_particulars.receiver_type='Batch',1,NULL)) as batch_wise",
                                                    :conditions => "finance_fee_particulars.is_instant=false and
                      collection_particulars.finance_fee_collection_id='#{@finance_fee_collection.id}' and 
                      finance_fee_particulars.batch_id='#{params[:batch_id]}' ").first
    end

    render :update do |page|
      page.replace_html "flash-div", :text => @flash if @flash.present?
      page.replace_html "right-panel", :partial => 'particulars'
      page.replace_html "particular-wise-discount", :text => ''
      page.replace_html "financial_year_details", :partial => 'finance/financial_year_info'
    end
  end

  # fetches collections for selected batch [in manage (finance) fee collection page]
  def fee_collections_for_batch
    @batch = Batch.find_by_id(params[:batch_id])
    @dates=@batch.finance_fee_collections.current_active_financial_year.all(
        :conditions => "#{active_account_conditions}",
        :joins => "LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id") if @batch.present?
    render :update do |page|
      page.replace_html "fee_collections", :partial => 'fee_collections'
      page.replace_html "financial_year_details", :partial => 'finance/financial_year_info'
    end
  end

  # saves changes performed to discounts from a discount tab
  # [in manage (finance) fee collection page]
  def update_collection_discount
    flash_message=''
    finance_fee_collection=FinanceFeeCollection.find(params[:fees_list][:collection_id])
    finance_fee_category=finance_fee_collection.fee_category
    paid_fees=FinanceFee.find(:all, :joins => :finance_transactions,
                              :conditions => ["fee_collection_id='#{finance_fee_collection.id}' AND
                               finance_fees.batch_id = ?", params[:fees_list][:batch_id]])
    paid_student_ids= (paid_fees.collect(&:student_id)<<0).compact.uniq
    paid_student_category_ids = (paid_fees.collect(&:student_category_id)<<0).compact.uniq
    collection_discount_ids = finance_fee_collection.collection_discounts.collect(&:fee_discount_id)
    part_ids = finance_fee_collection.finance_fee_particulars.collect(&:id)
    exclude_particular_enabled_discounts = part_ids.present? ?
        " or (fee_discounts.master_receiver_type='FinanceFeeParticular' and
              fee_discounts.master_receiver_id NOT IN (#{part_ids.join(',')}))" : ""
    discounts=FeeDiscount.find(:all,
                               :select => "fee_discounts.*,
                         IF(#{paid_fees.present? } and 
                             fee_discounts.receiver_type='Batch',true,
                             IF(#{paid_fees.present? } and fee_discounts.receiver_type='Student' and 
                                 fee_discounts.receiver_id IN (#{paid_student_ids.join(',')}),true,
                                 IF(#{paid_fees.present?} and fee_discounts.receiver_type='StudentCategory' and 
                                     fee_discounts.receiver_id IN (#{paid_student_category_ids.join(',')}),true,false
                                 )
                             ) #{exclude_particular_enabled_discounts}
                         ) AS disabled",
                               :joins => "LEFT JOIN batches
                                ON batches.id=fee_discounts.master_receiver_id and 
                                      fee_discounts.master_receiver_type='Batch' 
                       LEFT JOIN students 
                                ON students.id=fee_discounts.master_receiver_id and 
                                      fee_discounts.master_receiver_type='Student' 
                       LEFT JOIN student_categories 
                                ON student_categories.id=fee_discounts.master_receiver_id and 
                                      fee_discounts.master_receiver_type='StudentCategory' 
                       LEFT JOIN finance_fee_particulars 
                                ON finance_fee_particulars.id=fee_discounts.master_receiver_id and 
                                      fee_discounts.master_receiver_type='FinanceFeeParticular'",
                               :conditions => "fee_discounts.is_instant=false and
                                fee_discounts.batch_id='#{params[:fees_list][:batch_id]}' and 
                                fee_discounts.finance_fee_category_id='#{finance_fee_category.id}' and 
                                fee_discounts.master_receiver_type='#{params[:fees_list][:type]}'")

    disabled_discounts=discounts.select { |d| d.disabled? }.collect(&:id)
    disabled_and_assigned=collection_discount_ids&disabled_discounts
    disabled_and_unassigned=disabled_discounts-collection_discount_ids


    existing_discounts=CollectionDiscount.find(:all, :select => "distinct collection_discounts.*",
                                               :joins => [:finance_fee_collection, :fee_discount],
                                               :include => :fee_discount,
                                               :conditions => "fee_discounts.is_instant=false and
                                finance_fee_collections.id='#{params[:fees_list][:collection_id]}' and 
                                fee_discounts.batch_id='#{params[:fees_list][:batch_id]}' and 
                                fee_discounts.master_receiver_type='#{params[:fees_list][:type]}'")
    existing_discounts_ids=existing_discounts.collect(&:fee_discount_id)
    new_discount_ids=[]
    new_discount_ids=params[:fees_list][:discount_ids].map { |d| d.to_i } if params[:fees_list][:discount_ids].present?
    discounts_to_be_deleted=existing_discounts_ids-new_discount_ids
    new_discount_ids -= disabled_discounts if disabled_discounts.present?
    discounts_to_be_added=new_discount_ids-existing_discounts_ids
    update_fee = false
    unless (discounts_to_be_deleted&disabled_and_assigned).present? or
        (discounts_to_be_added&disabled_and_unassigned).present?

      ActiveRecord::Base.transaction do
        begin

          all_fees = FinanceFee.all(:conditions => {:fee_collection_id => finance_fee_collection.id,
                                                    :batch_id => params[:fees_list][:batch_id]})
          all_fees_ids = all_fees.map(&:id)
          affected_discount_ids = []

          if existing_discounts.present?
            discount_to_unlink_ids = []
            existing_discounts.select { |ed| discounts_to_be_deleted.include? ed.fee_discount_id }.each do |cd|
              discount=cd.fee_discount
              cd.destroy
              discount_to_unlink_ids << discount.id
              update_fee = true
            end
            if discount_to_unlink_ids.present?
              affected_discount_ids += discount_to_unlink_ids
              ffd_delete_cond = finance_fee_collection.discount_mode == "OLD_DISCOUNT" ? "" : " and fee_discount_id in (#{discount_to_unlink_ids.join(',')})"
              if all_fees_ids.present?
                FinanceFeeDiscount.delete_all("finance_fee_id in (#{all_fees_ids.join(',')}) #{ffd_delete_cond}")
              end
            end
          end

          if discounts_to_be_added.present?
            affected_discount_ids += discounts_to_be_added
            discs_to_be_added = FeeDiscount.find_all_by_id(discounts_to_be_added)

            discs_to_be_added.each do |discount|
              CollectionDiscount.create(:finance_fee_collection_id => finance_fee_collection.id,
                                        :fee_discount_id => discount.id)
              update_fee = true
            end
          end

          if update_fee
            all_fees.each do |fee|
              FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(fee)
            end
            # trigger delayed job to update expected collection reporting data
            fd = FeeDiscount.find(affected_discount_ids, :limit => 1).try(:first)
            Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('insert', fd, {:collection => finance_fee_collection})) if fd.present?
            @flash = "<p class='flash-msg'>#{t('discounts')} #{t('update').downcase} #{t('succesful')}</p>"
          else
            @flash = "<p class='flash-msg'>#{t('discounts_not_updated')}</p>"
          end

        rescue Exception => e
          @flash = "<p class='flash-msg'>#{t('flash_msg3')}</p>"
          a={"discount" => {"collection-"+finance_fee_collection.id.to_s => e.message}}
          File.open("#{RAILS_ROOT}/log/finance.yml", "a+") { |f| f.write a.to_yaml }
          raise ActiveRecord::Rollback
        end
      end
    else
      fee_part_ids=discounts.select { |fd| fd.master_receiver_type=='FinanceFeeParticular' }.collect(&:master_receiver_id)
      msg=''
      if paid_fees.present?
        msg="<li>
                      #{t('somebody_has_paid_for_the_collection_already')}. 
                      #{t('please_revert_transactions_and_try_again')}
                  </li>"
      end

      if (fee_part_ids.map { |f| f.to_i }-part_ids.map { |f| f.to_i }).present?
        msg+="<li>#{t('please_assign_associated_particular')}</li>"
      end
      @flash = "<div class='errorExplanation'><ul>#{msg}</ul></div>"

    end
    #    render :update do |page|
    #      page.replace_html "flash-div", :text => flash_message
    #    end

    params.merge!(params[:fees_list])
    show_discounts
  end

  # selects particulars from a list of particulars for a fee record
  def this_fee_particulars(particulars, fee)
    particulars.select do |particular|
      (particular.is_instant && fee.student_id == particular.receiver_id && particular.receiver_type == "Student") or
          ((!particular.is_instant) and
              ((particular.receiver_type == "Batch" and particular.receiver_id == fee.batch_id) or
                  (particular.receiver_type == "StudentCategory" and particular.receiver_id == fee.student_category_id) or
                  (particular.receiver_type == "Student" and particular.receiver_id == fee.student_id)
              ))
    end
  end

  # selects discounts from a list of fee discounts for a fee record
  def this_fee_discounts(discounts, fee)
    discounts.select do |discount|
      (discount.is_instant && fee.student_id == discount.master_receiver_id && discount.receiver_type == "Student") or
          ((!discount.is_instant) and
              ((discount.master_receiver_type == "Batch" and discount.master_receiver_id == fee.batch_id) or
                  (discount.master_receiver_type == "StudentCategory" and discount.master_receiver_id == fee.student_category_id) or
                  (discount.master_receiver_type == "Student" and discount.master_receiver_id == fee.student_id) or
                  (discount.master_receiver_type == "FinanceFeeParticular" and (
                  (discount.receiver_type == "Batch" and fee.batch_id == discount.receiver_id) or
                      (discount.receiver_type == "Student" and fee.student_id == discount.receiver_id) or
                      (discount.receiver_type == "StudentCategory" and fee.student_category_id == discount.receiver_id)
                  ))
              ))
    end
  end

  # saves changes performed to particulars from a particulars tab
  # [in manage (finance) fee collection page]
  def update_collection_particular
    flash_message = ''
    finance_fee_collection = FinanceFeeCollection.find(params[:fees_list][:collection_id])

    finance_fee_category = finance_fee_collection.fee_category
    paid_fees=FinanceFee.find(:all, :joins => :finance_transactions, 
      :conditions => ["fee_collection_id='#{finance_fee_collection.id}' AND 
                               finance_fees.batch_id=?",params[:fees_list][:batch_id]])
    


    paid_student_ids = (paid_fees.collect(&:student_id)<<0).compact
    paid_student_category_ids = (paid_fees.collect(&:student_category_id)<<0).compact
    collection_particular_ids=finance_fee_collection.collection_particulars.collect { |x| x.finance_fee_particular_id.to_i }
    particulars = FinanceFeeParticular.find(:all,
                                            :select => "finance_fee_particulars.*,if(#{paid_fees.present? and
                                                params[:fees_list][:type]=='Batch'},true,
                         IF(#{paid_fees.present? and params[:fees_list][:type]=='Student'} and 
                             finance_fee_particulars.receiver_id IN (#{paid_student_ids.join(',')}),
                             true,
                             IF(#{paid_fees.present? and params[:fees_list][:type]=='StudentCategory'} and 
                                 finance_fee_particulars.receiver_id IN (#{paid_student_category_ids.join(',')}),
                                 true,false))) as disabled",
                                            :joins => "LEFT JOIN batches
                        ON batches.id=finance_fee_particulars.receiver_id and 
                           finance_fee_particulars.receiver_type='Batch' 
                 LEFT JOIN students 
                        ON students.id=finance_fee_particulars.receiver_id and 
                           finance_fee_particulars.receiver_type='Student' 
                 LEFT JOIN student_categories 
                        ON student_categories.id=finance_fee_particulars.receiver_id and 
                           finance_fee_particulars.receiver_type='StudentCategory'",
                                            :conditions => "finance_fee_particulars.is_instant=false and
                      finance_fee_particulars.batch_id='#{params[:fees_list][:batch_id]}' and 
                      finance_fee_category_id='#{finance_fee_category.id}' and 
                      finance_fee_particulars.receiver_type='#{params[:fees_list][:type]}'")
    disabled_particulars = particulars.select { |d| d.disabled? }.collect { |x| x.id.to_i }
    disabled_and_assigned = collection_particular_ids & disabled_particulars
    disabled_and_unassigned = disabled_particulars - collection_particular_ids
    # check if pay all discount is added on certain collection fee
    @multi_discounts = MultiFeeDiscount.all(:conditions => "fd.batch_id = #{params[:fees_list][:batch_id]}",
                                            :select => "sc.id AS student_category_id, fd.id, fd.name, fd.batch_id, fd.master_receiver_type, fd.master_receiver_id,
                  multi_fee_discounts.id, fd.receiver_type, fd.receiver_id",
                                            :joins => "INNER JOIN fee_discounts fd ON fd.multi_fee_discount_id = multi_fee_discounts.id
                 INNER JOIN collection_discounts cd
                         ON cd.finance_fee_collection_id = #{finance_fee_collection.id} AND cd.fee_discount_id = fd.id
                  LEFT JOIN students s ON s.id = fd.master_receiver_id AND fd.master_receiver_type = 'Student'
                  LEFT JOIN student_categories sc ON sc.id = s.student_category_id")

    multi_discount_on_particular_ids = @multi_discounts.map {|x| x.master_receiver_id.to_i if x.master_receiver_type == 'FinanceFeeParticular'}.compact.uniq
    multi_discount_student_category_ids = @multi_discounts.map {|x| x.student_category_id.to_i }.compact.uniq

    multi_discount_student_ids = @multi_discounts.map {|x| x.master_receiver_id.to_i if x.master_receiver_type == 'Student' }.compact.uniq
    @discounted_particular_ids = particulars.map do |particular|
      if multi_discount_on_particular_ids.include?(particular.id)
        particular.id
      elsif(particular.receiver_type == 'StudentCategory' and multi_discount_student_category_ids.include?(particular.receiver_id))
        particular.id
      elsif(particular.receiver_type == 'Student' and multi_discount_student_ids.include?(particular.receiver_id))
        particular.id
      elsif(particular.receiver_type == 'Batch' and multi_discount_student_ids.present?)
        particular.id
      end
    end.compact
    collection_discount_disabled = !(particulars.map(&:id) - @discounted_particular_ids.map(&:to_i)).present?

    existing_particulars = CollectionParticular.find(:all, :select => "distinct collection_particulars.*", 
      :joins => [:finance_fee_collection, :finance_fee_particular], 
      :include => :finance_fee_particular, 
      :conditions => "finance_fee_particulars.is_instant=false and 
                      finance_fee_collections.id='#{params[:fees_list][:collection_id]}' and 
                      finance_fee_particulars.batch_id='#{params[:fees_list][:batch_id]}' and 
                      finance_fee_particulars.receiver_type='#{params[:fees_list][:type]}'")
    existing_particulars_ids=existing_particulars.collect { |x| x.finance_fee_particular_id.to_i }
    new_particular_ids = []
    new_particular_ids = params[:fees_list][:particular_ids].map { |d| d.to_i } if params[:fees_list][:particular_ids].present?
    particulars_to_be_deleted = existing_particulars_ids-new_particular_ids
    new_particular_ids -= disabled_particulars if disabled_particulars.present?
    particulars_to_be_added = new_particular_ids-existing_particulars_ids
    # exclude particulars if discounted directly or via collection
    particulars_to_be_deleted = [] if collection_discount_disabled
    particulars_to_be_deleted -= @discounted_particular_ids if @discounted_particular_ids.present?

    unless (particulars_to_be_deleted & disabled_and_assigned).present? or 
        (particulars_to_be_added & disabled_and_unassigned).present?

      ActiveRecord::Base.transaction do
        begin

          all_fees = FinanceFee.all(:conditions => {:fee_collection_id => finance_fee_collection.id,
                                                    :batch_id => params[:fees_list][:batch_id]})
          all_fees_ids = all_fees.map(&:id)
          if particulars_to_be_deleted.present?
            # unlink particulars from selected collection
            CollectionParticular.delete_all({:finance_fee_collection_id => finance_fee_collection.id,
                                             :finance_fee_particular_id => particulars_to_be_deleted})
            if all_fees_ids.present?
              # delete all particular level calculated discounts for selected collection
              FinanceFeeDiscount.delete_all("finance_fee_id in (#{all_fees_ids.join(',')}) AND 
                                                             finance_fee_particular_id in (#{particulars_to_be_deleted.join(',')})")

              # delete all particular level calculated tax (collections) for selected collection          
              TaxCollection.delete_all({:taxable_entity_id => particulars_to_be_deleted, :taxable_entity_type =>
                                           'FinanceFeeParticular', :taxable_fee_id => all_fees_ids, :taxable_fee_type => "FinanceFee"
                                       }) if finance_fee_collection.tax_enabled?
            end
            unless particulars_to_be_added.present?
              # update tax and discount wrt (instant) particular for other particulars in selected finance fee
              all_fees.each do |fee|
                FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(fee)
              end
            end
          end

          p_inc_assoc = finance_fee_collection.tax_enabled? ? [:tax_slabs] : []
          parts_to_be_added = FinanceFeeParticular.find_all_by_id(particulars_to_be_added,
                                                                  :include => p_inc_assoc)
          collection_discounts = finance_fee_collection.fee_discounts
          #          particulars_to_be_added.each do |particular_id|
          collection_discount_mode = all_fees[0].school_discount_mode if all_fees.present?
          parts_to_be_added.each do |particular|
            CollectionParticular.find_or_create_by_finance_fee_collection_id_and_finance_fee_particular_id(finance_fee_collection.id,
                                                                                                           particular.id)
            slab_id = particular.tax_slabs.try(:last).try(:id) if finance_fee_collection.tax_enabled? &&
                particular.tax_slabs.present?
            if finance_fee_collection.tax_enabled? && particular.tax_slabs.present?
              particular.collectible_tax_slabs.create({
                                                          :tax_slab_id => slab_id,
                                                          :collection_id => finance_fee_collection.id, :collection_type => 'FinanceFeeCollection'
                                                      })
            end
          end
          if all_fees.present? and (parts_to_be_added.present? or particulars_to_be_deleted.present?)
            all_fees.each_with_index do |fee, fi|
              particular_fee_discounts = []
              particular_tax_collections = []
              f_particulars = this_fee_particulars(parts_to_be_added, fee)
              f_particulars.each_with_index do |particular, i|

                # create tax records for this fee, 
                slab_id = particular.tax_slabs.try(:last).try(:id) if finance_fee_collection.tax_enabled? &&
                    particular.tax_slabs.present?
                particular_fee_discount_hsh = {:finance_fee_particular_id => particular.id}
                particular_tax_collection_hsh = {:taxable_entity_id => particular.id,
                                                 :taxable_entity_type => "FinanceFeeParticular", :taxable_fee_type => "FinanceFee",
                                                 :tax_amount => 0, :slab_id => slab_id
                } if slab_id.present?

                if collection_discount_mode == "NEW"
                  p_discounts = this_fee_discounts(collection_discounts, fee)
                  p_discounts.each do |discount|
                    fp_amt = particular.amount.to_f
                    d_amount = discount.discount.to_f
                    if discount.is_amount?
                      if discount.master_receiver_type == "FinanceFeeParticular" and
                          discount.master_receiver_id == particular.id
                        disc_amount = d_amount
                      else
                        ## TO DO :: add logic to adjust minor diff in last particular
                        disc_amount = 0
                      end
                    else
                      disc_amount = (d_amount * fp_amt * 0.01)
                    end
                    particular_fee_discounts << particular_fee_discount_hsh.dup.merge({:fee_discount_id =>
                                                                                           discount.id, :finance_fee_id => fee.id, :discount_amount => disc_amount})
                  end
                end

                particular_fee_discounts << particular_fee_discount_hsh.dup.merge!({
                                                                                       :finance_fee_id => fee.id, :discount_amount => 0
                                                                                   }) if collection_discount_mode == "OLD"

                particular_tax_collections << particular_tax_collection_hsh.dup.merge({
                                                                                          :taxable_fee_id => fee.id}) if finance_fee_collection.tax_enabled? &&
                    particular.tax_slabs.present?

                if finance_fee_collection.tax_enabled? && particular.tax_slabs.present?
                  TaxCollection.create(particular_tax_collections)
                end
                particular_tax_collections = []

              end

              FinanceFeeDiscount.create(particular_fee_discounts) if particular_fee_discounts.present?
              FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(fee)
            end
            # trigger delayed job to update expected collection reporting data
            trigger_ffp = FinanceFeeParticular.find(parts_to_be_added + particulars_to_be_deleted, :limit => 1).try(:first)
            Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('insert', trigger_ffp, {:collection => finance_fee_collection})) if trigger_ffp.present?

            @flash = flash_message="<p class='flash-msg'>
                                          #{t('particulars')} #{t('update').downcase} #{t('succesful')}
                                       </p>"
          else
            @flash = flash_message="<p class='flash-msg'>
                                          #{t('particulars_not_updated')}
                                       </p>"
          end
        rescue Exception => e
          @flash = flash_message="<p class='flash-msg'>#{t('flash_msg3')} </p>"
          a={"particular" => {"collection-"+finance_fee_collection.id.to_s => e.message}}
          File.open("#{RAILS_ROOT}/log/finance.yml", "a+") { |f| f.write a.to_yaml }
          raise ActiveRecord::Rollback
        end
      end
    else
      @flash = flash_message="<div class='errorExplanation'>
                                    <ul>
                                         <li>
                                            #{t('somebody_has_paid_for_the_collection_already')}. 
                                            #{t('please_revert_transactions_and_try_again')}
                                         </li>
                                    </ul>
                                 </div>"
    end
    params.merge!(params[:fees_list])
    show_particulars
    #    render :update do |page|
    #      page.replace_html "flash-div", :text => flash_message
    #      page.replace_html "right-panel", :partial => 'particulars'
    #    end
  end

  def add_or_remove_discount(discount, finance_fee_collection, batch_id, operation)

    receiver=discount.receiver_type.underscore+"_id"

    if discount.is_amount?
      FinanceFee.update_all(["finance_fees.is_paid=finance_fees.balance#{operation}#{discount.discount}<=0,finance_fees.balance=finance_fees.balance#{operation}#{discount.discount}"],
                            ["finance_fees.#{receiver}=#{discount.receiver_id} and finance_fees.batch_id='#{discount.batch_id}' and finance_fees.fee_collection_id='#{finance_fee_collection.id}'"])

    else
      if discount.master_receiver_type=='FinanceFeeParticular'
        particular=discount.master_receiver
        discount_amount=(particular.amount)*(discount.discount/100)
        sql="UPDATE finance_fees ff 
                       SET ff.balance=ff.balance#{operation}#{discount_amount} 
                  WHERE ff.fee_collection_id=#{finance_fee_collection.id} and 
                              ff.#{receiver}=#{discount.receiver_id} and ff.batch_id=#{discount.batch_id}"
      else
        sql="UPDATE finance_fees ff 
                       SET ff.balance=ff.balance#{operation}
                                                (SELECT SUM(finance_fee_particulars.amount)*(#{discount.discount/100}) 
                                                    FROM finance_fee_particulars 
                                            INNER JOIN collection_particulars 
                                                        ON collection_particulars.finance_fee_particular_id=finance_fee_particulars.id  
                                                  WHERE collection_particulars.finance_fee_collection_id=#{finance_fee_collection.id} AND 
                                                              finance_fee_particulars.finance_fee_category_id='#{finance_fee_collection.fee_category_id}' AND 
                                                              finance_fee_particulars.batch_id='#{batch_id}' and 
                                                              ((finance_fee_particulars.receiver_type='Student' and 
                                                                 finance_fee_particulars.receiver_id=ff.student_id) or 
                                                                (finance_fee_particulars.receiver_type='StudentCategory' and 
                                                                 finance_fee_particulars.receiver_id=ff.student_category_id) or 
                                                                (finance_fee_particulars.receiver_type='Batch' and 
                                                                 finance_fee_particulars.receiver_id=ff.batch_id)
                                                               )
                                                ) 
                  WHERE ff.fee_collection_id=#{finance_fee_collection.id} AND 
                              ff.#{receiver}=#{discount.receiver_id} AND ff.batch_id=#{discount.batch_id}"
      end

      sql1="UPDATE finance_fees ff SET ff.is_paid=(ff.balance<=0) where ff.fee_collection_id=#{finance_fee_collection.id} and ff.#{receiver}=#{discount.receiver_id} and ff.batch_id=#{discount.batch_id}"
      ActiveRecord::Base.connection.execute(sql)
      ActiveRecord::Base.connection.execute(sql1)

    end

  end

  # render form for adding new instant particular for a student (finance) fee
  def new_instant_particular
    @financefee = FinanceFee.find(params[:id])
    @target_action = params[:current_action]
    @target_controller = params[:current_controller]
    @finance_fee_category = @financefee.finance_fee_collection.fee_category
    @master_particulars = MasterFeeParticular.core
    @tax_slabs = TaxSlab.all if @financefee.tax_enabled
    @fee_particular = FinanceFeeParticular.new
    respond_to do |format|
      format.js { render :action => 'create_instant_particular' }
    end
  end

  # records a new instant particular for a student (finance) fee
  def create_instant_particular
    @status=false
    @fee_particular=FinanceFeeParticular.new(params[:finance_fee_particular])
    @financefee=FinanceFee.find(params[:id])
    FinanceFeeParticular.transaction do
      if @fee_particular.save
        #create link between collection and (instant) particular
        CollectionParticular.create(:finance_fee_particular_id => @fee_particular.id,
                                    :finance_fee_collection_id => @financefee.fee_collection_id)

        # create finance fee discount        
        @fee_particular.finance_fee_discounts.create({:finance_fee_id => @financefee.id,
                                                      :discount_amount => 0}) if @financefee.school_discount_mode == "OLD"
        #create link between collection and (instant) particular tax slab
        if @financefee.tax_enabled && @fee_particular.tax_slabs.present?
          slab_id = @fee_particular.tax_slabs.try(:last).try(:id)
          @fee_particular.collectible_tax_slabs.create({
                                                           :tax_slab_id => slab_id,
                                                           :collection_id => @financefee.fee_collection_id, :collection_type => 'FinanceFeeCollection'
                                                       })
          particular_tax_collection = @fee_particular.tax_collections.new
          particular_tax_collection.taxable_fee = @financefee
          particular_tax_collection.tax_amount = 0
          particular_tax_collection.slab_id = slab_id
          particular_tax_collection.save
        end
        #FinanceFeeParticular.add_or_remove_particular_or_discount(@fee_particular, @financefee.finance_fee_collection)
        # update tax and discount wrt (instant) particular for other particulars in selected finance fee
        FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(@financefee)
        @financefee.reload
        @target_action=params[:target_action]
        @target_controller=params[:target_controller]
        @status=true
      end
    end
    respond_to do |format|
      format.js { render :action => 'instant_particular.js.erb'
      }
      format.html
    end
  end

  # deletes an instant particular for a student (finance) fee
  def delete_student_particular
    @particular=FinanceFeeParticular.find(params[:id])
    @financefee=FinanceFee.find(params[:finance_fee_id])
    @status = false
    FinanceFeeParticular.transaction do
      @particular.destroy
      DiscountParticularLog.create(:amount => @particular.amount, :is_amount => true,
                                   :receiver_type => "FinanceFeeParticular", :finance_fee_id => @financefee.id,
                                   :user_id => current_user.id, :name => @particular.name)
      #      FinanceFeeParticular.add_or_remove_particular_or_discount(@particular, @financefee.finance_fee_collection)      
      FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(@financefee)
      @status = true
    end
    @target_action=params[:current_action]
    @target_controller=params[:current_controller]
    @financefee.reload
    respond_to do |format|
      format.js { render :action => 'instant_particular_delete.js.erb'
      }
      format.html
    end

  end

  def fee_particulars_data
    @particulars = @fee.finance_fee_particulars
    particular_payments = ParticularPayment.all(:select => "finance_fee_particular_id, sum(amount) AS total",
      :conditions => {:finance_fee_id => @fee.id, :is_active => true}, :group => "finance_fee_particular_id")
    if particular_payments.present?
      payments = Hash[particular_payments.map { |x| [x.finance_fee_particular_id, x.total] }]
      @particulars = @particulars.reject { |particular| payments[particular.id].to_f == particular.amount }
    end
  end

  def load_fee_particulars
    #    @student = Student.find(params[:student_id])
    @fee = FinanceFee.find(params[:fee_id])

    fee_particulars_data
    render(:update) do |page|
      page.replace_html "particulars_list", :partial => "discount_particulars_list"
    end
  end

  # renders form for a new instant (multi fee) discount from pay all page for a student
  def new_instant_pay_all_discount
    @student = Student.find(params[:student_id])
    @multi_fee_discount = @student.multi_fee_discounts.build
    @master_discounts = MasterFeeDiscount.core
    @transaction_date=params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : 
      Date.today_with_timezone.to_date
    @current_batch= params[:batch_id].present? ? Batch.find(params[:batch_id]) : @student.batch
    @all_batches= (@student.previous_batches+[@student.batch]).uniq
    exclude_fees = ['hostel']
    exclude_fees << 'transport' unless FedenaPlugin.can_access_plugin?("fedena_transport")
    fetch_all_fees(true, exclude_fees)
    zero_balance_fee_ids = balance_check(@finance_fees)
    if zero_balance_fee_ids.present?
      ff_new = []
      @finance_fees.each do|x|
        unless zero_balance_fee_ids.include?(x.id)
          ff_new << x
        end
      end
      @finance_fees = ff_new
    end
    @disabled_fee_ids = FinanceFee.find_all_by_id(@finance_fees.map(&:id),
#    @disabled_fee_ids = FinanceFee.find(:all,:conditions => ["finance_fees.id in (?) AND IF(finance_fees.tax_amount IS NULL,finance_fees.balance,(finance_fees.balance-finance_fees.tax_amount)) = 0",@finance_fees.map(&:id)],
                                                  :joins => "INNER JOIN finance_fee_collections ffc
                                   ON ffc.id = finance_fees.fee_collection_id AND ffc.discount_mode <> 'OLD_DISCOUNT'
                      INNER JOIN finance_transactions fts 
                                   ON fts.trans_type = 'particular_wise' AND 
                                         fts.finance_type = 'FinanceFee' AND 
                                         fts.finance_id = finance_fees.id"
                                                  ).map(&:id)
#    @disabled_fee_ids += TransportFee.find(:all,
#                                  :conditions => ["transport_fees.id in (?) AND 
#        IF(transport_fees.tax_amount IS NULL,transport_fees.balance,(transport_fees.balance-transport_fees.tax_amount)) = 0#",@finance_fees.map(&:id)]
#                                                          ).map(&:id) if FedenaPlugin.can_access_plugin?("fedena_transport")
    @grouped_fees = @finance_fees.group_by { |ff| ff.fee_type.underscore }
    @temporary_manual_fines = params[:manual_fines] if params[:manual_fines].present?
    respond_to do |format|
      format.js { render :action => 'new_instant_pay_all_discount' }
    end
  end

  # create a new instant (multi fee) discount from pay all page for a student
  # Note: 1. MultiFeeDiscount (MFD) is just used to show in pay all fee page for student
  #       2. MultiFeeDiscount can have FinanceFee / TransportFeeDiscount created under MFD as per presence or selection during creation
  #       3. MultiFeeDiscount can be for all collections present for student at that time
  #       4. MultiFeeDiscount can be for a FinanceFeeCollection / TransportFeeCollection
  #       5. MultiFeeDiscount can be for a FinanceFeeParticular
  def create_instant_pay_all_discount
    @student = Student.find(params[:student_id])
    @transaction_date=params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : 
      Date.today_with_timezone.to_date
    financial_year_check
    @current_batch= params[:batch_id].present? ? Batch.find(params[:batch_id]) : @student.batch
    @all_batches= (@student.previous_batches+[@student.batch]).uniq
    permitted_fees = ['finance']
    permitted_fees += ['transport'] if FedenaPlugin.can_access_plugin?("fedena_transport")
    exclude_fees = ['hostel']
    params[:multi_fee_discount].each_pair do |k, v|
      r = k.match /(.*)_fee_ids$/
      next unless permitted_fees.include?($1)
      instance_variable_set "@#{k}", v.map(&:to_i)
      exclude_fees -= ["#{$1}_fee"]
    end
    fetch_all_fees(true, exclude_fees)    
    @disabled_fee_ids = FinanceFee.find_all_by_id(@finance_fees.map(&:id), 
      :joins => "INNER JOIN finance_fee_collections ffc 
                         ON ffc.id = finance_fees.fee_collection_id AND ffc.discount_mode <> 'OLD_DISCOUNT'
                 INNER JOIN finance_transactions fts
                         ON fts.trans_type = 'particular_wise' AND fts.finance_type = 'FinanceFee' AND
                            fts.finance_id = finance_fees.id" ).map(&:id)
    @grouped_fees = @finance_fees.group_by {|ff| ff.fee_type.underscore }
    @status = false
    render_action = "new_instant_pay_all_discount.rjs"

    if request.post?
      @temporary_manual_fines = params[:manual_fines] if params[:manual_fines].present?
      waiver_check = params[:multi_fee_discount][:waiver_check]
      @multi_fee_discount = @student.multi_fee_discounts.build(params[:multi_fee_discount])
      if @multi_fee_discount.fee_type.present?
        @multi_fee_discount.fee_type = @multi_fee_discount.fee_type.camelize
        @multi_fee_discount.fee_id = params[:multi_fee_discount][:collections] if @multi_fee_discount.fee_type.present?
        case @multi_fee_discount.fee_type
          when "FinanceFee"
            if params[:multi_fee_discount][:particulars].present?
              if params[:multi_fee_discount][:particulars] != "Overall"
                particular = FinanceFeeParticular.find_by_id(params[:multi_fee_discount][:particulars].to_i)
                @multi_fee_discount.master_receiver = particular if particular.present?
              else
                fee = FinanceFee.find(@multi_fee_discount.fee_id) if @multi_fee_discount.fee_id
                @multi_fee_discount.master_receiver = fee if fee.present?
              end
            end
          when "TransportFee"
            @multi_fee_discount.master_receiver_type = 'Student'
            @multi_fee_discount.master_receiver_id = @student.id
        end
      else
        @multi_fee_discount.master_receiver_type = 'Student'
        @multi_fee_discount.master_receiver_id = @student.id
      end

      MultiFeeDiscount.transaction do
        if @multi_fee_discount.save          
          @status = true
          status,discount_hash,ledger_id,max_discount = @multi_fee_discount.create_fee_discounts(@student,@transaction_date)
          if status
            if waiver_check == "1"
               discount_hash
               ledger_id
               ftl = FinanceTransactionLedger.find (ledger_id) if ledger_id.present?
               ledger_hash = ftl.finance_transactions.map {|x| [x.id, x.finance_id, x.finance_type] }.group_by {|x| x[2] } if ftl.present?
               @multi_fee_discount.update_attribute(:transaction_ledger_id,ledger_id.to_i)
               linked_hash = make_transaction_discount_link(discount_hash,ledger_hash)
               link_discount_tables(linked_hash)
            end
            pay_all_data #(true)
            get_paid_fees(@student.id, @current_batch.id)
            
            flash.now[:notice] = t('discount_created_successfully')
            render :update do |page|
              page << "remove_popup_box()"
              page.replace_html "flash-message", :text => flash[:notice].present? ?
                "<p class='flash-msg'>#{flash[:notice]}</p>" : ""
              page.replace_html "pay_fees", :partial => "finance_extensions/pay_all_form/pay_fees_form"
              #            page.redirect_to(:action => "pay_all_fees", :id => @student.id, :batch_id => @current_batch.id)
            end
          else
            flash[:notice] = "maximum discount limit exceeded"
            render :update do |page|
              page << "remove_popup_box()"
              page.replace_html "flash-message", :text => flash[:notice].present? ?
                "<p class='flash-msg'>#{flash[:notice]}</p>" : ""
              page.replace_html "pay_fees", :partial => "finance_extensions/pay_all_form/pay_fees_form"
              #            page.redirect_to(:action => "pay_all_fees", :id => @student.id, :batch_id => @current_batch.id)
            end
            raise ActiveRecord::Rollback
          end
        else
          if @multi_fee_discount.fee_type.present? and @multi_fee_discount.fee_type == 'FinanceFee'
            @fee = FinanceFee.find(@multi_fee_discount.fee_id)
            fee_particulars_data
          end
          @master_discounts = MasterFeeDiscount.core
          render_action = "new_instant_pay_all_discount"
        end
      end
    end

    unless @status
      respond_to do |format|
        format.js { render :action => render_action }
      end
    end
  end

  # Delete MultiFeeDiscount for a student from pay all page
  def delete_instant_pay_all_discount
    multi_fee_discount = MultiFeeDiscount.find(params[:id])
    if request.post? and params[:student_id].present?
      multi_fee_discount.fetch_fees
      if multi_fee_discount.destroy
        flash.now[:notice] = "#{t('discount_deleted_successfully')}"
      else
        flash.now[:notice] = "custom failure message"
      end
      @student = Student.find(params[:student_id])
      pay_all_data
      get_paid_fees(@student.id, @current_batch.id)
      financial_year_check
      @temporary_manual_fines = params[:manual_fines] if params[:manual_fines].present?
      render :update do |page|
        page.replace_html "flash-message", :text => "<p class='flash-msg'>#{flash[:notice]}</p>"
        page.replace_html "pay_fees", :partial => "finance_extensions/pay_all_form/pay_fees_form"
        #        page.redirect_to(:action => "pay_all_fees", :id => params[:student_id], :batch_id => params[:batch_id])
      end
    else
      flash.now[:notice] = "#{t('flash_msg5')}"
      redirect_to :controller => 'user', :action => 'dashboard' and return
    end
  end

  # Renders form for creating a manual fine from pay all page for a student, and creates (temporary) MultiTransactionFine
  # Note: 1. this fine will be recorded in db only when a transaction happens after adding this fine
  #       2. this fine and multi fee discount can be added in parallel
  def add_pay_all_manual_fine
    render_action = 'add_pay_all_manual_fine'
    @multi_transaction_fine = MultiTransactionFine.new
    @temporary_manual_fines = Hash.new { |h, k| h[k] = Hash.new }
    @temporary_manual_fines.merge!(params[:manual_fines]) if params[:manual_fines].present?
    @student = Student.find(params[:student_id])
    @multi_fee_discount = @student.multi_fee_discounts.build
    @transaction_date=params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : 
      Date.today_with_timezone.to_date
    financial_year_check
    @current_batch= params[:batch_id].present? ? Batch.find(params[:batch_id]) : @student.batch
    @all_batches= (@student.previous_batches+[@student.batch]).uniq
    if request.post?
      @manual_fine = params[:multi_transaction_fine][:amount]
      @manual_fine_fee = case params[:fee_type]
                           when 'finance_fee'
                             @manual_fine_fee = FinanceFee.find(params[:multi_transaction_fine][:fee_id])
                           when 'transport_fee'
                             @manual_fine_fee = TransportFee.find(params[:multi_transaction_fine][:fee_id])
                           when 'hostel_fee'
                             @manual_fine_fee = HostelFee.find(params[:multi_transaction_fine][:fee_id])
                         end if params[:multi_transaction_fine][:fee_id].present?
      @multi_transaction_fine.fee_id = @manual_fine_fee.id if @manual_fine_fee.present?
      @multi_transaction_fine.fee_type = params[:fee_type]
      @multi_transaction_fine.amount = @manual_fine if @manual_fine.present? and @manual_fine.to_f > 0
      if @multi_transaction_fine.valid?
        @temporary_manual_fines[params[:fee_type].to_s][params[:multi_transaction_fine][:fee_id]] = @manual_fine
        render_action = ""
        @student = Student.find(params[:student_id])
        pay_all_data #(true)        
        get_paid_fees(@student.id, @current_batch.id)
        render :update do |page|
          page << "remove_popup_box()"
          page.replace_html "flash-message", :text => flash[:notice].present? ?
                                               "<p class='flash-msg'>#{flash[:notice]}</p>" : ""
          page.replace_html "pay_fees", :partial => "finance_extensions/pay_all_form/pay_fees_form"
        end
      else
        temp_fine_data
      end
    else
      temp_fine_data
    end
    respond_to do |format|
      format.js { render :action => render_action }
    end if render_action.present?
  end
    
  def remove_pay_all_auto_fine
    render_action = 'remove_pay_all_auto_fine'
    @student = Student.find(params[:student_id])
    @transaction_date=params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : 
      Date.today_with_timezone.to_date
    @current_batch= params[:batch_id].present? ? Batch.find(params[:batch_id]) : @student.batch
    @all_batches= (@student.previous_batches+[@student.batch]).uniq
    exclude_fees = ['hostel']
    exclude_fees << 'transport' unless FedenaPlugin.can_access_plugin?("fedena_transport")
    fetch_all_fees(true, exclude_fees)
    @disabled_fee_ids = FinanceFee.find_all_by_id(@finance_fees.map(&:id),
                                                  :joins => "INNER JOIN finance_fee_collections ffc
                                   ON ffc.id = finance_fees.fee_collection_id AND ffc.discount_mode <> 'OLD_DISCOUNT'
                      INNER JOIN finance_transactions fts 
                                   ON fts.trans_type = 'particular_wise' AND 
                                         fts.finance_type = 'FinanceFee' AND 
                                         fts.finance_id = finance_fees.id"
                                                  ).map(&:id)
    @grouped_fees = @finance_fees.group_by { |ff| ff.fee_type.underscore }
    @temporary_manual_fines = params[:manual_fines] if params[:manual_fines].present?
    unless request.post?
      respond_to do |format|
      format.js { render :action => 'remove_pay_all_auto_fine' }
      end 
    else
      @fine_fee_id = params[:fine_transaction][:fee_id] if params[:fine_transaction][:fee_id].present?          
      @fine_fee_type = params[:fine_transaction][:fee_type].camelize if params[:fine_transaction][:fee_type].present?
      @removal_fine_amt = params[:fine_transaction][:removal_fine_amt].camelize if params[:fine_transaction][:removal_fine_amt].present?
      @fin_fee_ids = params[:fine_transaction][:finance_fee_ids].map(&:to_i) if params[:fine_transaction][:finance_fee_ids].present?
      @trns_fee_ids = params[:fine_transaction][:transport_fee_ids].map(&:to_i) if params[:fine_transaction][:transport_fee_ids].present?
      render_action = ""
      if @fin_fee_ids.present? && (@fine_fee_type == "FinanceFee" || @fine_fee_type.blank?)
        @finance_fees = @fine_fee_type == "FinanceFee" ? FinanceFee.all(:conditions=>["id IN (?)",@fine_fee_id]) : FinanceFee.all(:conditions=>["id IN (?)",@fin_fee_ids]) 
        @finance_type = "FinanceFee"
        @finance_fees.each do |f|
          @financefee = f
          tax_amt = f.tax_amount if f.tax_enabled?
          @date = f.finance_fee_collection
          particular_and_discount_details
          bal = (@total_payable-@total_discount).to_f
          paid_amount = f.finance_transactions.map(&:amount).sum.to_f
          days = (@transaction_date - @date.due_date.to_date).to_i
          auto_fine=@date.fine
          fine_amount = 0.0
            if days > 0 and auto_fine
              paid_fine = f.finance_transactions.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)
              if Configuration.is_fine_settings_enabled? && f.balance <= 0 && f.is_paid == false && f.balance_fine.nil?
                fine_amount = f.balance_fine
              else
                fine_rule = auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
                fine_amount = fine_rule.is_amount ? fine_rule.fine_amount : (bal*fine_rule.fine_amount)/100 if fine_rule
                if fine_rule and f.balance==0
                  fine_amount = fine_amount - paid_fine
                end
              end
            end
          final_balance = bal + paid_fine.to_f + tax_amt.to_f - paid_amount.to_f
          if final_balance == 0.0 && fine_amount > 0.0
            f.update_attributes(:is_fine_waiver=>true, :is_paid=>true)
            f.track_fine_calculation(@finance_type, fine_amount, f.id)
          end
        end
      end
      if @trns_fee_ids.present? && (@fine_fee_type == "TransportFee" || @fine_fee_type.blank?)
        @transport_fees = @fine_fee_type == "TransportFee" ? TransportFee.all(:conditions=>["id IN (?)",@fine_fee_id]) : TransportFee.all(:conditions=>["id IN (?)",@trns_fee_ids]) 
        @finance_type = "TransportFee"
        @transport_fees.each do |t|
          @date = t.transport_fee_collection
          @total_discount = t.total_discount_amount
          @total_payable = t.bus_fare
          if t.tax_enabled? and t.tax_amount.present?
            @tax_slab = @date.collection_tax_slabs.try(:last)
            @total_tax = t.tax_amount.to_f
            @total_payable += @total_tax
          end
          bal = @total_payable - @total_discount
          days = (@transaction_date - @date.due_date.to_date).to_i
          auto_fine=@date.fine
          fine_amount = 0.0
            if days > 0 and auto_fine
              paid_fine = t.finance_transactions.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)
              if Configuration.is_fine_settings_enabled? && t.balance <= 0 && t.is_paid == false && t.balance_fine.nil?
                fine_amount = t.balance_fine
              else
                fine_rule = auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
                fine_amount = fine_rule.is_amount ? fine_rule.fine_amount : (bal*fine_rule.fine_amount)/100 if fine_rule
                if fine_rule and t.balance==0
                  fine_amount = fine_amount - paid_fine
                end
              end
            end
          final_balance = bal + paid_fine.to_f - t.finance_transactions.map(&:amount).sum.to_f
           if final_balance == 0.0 && fine_amount > 0.0
             t.update_attributes(:is_fine_waiver=>true, :is_paid=>true)
             t.track_fine_calculation(@finance_type, fine_amount, t.id)
           end
        end
      end     
      pay_all_data #(true)  
      financial_year_check
      get_paid_fees(@student.id, @current_batch.id)
      render :update do |page|
        page << "remove_popup_box()"        
        page << "remove_fine_link.hide();"
        page.replace_html "flash-message", :text => flash[:notice].present? ?
                                               "<p class='flash-msg'>#{flash[:notice]}</p>" : ""
        page.replace_html "pay_fees", :partial => "finance_extensions/pay_all_form/pay_fees_form"
      end
    end    
   end 
  
  def fetch_total_fine_amount_for_pay_all
    collections = params[:collection]
    fee_type = params[:fee_type_name]
    fee_finance_ids = params[:fee_finance_ids]
    fee_transport_ids = params[:fee_transport_ids]
    transaction_date = params[:transaction_date]
    batch_id = params[:batch_id]
    balance = FinanceFee.fetch_total_fine(collections,fee_type,fee_finance_ids,fee_transport_ids, transaction_date, batch_id)
    fine_waiver_amt = balance.to_f
    render :json => {'attributes' => fine_waiver_amt.to_f}
  end

  # remove instant pay all fine
  def delete_instant_pay_all_fine
    @student = Student.find(params[:student_id])
    pay_all_data
    get_paid_fees(@student.id, @current_batch.id)
    @temporary_manual_fines = params[:manual_fines] if params[:manual_fines].present?
    if params[:fee_type].present? and params[:fee_id].present?
      @temporary_manual_fines["#{params[:fee_type]}"].reject! { |k, v| k == params[:fee_id] }
    end
    render :update do |page|
      page.replace_html "flash-message", :text => flash[:notice].present? ?
                                           "<p class='flash-msg'>#{flash[:notice]}</p>" : ""
      page.replace_html "pay_fees", :partial => "finance_extensions/pay_all_form/pay_fees_form"
    end
  end

  # render form for adding new instant discount from a collection page
  def new_instant_discount
    @financefee=FinanceFee.find(params[:id])
    @particular_payment = params[:particular_payment] if params[:particular_payment].present?
    @target_action=params[:current_action]
    @target_controller=params[:current_controller]
    @finance_fee_category=@financefee.finance_fee_collection.fee_category
    @fee_discount = FeeDiscount.new
    @master_discounts = MasterFeeDiscount.core

    respond_to do |format|
      format.js { render :action => 'create_instant_discount' }
    end
  end

  # records new instant discount from a collection page
  def create_instant_discount
    @status=false
    @fee_discount=FeeDiscount.new(params[:fee_discount])
    @financefee=FinanceFee.find(params[:id])
    @particular_payment = params[:particular_payment] if params[:particular_payment].present?
    fee_particulars = @financefee.finance_fee_collection.finance_fee_particulars.all(:conditions => "batch_id=#{@financefee.batch_id}").select { |par| (par.receiver.present?) and (par.receiver==@financefee.student or par.receiver==@financefee.student_category or par.receiver==@financefee.batch) }
    total_payable=fee_particulars.map { |s| s.amount }.sum.to_f
    discount_amount=@fee_discount.is_amount? ? (total_payable*(@fee_discount.discount.to_f)/total_payable) : (total_payable*(@fee_discount.discount.to_f)/100)
    waiver_balance = @financefee.balance.to_f - (@financefee.tax_enabled ? @financefee.tax_amount.to_f : 0.0)
    if !(discount_amount.to_f >= @financefee.balance.to_f) and params[:fee_discount][:waiver_check] == "0"
      FinanceFeeParticular.transaction do
        if @fee_discount.save
          CollectionDiscount.create(:fee_discount_id => @fee_discount.id, :finance_fee_collection_id => @financefee.fee_collection_id)
          d_amount = @fee_discount.discount.to_f
          #          no_parts = fee_particulars.length
          fee_particulars.each do |f_p|
            fp_amt = f_p.amount.to_f
            if @school_discount_mode == "NEW_DISCOUNT"
              if @fee_discount.is_amount?
                ## TO DO :: add logic to adjust minor diff in last particular
                disc_amount = (d_amount / total_payable) * fp_amt.to_f
              else
                disc_amount = (d_amount * fp_amt * 0.01)
              end
            else
              disc_amount = 0
            end
            finance_fee_discount = FinanceFeeDiscount.find(:last,
                                                           :conditions => "finance_fee_id = #{@financefee.id} AND finance_fee_particular_id = #{f_p.id}")
            if finance_fee_discount.present?
              finance_fee_discount.discount_amount = disc_amount
              finance_fee_discount.save
            else
              @fee_discount.finance_fee_discounts.create({
                                                             :finance_fee_particular_id => f_p.id,
                                                             :finance_fee_id => @financefee.id,
                                                             :discount_amount => disc_amount
                                                         })
            end
          end
          FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(@financefee)
          @financefee.reload
          @target_action=params[:target_action]
          @target_controller=params[:target_controller]
          @status=true
        end
      end
    elsif (discount_amount.to_f == waiver_balance.to_f) and params[:fee_discount][:waiver_check] == "1"
      FinanceFeeParticular.transaction do
        if @fee_discount.save
          CollectionDiscount.create(:fee_discount_id => @fee_discount.id, :finance_fee_collection_id => @financefee.fee_collection_id)
          @fee_discount.update_fee_balances
          d_amount = @fee_discount.discount.to_f
          #          no_parts = fee_particulars.length
          fee_particulars.each do |f_p|
            fp_amt = f_p.amount.to_f
            if @school_discount_mode == "NEW_DISCOUNT"
              if @fee_discount.is_amount?
                ## TO DO :: add logic to adjust minor diff in last particular
                disc_amount = (d_amount / total_payable) * fp_amt.to_f
              else
                disc_amount = (d_amount * fp_amt * 0.01)
              end
            else
              disc_amount = 0
            end
            finance_fee_discount = FinanceFeeDiscount.find(:last,
                                                           :conditions => "finance_fee_id = #{@financefee.id} AND finance_fee_particular_id = #{f_p.id}")
            if finance_fee_discount.present?
              finance_fee_discount.discount_amount = disc_amount
              finance_fee_discount.save
            else
              @fee_discount.finance_fee_discounts.create({
                                                             :finance_fee_particular_id => f_p.id,
                                                             :finance_fee_id => @financefee.id,
                                                             :discount_amount => disc_amount
                                                         })
            end
          end  
          @financefee.reload
          transaction = FeeDiscount.create_transaction_for_waiver_discount(@financefee,@particular_payment)
          if transaction.present?
            @fee_discount.reload
            @fee_discount.finance_transaction_id = transaction.id.to_i
            @fee_discount.send(:update_without_callbacks)
            @fee_discount.reload
            flash[:warning] = "#{t('finance.flash14')}.  <a href ='#' onclick='show_print_dialog(#{transaction.id})'>#{t('print_receipt')}</a>"
          else
            flash[:notice] = "#{t('fee_payment_failed')}"
            raise ActiveRecord::Rollback
          end
          if @particular_payment.present?
            FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(@financefee)
            end
#          FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(@financefee)
          @financefee.reload
          @target_action = params[:target_action]
          @target_controller = params[:target_controller]
          @status=true
        end
      end
    else
      @fee_discount.errors.add_to_base(t('discount_cannot_be_greater_than_total_amount'))
    end

    respond_to do |format|
      format.js { render :action => 'instant_discount.js.erb'
      }
      format.html
    end
  end

  # deletes an instant discount for a student from a collection page
  def delete_student_discount
    @fee_discount=FeeDiscount.find(params[:id])
    @financefee=FinanceFee.find(params[:finance_fee_id])
    FinanceFeeParticular.transaction do
      @fee_discount.destroy
      DiscountParticularLog.create(:amount => @fee_discount.discount, :is_amount => @fee_discount.is_amount,
                                   :receiver_type => "FeeDiscount", :finance_fee_id => @financefee.id, :user_id => current_user.id,
                                   :name => @fee_discount.name)
      FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(@financefee)
    end
    @target_action=params[:current_action]
    @target_controller=params[:current_controller]
    @financefee.reload

    respond_to do |format|
      format.js { render :action => 'instant_discount_delete.js.erb'
      }
      format.html
    end
  end

  # pay all fees search page
  def pay_all_fees_index
    @batches = Batch.find(:all, :conditions => {:is_deleted => false, :is_active => true},
                          :joins => :course, :select => "`batches`.*,CONCAT(courses.code,'-',batches.name) as course_full_name",
                          :order => "course_full_name")
  end

  # search students for pay all fees page [at pay all fees search page]
  def search_students_for_pay_all_fees
    having="(count(distinct finance_fees.id)>0)"
    having+=" or (count(hostel_fees.id)>0)" if FedenaPlugin.can_access_plugin?("fedena_hostel")
    having+=" or (count(distinct transport_fees.id)>0)" if FedenaPlugin.can_access_plugin?("fedena_transport")
    if params[:query].length>= 3
      #      SUM(
      #                                           IF(ft.trans_type = 'particular_wise' AND ffc.discount_mode = 'OLD_DISCOUNT',
      #                                               ff.balance,0)) 
      @students = Student.find(:all,
        :select => "students.id AS id, students.admission_no AS admission_no, students.roll_number,
                           IF(CONCAT(students.first_name,' ',students.middle_name,' ',  students.last_name) is NULL,
                           CONCAT(students.first_name,' ',  students.last_name), CONCAT(students.first_name,' ',students.middle_name,' ',  students.last_name)) AS fullname,
                           CONCAT(courses.code,'-',batches.name) AS batch_full_name,
                           (SELECT SUM(ff.balance) FROM finance_fees ff WHERE  ff.student_id=students.id AND 
                            FIND_IN_SET(id,GROUP_CONCAT(distinct finance_fees.id))) AS fee_due,
                           IFNULL(#{transport_fee_due},0) AS transport_due, IFNULL(#{hostel_fee_due},0) AS hostel_due",
        :joins => join_sql_for_student_fees, :group => "students.id", :having => having,
        :conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR 
                                   admission_no = ? OR (concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? ) OR 
                                   (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ? ) #{Student.account_deletion_conditions}",
          "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}%", "#{params[:query]}", 
          "#{params[:query]}%", "#{params[:query]}%"],
        :order => "batches.id ASC, students.first_name ASC") unless params[:query] == ''
    else
      @students = Student.find(:all,
        :select => "students.id AS id, students.admission_no AS admission_no, students.roll_number,
                           IF(CONCAT(students.first_name,' ',students.middle_name,' ',  students.last_name) is NULL,
                           CONCAT(students.first_name,' ',  students.last_name), CONCAT(students.first_name,' ',students.middle_name,' ',  students.last_name)) AS fullname,
                           CONCAT(courses.code,'-',batches.name) AS batch_full_name,
                           (SELECT SUM(ff.balance) FROM finance_fees ff WHERE  ff.student_id=students.id AND 
                            FIND_IN_SET(id,GROUP_CONCAT(DISTINCT finance_fees.id))) AS fee_due,
                           IFNULL(#{transport_fee_due},0) AS transport_due, IFNULL(#{hostel_fee_due},0) AS hostel_due",
        :joins => join_sql_for_student_fees, :group => "students.id", :having => having, 
        :conditions => ["#{Student.account_deletion_conditions(false)} AND
                         admission_no = ? ", params[:query]],
        :order => "batches.id ASC, students.first_name ASC") unless params[:query] == ''
    end

    render :layout => false


  end

  def cond_sql_for_student_fees
    result = "((finance_fees.id IS NOT NULL AND (fa_ff.id IS NULL OR fa_ff.is_deleted = false))"
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      result += " OR (transport_fees.id IS NOT NULL AND (fa_tf.id IS NULL OR fa_tf.is_deleted = false))"
    end

    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      result += " OR (hostel_fees.id IS NOT NULL AND (fa_hf.id IS NULL OR fa_hf.is_deleted = false))"
    end
    result += ")"
  end

  def join_sql_for_student_fees(batch_id=nil)
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


    result = "INNER JOIN batches ON batches.id=students.batch_id
               INNER JOIN courses ON courses.id=batches.course_id
               LEFT JOIN finance_fees 
                      ON finance_fees.student_id=students.id #{finance_sql}
               LEFT JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id
               LEFT JOIN fee_accounts fa_ff ON fa_ff.id = ffc.fee_account_id"
    result +=" LEFT JOIN transport_fees 
                      ON transport_fees.receiver_id=students.id AND 
                         transport_fees.receiver_type='Student' AND 
                         transport_fees.is_active=1 #{transport_sql}
               LEFT JOIN transport_fee_collections tfc ON tfc.id = transport_fees.transport_fee_collection_id
               LEFT JOIN fee_accounts fa_tf ON fa_tf.id = tfc.fee_account_id" if FedenaPlugin.
        can_access_plugin?("fedena_transport")
    result +=" LEFT JOIN hostel_fees 
                      ON hostel_fees.student_id=students.id AND 
                         hostel_fees.is_active=1 #{hostel_sql}
               LEFT JOIN hostel_fee_collections hfc ON hfc.id = hostel_fees.hostel_fee_collection_id
               LEFT JOIN fee_accounts fa_hf ON fa_hf.id = hfc.fee_account_id" if FedenaPlugin.
        can_access_plugin?("fedena_hostel")
    result
  end

  # fetches and renders students for a selected batch at pay all fees search page
  def list_students_by_batch
    if params[:fees_submission][:batch_id].present?
      @batch_id=params[:fees_submission][:batch_id]
      having="(count(distinct finance_fees.id)>0)"
      having+=" or (count(hostel_fees.id)>0)" if FedenaPlugin.can_access_plugin?("fedena_hostel")
      having+=" or (count(distinct transport_fees.id)>0)" if FedenaPlugin.can_access_plugin?("fedena_transport")
      @students=Student.find(:all,
        :select => "students.id AS id, IF(CONCAT(students.first_name,' ',students.middle_name,' ',  students.last_name) is NULL,
                           CONCAT(students.first_name,' ',  students.last_name), CONCAT(students.first_name,' ',students.middle_name,' ',  students.last_name)) AS fullname,
                           CONCAT(courses.code,'-',batches.name) AS batch_full_name,
                           students.admission_no AS admission_no,
                           (SELECT SUM(ff.balance) 
                               FROM finance_fees ff
                             INNER JOIN finance_fee_collections ffc ON ffc.id = ff.fee_collection_id
                             LEFT JOIN fee_accounts fa ON fa.id = ffc.fee_account_id
                             WHERE  ff.student_id=students.id AND 
                                    FIND_IN_SET(ff.id,GROUP_CONCAT(DISTINCT finance_fees.id)) AND
                                    (ffc.fee_account_id IS NULL OR (ffc.fee_account_id IS NOT NULL AND fa.is_deleted = false))
                            ) AS fee_due,
                            #{Student.transport_fee_due(@batch_id)} AS transport_due,
                            #{Student.hostel_fee_due(@batch_id)} AS hostel_due,students.roll_number",
                             :joins => join_sql_for_student_fees(@batch_id),
                             :group => "students.id",
                             :conditions => Student.account_deletion_conditions(false),
                             :having => having,
                             :order => "batches.id asc,students.first_name asc"
      )
    else
      @students=[]
    end
    respond_to do |format|
      format.js
    end
  end

  # builds query for finding transport fee due
  def transport_fee_due batch_id=nil
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      batch_id_join = batch_id.present? ? "tf.groupable_type='Batch' AND 
                                           tf.groupable_id=#{batch_id} AND " : ""
      #      "(SELECT SUM(tf.balance) 
      "(SELECT SUM(ROUND(tf.balance,#{@precision}))
           FROM transport_fees tf
           INNER JOIN transport_fee_collections ON transport_fee_collections.id = tf.transport_fee_collection_id
           #{active_account_joins(true, 'transport_fee_collections')}
        WHERE tf.receiver_id=students.id AND tf.receiver_type='Student' AND
              #{active_account_conditions(true, 'transport_fee_collections')} AND #{batch_id_join}
              FIND_IN_SET(tf.id,GROUP_CONCAT(DISTINCT transport_fees.id))
       )"
    else
      0
    end
  end

  # builds query for finding transport fee count
  def transport_fee_count batch_id=nil
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      batch_id_join = batch_id.present? ? "tf.groupable_type='Batch' AND 
                                           tf.groupable_id=#{batch_id} AND " :
          "students.batch_id AND "
      "(SELECT COUNT(DISTINCT tf.id) 
          FROM transport_fees tf
         INNER JOIN transport_fee_collections ON transport_fee_collections.id = tf.transport_fee_collection_id
         #{active_account_joins(true, 'transport_fee_collections')}
        WHERE tf.receiver_id=students.id AND tf.receiver_type='Student' AND
              #{active_account_conditions(true, 'transport_fee_collections')} AND #{batch_id_join}
               FIND_IN_SET(tf.id,GROUP_CONCAT(DISTINCT transport_fees.id)))"
    else
      0
    end
  end

  # builds query for finding hostel fee due
  def hostel_fee_due batch_id=nil
    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      batch_id_join = batch_id.present? ? "hf.batch_id = #{batch_id} AND " : ""
      #      "(SELECT SUM(hf.balance) 
      "(SELECT SUM(ROUND(hf.balance,#{@precision}))
          FROM hostel_fees hf
         INNER JOIN hostel_fee_collections ON hostel_fee_collections.id = hf.hostel_fee_collection_id
         #{active_account_joins(true, 'hostel_fee_collections')}
         WHERE hf.student_id = students.id AND #{active_account_conditions(true, 'hostel_fee_collections')} AND
               #{batch_id_join} FIND_IN_SET(hf.id,GROUP_CONCAT(DISTINCT hostel_fees.id)))"
    else
      0
    end
  end

  # builds query for finding hostel fee count
  def hostel_fee_count batch_id = nil
    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      batch_id_join = batch_id.present? ? "hf.batch_id = #{batch_id} AND " :
          "students.batch_id AND "
      "(SELECT COUNT(DISTINCT hf.id) 
          FROM hostel_fees hf
         INNER JOIN hostel_fee_collections ON hostel_fee_collections.id = hf.hostel_fee_collection_id
         #{active_account_joins(true, 'hostel_fee_collections')}
        WHERE hf.student_id=students.id AND #{active_account_conditions(true, 'hostel_fee_collections')} AND
              #{batch_id_join} FIND_IN_SET(hf.id,GROUP_CONCAT(DISTINCT hostel_fees.id)))"
    else
      0
    end
  end

  #  def student_search_autocomplete
  #    students= Student.active.find(:all, :select => "students.*,sum(finance_fees.balance) as fee_due,sum(transport_fees.balance) as transport_due,sum(hostel_fees.balance) as hostel_due",
  #                                  :joins => join_sql_for_student_fees,
  #                                  :conditions => ["(admission_no LIKE ? OR first_name LIKE ?) and students.id<>#{params[:student_id]}", "%#{params[:query]}%", "%#{params[:query]}%"],
  #                                  :group => "students.id",
  #                                  :having => "(count(distinct transport_fees.id)>0) or (count(distinct finance_fees.id)>0) or (count(hostel_fees.id)>0)",
  #                                  :order => "batches.id asc,students.first_name asc").uniq
  #    suggestions=students.collect { |s| s.full_name.length+s.admission_no.length > 20 ? s.full_name[0..(18-s.admission_no.length)]+".. "+"(#{s.admission_no})"+" - " : s.full_name+"(#{s.admission_no})" }
  #    receivers=students.map { |st| "{'receiver': 'Student','id': #{st.id}}" }
  #    if receivers.present?
  #      render :json => {'query' => params["query"], 'suggestions' => suggestions, 'data' => receivers}
  #    else
  #      render :json => {'query' => params["query"], 'suggestions' => ["#{t('no_users')}"], 'data' => ["{'receiver': #{false}}"]}
  #    end
  #  end

  def student_search_autocomplete
    having="(count(distinct finance_fees.id)>0)"
    having+=" or (count(hostel_fees.id)>0)" if FedenaPlugin.can_access_plugin?("fedena_hostel")
    having+=" or (count(distinct transport_fees.id)>0)" if FedenaPlugin.can_access_plugin?("fedena_transport")
    students= Student.active.find(:all, :select => "students.*,sum(finance_fees.balance) as fee_due,#{transport_fee_due} as transport_due,#{hostel_fee_due} as hostel_due",
                                  :joins => join_sql_for_student_fees,
                                  :conditions => ["(admission_no LIKE ? OR first_name LIKE ?) and students.id<>#{params[:student_id]}", "%#{params[:query]}%", "%#{params[:query]}%"],
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

  # get pdf for overall fee receipt from pay all fees page
  def generate_overall_fee_receipt_pdf
    @student = Student.find(params[:student_id])
    status = true
    # begin
    ledger = FinanceTransactionLedger.find_by_id(params[:transaction_id],
                                                 :joins => "LEFT JOIN finance_transactions ft ON ft.transaction_ledger_id = finance_transaction_ledgers.id
                  INNER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                   LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id",
                                                 # :conditions => "(ftrr.fee_account_id IS NULL OR (ftrr.fee_account_id IS NOT NULL AND fa.is_deleted = false))"
                                                 :conditions => "#{active_account_conditions(true, 'ftrr')}"
    )
    #      @transactions
    #      @transactions = FinanceTransaction.find(params[:transaction_id])
    # rescue ActiveRecord::RecordNotFound
    #   status=false
    # end
    # generate data for overall receipt 
    unless ledger.present?
      respond_to do |format|
        format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
      end
    else
      #      config_keys = ['PdfReceiptSignature', 'PdfReceiptSignatureName', 
      #        'PdfReceiptCustomFooter','PdfReceiptAtow','PdfReceiptNsystem', 'PdfReceiptHalignment',
      #        'InstitutionAddress', 'InstitutionName' ]
      #      fetch_config_hash config_keys
      #      @default_currency = Configuration.default_currency
      #      @current_batch = Batch.find(params[:batch_id])
      #      overall_receipt = OverallReceipt.new(params[:student_id], params[:transaction_id])
      #      @data = overall_receipt.fetch_details
      @transaction_ledger = ledger
      @transactions_data = ledger.overall_receipt_data(params[:batch_id])
      @transactions_data.transaction_status = ledger.status
      @data = {:templates => @transactions_data.template_ids.present? ?
          FeeReceiptTemplate.find(@transactions_data.template_ids).group_by(&:id) : {}}
      render :pdf => 'generate_overall_fee_receipt_pdf',
             :template => 'finance_extensions/generate_overall_fee_receipt_pdf_new.erb',
             :margin => {:top => 2, :bottom => 10, :left => 5, :right => 5},
             :header => {:html => {:content => ''}},
             :footer => {:html => {:content => ''}},
             :show_as_html => params.key?(:debug)
    end
  end

  #  def generate_overall_fee_receipt_pdf_old
  #    @student=Student.find(params[:student_id])
  #    status=true
  #    begin
  #      #                          ,CONCAT(IFNULL(transaction_receipts.receipt_sequence,''),
  #      #                                        transaction_receipts.receipt_number) AS receipt_no
  #      @transactions = FinanceTransaction.find(params[:transaction_id], 
  #        :joins => [:transaction_ledger,:finance_transaction_receipt_record], 
  #        #        :include => {:finance_transaction_receipt_record => [:fee_receipt_template]},
  #        :select => "finance_transactions.*,  
  #                          finance_transaction_receipt_records.fee_receipt_template_id,
  #                          finance_transaction_receipt_records.transaction_receipt_id").
  #        group_by {|x| x.fee_receipt_template_id }
  #      template_ids = @transactions.keys.compact
  #      @templates = (template_ids.present? ? FeeReceiptTemplate.find(template_ids) : []).group_by(&:id)
  #      puts @templates.inspect
  #      #                        if(finance_transaction_ledgers.transaction_mode = 'MULTIPLE',
  #      #                        finance_transactions.receipt_no, finance_transaction_ledgers.receipt_no) receipt_no")      
  #    rescue ActiveRecord::RecordNotFound
  #      status=false
  #    end
  #    unless status
  #      respond_to do |format|
  #        format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found }
  #      end
  #    else
  #      config_keys = ['PdfReceiptSignature', 'PdfReceiptSignatureName', 
  #        'PdfReceiptCustomFooter','PdfReceiptAtow','PdfReceiptNsystem', 'PdfReceiptHalignment']
  #      fetch_config_hash config_keys
  #      @default_currency = Configuration.default_currency
  #      @current_batch = Batch.find(params[:batch_id])
  #      @overall_receipt = OverallReceiptOld.new(params[:student_id], params[:transaction_id])
  #      render :pdf => 'generate_overall_fee_receipt_pdf', 
  #        :template => 'finance_extensions/generate_overall_fee_receipt_pdf.erb',         
  #        :margin => {:top => 5, :bottom => 10, :left => 5, :right => 5}, 
  #        :header => {:html => {:content => ''}}, 
  #        :footer => {:html => {:content => ''}}, 
  #        :show_as_html => params.key?(:debug)
  #    end
  #  end

  # tax report
  def tax_report

  end

  # get pdf for tax report
  def tax_report_pdf
    @data_hash = FinanceTransaction.fetch_finance_tax_data(params)
    render :pdf => 'tax_report_pdf', :show_as_html => params[:d].present?
  end

  # update tax report based on filters
  def update_tax_report

    if validate_date
      # finance fee tax payments
      all_tax_payments = TaxPayment.finance_fee_tax_payments(@start_date, @end_date)
      # hostel tax payments if plugin is enabled
      all_tax_payments += TaxPayment.hostel_fee_tax_payments(@start_date,
                                                             @end_date) if FedenaPlugin.can_access_plugin?("fedena_hostel")
      # transport tax payments if plugin is enabled
      all_tax_payments += TaxPayment.transport_fee_tax_payments(@start_date,
                                                                @end_date) if FedenaPlugin.can_access_plugin?("fedena_transport")
      # instant fee tax payments if plugin is enabled
      all_tax_payments += TaxPayment.instant_fee_tax_payments(@start_date,
                                                              @end_date) if FedenaPlugin.can_access_plugin?("fedena_instant_fee")

      @tax_payments = all_tax_payments.group_by { |tax| "#{tax.slab_name} - &rlm;(#{precision_label(tax.slab_rate)}%)&rlm;" }

      @total_tax = all_tax_payments.map(&:tax_amount).sum.to_f

      @target_action="update_tax_report"

      if request.xhr?
        render(:update) do |page|
          page.replace_html "fee_report_div", :partial => "update_tax_report_partial"
        end
      end
    else
      if request.xhr?
        render_date_error_partial
      else
        flash[:warn_notice] = "error"
        redirect_to :action => :tax_report
      end
    end
  end

  def show_date_filter
    month_date
    @target_action=params[:target_action]
    if request.xhr?
      render(:update) do |page|
        page.replace_html "date_filter", :partial => "filter_dates"
      end
    end
  end

  # search page students fee structure
  def fees_student_structure
    @batches = Batch.find(:all, :conditions => {:is_deleted => false, :is_active => true},
                          :joins => :course, :order => "course_full_name",
                          :select => "batches.*,
                  CONCAT(courses.code,'-',batches.name) as course_full_name")
  end

  # list students as per selected batch [ at Fee Structure search page]
  def list_students_by_batch_for_structure
    @batch_id = params[:fees_submission][:batch_id]
    @students = Student.fetch_students_structure({:batch_id => @batch_id})
    respond_to do |format|
      format.js
    end
  end

  # search students [ at Fee Structure search page]
  def search_student_list_for_structure
    unless params[:query] == ''
      @search_query = params[:query]
      @students = Student.fetch_students_structure({:query => @search_query})
    else
      @search_query = params[:query]
    end
    render :layout => false
  end

  # list of students with balances as per fee structure in PDF format
  # [from fee structure search page]
  def structure_overview_pdf
    if (params[:query] || params[:batch_id]).present?
      @search_query = params[:query]
      @batch = Batch.find(params[:batch_id]) if params[:batch_id].present?
      @students = Student.fetch_students_structure(params)
      render :pdf => 'structure_overview_pdf',
             :template => 'finance_extensions/structure_overview_pdf.erb',
             #        :margin =>{:top=>2,:bottom=>20,:left=>5,:right=>5},
             #        :header => {:html => { :content=> ''}},
             #        :footer => {:html => {:content => ''}},
             :show_as_html => params.key?(:debug)
    else
      flash.now[:notice] = "#{t('flash_msg5')}"
      redirect_to :controller => 'user', :action => 'dashboard' and return
    end
  end

  # view summary of collections as fee structure for a student
  def view_fees_structure
    @search_query = params[:query]
  end

  # summary of collections as fee structure for a student as PDF format
  def student_fees_structure_pdf
    @config = Configuration.get_multiple_configs_as_hash ['PdfReceiptAtow', 'PdfReceiptNsystem']
    render :pdf => "#{@student.full_name}",
           :template => 'finance_extensions/student_fees_structure_pdf.erb',
           :show_as_html => params.key?(:debug)
  end

  # builds query to fetch fees as per fee type
  def fetch_fees fee_type
    tbl_name = fee_type.underscore.pluralize
    inc_assoc = "#{fee_type.underscore}_collection"
    conditions = []
    conditions << "#{tbl_name}.is_active = true" unless fee_type == 'FinanceFee'
    if fee_type == 'TransportFee'
      conditions << "receiver_id = #{@student.id}"
      conditions << "receiver_type = 'Student'"
      conditions << "groupable_id = #{@batch.id}"
      conditions << "groupable_type = 'Batch'"
    else
      conditions << "#{tbl_name}.student_id = #{@student.id}"
      conditions << "#{tbl_name}.batch_id = #{@batch.id}"
    end

    # fee_joins = (fee_type == 'FinanceFee') ? "INNER JOIN finance_fee_collections ffc
    #                                                   ON ffc.id = #{tbl_name}.fee_collection_id
    #                                           INNER JOIN collection_particulars cp
    #                                                   ON cp.finance_fee_collection_id = ffc.id
    #                                           INNER JOIN finance_fee_particulars ffp
    #                                                   ON ffp.id = cp.finance_fee_particular_id " : ""
    fee_joins = (
    case fee_type
      when 'FinanceFee'
        " INNER JOIN finance_fee_collections ffc ON ffc.id = #{tbl_name}.fee_collection_id
          INNER JOIN collection_particulars cp ON cp.finance_fee_collection_id = ffc.id
          INNER JOIN finance_fee_particulars ffp ON ffp.id = cp.finance_fee_particular_id"
      when 'TransportFee'
        " INNER JOIN transport_fee_collections ffc ON ffc.id = #{tbl_name}.transport_fee_collection_id"
      when 'HostelFee'
        " INNER JOIN hostel_fee_collections ffc ON ffc.id = #{tbl_name}.hostel_fee_collection_id"
      else
        " "
    end)
    fee_joins += " LEFT JOIN fee_accounts fa ON fa.id = ffc.fee_account_id" if fee_joins.present?

    fees_where = fee_type == 'FinanceFee' ? " AND 
                  ffc.is_deleted = false AND 
                  ((ffp.receiver_type='Batch' and ffp.receiver_id=#{tbl_name}.batch_id) or 
                   (ffp.receiver_type='Student' and ffp.receiver_id=#{tbl_name}.student_id) or 
                   (ffp.receiver_type='StudentCategory' and ffp.receiver_id=#{tbl_name}.student_category_id)
                  )" : ""

    if fee_joins.present?
      fees_where += " AND " #if fee_type == 'FinanceFee'
      # fees_where += " (ffc.fee_account_id IS NULL OR (ffc.fee_account_id IS NOT NULL AND fa.is_deleted = false))"
      fees_where += " #{active_account_conditions(true)}"
    end

    trans_select = "(SELECT SUM(ft.amount) FROM finance_transactions ft 
                      WHERE ft.finance_id=#{tbl_name}.id AND ft.finance_type='#{fee_type}' AND
                            FIND_IN_SET(ft.finance_id,GROUP_CONCAT(distinct #{tbl_name}.id))
                    ) AS paid_amount"
    trans_joins = " LEFT JOIN finance_transactions ft ON ft.finance_id = #{tbl_name}.id AND ft.finance_type ='#{fee_type}'"
    fee_name = (fee_type.constantize rescue nil)
    conditions = conditions.compact.join(" AND ")
    conditions += fees_where #if fee_type == 'FinanceFee'
    # joins = "#{fee_type == 'FinanceFee' ? fee_joins : ''} #{trans_joins}"
    joins = "#{fee_joins} #{trans_joins}"
    fee_name.present? ? (fee_name.all(:conditions => conditions,
                                      :include => "#{inc_assoc}", :joins => joins, :group => "#{tbl_name}.id",
                                      :select => "#{tbl_name}.*, #{trans_select}, MAX(ft.transaction_date) AS last_transaction_date")) : []
  end

  # view fee structure of a collection for a student
  def fees_structure_for_student
    @student = Student.find(params[:id])
    tbl_name = params[:fee_type]
    fee_type = tbl_name.singularize
    fee_name = fee_model_name tbl_name
    collection_name = ("#{fee_type.camelize}Collection".constantize rescue nil)
    @date = collection_name.find params[:id2] if collection_name.present?
    inc_assoc = @date.tax_enabled? ? {:tax_collections => :tax_slab,
                                      :finance_transactions => :transaction_ledger} : {}
    @fee = @student.fee_by_date(@date, fee_name, inc_assoc)
    @total_discount = 0.to_f
    #    @fee = @student.finance_fee_by_date(@date)
    #      :conditions => ["is_deleted IS NOT NULL"])
    #    @paid_fees = @fee.finance_transactions.all(:include => :transaction_ledger)
    @paid_fees = @fee.finance_transactions
    case fee_type
      when "finance_fee"
        @financefee = @fee
        @fee_category = FinanceFeeCategory.find(@date.fee_category_id)
        particular_and_discount_details
        bal=(@total_payable-@total_discount).to_f
        @transaction_date=params[:transaction_date].present? ? Date.parse(params[:transaction_date]) : Date.today
        days=(Date.today-@date.due_date.to_date).to_i
        auto_fine=@date.fine
        if days > 0 and auto_fine and !@financefee.is_fine_waiver
          if Configuration.is_fine_settings_enabled? && @financefee.balance == 0 && @financefee.is_paid == false && @financefee.balance_fine.present?
            @fine_amount = @financefee.balance_fine
          else
          @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
          @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100 if @fine_rule
          if @fine_rule and @financefee.balance==0
            @fine_amount=@fine_amount-@financefee.paid_auto_fine
          end
          end
        end
      when "transport_fee"
        @transport_fee = @fee
        @transport_fee_discounts = @transport_fee.transport_fee_discounts
        @total_discount = @transport_fee.total_discount_amount
        @total_payable = @transport_fee.bus_fare
        #      @total_payable -= @total_discount
        if @transport_fee.tax_enabled? and @transport_fee.tax_amount.present?
          @tax_slab = @date.collection_tax_slabs.try(:last)
          @total_tax = @transport_fee.tax_amount.to_f
          @total_payable += @total_tax
        end
        #      @total_fine = @transport_fee.fine_amount.to_f
        days=(Date.today-@date.due_date.to_date).to_i
        auto_fine=@date.fine
        @fine_amount=0
        @paid_fine=0
        @total_fine = 0
        bal= (@transport_fee.bus_fare-@total_discount).to_f
        if days > 0 and auto_fine
          @fine_rule=auto_fine.fine_rules.find(:last, :conditions => ["fine_days <= '#{days}' and created_at <= '#{@date.created_at}'"], :order => 'fine_days ASC')
          if @fine_rule.present?
            @fine_amount=@fine_rule.is_amount ? @fine_rule.fine_amount : (bal*@fine_rule.fine_amount)/100
            @paid_fine=@fine_amount
            if @fine_amount > 0 and @transport_fee.is_paid == false
              @fine_amount=@fine_amount-@transport_fee.finance_transactions.all(:conditions => ["description=?", 'fine_amount_included']).sum(&:auto_fine)
            else
              @fine_amount = 0.0
            end
          end
        end
        @total_fine = @fine_amount + @transport_fee.finance_transactions.all.sum(&:fine_amount)
      else
        @total_fine = @fee.fine_amount.to_f
        tax_details_if_enabled
    end
  end

  # fetch tax to be collected for a fee if tax is enabled for fee record
  def tax_details_if_enabled
    if @fee.tax_enabled?
      @tax_collections = @fee.tax_collections
      @total_tax = @tax_collections.map do |x|
        FedenaPrecision.set_and_modify_precision(x.tax_amount).to_f
      end.sum.to_f
      @tax_slabs = @tax_collections.group_by { |x| x.tax_slab }
    end
  end

  # fee structure of a collection for a student as PDF format
  def fee_structure_pdf
    @student = Student.find(params[:id])
    tbl_name = params[:fee_type]
    fee_type = tbl_name.singularize
    fee_name = fee_model_name tbl_name
    collection_name = ("#{fee_type.camelize}Collection".constantize rescue nil)
    @date = collection_name.find params[:id2] if collection_name.present?
    inc_assoc = @date.tax_enabled? ? {:tax_collections => :tax_slab,
                                      :finance_transactions => :transaction_ledger} : {}
    #    fee_type = params[:fee_type]
    fee_name = fee_model_name tbl_name
    if fee_name.present?
      @fee = @student.fee_by_date(@date, fee_name, inc_assoc)
      #      @fee = fee_model_name.last(:conditions => {:student_id => @student.id,
      #          :fee_collection_id => params[:id2]}, :include => [:finance_transactions, 
      #          :finance_fee_collection,
      #          {:tax_collections => :tax_slab}]) 
      @config = Configuration.get_multiple_configs_as_hash ['PdfReceiptSignature', 'PdfReceiptSignatureName',
                                                            'PdfReceiptCustomFooter', 'PdfReceiptAtow', 'PdfReceiptNsystem', 'PdfReceiptHalignment']
      @default_currency = Configuration.default_currency
      @tax_config = Configuration.get_multiple_configs_as_hash(['FinanceTaxIdentificationLabel',
                                                                'FinanceTaxIdentificationNumber']) if @fee.tax_enabled?
      get_student_invoice(@fee, tbl_name)
      @enabled_due_amount = Configuration.get_config_value("ShowTotalDueAmount")
      @enabled_paid_amount = Configuration.get_config_value("ShowToatlPaidAmount")
      render :pdf => 'fee_structure_pdf',
             :template => 'finance_extensions/fee_structure_pdf.erb',
             :margin => {:top => 2, :bottom => 20, :left => 5, :right => 5},
             :header => {:html => {:content => ''}},
             :footer => {:html => {:content => ''}},
             :show_as_html => params.key?(:debug)
    else
      flash.now[:notice] = "#{t('flash_msg5')}"
      redirect_to :controller => 'user', :action => 'dashboard' and return
    end
  end
  
  def fetch_waiver_amount_pay_all
    collections = params[:collection]
    particulars = params[:particular]
    fee_type = params[:fee_type]
    fee_finance_ids = params[:fee_finance_ids]
    fee_transport_ids = params[:fee_transport_ids]
    check,balance = MultiFeeDiscount.fetch_waiver_balance(collections,particulars,fee_type,fee_finance_ids,fee_transport_ids)
    waiver_amount = balance.to_f
    render :json => {'attributes' => waiver_amount.to_f}
  end
  
  def fetch_waiver_amount_collection_wise
    waiver_check = params[:id]
    collections = params[:collection]
    balance = FeeDiscount.fetch_waiver_balance(collections)
    waiver_amount = balance.to_f
    render :json => {'attributes' => waiver_amount.to_f}
  end
  
  def balance_check(fees)
    rejected_id = ''
    rejected_ids = []
    balance = 0.0
    fees.each do |x|
      if x.tax_enabled == true
        balance = (x.balance.to_f - x.tax_amount.to_f)
      else
        balance = x.balance.to_f
      end
      rejected_id = x.id if balance.to_f == 0.0
      rejected_ids << rejected_id if rejected_id.present?
    end
    return rejected_ids
  end

  private

  # def active_account_conditions use_alias = false, alias_name = nil
  #   collection_name = use_alias ? (alias_name.present? ? alias_name : 'ffc') : "finance_fee_collections"
  #   "(#{collection_name}.fee_account_id IS NULL OR (#{collection_name}.fee_account_id IS NOT NULL AND fa.is_deleted = false))"
  # end

  # pepares temporary multi fine data for successive requests
  def temp_fine_data
    _h = {}
    @temporary_manual_fines.each_pair { |k, v| _h.merge!({k => v.keys.map(&:to_i)}) }
    fetch_all_fees(true, [], _h)
    @finance_fees.reject! { |x| x.collection_due_date.to_date >= @transaction_date.to_date }
    @grouped_fees = @finance_fees.group_by { |ff| ff.fee_type.underscore }
  end


  def student_fees_structure
    @student = Student.find(params[:id])
    @batch = Batch.find(params[:id2])
    @student_fees = ActiveSupport::OrderedHash.new
    # finance fees
    @student_fees["finance_fees"] = fetch_fees 'FinanceFee'
    # hostel fees    
    @student_fees["hostel_fees"] = fetch_fees 'HostelFee' if FedenaPlugin.
        can_access_plugin?('fedena_hostel')
    # transport fees
    @student_fees["transport_fees"] = fetch_fees 'TransportFee' if FedenaPlugin.
        can_access_plugin?('fedena_transport')
  end

  def fee_model_name fee_type
    case fee_type
      when "finance_fees"
        (fee_type.singularize.camelize.constantize rescue nil)
      when "hostel_fees"
        FedenaPlugin.can_access_plugin?("fedena_hostel") ?
            (fee_type.singularize.camelize.constantize rescue nil) : nil
      when "transport_fees"
        FedenaPlugin.can_access_plugin?("fedena_transport") ?
            (fee_type.singularize.camelize.constantize rescue nil) : nil
    end
  end

  def invoice_number_enabled?
    @invoice_enabled = Configuration.get_config_value('EnableInvoiceNumber').to_i == 1
  end

  def lock_particular_wise_auto_creation
    FinanceTransaction.particular_wise_pay_lock=true
    yield
    FinanceTransaction.particular_wise_pay_lock=false
  end

  # fetch
  def fetch_config_hash config_keys
    @config = Configuration.get_multiple_configs_as_hash config_keys
  end
  
  def make_transaction_discount_link(discount_hash,ledger_hash)
    hash3=Hash.new
    ledger_hash.each do |k,v|
      val_set1 = discount_hash[k]
      v.each_with_index do|set,index|
        element=[]
        element<<val_set1[index][1]
        element<<set[0]
        if hash3[k].present?
          hash3[k]<<element.flatten
        else
          hash3[k]=[]
          hash3[k]<<element.flatten
        end
      end
    end
    hash3   
  end
  
  def link_discount_tables(linked_hash)
    record_hash = linked_hash
    record_hash.each do |key,val|
      if key == "FinanceFee"
        query_string = "update fee_discounts set finance_transaction_id = case "
      else
        query_string = "update transport_fee_discounts set finance_transaction_id = case "
      end
      record_hash[key].map{|t| query_string+="when id=#{t[0]} then #{t[1]} "}
      query_string+="end;"
      ActiveRecord::Base.connection.execute(query_string)
    end
  end
  
  def make_fee_discount_waiver(status,fee_discount,financefee,fee_particular,total_pay,discount_amount,target_action,target_controller)
    @status = status
    @fee_discount = fee_discount
    @financefee = financefee
    fee_particulars = fee_particular
    total_payable = total_pay
    discount_amount = discount_amount
    FinanceFeeParticular.transaction do
        if @fee_discount.save
          CollectionDiscount.create(:fee_discount_id => @fee_discount.id, :finance_fee_collection_id => @financefee.fee_collection_id)
          d_amount = @fee_discount.discount.to_f
          #          no_parts = fee_particulars.length
          fee_particulars.each do |f_p|
            fp_amt = f_p.amount.to_f
            if @school_discount_mode == "NEW_DISCOUNT"
              if @fee_discount.is_amount?
                ## TO DO :: add logic to adjust minor diff in last particular
                disc_amount = (d_amount / total_payable) * fp_amt.to_f
              else
                disc_amount = (d_amount * fp_amt * 0.01)
              end
            else
              disc_amount = 0
            end
            finance_fee_discount = FinanceFeeDiscount.find(:last,
                                                           :conditions => "finance_fee_id = #{@financefee.id} AND finance_fee_particular_id = #{f_p.id}")
            if finance_fee_discount.present?
              finance_fee_discount.discount_amount = disc_amount
              finance_fee_discount.save
            else
              @fee_discount.finance_fee_discounts.create({
                                                             :finance_fee_particular_id => f_p.id,
                                                             :finance_fee_id => @financefee.id,
                                                             :discount_amount => disc_amount
                                                         })
            end
          end
          FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(@financefee)
          @financefee.reload
          @target_action = target_action
          @target_controller = target_controller
          @status=true
          
          transaction = FeeDiscount.create_transaction_for_waiver_discount(@financefee)
          if transaction.present?
            @fee_discount.reload
            @fee_discount.finance_transaction_id = transaction.id.to_i
            @fee_discount.send(:update_without_callbacks)
            @fee_discount.reload
            flash[:warning] = "#{t('finance.flash14')}.  <a href ='#' onclick='show_print_dialog(#{transaction.id})'>#{t('print_receipt')}</a>"
          else
            flash[:notice] = "#{t('fee_payment_failed')}"
            raise ActiveRecord::Rollback
          end
        end
      end 
  end
  
  
end
