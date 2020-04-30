class AllocateAmountToParticulars
  attr_accessor :particulars, :discounts

  def initialize(finance_transaction, finance)
    @finance_transaction=finance_transaction
    @finance_fee=finance
    @particulars=@finance_fee.finance_fee_particulars
    @discounts=@finance_fee.fee_discounts
  end

  def save_allocation    
    discount_mode = @finance_fee.school_discount_mode
    transaction_amount=@finance_transaction.amount.to_f-@finance_transaction.fine_amount.to_f
    total_tax_collected = 0 if @finance_fee.tax_enabled?
    if transaction_amount > 0
      #old mode
      if discount_mode == "OLD"
        transaction_amount = transaction_amount.to_f+pending_discount
        transaction_tax_amount = @finance_transaction.tax_amount.to_f if @finance_fee.tax_enabled? and @finance_transaction.tax_included?
        transaction_amount-= transaction_tax_amount if transaction_tax_amount.present?
        #      if transaction_amount > 0
        particular_pending_amount.each do |part|
          balance_particular_amount = part.pending_amount.to_f
          particular_tax_pending = (part.tax_to_pay.to_f - part.paid_tax_amount.to_f) if @finance_fee.tax_enabled?
          paying_for_particular= (transaction_amount-part.pending_amount.to_f) < 0 ? transaction_amount : part.pending_amount.to_f
          transaction_amount-=part.pending_amount.to_f
          particular_payment=@finance_transaction.particular_payments.new(
            :amount => paying_for_particular, :finance_fee_id => @finance_fee.id, 
            :finance_fee_particular_id => part.id)
          particular_payment.save
          paying_for_discount= (paying_for_particular-pending_discount) < 0 ? paying_for_particular : pending_discount
          particular_payment.particular_discounts.create(:discount => paying_for_discount, :name => 'automated_discount_allocation') if paying_for_discount > 0
          #          if transaction_tax_amount.to_f > 0 # add tax payments
          #              
          #          end
          is_particular_paid = balance_particular_amount > 0 ? (balance_particular_amount - paying_for_particular) <= 0 : true 
          
          if @finance_fee.tax_enabled? and is_particular_paid and particular_tax_pending.to_f > 0
            if transaction_tax_amount.to_f > 0 and @finance_transaction.tax_included?
              paying_part_tax = transaction_tax_amount.to_f - particular_tax_pending.to_f < 0 ? transaction_tax_amount.to_f : particular_tax_pending.to_f
              transaction_tax_amount -= paying_part_tax
              part.tax_payments.create({
                  :tax_amount => paying_part_tax,
                  :taxed_fee_type => 'FinanceFee',
                  :taxed_fee_id => @finance_fee.id,
                  :finance_transaction_id => @finance_transaction.id
                })
            elsif transaction_amount > 0
              paying_part_tax = transaction_amount.to_f - particular_tax_pending.to_f < 0 ? transaction_amount.to_f : particular_tax_pending.to_f
              total_tax_collected += paying_part_tax
              transaction_amount -= paying_part_tax
              part.tax_payments.create({
                  :tax_amount => paying_part_tax,
                  :taxed_fee_type => 'FinanceFee',
                  :taxed_fee_id => @finance_fee.id,
                  :finance_transaction_id => @finance_transaction.id
                })
            end
          end
          
          break if transaction_amount <= 0
        end
        #      end
      elsif discount_mode == "NEW"
        #new mode
