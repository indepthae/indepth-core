class TransportFeeFinanceTransaction < ActiveRecord::Base

  belongs_to :transport_fee
  belongs_to :finance_transaction
  belongs_to :parent, :class_name => 'TransportFeeFinanceTransaction'
  belongs_to :child, :foreign_key => :id, :primary_key => :parent_id, :class_name => 'TransportFeeFinanceTransaction', :conditions => 'id<>#{self.id}'
  has_many :children, :foreign_key => 'transport_fee_id', :primary_key => 'transport_fee_id', :class_name => 'TransportFeeFinanceTransaction', :conditions => 'id > #{self.id}'
  has_many :parents, :foreign_key => 'transport_fee_id', :primary_key => 'transport_fee_id', :class_name => 'TransportFeeFinanceTransaction', :conditions => 'id < #{self.id}'
  has_many :siblings, :foreign_key => 'transport_fee_id', :primary_key => 'transport_fee_id'

  validates_uniqueness_of :transport_fee_id, :scope => :finance_transaction_id
  before_save :set_transaction_data
  after_create :set_parent, :if => Proc.new { |h| h.parent.nil? }
  before_destroy :update_balance, :update_parent

  def has_parent?
    parent.present?
  end

  def has_children?
    children.present?
  end

  def is_root?
    id==parent_id
  end

  def previous_payments
    parents.sum(:transaction_amount).to_f
  end


  private

  def set_transaction_data
    self.transaction_amount=finance_transaction.amount.to_f
    self.transaction_balance= transport_fee.balance.to_f
  end

  def set_parent
    parent_id=parents.last.try(:id)
    self.update_attributes(:parent_id => parent_id||self.id)
  end

  def update_balance
    TransportFeeFinanceTransaction.update_all("transaction_balance=transaction_balance+#{transaction_amount}", "transport_fee_id=#{transport_fee_id} and id> #{id}")
  end

  def update_parent
    child_id= is_root? ? child.try(:id) : parent_id
    if child.present?
      child.update_attributes(:parent_id => child_id)
    end
  end

end
