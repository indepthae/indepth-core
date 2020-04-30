class PaymentRequest < ActiveRecord::Base
  #to save payment request parameters
  serialize :transaction_parameters

  has_many :payments

  validates_uniqueness_of :identification_token

  before_create :generate_identification_token
  before_create :set_is_processed_value

  def validate
    if transaction_parameters[:multi_fees_transaction]
      if transaction_parameters[:multi_fees_transaction]["wallet_amount_applied"] == "true"
        
      else
        m_amount = self.amount
        t_amount = 0
        self.transactions.map{|k,v| t_amount+=v["amount"].to_f}
        self.errors.add_to_base("amount don't match") unless precision_label(m_amount)==precision_label(t_amount)  
      end
    elsif transaction_parameters[:advance_fees_collection]
      return true
    end
  end

  def precision_label(val)
    precision_count ||= FedenaPrecision.get_precision_count
    return sprintf("%0.#{precision_count}f",val)
  end

  def amount #payment amount
    transaction_parameters[:multi_fees_transaction][:amount].to_f
  end

  def transactions # to get all the transactions - Parameters
    transaction_parameters[:multi_fees_transaction][:transactions]
  end

  def payee
    Student.find(transaction_parameters[:multi_fees_transaction][:student_id])
  end

  def student_id #to get student id
    transaction_parameters[:multi_fees_transaction][:student_id].to_i
  end

 def set_is_processed
		update_attribute(:is_processed,true)
  end

  def advance_fee_amount
    transaction_parameters[:advance_fees_collection][:fees_paid].to_f
  end


  def advance_fee_payee
    Student.find(transaction_parameters[:advance_fees_collection][:student_id])
  end

  def advance_fee_transaction
    transaction_parameters[:advance_fees_collection]
  end


  private

  def set_is_processed_value #to set default value
    self.is_processed = false
    true
  end

  def generate_identification_token
    self.identification_token = loop do
      random_token = rand(36**25).to_s(36) # url friendly tocken
      break random_token unless PaymentRequest.exists?(:identification_token=>random_token)
    end
  end

end