#        transaction_amount=@finance_transaction.amount.to_f-@finance_transaction.fine_amount.to_f
        transaction_tax_amount = @finance_transaction.tax_amount.to_f if @finance_fee.tax_enabled? and @finance_transaction.tax_included?
        transaction_amount-= transaction_tax_amount if transaction_tax_amount.present?        
        
        #      if transaction_amount > 0
        # fields :: (actual) amount, pending_amount, pending_tax_amount, tax_to_pay (actual), paid_tax_amount
        particular_pending_amount.each do |part|        
          balance_particular_amount = part.pending_amount.to_f
          paying_for_particular = 0
          particular_tax_pending = (part.tax_to_pay.to_f - part.paid_tax_amount.to_f) if @finance_fee.tax_enabled?
        
          if part.pending_amount.to_f > 0
            balance_particular_discount = pending_particular_discount(part.id) 
            # adding balance particular discount just for calculation purpose            
            transaction_amount += balance_particular_discount            
            paying_for_particular= (transaction_amount-part.pending_amount.to_f) < 0 ? transaction_amount : part.pending_amount.to_f            
            transaction_amount-=part.pending_amount.to_f
            particular_payment=@finance_transaction.particular_payments.new(
              :amount => paying_for_particular, :finance_fee_id => @finance_fee.id, 
              :finance_fee_particular_id => part.id)
            particular_payment.save          
            paying_for_discount= (paying_for_particular-balance_particular_discount) < 0 ? paying_for_particular : balance_particular_discount
            particular_payment.particular_discounts.create(:discount => paying_for_discount, :name => 'automated_discount_allocation') if paying_for_discount > 0
          end
          # add tax payments
          is_particular_paid = balance_particular_amount > 0 ? (balance_particular_amount - paying_for_particular) <= 0 : true 
          
          if @finance_fee.tax_enabled? and is_particular_paid and particular_tax_pending.to_f > 0
            if transaction_tax_amount.to_f > 0 and @finance_transaction.tax_included?
              paying_part_tax = transaction_tax_amount.to_f - particular_tax_pending.to_f < 0 ? transaction_tax_amount.to_f : particular_tax_pending.to_f
              transaction_tax_amount -= paying_part_tax
              part.tax_payments.create({
                  :tax_amount => paying_part_tax,
                  :taxed_fee_type => 'FinanceFee',
                  :taxed_fee_id => @finance_fee.id,
                  :finance_transaction_id => @finance_transaction.id
                })
            elsif transaction_amount > 0
              paying_part_tax = transaction_amount.to_f - particular_tax_pending.to_f < 0 ? transaction_amount.to_f : particular_tax_pending.to_f
              total_tax_collected += paying_part_tax
              transaction_amount -= paying_part_tax
              part.tax_payments.create({
                  :tax_amount => paying_part_tax,
                  :taxed_fee_type => 'FinanceFee',
                  :taxed_fee_id => @finance_fee.id,
                  :finance_transaction_id => @finance_transaction.id
                })
            end
          end
          break if transaction_amount <= 0
        end
                
        #      end      
      end
    
      #    if transaction_amount > 0
      if @finance_fee.tax_enabled? and total_tax_collected > 0
        @finance_transaction.tax_amount = total_tax_collected
        @finance_transaction.tax_included = true
        @finance_transaction.send(:update_without_callbacks)
        @finance_fee = FinanceFee.find(@finance_fee.id,
          :include => [:tax_payments, {:particular_payments => :particular_discounts}])
        tax_collected = @finance_fee.tax_payments.select{|x| x.is_active == true}.map(&:tax_amount).sum.to_f
        particular_payments = @finance_fee.particular_payments.select {|x| x.is_active == true}
        fee_collected = particular_payments.map(&:amount).sum.to_f 
        discount_applied = particular_payments.map {|x| x.particular_discounts.select{|x| x.is_active == true}.
            map(&:discount) }.flatten.sum.to_f
        net_amount_collected = (fee_collected - discount_applied + tax_collected).to_f
        amount_to_be_paid = (@finance_fee.particular_total - @finance_fee.discount_amount + @finance_fee.tax_amount).to_f
                  
        if (amount_to_be_paid <= net_amount_collected) and @finance_fee.balance.to_f == 0 and @finance_transaction.full_fine_paid
          @finance_fee.is_paid = true
          @finance_fee.send(:update_without_callbacks)
        end          
      end
    end
    
  end
  
  def total_particular_amount
    @particulars.collect(&:amount).sum.to_f
  end

  def get_all_discounts
    @discounts.each do |fee_discount|
      total_amount=fee_discount.master_receiver_type=='FinanceFeeParticular' ? get_particular_amount(fee_discount.master_receiver_id) : total_particular_amount
      fee_discount['total_amount']=total_amount
      fee_discount['amount']=fee_discount.is_amount ? fee_discount.discount : (fee_discount.total_amount * (fee_discount.discount/100))
    end
  end
  
  def get_particular_amount(particular_id)
    FinanceFeeParticular.find(particular_id).amount.to_f
  end
  
  def pending_particular_tax(particular_id)
    total_particular_tax(particular_id) - total_particular_tax_paid(particular_id)
  end
  
  def total_particular_tax_paid(particular_id)
    @finance_fee.tax_payments.select {|x| x.is_active == true and x.taxed_entity_id == particular.id and
        x.taxed_entity_type == 'FinanceFeeParticular' }.sum(&:tax_amount).to_f
  end
  
  def total_particular_tax(particular_id)
    @finance_fee.tax_collections.select {|x| x.taxable_entity_id == particular.id and x.taxable_entity_type == 'FinanceFeeParticular' }.sum(&:tax_amount).to_f
  end
  
  def total_particular_discount(particular_id)
    FinanceFeeDiscount.all(:select => "SUM(discount_amount) AS total_discount",
    :conditions => "finance_fee_id = #{@finance_fee.id} AND finance_fee_particular_id = #{particular_id}",
    :group => "finance_fee_particular_id").map(&:total_discount).try(:last).to_f
    
