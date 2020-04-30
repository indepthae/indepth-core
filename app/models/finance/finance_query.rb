# Class to find user specific query

class FinanceQuery
  def initialize(user=Authorization.current_user, current_batch=nil,options={})
    @user = user #student or employee or archived_student
    @current_user = current_user
    @current_batch=current_batch
    process_options(options)
  end


  def get_paid_fees options = {}
    #    fees="'FinanceFee','HostelFee','TransportFee'"
    where_condition_for_check ="finance_fees.id    IS NOT NULL " 
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      transport_fee_sql =  " LEFT JOIN transport_fees 
                                    ON transport_fees.id=finance_transactions.finance_id AND 
                                       finance_transactions.finance_type='TransportFee' AND 
                                       transport_fees.groupable_type='Batch' AND 
                                       transport_fees.groupable_id=#{@current_batch.id} 
                             LEFT JOIN transport_fee_collections 
                                    ON transport_fee_collections.id=transport_fees.transport_fee_collection_id "
      where_condition_for_check +=  " OR transport_fees.id IS NOT NULL"
      transport_sql = ", group_concat((transport_fee_collections.name) SEPARATOR '||')"
    else
      transport_fee_sql =  ""  
      transport_sql = ""
    end
    
    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      hostel_fee_sql = " LEFT JOIN hostel_fees 
                                ON hostel_fees.id=finance_transactions.finance_id AND 
                                   finance_transactions.finance_type='HostelFee' AND 
                                   hostel_fees.batch_id=#{@current_batch.id} 
                         LEFT JOIN hostel_fee_collections 
                                ON hostel_fee_collections.id=hostel_fees.hostel_fee_collection_id "
      where_condition_for_check +=  " OR hostel_fees.id IS NOT NULL"
      hostel_sql= ", group_concat((hostel_fee_collections.name) SEPARATOR '||')"
    else
      hostel_sql= ""
      hostel_fee_sql = ""
    end    
    
    fees_combining=" LEFT JOIN finance_fees 
                            ON finance_fees.id=finance_transactions.finance_id AND 
                               finance_transactions.finance_type='FinanceFee' AND
                               finance_fees.batch_id=#{@current_batch.id} 
                     LEFT JOIN finance_fee_collections 
                            ON finance_fee_collections.id=finance_fees.fee_collection_id"

    fees_combining_sql = fees_combining + hostel_fee_sql + transport_fee_sql
    
    transactions_sql = "SELECT distinct finance_transaction_ledgers.id, 
      IF(finance_transaction_ledgers.status = 'PARTIAL',
      SUM(finance_transactions.amount),
      finance_transaction_ledgers.amount
    ) amount,
      finance_transaction_ledgers.created_at creation_time,
      CONCAT_WS('||',group_concat(finance_fee_collections.name SEPARATOR '||')#{hostel_sql}#{transport_sql}
    ) as collection_name,
      CONCAT(users.first_name,' ', users.last_name) AS cashier, 
      users.id AS usersid,
      'multi_fees_transaction' AS transaction_type,
      GROUP_CONCAT(DISTINCT IFNULL(CONCAT(IFNULL(tr.receipt_sequence,''), tr.receipt_number),'-')) AS receipt_no,
      finance_transactions.reference_no, 
      finance_transactions.payment_mode,
      finance_transactions.payment_note, 
      finance_transaction_ledgers.transaction_date,
      IF(fee_refunds.id is NULL,false,true) refund_exists 
    FROM `finance_transaction_ledgers` 
    INNER JOIN `finance_transactions` 
            ON `finance_transactions`.transaction_ledger_id = `finance_transaction_ledgers`.id 
    INNER JOIN finance_transaction_receipt_records ftrr 
            ON ftrr.finance_transaction_id = finance_transactions.id
    INNER JOIN transaction_receipts tr 
            ON tr.id = ftrr.transaction_receipt_id
     LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id
     LEFT JOIN fee_refunds 
            ON fee_refunds.finance_fee_id=finance_transactions.finance_id AND 
               finance_transactions.finance_type='FinanceFee' 
     LEFT JOIN users 
            ON users.id=finance_transactions.user_id 
    #{fees_combining_sql}  
    WHERE (finance_transaction_ledgers.payee_id='#{student.id}' AND 
      finance_transaction_ledgers.payee_type = 'Student' AND 
      (finance_transaction_ledgers.status='ACTIVE' or 
          finance_transaction_ledgers.status='PARTIAL')
    ) AND (fa.id IS NULL OR fa.is_deleted = false) AND
    (#{where_condition_for_check}) 
      GROUP BY id "
    #    finance_transactions_sql="UNION ALL ( 
    #                                                  SELECT finance_transactions.id, finance_transactions.amount,
    #                                                              finance_transactions.created_at creation_time, 
    #                                                              IF( finance_transactions.finance_type='FinanceFee',
    #                                                                   finance_fee_collections.name, 
    #                                                                   IF( finance_transactions.finance_type='HostelFee',
    #                                                                        #{hostel_sql}, #{transport_sql})
    #                                                              ) AS collection_name, 
    #                                                              CONCAT( users.first_name, ' ', users.last_name) AS cashier,
    #                                                              users.id AS usersid, 'normal_fees_transaction' AS transaction_type,
    #                                                              finance_transactions.receipt_no, finance_transactions.reference_no,
    #                                                              finance_transactions.payment_mode, finance_transactions.payment_note,
    #                                                              finance_transactions.transaction_date,
    #                                                              if(fee_refunds.id is null,false,true) refund_exists FROM `finance_transactions` LEFT OUTER JOIN `multi_fees_transactions_finance_transactions` ON `multi_fees_transactions_finance_transactions`.finance_transaction_id = `finance_transactions`.id LEFT OUTER JOIN `multi_fees_transactions` ON `multi_fees_transactions`.id = `multi_fees_transactions_finance_transactions`.multi_fees_transaction_id #{fees_combining_sql} left join users on users.id=finance_transactions.user_id left join fee_refunds on fee_refunds.finance_fee_id=finance_transactions.finance_id and finance_transactions.finance_type='FinanceFee' WHERE (payee_id='#{student.id}' and (#{where_condition_for_check}) and multi_fees_transactions.id is NULL and finance_type in ('FinanceFee','HostelFee','TransportFee')))"
    order_param=" ORDER BY creation_time DESC"
    #    paid_fees=MultiFeesTransaction.find_by_sql("#{multi_fees_transactions_sql} #{finance_transactions_sql}#{order_param}")
    if options[:paginate] == true and options[:paginate_options].present?
      FinanceTransactionLedger.paginate_by_sql("#{transactions_sql} #{order_param}", options[:paginate_options])
    else
      FinanceTransactionLedger.find_by_sql("#{transactions_sql} #{order_param}")
    end
  end

  def fetch_all_fees include_paid = false
    fee_transaction_category_id=FinanceTransactionCategory.find_by_name("Fee").id
    hostel_transaction_category_id=FinanceTransactionCategory.find_by_name("Hostel").try(:id)
    transport_transaction_category_id=FinanceTransactionCategory.find_by_name("Transport").try(:id)
    finance_fee_conditions = " AND (finance_fee_collections.id IS NOT NULL AND (fa.id IS NULL OR fa.is_deleted = false))"

    precision_count = FedenaPrecision.get_precision_count
    master_fees_sql = <<-SQL
      SELECT DISTINCT finance_fee_collections.name AS collection_name, 
                      finance_fee_collections.due_date As collection_due_date,
                      #{fee_transaction_category_id} as transaction_category_id,
                      finance_fees.is_paid, finance_fees.balance, finance_fees.balance_fine as balance_fine, finance_fees.is_fine_waiver as is_fine_waiver,finance_fees.id AS id, 'FinanceFee' as fee_type,
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
                                ( SELECT IFNULL( SUM( finance_transactions.fine_amount), 0)
                                  FROM finance_transactions
                                  WHERE finance_transactions.finance_id=finance_fees.id AND 
                                              finance_transactions.finance_type='FinanceFee' AND 
                                              description= 'fine_amount_included' 
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
                                fine_rules.fine_amount AS fine_amount, fine_rules.is_amount,
                                IF(finance_fees.tax_enabled,
                                    (SELECT SUM(ROUND(tax_amount,#{precision_count}))
                                     FROM tax_collections tc
                                  WHERE tc.taxable_fee_type = 'FinanceFee' AND
                                              tc.taxable_fee_id = finance_fees.id),
                                              '-'
                                ) AS tax_amount, finance_fees.tax_enabled                                
                                FROM `finance_fees`
                                INNER JOIN `finance_fee_collections` ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id
                                 LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
                                INNER JOIN `fee_collection_batches` ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id
                                INNER JOIN `collection_particulars` ON (`finance_fee_collections`.`id` = `collection_particulars`.`finance_fee_collection_id`)
                                INNER JOIN `finance_fee_particulars` ON (`finance_fee_particulars`.`id` = `collection_particulars`.`finance_fee_particular_id`)
                                LEFT JOIN `finance_transactions` ON (`finance_transactions`.`finance_id` = `finance_fees`.`id`)
                                LEFT JOIN `fines` ON `fines`.id = `finance_fee_collections`.fine_id AND fines.is_deleted is false
                                LEFT JOIN `fine_rules` 
                                          ON fine_rules.fine_id = fines.id  AND 
                                                fine_rules.id = (
                                                 SELECT id 
                                                 FROM fine_rules ffr 
                                                 WHERE ffr.fine_id = fines.id AND 
                                                             ffr.created_at <= finance_fee_collections.created_at AND 
                                                             ffr.fine_days <= DATEDIFF( 
                                                                                            COALESCE(Date('#{@transaction_date}'), 
                                                                                                             CURDATE()),
                                                                                            finance_fee_collections.due_date ) 
                                                 ORDER BY ffr.fine_days DESC LIMIT 1
                                                )
    SQL

    if FedenaPlugin.can_access_plugin?("fedena_hostel") and (@hostel_fee_for_online and (@current_user.admin? or
        @current_user.privileges.collect(&:name).include? "HostelAdmin" or
        student.hostel_fees.present?))
      hostel_fees_sql="UNION ALL (
              SELECT hfc.name AS collection_name, hfc.due_date As collection_due_date,
                          #{hostel_transaction_category_id} AS transaction_category_id,
                          IF( hf.balance > 0, false, true) is_paid, hf.balance balance, NULL as balance_fine,
                          NULL as is_fine_waiver, hf.id AS id, 'HostelFee' AS fee_type,
                          hf.rent actual_amount, 0 AS paid_fine,
                          (SELECT IFNULL(SUM(finance_transactions.fine_amount),0)
                              FROM finance_transactions
                           WHERE finance_transactions.finance_id=hf.id AND 
                                       finance_transactions.finance_type='HostelFee' AND 
                                       description IS NULL
                          ) AS manual_paid_fine,
                          0 fine_amount, 0 is_amount,
                          IF(hf.tax_enabled,hf.tax_amount,'-') AS tax_amount, hf.tax_enabled 
              FROM hostel_fees hf
              INNER JOIN hostel_fee_collections hfc 
                           ON hfc.id = hf.hostel_fee_collection_id AND hfc.is_deleted=0 AND 
                                 hf.student_id='#{@student.id}' AND hf.batch_id=#{@current_batch.id} AND 
                                 #{include_paid == true ? '' : 'hf.balance > 0 AND'} is_active IS true
               LEFT JOIN fee_accounts fa ON fa.id = hfc.fee_account_id
                   WHERE (hfc.id IS NOT NULL AND (fa.id IS NULL OR fa.is_deleted = false))
            )"
      # finance_fee_conditions += " OR (hostel_fee_collections.id IS NOT NULL AND (fa.id IS NULL OR fa.is_deleted = false)) "
    else
      hostel_fees_sql=''
    end

    if FedenaPlugin.can_access_plugin?("fedena_transport") and (@transport_fee_for_online and
        (@current_user.admin? or @current_user.privileges.collect(&:name).include? "TransportAdmin" or
            student.transport_fees.present?))
      transport_fees_sql="UNION ALL (
              SELECT tfc.name AS collection_name, tfc.due_date As collection_due_date,
                          #{transport_transaction_category_id} AS transaction_category_id,
                          tf.is_paid is_paid, tf.balance balance, tf.balance_fine as balance_fine,
                          tf.is_fine_waiver as is_fine_waiver, tf.id AS id, 
                          'TransportFee' AS fee_type, 
                          (tf.bus_fare - IFNULL((SELECT SUM(IF(is_amount, discount,(discount * tf.bus_fare * 0.01))) AS discount 
                                                  FROM transport_fee_discounts 
                                                   WHERE transport_fee_discounts.transport_fee_id = tf.id 
                                                  GROUP BY transport_fee_discounts.transport_fee_id),0)) actual_amount, 
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
                          fine_rules.is_amount, IF(tf.tax_enabled,tf.tax_amount,'-') AS tax_amount, tf.tax_enabled
              FROM transport_fees tf

              INNER JOIN transport_fee_collections tfc 
                         ON tfc.id = tf.transport_fee_collection_id AND tfc.is_deleted=0 AND 
                               tf.receiver_id='#{@student.id}' AND tf.groupable_type='Batch' AND 
                               tf.groupable_id=#{@current_batch.id} AND tf.receiver_type='Student' AND 
                               #{include_paid == true ? '' : 'tf.is_paid = false AND '} is_active IS true
               LEFT JOIN fee_accounts fa ON fa.id = tfc.fee_account_id
               LEFT JOIN `finance_transactions` ON (`finance_transactions`.`finance_id` = tf.`id`)
              LEFT OUTER JOIN `fines` ON `fines`.id = tfc.fine_id AND fines.is_deleted is false
              LEFT OUTER JOIN `fine_rules` ON  fine_rules.fine_id = fines.id  AND 
                            fine_rules.id= (
                             SELECT id 
                              FROM fine_rules ffr 
                              WHERE ffr.fine_id=fines.id AND 
                              ffr.created_at <= tfc.created_at AND 
                              ffr.fine_days <= DATEDIFF(
                               COALESCE(Date('#{@transaction_date}'),CURDATE()),
                              tfc.due_date)
                               ORDER BY ffr.fine_days DESC LIMIT 1)
                  WHERE (tfc.id IS NOT NULL AND (fa.id IS NULL OR fa.is_deleted = false))
              group by tf.id
                          )"
      # finance_fee_conditions += " OR ((transport_fee_collections.id IS NOT NULL AND (fa.id IS NULL OR fa.is_deleted = false)) "
    else
      transport_fees_sql = ''
    end

    # finance_fee_conditions += ") "
    @finance_fees=FinanceFee.find_by_sql(<<-SQL
(#{master_fees_sql} WHERE
      (
        #{@finance_fee_for_online} and
        finance_fees.student_id=#{student.id} and
        #{include_paid == true ? '' : 'finance_fees.is_paid=true and '}
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
      ) GROUP BY finance_fees.id) #{transport_fees_sql} #{hostel_fees_sql} ORDER BY fee_type, id
      SQL
    )
  end


  private

  def current_user
    @current_user ||= Authorization.current_user
  end

  def student
    @student ||= @user
  end

  def process_options(opts)
    status=opts.empty? ? true : false
    opts.each{|k,v|
      instance_variable_set('@'+k,status || v)
    }
  end
end
