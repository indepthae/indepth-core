# Model holds logic for multiple receipt sets
# A receipt number set is a combination of
#     sequence_prefix : a receipt sequence,
#     starting_number : starting sequence number
class ReceiptNumberSet < ActiveRecord::Base
  
  has_many :transaction_receipts
  has_many :finance_category_receipt_sets
  has_many :finance_fee_categories, :through => :finance_category_receipt_sets, :source => :category,
    :source_type => "FinanceFeeCategory"
  has_many :finance_transaction_categories, :through => :finance_category_receipt_sets, :source => :category,
    :source_type => "FinanceTransactionCategory"
  
  validates_presence_of :name, :starting_number
  validates_uniqueness_of :name
  validates_numericality_of :starting_number, :only_integer => true, :greater_than => 0
  validates_format_of :name, :with => /^[a-zA-Z0-9\s]*$/, :message => :special_characters_not_valid
  
  validate :validate_sequence_combination, :if => Proc.new {|x| x.new_record? or x.sequence_prefix_changed?}
  
  # TO DO ::
  # custom validation on starting number if sequence has only numeric digits, 
  # validate the numeric digits to go in starting number
  def validate_sequence_combination    
    empty_set = ReceiptNumberSet.find(:first, 
      :conditions => "sequence_prefix is NULL or sequence_prefix = ''") unless sequence_prefix.present?
    
    errors.add :sequence_prefix, :empty_sequence_exists if !sequence_prefix.present? and empty_set.present?          
    errors.add :sequence_prefix, :taken if sequence_prefix.present? and ReceiptNumberSet.find(:first, 
      :conditions => "sequence_prefix = '#{sequence_prefix}'").present?
    errors.add :sequence_prefix, :must_be_alphanumeric if sequence_prefix.present? and sequence_prefix.to_i > 0
  end

  # validates if ReceiptNumberSet is linked with FinanceFeeCategory / FinanceTransactionCategory or TransactionReceipt
  def has_assignments?
    return (self.finance_category_receipt_sets.last or self.transaction_receipts.last).present?    
  end
    
end
