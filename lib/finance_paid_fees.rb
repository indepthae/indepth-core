module FinancePaidFees
 # fetches paid fees data from FinanceFee / TransportFee / HostelFee
  def get_paid_fees(student_id, batch_id)
      @student = Student.find(student_id)
      @current_batch = Batch.find(batch_id)
    #    fees="'FinanceFee', 'HostelFee', 'TransportFee'"

    where_condition_for_check = "finance_fees.id    IS NOT NULL "
    # OR
    #                                              hostel_fees.id      IS NOT NULL OR
    #                                              transport_fees.id IS NOT NULL"
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      transport_fee_sql=
          " LEFT JOIN transport_fees
                 ON transport_fees.id=finance_transactions.finance_id AND
                       finance_transactions.finance_type='TransportFee' AND 
                       transport_fees.groupable_type='Batch' AND 
                       transport_fees.groupable_id=#{@current_batch.id} 
        LEFT JOIN transport_fee_collections 
                 ON transport_fee_collections.id=transport_fees.transport_fee_collection_id "

      where_condition_for_check += " OR transport_fees.id IS NOT NULL "
      # transport_sql="(transport_fee_collections.name)"
      transport_sql = ", group_concat((transport_fee_collections.name) SEPARATOR '||')"
    else
      transport_fee_sql = ""
      transport_sql = ""
    end

    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      hostel_fee_sql=
          " LEFT JOIN hostel_fees
                 ON hostel_fees.id=finance_transactions.finance_id AND 
                       finance_transactions.finance_type='HostelFee' AND 
                       hostel_fees.batch_id=#{@current_batch.id}
        LEFT JOIN hostel_fee_collections 
                 ON hostel_fee_collections.id=hostel_fees.hostel_fee_collection_id "

      where_condition_for_check += " OR hostel_fees.id IS NOT NULL "
      # hostel_sql="(hostel_fee_collections.name)"
      hostel_sql= ", group_concat((hostel_fee_collections.name) SEPARATOR '||')"
    else
      hostel_fee_sql = ""
      hostel_sql = ""
    end

    fees_combining=
        " LEFT JOIN finance_fees
                 ON finance_fees.id=finance_transactions.finance_id AND
                       finance_transactions.finance_type='FinanceFee' AND 
                       finance_fees.batch_id=#{@current_batch.id} 
        LEFT JOIN finance_fee_collections 
                 ON finance_fee_collections.id=finance_fees.fee_collection_id"

    fees_combining_sql = fees_combining + hostel_fee_sql + transport_fee_sql

    finance_transaction_ledgers_sql=
        #      "SELECT DISTINCT multi_fees_transactions.id, " +
        "SELECT DISTINCT finance_transaction_ledgers.id," +
            #                                         multi_fees_transactions.amount,
            #                                         multi_fees_transactions.created_at creation_time,
            "if(finance_transaction_ledgers.status = 'PARTIAL',
                                            SUM(finance_transactions.amount),
                                            finance_transaction_ledgers.amount
                                          ) amount, 
                                          if(finance_transaction_ledgers.is_waiver = true, 'true', 'false') is_waiver ,
                                         finance_transaction_ledgers.created_at creation_time," +
            # "CONCAT_WS(
            #                                 '||', group_concat(finance_fee_collections.name SEPARATOR '||' ),
            #                                 group_concat( #{hostel_sql} SEPARATOR '||' ),
            #                                 group_concat( #{transport_sql} SEPARATOR '||' )
            "CONCAT_WS('||',group_concat(finance_fee_collections.name SEPARATOR '||')#{hostel_sql}#{transport_sql}
                                          ) AS collection_name,
                                         concat( users.first_name,' ', users.last_name ) AS cashier, 
                                         users.id AS usersid,
                                         IF(finance_transaction_ledgers.is_waiver = true,
                                         IF(finance_transaction_ledgers.transaction_type = 'MULTIPLE' ,
                                               'multi_fees_transaction','single_fee_transaction'),'multi_fees_transaction') AS transaction_type," +
            #                                         `finance_transaction_receipts`.receipt_number AS receipt_no," +
            #                                         group_concat(finance_transactions.receipt_no) AS receipt_no,
            "GROUP_CONCAT(DISTINCT IFNULL(CONCAT(IFNULL(transaction_receipts.receipt_sequence,''),
                                         transaction_receipts.receipt_number), '')) receipt_no," +
            "finance_transactions.reference_no, finance_transactions.payment_mode, finance_transactions.payment_note," +
            #                                         multi_fees_transactions.transaction_date,
            "finance_transaction_ledgers.transaction_date,
                                         if(
                                            fee_refunds.id is null,false,true
                                         ) refund_exists " +
            #                             FROM `multi_fees_transactions`
            "FROM `finance_transaction_ledgers` " +
            #                             INNER JOIN `finance_transaction_receipts` ON
            #                                       `finance_transaction_receipts`.`receipt_transaction_id` = `multi_fees_transactions`.`id` AND
            #`finance_transaction_receipts`.`receipt_transaction_type` = 'MultiFeesTransaction'" +
            #                             INNER JOIN `multi_fees_transactions_finance_transactions` ON
            #                             "INNER JOIN `multi_fees_transactions_finance_transactions` ON
            #                                        `multi_fees_transactions_finance_transactions`.multi_fees_transaction_id = `multi_fees_transactions`.id and
            #                                          multi_fees_transactions.school_id=#{MultiSchool.current_school.id}
            "INNER JOIN `finance_transactions`
                  ON `finance_transactions`.transaction_ledger_id = `finance_transaction_ledgers`.id
     INNER JOIN `finance_transaction_receipt_records` 
                  ON `finance_transactions`.id = `finance_transaction_receipt_records`.finance_transaction_id
        LEFT JOIN fee_accounts fa ON fa.id = finance_transaction_receipt_records.fee_account_id
        LEFT JOIN transaction_receipts 
                  ON transaction_receipts.id = finance_transaction_receipt_records.transaction_receipt_id     
        LEFT JOIN fee_refunds 
                  ON fee_refunds.finance_fee_id=finance_transactions.finance_id and 
                        finance_transactions.finance_type='FinanceFee' 
        LEFT JOIN users ON users.id=finance_transactions.user_id 
                             #{fees_combining_sql}  
                             WHERE " +
            #                                          (multi_fees_transactions.student_id='#{@student.id}') and
            "(finance_transaction_ledgers.payee_id='#{@student.id}' AND
      finance_transaction_ledgers.payee_type='Student' AND
                                            (finance_transaction_ledgers.status='ACTIVE' or 
                                             finance_transaction_ledgers.status='PARTIAL')
                                          ) and (fa.id IS NULL OR (fa.is_deleted = false)) AND
                                          (#{where_condition_for_check}) group by id "
    finance_transactions_sql=
        "UNION ALL(
                                         SELECT finance_transactions.id,
                                                     finance_transactions.amount,
                                                     finance_transactions.created_at creation_time,
                                                     if(
                                                        finance_transactions.finance_type='FinanceFee',
                                                        finance_fee_collections.name,
                                                        if(
                                                            finance_transactions.finance_type='HostelFee',
                                                            #{hostel_sql},
                                                            #{transport_sql}
                                                          )
                                                       ) as collection_name,
                                                     concat(users.first_name,' ',users.last_name) AS cashier, 
                                                     users.id as usersid,
                                                     'normal_fees_transaction' AS transaction_type,                                                     
                                                     finance_transactions.receipt_no,
                                                     finance_transactions.reference_no,
                                                     finance_transactions.payment_mode,
                                                     finance_transactions.payment_note,
                                                     finance_transactions.transaction_date,
                                                     if(fee_refunds.id is null,false,true) refund_exists 
                                         FROM `finance_transactions` " +
            #                                         INNER JOIN `finance_transaction_receipts` ON
            #                                                    `finance_transaction_receipts`.`receipt_transaction_id` = `finance_transactions`.`id` AND
            #`finance_transaction_receipts`.`receipt_transaction_type` = 'FinanceTransaction'"
            #                                         LEFT OUTER JOIN `multi_fees_transactions_finance_transactions` ON
            #                                                     `multi_fees_transactions_finance_transactions`.finance_transaction_id = `finance_transactions`.id
            "LEFT OUTER JOIN `finance_transaction_ledgers` ON
                                                     `finance_transaction_ledgers`.id = `finance_transactions`.transaction_ledger_id 
                                         #{fees_combining_sql} 
                                         LEFT JOIN users ON 
                                                      users.id=finance_transactions.user_id 
                                         LEFT JOIN fee_refunds ON 
                                                      fee_refunds.finance_fee_id=finance_transactions.finance_id and 
                                                      finance_transactions.finance_type='FinanceFee' 
                                         WHERE (
                                                        finance_transactions.payee_id='#{@student.id}' and (#{where_condition_for_check}) and " +
            #                                                        multi_fees_transactions.id is NULL and
            "finance_transaction_ledgers.id is NULL and
                                                        finance_type in ('FinanceFee','HostelFee','TransportFee')
                                                      )
                                        )"
    order_param = " ORDER BY creation_time DESC"
    #@paid_fees=FinanceTransactionLedger.paginate_by_sql("#{finance_transaction_ledgers_sql} #{finance_transactions_sql}#{order_param}", :page => params[:page], :per_page => 10, :order => 'creation_time desc')
    @paid_fees=FinanceTransactionLedger.paginate_by_sql("#{finance_transaction_ledgers_sql} #{order_param}",
                                                        :page => params[:page], :per_page => 10, :order => 'creation_time desc')
    # fetch advance fees used
    @advance_fee_used = @paid_fees.present? ? @paid_fees.collect(&:finance_transactions).flatten.compact.collect(&:wallet_amount).map(&:to_f).sum : 0.00

    @multi_transaction_fines = MultiTransactionFine.all(:select => "multi_transaction_fines.*, 
       ft.finance_id AS finance_id, ft.finance_type AS finance_type",
                                                        :conditions => "receiver_type = 'Student' AND receiver_id = #{@student.id} AND
                              ft.batch_id = #{@current_batch.id}",
                                                        :joins => "INNER JOIN finance_transaction_fines ftf
                                   ON ftf.multi_transaction_fine_id = multi_transaction_fines.id 
                      INNER JOIN finance_transactions ft ON ft.id = ftf.finance_transaction_id") unless current_user.student?
    #    @paid_fees=FinanceTransactionLedger.paginate_by_sql("#{finance_transaction_ledgers_sql} #{order_param}", :page => params[:page], :per_page => 10, :order => 'creation_time desc')
    #    @paid_fees=MultiFeesTransaction.paginate_by_sql("#{multi_fees_transactions_sql} #{finance_transactions_sql}#{order_param}", :page => params[:page], :per_page => 10, :order => 'creation_time desc')
  end
end