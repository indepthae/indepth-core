class MultiFeeDiscount < ActiveRecord::Base
  belongs_to :receiver, :polymorphic => true
  belongs_to :master_receiver, :polymorphic => true
  belongs_to :fee, :polymorphic => true
  has_many :fee_discounts, :dependent => :destroy
  
  attr_accessor :finance_fee_ids      
  attr_accessor :collections
  attr_accessor :particulars
  attr_accessor :fees_to_update
  attr_accessor :waiver_check
  attr_accessor :master_fee_discount_id
  after_destroy :update_fee_balances
  after_create :update_fee_balances
  
  validates_presence_of :name, :collections, :master_fee_discount_id
  validate :check_amount_wise_discount #, :if => "discount.to_f > 0"
  before_validation :set_discount_name, :if => Proc.new {|x| x.new_record? }

  def set_discount_name
    self.name = MasterFeeDiscount.find_by_id(self.master_fee_discount_id).try(:name)
  end

  def fetch_fees # find fee which has discount record added by multi fee discount from pay all page
    self.fees_to_update = fee_discounts.map {|x| x.finance_fees }.flatten    
  end
  
  def update_fee_balances
    self.fees_to_update.each do |fee|
      if fee.is_a? FinanceFee
        FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(fee)
      end
    end if self.fees_to_update.present?
  end
  
  def can_delete? batch_id = nil
    batch_conditions = batch_id.present? ? "fee_discounts.batch_id = #{batch_id} AND " : ""
    fees = fee_discounts.find(:all, :select => "fee_discounts.id",
      :conditions => "#{batch_conditions} ft.created_at > '#{self.created_at}'", :limit => 1,
      :joins => "INNER JOIN collection_discounts cd ON cd.fee_discount_id=fee_discounts.id
                 INNER JOIN finance_fees ff ON ff.student_id = fee_discounts.master_receiver_id AND
                                               fee_discounts.master_receiver_type = 'Student' AND
                                               ff.fee_collection_id = cd.finance_fee_collection_id
                 INNER JOIN finance_transactions ft ON ft.finance_type = 'FinanceFee' AND ft.finance_id = ff.id")
    if FedenaPlugin.can_access_plugin?('fedena_transport') and !fees.present?
      batch_conditions = batch_id.present? ? "tf.groupable_id = #{batch_id} AND tf.groupable_type = 'Batch' AND " : ""
      fees += transport_fee_discounts.find(:all, :select => "transport_fee_discounts.id", 
        :conditions => "#{batch_conditions} ft.created_at > '#{self.created_at}'", :limit => 1,
        :joins => "INNER JOIN transport_fees tf ON tf.id = transport_fee_discounts.transport_fee_id 
                        INNER JOIN finance_transactions ft ON ft.finance_id = tf.id AND ft.finance_type='TransportFee'")
    end
    !fees.present?
  end
  # ((ff.balance + IFNULL(SUM(IF(ft.fine_included,ft.amount - ft.fine_amount,ft.amount)),0)
  #                                                +                                                 
  #                                                 - IFNULL(ff.tax_amount, 0)) 
  #                                -
  #                              (ff.balance + IF(ff.tax_enabled,IFNULL(SUM(IF(ft.tax_included,ft.tax_amount,0)),0),0)
  #                                                - IFNULL(ff.tax_amount, 0)
  #                               )
  def process_discount_fees #should_validate = false
    precision_count = FedenaPrecision.get_precision_count
    precision_count = 2 if precision_count.to_i < 2
    sql_ft_tax_amount = "SELECT SUM(tax_amount) 
                                       FROM finance_transactions ft 
                                    WHERE ft.finance_id=ff.id AND ft.finance_type='FinanceFee'"
    #    sql_ft_fine_amount
    sql_ft_amount = "SELECT SUM(IF(ft.fine_included,ft.amount - ft.fine_amount,ft.amount)) 
                                 FROM finance_transactions ft 
                              WHERE ft.finance_id=ff.id AND ft.finance_type='FinanceFee'"
    sql_ff_discount = "SELECT SUM(ffd.discount_amount) 
                                  FROM finance_fee_discounts ffd 
                               WHERE ffd.finance_fee_id=ff.id"
        
    if self.fee_type == "FinanceFee"
      if self.particulars == 'Overall'
        sql_select = self.is_amount ? 
          "(ff.balance + IF(ff.tax_enabled,IFNULL((#{sql_ft_tax_amount}),0),0)
                             - IFNULL(ff.tax_amount, 0)) - #{self.discount}" : 
          "((ff.balance + IF(ff.tax_enabled,IFNULL((#{sql_ft_tax_amount}),0),0)
                              - IFNULL(ff.tax_amount, 0)) 
           - 
           (((ff.balance + IFNULL((#{sql_ft_amount}),0)                                                                        
                               - IFNULL(ff.tax_amount, 0))
                              + IFNULL((#{sql_ff_discount}),0)) * #{self.discount.to_f} * 0.01))"
        sql_from = "FROM finance_fees ff"
        sql_con = "WHERE ff.id = #{self.collections.to_i}"
        # check discount applied should not be more than fee balance
        sql = "SELECT #{sql_select} AS discount_check #{sql_from} #{sql_con}"
        #        puts sql
        discount_check = FinanceFee.find_by_sql(sql).try(:last).try(:discount_check).to_f
        if self.waiver_check == "1"
          discount_check == 0 
        else
          discount_check > 0
        end
      elsif self.particulars.present?
        #        self.particulars.to_i          
        #        fee = FinanceFee.find(self.collections, :include => :finance_fee_collection)        
        sql_join = "INNER JOIN finance_fee_particulars ffp ON ffp.id = #{self.particulars.to_i}
                    LEFT JOIN finance_fee_discounts ffd 
                           ON ffd.finance_fee_id = ff.id AND ffd.finance_fee_particular_id = ffp.id
                     LEFT JOIN particular_payments pp
                            ON pp.finance_fee_id = ff.id AND pp.finance_fee_particular_id = ffp.id AND pp.is_active = true"
        sql_ff_discount = "SELECT SUM(ffd.discount_amount) 
                             FROM finance_fee_discounts ffd
                            WHERE ffd.finance_fee_id=ff.id AND ffd.finance_fee_particular_id = #{self.particulars.to_i}"
        sql_p_tax = "SELECT tax_amount FROM tax_collections tc
                      WHERE tc.taxable_entity_type = 'FinanceFeeParticular' AND
                            tc.taxable_entity_id = #{self.particulars.to_i} AND
                            tc.taxable_fee_type = 'FinanceFee' AND
                            tc.taxable_fee_id = #{self.collections.to_i}"
        sql_ff_discount = "SELECT SUM(discount_amount) FROM finance_fee_discounts ffd 
                            WHERE ffd.finance_fee_id = ff.id AND ffd.finance_fee_particular_id = ffp.id "
        sql_pp_amount = "SELECT SUM(amount) FROM particular_payments pp
                          WHERE pp.finance_fee_id = ff.id AND pp.finance_fee_particular_id = ffp.id AND pp.is_active = true"
        sql_select = self.is_amount ? 
          "(ffp.amount - IFNULL((#{sql_ff_discount}),0)
                             - IFNULL((#{sql_pp_amount}), 0)) - #{self.discount}" : 
          "((ff.balance + IF(ff.tax_enabled,IFNULL((#{sql_ft_tax_amount}),0),0)
                              - IFNULL((#{sql_p_tax}), 0)) 
           - 
           (((ff.balance + IFNULL((#{sql_ft_amount}),0)                                                                        
                               - IFNULL((#{sql_p_tax}), 0))
                              + IFNULL((#{sql_ff_discount}),0)) * #{self.discount.to_f} * 0.01))"
        sql_from = "FROM finance_fees ff"
        sql_con = "WHERE ff.id = #{self.collections.to_i}"
        # check discount applied should not be more than fee balance
        sql = "SELECT #{sql_select} AS discount_check #{sql_from} #{sql_join} #{sql_con}"
        #        puts sql
        discount_check = FinanceFee.find_by_sql(sql).try(:last).try(:discount_check).to_f
        if self.waiver_check == "1"
          discount_check == 0 
        else
          discount_check > 0
        end
      end
    elsif self.collections == 'Overall'
      finance_fees = FinanceFee.all(:select => "finance_fees.*", 
        :include => [:finance_fee_collection, :finance_transactions],
        :conditions => ["finance_fees.id in (?) AND finance_fees.is_paid = false", self.finance_fee_ids]).reject do |ff|
        ff.finance_fee_collection.discount_mode != "OLD_DISCOUNT" and 
          ff.finance_transactions.select {|ft| ft.trans_type == 'particular_wise'}.present?
      end
      @particular_total = finance_fees.map {|x| x.finance_fee_particulars.
          map {|x| x.amount }}.flatten.sum
      
      @particular_balance = finance_fees.map{|x| x.tax_enabled ? (x.balance.to_f - x.tax_amount.to_f ) : x.balance }.sum.to_f
      
      
      
      transport_fees = []
      transport_fees = TransportFee.all(:conditions => {:id => self.transport_fee_ids}, 
        :include => :transport_fee_collection) if FedenaPlugin.can_access_plugin?('fedena_transport')
      
      @particular_total += transport_fees.map {|x| x.bus_fare }.sum      
      @particular_balance += transport_fees.map{|x| x.tax_enabled ? (x.balance.to_f - x.tax_amount.to_f ) : x.balance }.sum.to_f      
      
      
      
      sql_select = self.is_amount ?  self.waiver_check == "1"? 
        "ROUND(ROUND((ff.balance + IF(ff.tax_enabled,IFNULL((#{sql_ft_tax_amount}),0),0) - IFNULL(ff.tax_amount, 0)) 
         * (1 - ((#{self.discount}) / (#{@particular_balance.to_f}))), #{precision_count}), #{precision_count})" : 
        "ROUND((ff.balance + IF(ff.tax_enabled,IFNULL((#{sql_ft_tax_amount}),0),0)
                                       - IFNULL(ff.tax_amount, 0)) 
                      - ROUND(((ff.balance + IFNULL((#{sql_ft_amount}),0)                                                                        
                                        - IFNULL(ff.tax_amount, 0))
                                       + IFNULL((#{sql_ff_discount}),0))
                                      * (#{self.discount}/#{@particular_balance.to_f})       
                                      , #{precision_count}), #{precision_count})" :
        #                      * ( 1 - (#{self.discount}/#{@particular_total.to_f})), #{precision_count})" : 
      #- (#{self.discount}/#{@particular_total}),#{precision_count})" : 
      "ROUND(ROUND((ff.balance + IF(ff.tax_enabled,IFNULL((#{sql_ft_tax_amount}),0),0)
                              - IFNULL(ff.tax_amount, 0)) 
           - 
           (((ff.balance + IFNULL((#{sql_ft_amount}),0)                                                                        
                               - IFNULL(ff.tax_amount, 0))
                              + IFNULL((#{sql_ff_discount}),0)) * #{self.discount.to_f} * 0.01),#{precision_count}),
            #{precision_count})"
      sql_from = "FROM finance_fees ff"
      sql_con = self.finance_fee_ids ? "WHERE ff.id IN (#{self.finance_fee_ids.join(',')})" : ""
      
      sql = self.finance_fee_ids.present? ? "SELECT #{sql_select} AS discount_check #{sql_from} #{sql_con}" : ""
      discount_checks = sql.present? ? FinanceFee.find_by_sql(sql) : []
      
      #      puts discount_checks.map {|x| x.discount_check.to_f }.inspect
      ## add <= if want to avoid exact amount as discount, else make < ( but add same condition for all cases)
      
      if self.waiver_check == "1"
        discount_checks_present = discount_checks.present? ? discount_checks.select{|x| x.discount_check.to_f < 0} : [] 
      else
        discount_checks_present = discount_checks.present? ? discount_checks.select{|x| x.discount_check.to_f <= 0} : []
      end
      
      if FedenaPlugin.can_access_plugin?('fedena_transport') and self.transport_fee_ids.present?
        sql_ft_amount = "SELECT SUM(IF(ft.fine_included,ft.amount - ft.fine_amount,ft.amount)) 
                                     FROM finance_transactions ft 
                                  WHERE ft.finance_id=ff.id AND ft.finance_type='TransportFee'"
        sql_ft_tax_amount = "SELECT SUM(tax_amount) 
                                           FROM finance_transactions ft 
                                         WHERE ft.finance_id=ff.id AND ft.finance_type='TransportFee'"
        sql_ff_discount = "SELECT SUM(IF(tfd.is_amount,tfd.discount,
                                                           ROUND(ff.bus_fare * tfd.discount * 0.01,#{precision_count}))) 
                                      FROM transport_fee_discounts tfd
                                   WHERE tfd.transport_fee_id=ff.id"        
        sql_from = "FROM transport_fees ff"
        sql_con = "WHERE ff.id IN (#{self.transport_fee_ids.join(',')})"
        
        sql_select = self.is_amount ? self.waiver_check == "1"? 
          
          "ROUND(ROUND((ff.balance + IF(ff.tax_enabled,IFNULL((#{sql_ft_tax_amount}),0),0) - IFNULL(ff.tax_amount, 0)) 
         * (1 - ((#{self.discount}) / (#{@particular_balance.to_f}))), #{precision_count}), #{precision_count})" :
          
          "ROUND((ff.balance + IF(ff.tax_enabled,IFNULL((#{sql_ft_tax_amount}),0),0)
                                          - IFNULL(ff.tax_amount, 0)) 
                         - ROUND(((ff.balance + IFNULL((#{sql_ft_amount}),0)                                                                        
                                        - IFNULL(ff.tax_amount, 0))
                                       + IFNULL((#{sql_ff_discount}),0))
                                      * (#{self.discount}/#{@particular_balance.to_f})       
                                      , #{precision_count}))" :
          #                        * ( 1 - (#{self.discount}/#{@particular_total.to_f})), #{precision_count})" : 
        #- #{self.discount},#{precision_count})" : 
        "ROUND(ROUND((ff.balance + IF(ff.tax_enabled,IFNULL((#{sql_ft_tax_amount}),0),0)
                              - IFNULL(ff.tax_amount, 0)) 
           - 
           (((ff.balance + IFNULL((#{sql_ft_amount}),0)                                                                        
                               - IFNULL(ff.tax_amount, 0))
                              + IFNULL((#{sql_ff_discount}),0)) * #{self.discount.to_f} * 0.01),#{precision_count}),
            #{precision_count})"
        
        sql = "SELECT #{sql_select} AS discount_check #{sql_from} #{sql_con}"      
        
        discount_checks = TransportFee.find_by_sql(sql)
        
        #        puts discount_checks.map {|x| x.discount_check.to_f }.inspect
        if self.waiver_check == "1"
          discount_checks_present += discount_checks.select{|x| x.discount_check.to_f < 0}
        else
          discount_checks_present += discount_checks.select{|x| x.discount_check.to_f <= 0}
        end
        
      end
      #      discount_checks.present?
      !(discount_checks_present.present?)
      
    elsif self.fee_type == "TransportFee" # write case for transport fee alone
      sql_ft_amount = "SELECT SUM(IF(ft.fine_included,ft.amount - ft.fine_amount,ft.amount)) 
                                     FROM finance_transactions ft 
                                  WHERE ft.finance_id=ff.id AND ft.finance_type='TransportFee'"
      sql_ft_tax_amount = "SELECT SUM(tax_amount) 
                                           FROM finance_transactions ft 
                                         WHERE ft.finance_id=ff.id AND ft.finance_type='TransportFee'"
      sql_ff_discount = "SELECT SUM(IF(tfd.is_amount,tfd.discount,
                                                           ROUND(ff.bus_fare * tfd.discount * 0.01,#{precision_count}))) 
                                      FROM transport_fee_discounts tfd
                                   WHERE tfd.transport_fee_id=ff.id"        
      sql_from = "FROM transport_fees ff"
      sql_con = "WHERE ff.id = #{self.collections.to_i}"
        
      sql_select = self.is_amount ? 
        "ROUND((ff.balance + IF(ff.tax_enabled,IFNULL((#{sql_ft_tax_amount}),0),0)
                                        - IFNULL(ff.tax_amount, 0)) 
                       - #{self.discount}, #{precision_count})" :
        "ROUND(ROUND((ff.balance + IF(ff.tax_enabled,IFNULL((#{sql_ft_tax_amount}),0),0)
                              - IFNULL(ff.tax_amount, 0)) 
           - 
           (((ff.balance + IFNULL((#{sql_ft_amount}),0)                                                                        
                               - IFNULL(ff.tax_amount, 0))
                              + IFNULL((#{sql_ff_discount}),0)) * #{self.discount.to_f} * 0.01),#{precision_count}),
            #{precision_count})"
        
      sql = "SELECT #{sql_select} AS discount_check #{sql_from} #{sql_con}"      
        
      discount_check = TransportFee.find_by_sql(sql).try(:last).try(:discount_check).to_f
      if self.waiver_check == "1"
          discount_check == 0 
        else
          discount_check > 0
        end
    end
  end
  
  def check_amount_wise_discount    
    if discount.to_f > 0      
      errors.add(:discount, :discount_percentage_cannot_be_more_than_100) if is_amount == false and discount > 100
      errors.add(:discount, :discount_cannot_be_more_than_collection_amount_or_balance) unless process_discount_fees #(true)
    else
      errors.add(:discount, :must_be_positive_number) 
    end
  end
  
  def create_fee_discounts(student,transaction_date)   
    #    @total_discount = 0
    @particular_total = 0
    @transaction_date = transaction_date
    @student = student
    self.total_discount = self.is_amount ? self.discount : 0
    status = false
    max_discount = ''
    discount_hash = Hash.new
    if self.fee_type == "FinanceFee"
      if self.particulars == 'Overall'
        fee = FinanceFee.find(self.collections, :include => :finance_fee_collection)
        discount_id, net_amount = make_fee_discounts(fee)
        self.total_discount += net_amount
        if self.waiver_check
          discount_hash["FinanceFee"] = [[fee.id,discount_id]]
#          ledger_id = make_waiver_transactions
        end

      elsif self.particulars.present?
        fee = FinanceFee.find(self.collections, :include => :finance_fee_collection)
        discount_id, net_amount = make_fee_discounts(fee,'particular-discount') if fee.present?
        self.total_discount += net_amount
        if self.waiver_check
          discount_hash["FinanceFee"] = [[fee.id,discount_id]]
#          ledger_id = make_waiver_transactions
        end
      end
    elsif self.collections == 'Overall'
      finance_fees = FinanceFee.all(:select => "finance_fees.*", 
        :include => [:finance_fee_collection, :finance_transactions],
        :conditions => ["finance_fees.id in (?) AND finance_fees.is_paid = false", self.finance_fee_ids]).reject do |ff|
        ff.finance_fee_collection.discount_mode != "OLD_DISCOUNT" and 
          ff.finance_transactions.select {|ft| ft.trans_type == 'particular_wise'}.present?
      end
      #      finance_fees = FinanceFee.all(:conditions => {:id => self.finance_fee_ids}, 
      #        :include => :finance_fee_collection)
      @particular_total = finance_fees.map do |x| 
        x.finance_fee_particulars.map {|x| x.amount }
      end.flatten.sum
      
      @particular_balance = finance_fees.map do |x|
        x.tax_enabled ? (x.balance.to_f - x.tax_amount.to_f ) : x.balance.to_f
      end.flatten.sum
      
      if FedenaPlugin.can_access_plugin?('fedena_transport')
        transport_fees = TransportFee.all(:conditions => {:id => self.transport_fee_ids, :is_paid => false}, 
          :include => :transport_fee_collection)      
        @particular_total += transport_fees.map {|x| x.bus_fare }.sum
        @particular_balance += transport_fees.map {|x| x.tax_enabled ? (x.balance.to_f - x.tax_amount.to_f ) : x.balance.to_f }.sum
      else
        transport_fees = []
      end
      max_discount = @particular_balance.to_f
      if self.discount.to_f < @particular_total.to_f and self.waiver_check == "0"
        (finance_fees + transport_fees).each do |fee|
          discount_id, net_amount = make_fee_discounts(fee)        
          self.total_discount += net_amount        
        end
      elsif (self.discount.to_f == @particular_balance.to_f) and self.waiver_check == "1"
        discount_hash["FinanceFee"] = []
        discount_hash["TransportFee"] = []
        (finance_fees + transport_fees).each do |fee|
          discount_id, net_amount = make_fee_discounts(fee)
          self.total_discount += net_amount
          if fee.is_a? FinanceFee 
            discount_hash["FinanceFee"] << [fee.id,discount_id]
          else
            discount_hash["TransportFee"] << [fee.id,discount_id]
          end
        end
      else
        return status , max_discount
      end
    elsif self.fee_type == 'TransportFee'
      @particular_total = self.fee.bus_fare
      @particular_balance = self.fee.tax_enabled ? (self.fee.balance.to_f - self.fee.tax_amount.to_f ) : self.fee.balance.to_f
      discount_hash["TransportFee"] = []
      max_discount = @particular_total.to_f
      if self.discount.to_f < @particular_total.to_f and self.waiver_check == "0"
        discount_id, net_amount = make_fee_discounts(self.fee) 
        self.total_discount += net_amount 
      elsif (self.discount.to_f == @particular_balance.to_f) and self.waiver_check == "1"
        discount_id, net_amount = make_fee_discounts(self.fee) 
        self.total_discount += net_amount
        if self.waiver_check
          discount_hash["TransportFee"] = [[fee.id,discount_id]]
        end
      else
        return status , max_discount
      end
    end
    self.total_discount = self.discount if self.is_amount
    if self.waiver_check == "1"
      ledger_id = make_waiver_transactions
    end
    send(:update_without_callbacks) # save total discount 
    status = true
    return status , discount_hash, ledger_id , max_discount
  end
  
  def make_fee_discounts(fee,discount_type = 'collection-discount')        
    net_discount = 0
    fee_discount_id = ''
    if fee.is_a? FinanceFee
      if self.is_amount # for fixed discount amount
        discount_amount = self.discount
        if discount_type == 'particular-discount'
          particular = FinanceFeeParticular.find(self.particulars.to_i)
          master_receiver_type = "FinanceFeeParticular"
          master_receiver_id = particular.id
        else
          master_receiver_type = "Student"
          master_receiver_id = fee.student_id
          particular_total = fee.finance_fee_particulars.map {|x| x.amount }.sum
          particular_total_balance = fee.tax_enabled ? (fee.balance.to_f - fee.tax_amount.to_f ) : fee.balance.to_f
          discount_amount = @particular_balance.to_f == 0 ? self.discount : 
            (self.discount * particular_total_balance.to_f) / @particular_balance.to_f 
          #          @total_discount += FedenaPrecision.set_and_modify_precision(discount_amount).to_f
        end
      else
        if discount_type == 'collection-discount'
          particulars = fee.finance_fee_particulars
          master_receiver_type = "Student"
          master_receiver_id = fee.student_id
          total_payable = particulars.map { |s| s.amount }.sum.to_f          
        elsif discount_type == 'particular-discount'
          particular = FinanceFeeParticular.find(self.particulars.to_i)
          master_receiver_type = "FinanceFeeParticular"
          master_receiver_id = particular.id
          total_payable = particular.amount.to_f
        end        
        discount_amount = self.discount.to_f #(total_payable*(self.discount.to_f)/total_payable)                   
        net_discount = total_payable*(self.discount.to_f)/ 100.to_f
      end
      fee_discount = self.fee_discounts.build({:is_amount => self.is_amount, :name => self.name,        
          :receiver_id => self.receiver_id, :receiver_type => self.receiver_type, :batch_id => fee.batch_id,
          :finance_fee_category_id => fee.finance_fee_collection.fee_category_id, :is_instant => true, 
          :master_receiver_type => master_receiver_type, :master_receiver_id => master_receiver_id,
          :master_fee_discount_id => self.master_fee_discount_id})
      fee_discount.discount = discount_amount
      if fee_discount.save
        CollectionDiscount.create(:fee_discount_id => fee_discount.id, 
          :finance_fee_collection_id => fee.fee_collection_id) 
        FinanceFeeParticular.add_or_remove_particular_update_discounts_and_taxes(fee)
        fee_discount_id = fee_discount.id
      else
        puts fee_discount.errors.full_messages.inspect
      end
    elsif FedenaPlugin.can_access_plugin?('fedena_transport') and fee.is_a? TransportFee 
      balance = fee.tax_enabled ? (fee.balance.to_f - fee.tax_amount.to_f ) : fee.balance.to_f
      discount = @particular_balance.to_f > 0 ? ((self.discount * balance) / @particular_balance.to_f) : balance.to_f if self.is_amount
      fee_discount = TransportFeeDiscount.create_discount(self, fee, discount)
      if fee_discount.new_record?
        self.is_amount? ? (self.discount -= discount) : (net_discount = 0)
        fee_discount_id = fee_discount.id
      else
        net_discount = (self.discount * fee.bus_fare) / 100.to_f unless self.is_amount
        fee_discount_id = fee_discount.id
      end
    end    
    #    @total_discount += FedenaPrecision.set_and_modify_precision(fee_discount.discount).to_f if self.is_amount and
    #      fee_discount.present?    
    return fee_discount_id,net_discount
  end
  
  def make_waiver_transactions
    multi_fee_transaction = make_transactiom_ledger
    transactions = make_finance_transaction
    ledger_id = make_ledger(multi_fee_transaction,transactions) if multi_fee_transaction.present? and transactions.present?
  end
  
  def make_transactiom_ledger
    amount = 0
    transaction_ledger = Hash.new
    transaction_ledger[:payee_id] = @student.id
    transaction_ledger[:amount] = amount.to_f
    transaction_ledger[:transaction_date] = @transaction_date
    transaction_ledger[:payee_type] = "Student"
    transaction_ledger[:payment_mode] = "Cash"
    transaction_ledger
  end
  
  def make_finance_transaction
    transactions = Hash.new
    i=1
    amount = 0
    ft = Hash.new
    ft[:payee_type] = "Student"
    ft[:payee_id] = @student.id
    ft[:amount] = amount.to_f
    ft[:payment_mode] = "Cash"
    ft[:payment_note] = "waiver discount"
    ft[:transaction_date] = @transaction_date.to_date
    ft[:is_waiver] = true
    ft[:title] = "Waiver Transaction"
    if self.fee_type == "finance_fee" or self.fee_type == "FinanceFee" 
      if self.particulars == 'Overall'
        ft[:finance_id] = self.collections
        ft[:category_id] = FinanceTransactionCategory.find_by_name("Fee").id
        ft[:finance_type] = "FinanceFee"
        transactions[i] = ft
        transactions
      elsif self.particulars.present?
        ft[:finance_id] = self.collections
        ft[:category_id] = FinanceTransactionCategory.find_by_name("Fee").id
        ft[:finance_type] = "FinanceFee"
        transactions[i] = ft
        transactions
      end 
    elsif self.collections == 'Overall'
      if self.finance_fee_ids.present?
        self.finance_fee_ids.each do|ffid|
          ft[:finance_id] = ffid
          ft[:category_id] = FinanceTransactionCategory.find_by_name("Fee").id
          ft[:finance_type] = "FinanceFee"
          transactions[i] = ft.dup
          i+=1
        end  
      end
      if self.transport_fee_ids.present?
        self.transport_fee_ids.each do|tfid|
          ft[:finance_id] = tfid
          ft[:category_id] = FinanceTransactionCategory.find_by_name("Transport").id
          ft[:finance_type] = "TransportFee"
          transactions[i] = ft.dup
          i+=1
        end
      end
      transactions
    elsif self.fee_type == "transport_fee" or self.fee_type == "TransportFee" # write case for transport fee alone
      ft[:finance_id] = self.collections
      ft[:category_id] = FinanceTransactionCategory.find_by_name("Transport").id
      ft[:finance_type] = "TransportFee"
      transactions[i] = ft
      transactions
    end
  end
  
  def make_ledger(multi_fee_transaction,transactions)
    particular_paid = false
    ledger_id = ''
    FinanceTransactionLedger.transaction do
      if !particular_paid
        status=true
        ledger_info = multi_fee_transaction.
          merge({:transaction_type => 'MULTIPLE', :category_is_income => true,
            :current_batch => @current_batch,:is_waiver => true})
        
        
        transaction_ledger = FinanceTransactionLedger.safely_create(ledger_info, transactions)
        status = transaction_ledger.present?
        #          finance_transactions = []
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
          ledger_id = transaction_ledger.id
        else
          raise ActiveRecord::Rollback
        end
      else
        raise ActiveRecord::Rollback
      end
    end
    ledger_id
  end
  
  def self.fetch_waiver_balance(collections,particulars,fee_type,fee_finance_ids,fee_transport_ids)
    waiver_amount = 0
    precision_count = FedenaPrecision.get_precision_count
    precision_count = 2 if precision_count.to_i < 2
    if fee_type == "finance_fee"
      if particulars == 'Overall'
        sql_select = "(SUM(ff.balance)-IFNULL((SUM(ff.tax_amount)),0))" 
        sql_from = "FROM finance_fees ff"
        sql_con = "WHERE ff.id = #{collections.to_i}"
        # check discount applied should not be more than fee balance
        sql = "SELECT #{sql_select} AS balance #{sql_from} #{sql_con}"
        #        puts sql
        balance = FinanceFee.find_by_sql(sql).try(:last).try(:balance).to_f
        #        puts discount_check
        if balance.present?
          waiver_amount += balance.to_f
          return true,waiver_amount
        else
          return false,waiver_amount
        end
      elsif particulars.present?
        #        self.particulars.to_i          
        #        fee = FinanceFee.find(self.collections, :include => :finance_fee_collection)
        ## add_join = " LEFT JOIN finance_fee_discounts ffd ON ffd.finance_fee_id = #{fee.id} AND ffd.finance_fee_particular_id = ffp.id"
        ## add_join += " LEFT JOIN particular_payments pp ON pp.finance_fee_id = #{fee.id} AND pp.finance_fee_particular_id = ffp.id"
        ## add_join to sql_join        
        sql_join = "INNER JOIN finance_fee_particulars ffp 
                                     ON ffp.id = #{particulars.to_i}
                     LEFT JOIN finance_fee_discounts ffd 
                          ON ffd.finance_fee_id = ff.id AND 
                              ffd.finance_fee_particular_id = ffp.id
                     LEFT JOIN particular_payments pp 
                          ON pp.finance_fee_id = ff.id AND 
                              pp.finance_fee_particular_id = ffp.id"
        
        sql_ff_discount = "SELECT SUM(discount_amount) FROM finance_fee_discounts ffd 
                              WHERE ffd.finance_fee_id = ff.id AND ffd.finance_fee_particular_id = ffp.id "
        sql_pp_amount = "SELECT SUM(amount) FROM particular_payments pp
                              WHERE pp.finance_fee_id = ff.id AND pp.finance_fee_particular_id = ffp.id"
        ## ffp.amount - sum(ffd[ffp.id, fee.id]) - sum(pp(ffp.id, fee.id)) > 0 => diff is permissible value
        sql_select = "(ffp.amount - IFNULL((#{sql_ff_discount}),0)
                             - IFNULL((#{sql_pp_amount}), 0))"
        sql_from = "FROM finance_fees ff"
        sql_con = "WHERE ff.id = #{collections.to_i}"
        # check discount applied should not be more than fee balance
        sql = "SELECT #{sql_select} AS balance #{sql_from} #{sql_join} #{sql_con}"
        #        puts sql
        balance = FinanceFee.find_by_sql(sql).try(:last).try(:balance).to_f
        #        puts discount_check
        if balance.present?
          waiver_amount += balance.to_f
          return true,waiver_amount
        else
          return false,waiver_amount
        end
      end 
    elsif collections == 'Overall'
      finance_fees = FinanceFee.all(:select => "finance_fees.*", 
        :include => [:finance_fee_collection, :finance_transactions],
        :conditions => ["finance_fees.id in (?) AND finance_fees.is_paid = false", fee_finance_ids]).reject do |ff|
        ff.finance_fee_collection.discount_mode != "OLD_DISCOUNT" and 
          ff.finance_transactions.select {|ft| ft.trans_type == 'particular_wise'}.present?
      end
      @particular_total = finance_fees.map {|x| x.finance_fee_particulars.
          map {|x| x.amount }}.flatten.sum
      
      
      transport_fees = []
      transport_fees = TransportFee.all(:conditions => {:id => fee_transport_ids}, 
        :include => :transport_fee_collection) if FedenaPlugin.can_access_plugin?('fedena_transport')
      
      @particular_total += transport_fees.map {|x| x.bus_fare }.sum      
      
      
      sql_select = "(SUM(ff.balance)- IFNULL((SUM(ff.tax_amount)),0))"
      sql_from = "FROM finance_fees ff"
      sql_con = fee_finance_ids ? "WHERE ff.id IN (#{fee_finance_ids.join(',')})" : ""
      
      sql = fee_finance_ids.present? ? "SELECT #{sql_select} AS balance #{sql_from} #{sql_con}" : ""
      
      balance = sql.present? ? FinanceFee.find_by_sql(sql) : []
      
      balance_present = balance.present? ? balance.select{|x| x.balance.to_f > 0} : []
      
      
      if FedenaPlugin.can_access_plugin?('fedena_transport') and fee_transport_ids.present?              
      sql_from = "FROM transport_fees ff"
      sql_con = fee_transport_ids ? "WHERE ff.id IN (#{fee_transport_ids.join(',')})" : ""
      
      sql_select =  "ROUND((SUM(ff.balance)- IFNULL((SUM(ff.tax_amount)),0)),#{precision_count})" 
      
      sql = "SELECT #{sql_select} AS balance #{sql_from} #{sql_con}"      
      
      balance = sql.present? ? TransportFee.find_by_sql(sql) : []
        
        #        puts discount_checks.map {|x| x.discount_check.to_f }.inspect
        
        balance_present += balance.select{|x| x.balance.to_f > 0}
      end
      #      balance.present?
      if (balance_present.present?)
        balance_present.each do|bal|
          waiver_amount += bal.balance.to_f
        end
        return true,waiver_amount
      else
        return false,waiver_amount
      end
    elsif fee_type == "transport_fee" # write case for transport fee alone
      sql_ft_tax_amount = "SELECT SUM(tax_amount) 
                                           FROM finance_transactions ft 
                                         WHERE ft.finance_id=ff.id AND ft.finance_type='TransportFee'"
      sql_ff_discount = "SELECT SUM(IF(tfd.is_amount,tfd.discount,
                                                           ROUND(ff.bus_fare * tfd.discount * 0.01,#{precision_count}))) 
                                      FROM transport_fee_discounts tfd
                                   WHERE tfd.transport_fee_id=ff.id"        
      sql_from = "FROM transport_fees ff"
      sql_con = "WHERE ff.id = #{collections.to_i}"
      
      sql_select =  "ROUND((SUM(ff.balance)- IFNULL((SUM(ff.tax_amount)),0)),#{precision_count})" 
      
      sql = "SELECT #{sql_select} AS balance #{sql_from} #{sql_con}"      
      
      balance = TransportFee.find_by_sql(sql).try(:last).try(:balance).to_f
      #           puts discount_check
      if balance.present?
        waiver_amount += balance.to_f
        return true,waiver_amount
      else
        return false,waiver_amount
      end
    end
  end
  
end
