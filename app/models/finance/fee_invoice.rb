require 'logger'
class FeeInvoice < ActiveRecord::Base
  # Generally we never destroy a fee invoice once generated

  belongs_to :fee, :polymorphic => true
  validates_presence_of :invoice_number, :fee_id, :fee_type
  
  #  before_create :generate_invoice_no
  attr_accessor :invoice_configuration
  serialize :invoice_data
  include FeeReceiptMod  
  
  # check if collection has existing fee invoices
  # method can fetch only if collection has atleast 1 fee record present
  def self.is_generated_for_collection?(collection,is_active=nil)
    collection_name = collection.class.name    
    fee_model_name = collection_name.gsub("Collection","")
    fee_name = fee_model_name.underscore
    fee_type = fee_name.pluralize    
    fee_name = "fee" if fee_name == 'finance_fee'
    conditions = {:fee_type => fee_model_name}
    conditions = conditions.merge({:is_active => is_active}) unless is_active.nil?
    invoice = FeeInvoice.last(:conditions => conditions,
      :joins => "INNER JOIN #{fee_type} ff 
                                  ON ff.#{fee_name}_collection_id = #{collection.id} and 
                                        ff.id = fee_invoices.fee_id")
    invoice.present?
  end
  
  # marks fee invoice record as deleted and stores last state of fee structure
  def mark_deleted    
    get_student_invoice(self.fee,self.fee_type.underscore.pluralize)
    self.update_attributes({:is_active => false, :invoice_data => @inv_data})
  end
    
  def self.create_with_failsafe fee, invoice_no_config = nil, retries = 5
    # fail safe can be ommited now, since NumberSequence always gives a unique non-conflicting number
    log = Logger.new('log/failed_invoices.log')
    invoice = fee.fee_invoices.new
    r = 0
    while r < retries      
      begin        
        invoice.generate_invoice_no invoice_no_config
        break if invoice.save
      rescue ActiveRecord::StatementInvalid => e    
      rescue Exception => e
        log.info(e.inspect)
        break 
      end
      r = r.next
    end
    if invoice.new_record?
      log.info("retry_attempts: #{r}; fee_id: #{fee.id}; fee_type: #{fee.class.name}; school_id: #{fee.school_id};") 
      log.info("fee record: #{fee.inspect}")
      log.info("invoice_errors: #{invoice.errors.inspect}")
    end
  end
  
  def self.invoice_config
    _config = Configuration.get_config_value('FeeInvoiceNo').try(:strip) || ""
    /(.*?)([0]*)(\d*)$/.match(_config)
    _prefix, _zeros, _suffix = $1.to_s, $2.to_s, $3.to_s
    _zero_length = (_zeros + _suffix).length
    _suffix = _suffix.to_i
    [_prefix, _zero_length, _suffix]
  end
  
  def generate_invoice_no invoice_no_format
    _prefix, _zero_length, _suffix = (invoice_no_format || FeeInvoice.invoice_config)
    result = NumberSequence.generate_next_number(_suffix, _prefix, 'invoice_no')
    if result.present?
      suffix = result.first['next_number']
      if _zero_length > 0
        _zero_length = _zero_length - 1 unless _suffix.present?
        suffix = "%0#{_zero_length}d" % "#{suffix}" #suffix.to_s.rjust(_zero_length, '0') 
      end
      self.invoice_number = "#{_prefix}#{suffix}" if suffix.present?
    end    
  end
  
end