#    @finance_fee.finance_fee_discounts.all(:select => "SUM(discount_amount) AS total_discount",
#      :conditions => {:finance_fee_particular_id => particular_id}, 
#      :group => "finance_fee_particular_id").map(&:total_discount).try(:last).to_f
  end
  
  def paid_particular_discount(particular_id)
    @finance_fee.particular_payments.all(:joins => :particular_discounts, 
      :conditions => ["finance_fee_particular_id = ? AND particular_payments.is_active = ? AND particular_discounts.is_active = ?",
                      particular_id, true, true],
      :select => "IFNULL(particular_discounts.discount,0) as paid_amount").
      map {|x| x.paid_amount.to_f }.sum
  end
  
  def pending_particular_discount(particular_id)
    total_particular_discount(particular_id) - paid_particular_discount(particular_id)
  end
  
  def total_discount
    get_all_discounts.collect(&:amount).sum.to_f
  end

  def paid_discount
    # old mode
    # @finance_fee.particular_payments.first(:select => "ifnull(sum(particular_discounts.discount),0) as paid_amount", :joins => :particular_discounts).paid_amount.to_f
    # new mode
    @finance_fee.particular_payments.all(:joins => :particular_discounts,
      :conditions => "particular_payments.is_active = true AND particular_discounts.is_active = true",
      :select => "IFNULL(particular_discounts.discount,0) as paid_amount").map {|x| x.paid_amount.to_f }.sum
  end

  def pending_discount
    total_discount-paid_discount
  end

  def particular_pending_amount
    if @finance_fee.tax_enabled?
      #      tax_join = "LEFT JOIN tax_collections tc 
      #                                 ON tc.taxable_fee_type = 'FinanceFee' AND
      #                                      tc.taxable_fee_id = #{@finance_fee.id} AND
      #                                      tc.taxable_entity_type = 'FinanceFeeParticular' AND
      #                                      tc.taxable_entity_id = finance_fee_particulars.id
      #                        LEFT JOIN tax_payments tp
      #                                 ON tp.taxed_fee_type = 'FinanceFee' AND 
      #                                      tp.taxed_fee_id = #{@finance_fee.id} AND
      #                                      tp.taxed_entity_type = 'FinanceFeeParticular' AND
      #                                      tp.taxed_entity_id = finance_fee_particulars.id"
      #      tax_select = ",IFNULL((tc.tax_amount-IFNULL(SUM(tp.tax_amount),0)),0) AS pending_tax_amount,
      #                            IFNULL(tc.tax_amount,0) AS tax_to_pay,
      #                            IFNULL(SUM(tp.tax_amount),0) AS paid_tax_amount"
      tax_select = ",IFNULL( 
                              IFNULL(SUM(DISTINCT tc.tax_amount),0) - IFNULL(SUM(DISTINCT tp.tax_amount),0), 
                            0) AS pending_tax_amount,
                            IFNULL(
                              SUM(DISTINCT tc.tax_amount),0) AS tax_to_pay, 
                            IFNULL(SUM(DISTINCT tp.tax_amount),0) AS paid_tax_amount"
      tax_select = ",IFNULL(
                              (SELECT SUM(tax_amount) 
                                  FROM tax_collections tc 
                                WHERE tc.taxable_fee_type = 'FinanceFee' AND 
                                            tc.taxable_fee_id = #{@finance_fee.id} AND 
                                            tc.taxable_entity_type = 'FinanceFeeParticular' AND
                                            tc.taxable_entity_id = finance_fee_particulars.id),
                            0) AS tax_to_pay, 
                            IFNULL(
                              (SELECT SUM(tax_amount) 
                                  FROM tax_payments tp 
                                WHERE tp.taxed_fee_type = 'FinanceFee' AND 
                                            tp.taxed_fee_id = #{@finance_fee.id} AND 
                                            tp.taxed_entity_type = 'FinanceFeeParticular' AND
                                            tp.taxed_entity_id = finance_fee_particulars.id AND tp.is_active = true),
                            0) AS paid_tax_amount"
      
      tax_having = " OR (tax_to_pay - paid_tax_amount) > 0"
    else
      #      tax_join = ""      
      tax_select = ""      
      tax_having = ""      
    end
    
    FinanceFeeParticular.find(:all, 
      :select => "finance_fee_particulars.id, finance_fee_particulars.amount,
                        (finance_fee_particulars.amount-
                         IFNULL(SUM(particular_payments.amount),0)) AS pending_amount #{tax_select}",
      :joins => "LEFT JOIN particular_payments 
                        ON particular_payments.finance_fee_particular_id = finance_fee_particulars.id AND
                           particular_payments.finance_fee_id=#{@finance_fee.id} AND
                           particular_payments.is_active = true",
      :conditions => ["finance_fee_particulars.id in (?)", @particulars.collect(&:id)],
      :group => "finance_fee_particulars.id",
      :having => "pending_amount > 0 #{tax_having}")
  end

end