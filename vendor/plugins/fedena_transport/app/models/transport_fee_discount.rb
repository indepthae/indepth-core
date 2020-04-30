class TransportFeeDiscount < ActiveRecord::Base
  belongs_to :transport_fee
  belongs_to :multi_fee_discount
  belongs_to :master_fee_discount

  has_one :transport_transaction_discount

  validates_presence_of :name,:transport_fee_id, :discount
  validates_numericality_of :discount, :allow_nil=>true, :allow_blank=>true
  validates_inclusion_of :discount, :in => 0..100, :unless => :is_amount, 
    :allow_nil=>true, :allow_blank=>true, :message => :amount_in_percentage_cant_exceed_100
  validate :discount_amount
  after_destroy :update_fee_balances
  attr_accessor :waiver_check
  
  before_validation :set_discount_name, :if => Proc.new {|x| x.new_record? }

  after_create :trigger_update_collection_master_particular_reports
  after_destroy :trigger_update_collection_master_particular_reports

  def trigger_update_collection_master_particular_reports
    if self.destroyed?
      clean_associated_data
      Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('remove', self))
    else
      Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('insert', self))
    end
  end

  def set_discount_name
    self.name = MasterFeeDiscount.find_by_id(self.master_fee_discount_id).try(:name)
  end

  def update_fee_balances
    # mark transaction discount marker as inactive
    # transaction was done on this discount
    transport_transaction_discount.deactivate if transport_transaction_discount.present?

    update_discounts_on_creation_or_deletion(self.transport_fee, 'delete')
    self.transport_fee.reload.update_tax_on_discount
  end

  def self.create_discount(multi_fee_discount, fee, discount = 0)
    transport_fee_discount = fee.transport_fee_discounts.build({:is_amount => multi_fee_discount.is_amount, 
        :name => multi_fee_discount.name, :discount => multi_fee_discount.discount})
    transport_fee_discount.discount = discount if multi_fee_discount.is_amount and discount > 0
    transport_fee_discount.multi_fee_discount = multi_fee_discount
    transport_fee_discount.master_fee_discount_id = multi_fee_discount.master_fee_discount_id
    if transport_fee_discount.save 
      collection = fee.transport_fee_collection
      fee.update_tax_on_discount(collection)
      transport_fee_discount.update_discounts_on_creation_or_deletion(fee,"create")
    else
      puts transport_fee_discount.errors.full_messages.inspect
    end    
    transport_fee_discount
  end
  
  def discount_amount
    if discount.present?
      unless is_amount
        discount_amt = (transport_fee.bus_fare*(discount/100))
        if discount_amt.to_f > transport_fee.balance.to_f
          errors.add(:discount, t('cannot_be_greater_than_total_amount'))
        end
      else
        if discount.to_f > transport_fee.balance.to_f
          errors.add(:discount, t('cannot_be_greater_than_total_amount'))
        end
      end
    end
  end
  
  def update_discounts_on_creation_or_deletion(transport_fee, activity = nil)
    discount_amount = self.is_amount ? self.discount : (transport_fee.bus_fare*(self.discount/100))
    discount_amount = get_precision_count(discount_amount).to_f
    transport_fee.balance = transport_fee.balance - discount_amount if activity == "create"
    transport_fee.balance = transport_fee.balance + discount_amount if activity == "delete"
    transport_fee.save
  end
  
  def self.fetch_waiver_balance(collection)
    transportfee=TransportFee.find(collection.to_i)
    waiver_amount = ((transportfee.balance.to_f) - (transportfee.tax_amount.to_f)).to_f
  end
  
  def self.create_transaction_for_waiver_discount(transportfee_details)
    transaction = FinanceTransaction.new
    amount = 0
    transportfee = transportfee_details
    ActiveRecord::Base.transaction do 
      transaction.title = "Waiver Transaction"
      transaction.category = FinanceTransactionCategory.find_by_name("Fee")
      transaction.payee = transportfee.receiver
      transaction.finance = transportfee
      transaction.amount = amount.to_f
      transaction.transaction_type = 'SINGLE'
      transaction.transaction_date = Date.today_with_timezone.to_date
      transaction.payment_mode = "Cash"
      transaction.payment_note = "waiver discount"
      transaction.is_waiver = true
      transaction.safely_create
#      transaction.transaction_ledger.is_waiver = true
#      transaction.transaction_ledger.save
      
      if transaction.errors.present?
        transaction.errors.full_messages.each do |err_msg|
          @transportfee.errors.add_to_base(err_msg)
        end
        raise ActiveRecord::Rollback 
      else
        transaction                 
      end
    end
  end
    
  private

  def clean_associated_data
    self.instance_variables.each do |instance_var|
      object_data = ['@attributes_cache','@attributes','@changed_attributes']
      self.send('remove_instance_variable', instance_var) unless object_data.include?(instance_var)
    end
  end
  
  def get_precision_count(val)
    precision_count ||= FedenaPrecision.get_precision_count
    return sprintf("%0.#{precision_count}f",val)
  end
  
  def precision_label(val)
    if defined? val and val != '' and !val.nil?
      return sprintf("%0.#{precision_count}f",val)
    else
      return
    end
  end

  def precision_count
    precision_count = Configuration.get_config_value('PrecisionCount')
    precision = precision_count.to_i < 2 ? 2 : precision_count.to_i > 9 ? 8 : precision_count.to_i
    precision
  end
  
end
