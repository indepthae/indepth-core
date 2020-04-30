class TransactionReceipt < ActiveRecord::Base
  belongs_to :fee_account
  belongs_to :fee_receipt_template
  belongs_to :receipt_number_set

  has_many :finance_transaction_receipt_records
  has_many :finance_transactions, :through => :finance_transaction_receipt_records
  
  serialize :receipt_data, Hash
  before_create :set_receipt_no
  attr_accessor :receipt_set
  #  validates_presence_of :receipt_number
  #  validates_numericality_of :receipt_number, :only_integer => true

  # request new receipt number and sets it to transaction receipt object
  def set_receipt_no
    self.receipt_sequence, self.receipt_number = TransactionReceipt.generate_receipt_no self.receipt_set
    self.ef_receipt_number = "#{self.receipt_sequence}#{self.receipt_number}"
  end

  # receipt no generation logic
  class << self

    def safely_create receipt_number_set = nil
      # puts "attempting to create transaction receipt"
      receipt = receipt_number_set.present? ? receipt_number_set.transaction_receipts.build : TransactionReceipt.new
      receipt.receipt_set = receipt_number_set
      begin
        retries ||= 0
        receipt.save #(*args)
      rescue ActiveRecord::StatementInvalid => ex
        retry if (retries += 1) < 4
        raise ex
      end
      # puts receipt.inspect
      return receipt
    end

    def generate_receipt_no receipt_set = nil
      _prefix, _zero_length, _suffix = TransactionReceipt.receipt_no_config receipt_set
      # fetch next available receipt number as per sequence series
      result = NumberSequence.generate_next_number(_suffix, _prefix, 'receipt_no')
      if result.present?
        suffix = result.first['next_number']
        if _zero_length > 0
          _zero_length = _zero_length - 1 unless _suffix.present?
          suffix = "%0#{_zero_length}d" % "#{suffix}" #suffix.to_s.rjust(_zero_length, '0')
        end
        [_prefix, suffix]
      end
    end

    # extracts prefix, suffix and zeros to be prefix after prefix
    # as per multi config/default (fallback) configuration for receipt number generation
    def receipt_no_config receipt_set
      multi_configs = FinanceTransactionCategory.get_multi_configuration
      # fetch series prefix and starting series number
      _prefix, _suffix = (multi_configs.present? and multi_configs[:receipt_set].present? and receipt_set.present?) ?
          [receipt_set.sequence_prefix, receipt_set.starting_number] : default_receipt_config
      # separate prefixed zeros from series number
      /([0]*)(\d*)$/.match(_suffix)
      _zeros, _suffix = $1.to_s, $2.to_s
      _zero_length = (_zeros + _suffix).length
      _suffix = _suffix.to_i
      [_prefix, _zero_length, _suffix]
    end


    # returns prefix and suffix as per default configuration for receipt number generation
    def default_receipt_config
      c_hsh =['FeeReceiptStartingNumber','FeeReceiptPrefix']
      config = Configuration.get_multiple_configs_as_hash c_hsh
      [config[:fee_receipt_prefix], config[:fee_receipt_starting_number]]
    end

    #fetch receipt number configuration of a transaction/fee category
    #based on multi/default configuration for receipt number generation
    def fetch_receipt_config category
      #      multi_configs = FinanceTransactionCategory.get_multi_configuration
      multi_configs = category.present? ? category.get_multi_config : {}
      return default_receipt_config if !(multi_configs.present? and multi_configs[:receipt_set].present?)
      return [multi_configs[:receipt_set].try(:sequence_prefix), multi_configs[:receipt_set].try(:starting_number)]
    end

    ##  OLD receipt number generation process ::
    #
    #
    #    def generate_receipt_no category = nil
    #      _prefix, _suffix = fetch_receipt_config category
    #      next_receipt_number=''
    #      if is_available_in_cache?
    #        next_receipt_number = calculate_receipt_number _prefix, _suffix
    #      else
    #        next_receipt_number = FeeReceiptLock.receipt_number_in_cache
    #      end
    #      # checking new receipt_no is present in cancel_transaction ,Else it will make duplicates while reverting last transaction
    #      check_receipt_number_existance(next_receipt_number)
    #    end
    #
    #    def calculate_receipt_number config_receipt_num_prefix, config_receipt_num_sufix
    #      #      config_receipt_no_format = Configuration.get_config_value('FeeReceiptNo').nil? ? "" : Configuration.get_config_value('FeeReceiptNo').delete(' ')
    #      #      config_receipt_number = /(.*?)(\d*)$/.match(config_receipt_no_format)
    #      #      config_receipt_num_prefix = config_receipt_number[1] =~ /^\d+$/ ? "" : config_receipt_number[1]
    #      #      config_receipt_num_sufix = config_receipt_number[2].to_i
    #      if config_receipt_num_prefix.present?
    #        finance_transaction_receipt_nos = transactions_with_similar_receipt_number(config_receipt_num_prefix)
    #        if finance_transaction_receipt_nos.present?
    #          last_receipt_number = finance_transaction_receipt_nos.map { |k| k.scan(/\d+$/i).last.to_i }.max
    #          next_receipt_no_sufix = last_receipt_number > config_receipt_num_sufix ? last_receipt_number : config_receipt_num_sufix
    #          next_receipt_number = config_receipt_num_prefix + next_receipt_no_sufix.next.to_s
    #        else
    #          next_prefix = config_receipt_num_sufix.present? ? config_receipt_num_sufix : 0
    #          next_receipt_number = config_receipt_num_prefix + next_prefix.to_s
    #        end
    #      else
    #        #code for manage no prefix(string) condition
    #        finance_transaction_receipts = []
    #        finance_transaction_receipts += FinanceTransactionLedger.search(
    #          :receipt_no_not_like => "refund",
    #          :receipt_no_greater_than => config_receipt_num_sufix.to_i).all.map(&:receipt_no)
    #        finance_transaction_receipts += FinanceTransaction.search(
    #          :receipt_no_not_like => "refund",
    #          :receipt_no_greater_than => config_receipt_num_sufix.to_i).all.map(&:receipt_no)
    #        if finance_transaction_receipts.present?
    #          last_receipt_number = finance_transaction_receipts.map { |k| k.to_i }.max
    #          # to find maximum value of receipt no
    #          next_receipt_number = last_receipt_number.next
    #        else
    #          # for the first transaction it will count from 1  else it will count from suffix.
    #          next_receipt_number = config_receipt_num_sufix.present? ? config_receipt_num_sufix.next : 1
    #        end
    #      end
    #      next_receipt_number
    #    end
    #
    #    def is_available_in_cache?
    #      !FeeReceiptLock.cache_has_receipt_no?
    #    end
    #
    #    def transactions_with_similar_receipt_number(config_receipt_num_prefix)
    #      transaction_receipt_nos = []
    #      transaction_receipt_nos += (FinanceTransactionLedger.all(:conditions => "receipt_no IS NOT NULL and
    #                                                                        receipt_no REGEXP '(#{config_receipt_num_prefix})\d*' and
    #                                                                        receipt_no NOT LIKE 'refund%'#")).map(&:receipt_no)
    #      transaction_receipt_nos += (FinanceTransaction.all(:conditions => "receipt_no IS NOT NULL and
    #                                                              receipt_no REGEXP '(#{config_receipt_num_prefix})\d*' and
    #                                                              receipt_no NOT LIKE 'refund%'#")).map(&:receipt_no)
    #      transaction_receipt_nos.compact!
    #      return transaction_receipt_nos if transaction_receipt_nos.present?
    #    end
    #
    #    def check_receipt_number_existance(next_receipt_number)
    #      updated_receipt_number = check_receipt_number_in_cancel_transaction(next_receipt_number)
    #      FeeReceiptLock.receipt_no(updated_receipt_number)
    #    end
    #
    #    def check_receipt_number_in_cancel_transaction(receipt_number)
    #      cancel_transaction = CancelledFinanceTransaction.find_last_by_receipt_no(receipt_number)
    #      if cancel_transaction.nil?
    #        return receipt_number
    #      else
    #        data = /(.*?)(\d*)$/.match(receipt_number.to_s)
    #        receipt_number = data[1].to_s + data[2].next.to_s
    #        check_receipt_number_in_cancel_transaction(receipt_number)
    #      end
    #    end

  end
end
