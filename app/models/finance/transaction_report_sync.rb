require 'zlib'
class TransactionReportSync < ActiveRecord::Base
  # Its a report sync marker for tracking which FinanceTransaction are synced to MasterParticularReport
  # it also is used to track back if CancelledFinanceTransaction is reverse synced from MasterParticularReport
  belongs_to :transaction, :polymorphic => true

  TRANSACTION_TYPES_TO_SYNC = ['FinanceFee', 'HostelFee', 'TransportFee', 'InstantFee', 'RegistrationCourse'].freeze
  SYNC_STATUS = ['SYNCED', 'NOT_SYNCED'].freeze
  DIGEST_COLUMNS = ['date', 'master_fee_particular_id', 'fee_account_id', 'student_id', 'batch_id', 'mode_of_payment',
                    'collection_type', 'collection_id', 'school_id'].freeze

  after_create :build_report_sync_job, :if => Proc.new { |trs| trs.valid_for_sync }


  def perform
    @logger = Logger.new('log/master_particular_report_job.log')
    update_report unless destroyed?
  end

  def job_run_at
    5.minutes.from_now
  end

  def job_queue_name
    'finance_report'
  end

  def sync_status
    if transaction.present?
      transaction.is_a?(FinanceTransaction) ? 'NOT_SYNCED' : transaction.is_a?(CancelledFinanceTransaction) ? 'SYNCED' : false
    else
      false
    end
  end

  def update_report_record particular_data, sync_type
    @log = Logger.new('log/transaction_report_sync_log.log')
    report_cols = ['date', 'master_fee_particular_id', 'fee_account_id', 'student_id', 'batch_id',
                   'collection_type', 'collection_id', 'mode_of_payment', 'amount', 'school_id',
                   'tax_amount', 'discount_amount', 'digest'].freeze
    # discount_report_cols = ['date', 'master_fee_discount_id', 'student_id', 'batch_id',
    #                'collection_type', 'collection_id', 'amount', 'school_id', 'digest'].freeze
    crc_cols = DIGEST_COLUMNS
    fine = 0
    rec_count = 0
    # discount_rec_count = 0
    if sync_type == 'NOT_SYNCED' # sync operation
      # MasterParticularReport.transaction do
      particular_data.each_with_index do |_data, i|
        fine = _data['fine_amount'] if i == 0
        _data = _data.slice *report_cols # selecting only report columns
        # _discount_data = _data.slice *discount_report_cols # selecting only report columns

        rec = MasterParticularReport.new _data
        # discount_rec = MasterDiscountReport.new _discount_data

        valid_data = rec.amount.to_f > 0 || rec.discount_amount.to_f > 0 || rec.tax_amount.to_f > 0
        unless (rec.save rescue nil)
          rec = get_master_particular_report(_data)
          # acquire row lock and perform update
          if rec.present?
            rec.with_lock do
              rec.amount += _data['amount'].to_f
              rec.tax_amount += _data['tax_amount'].to_f
              rec.discount_amount += _data['discount_amount'].to_f
              rec.save
            end
            rec_count += 1
          else
            @log.info rec.inspect
            @log.info "*********************************************************"
          end  
        end if valid_data

        # unless rec.new_record?
        #   unless (discount_rec.save rescue nil)
        #     discount_rec = MasterDiscountReport.find_by_digest _discount_data['digest']
        #     discount_rec.amount += _discount_data['amount'].to_f
        #     discount_rec.save
        #     discount_rec_count += 1
        #   end
        # end if valid_data and rec.discount_amount.to_f > 0

        # attempting for updating report for fine
        next if i > 0 or fine == 0
        if fine > 0
          fine_master_particular = MasterFeeParticular.find_by_name 'Fine'
          # prevent for using wrong particular id and messing up particular report data
          unless fine_master_particular.present?
            self.record_error "MasterFeeParticular for fine not found"
            raise ActiveRecord::Rollback
          end

          _data['master_fee_particular_id'] = fine_master_particular.id
          _data['amount'] = fine.to_f
          _data['tax_amount'] = _data['discount_amount'] = 0
          # update digest for fine record
          _data['digest'] = calculate_crc(_data, crc_cols)

          fine_rec = MasterParticularReport.new _data
          unless (fine_rec.save rescue nil)
            fine_rec = get_master_particular_report(_data)
            # acquire row lock and perform update
            fine_rec.with_lock do
              fine_rec.amount += _data['amount'].to_f
              fine_rec.save
            end if fine_rec.present?
          else
            @log.info fine_rec.inspect
            @log.info "*********************************************************"
          end  
        end
      end
      ## delete trs
      # end
    elsif sync_type == 'SYNCED' # reverse sync
      # MasterParticularReport.transaction do
      particular_data.each_with_index do |_data, i|
        fine = _data['fine_amount'] if i == 0
        # _data = _data.except('ft_id')
        _data = _data.slice *report_cols
        rec = get_master_particular_report(_data)
        # acquire row lock and perform update
          rec.with_lock do
            rec.amount -= _data['amount'].to_f
            rec.tax_amount -= _data['tax_amount'].to_f
            rec.discount_amount -= _data['discount_amount'].to_f

            #fix for negative values
            rec.amount = 0 if rec.amount < 0
            rec.tax_amount = 0 if rec.tax_amount < 0
            rec.discount_amount = 0 if rec.discount_amount < 0
            if rec.amount.to_f <= 0.to_f #&& rec.tax_amount.to_f == 0 && rec.discount_amount.to_f == 0
              rec.destroy
            else
              rec.save
            end
          end if rec.present?

        # attempting for updating report for fine
        next if i > 0 or fine == 0

        if fine > 0
          fine_master_particular = MasterFeeParticular.find_by_name 'Fine'
          # prevent for using wrong particular id and messing up particular report data
          unless fine_master_particular.present?
            self.record_error "MasterFeeParticular for fine not found"
            raise ActiveRecord::Rollback
          end

          _data['master_fee_particular_id'] = fine_master_particular.id
          _data['amount'] = fine.to_f
          _data['tax_amount'] = _data['discount_amount'] = 0
          # update digest for fine record
          _data['digest'] = calculate_crc(_data, crc_cols)

          fine_rec = get_master_particular_report(_data)
          # acquire row lock and perform update
            fine_rec.with_lock do
              fine_rec.amount -= _data['amount'].to_f
              #remove if records having 0 amount
              if fine_rec.amount.to_f <= 0.to_f
                fine_rec.destroy
              else
                fine_rec.save
              end
            end if fine_rec.present?
        end

      end
      # end
    end
  end

  def flush_records sync_type
    self.transaction.delete_inactive_finance_payment_data if sync_type == 'SYNCED' #&& self.transaction.finance_type == 'FinanceFee'
    self.destroy ## deleting after sync is completed
  end

  def calculate_crc data, cols
    data_str = ""
    cols.each do |k|
      data_str += data[k].to_s
    end
    # digest as CRC value
    Zlib::crc32 data_str
  end

  def update_report options = {}

    return unless valid_for_sync

    tr_rec = self.transaction
    sync_type = sync_status
    TransactionReportSync.transaction do
      begin
        if tr_rec.present? and sync_type
          tr_type = tr_rec.finance_type
          # tr_id = actual_transaction_id

          ## TO DO :: also add cases for fine as a particular from finance transactions
          particular_data = send "fetch_#{tr_type.underscore}_master_particular_data"
          update_report_record particular_data, sync_type
          # self.destroy ## deleting after sync is completed
          flush_records sync_type
        else ## TODO :: delete this transaction_report_sync record
          # self.destroy
          flush_records sync_type
        end
      rescue Exception => e
        @logger.info(e.inspect)

        record_error "#{e}"
        raise ActiveRecord::Rollback
      end
    end
  end

  def record_error error
    self.last_error = error
    self.failed_at = DateTime.now.utc
    self.save
  end

  def finance_transaction_id
    transaction.is_a?(FinanceTransaction) ? transaction.id : transaction.is_a?(CancelledFinanceTransaction) ?
        transaction.finance_transaction_id : nil
  end

  # Finance Fee
  def fetch_finance_fee_master_particular_data options = {}
    tran_id = finance_transaction_id
    fee_id = transaction.finance_id
    klass = transaction_type.constantize
    tbl_name = klass.table_name
    is_fine_only = (transaction.amount - transaction.fine_amount).to_f == 0.0
    mfp = MasterFeeParticular.fine.try(:last)
    ## raise if transaction is fine only and there is fine master particular found

    if is_fine_only and !mfp
      @logger.info("TRS:#{self.id} :: Master Particular for fine not found")
      raise "Master Particular for fine not found"
    end
    is_active = transaction_type == 'FinanceTransaction'
    filtered_options = options.slice(:joins, :conditions)
    filtered_options[:joins] ||= ""
    filtered_options[:conditions] ||= [""]
    filtered_options[:conditions][0] += " AND " if filtered_options[:conditions][0].length > 0
    filtered_options[:conditions][0] += "#{tbl_name}.#{transaction_type == 'FinanceTransaction' ? 'id' : 'finance_transaction_id'} = ?"
    filtered_options[:conditions] << tran_id
    filtered_options[:joins] += " INNER JOIN finance_transaction_receipt_records ftrr
                                        ON ftrr.finance_transaction_id = #{tran_id}
                                  INNER JOIN finance_fees ff ON ff.id = #{fee_id} "
    filtered_options[:joins] += "INNER JOIN particular_payments pp ON pp.finance_transaction_id = #{tran_id}
                           LEFT JOIN particular_discounts pd ON pd.particular_payment_id = pp.id
                          INNER JOIN finance_fee_particulars ffp ON ffp.id = pp.finance_fee_particular_id
                           LEFT JOIN tax_payments tp
                                  ON tp.taxed_entity_id = ffp.id AND tp.taxed_entity_type = 'FinanceFeeParticular' AND
                                     tp.taxed_fee_id = ff.id AND tp.taxed_fee_type = 'FinanceFee' AND tp.is_active = #{is_active}
                          INNER JOIN master_fee_particulars mfp ON mfp.id = ffp.master_fee_particular_id " unless is_fine_only
    filtered_options[:select] = "#{tbl_name}.transaction_date date, 'FinanceFeeCollection' AS collection_type,
                                 ff.fee_collection_id AS collection_id, "
    filtered_options[:select] += is_fine_only ? "#{mfp.id} master_fee_particular_id," : "mfp.id AS master_fee_particular_id,"
    filtered_options[:select] += " ftrr.fee_account_id, payee_id AS student_id, ff.batch_id batch_id, #{tbl_name}.payment_mode mode_of_payment,
                                 #{tran_id} ft_id, IFNULL(#{tbl_name}.fine_amount,0) AS fine_amount,"
    filtered_options[:select] += is_fine_only ? "0 amount, 0 discount_amount, 0 tax_amount," :
        "GREATEST(SUM(pp.amount) - SUM(IFNULL(pd.discount,0)) + SUM(IFNULL(tp.tax_amount,0)),0) amount,
                                 SUM(IFNULL(pd.discount,0)) discount_amount, SUM(IFNULL(tp.tax_amount,0)) tax_amount,"
    filtered_options[:select] += "#{tbl_name}.school_id, CRC32(concat(#{tbl_name}.transaction_date,"
    filtered_options[:select] += is_fine_only ? "#{mfp.id}," : "mfp.id,"
    filtered_options[:select] += "IFNULL(ftrr.fee_account_id,''), payee_id, ff.batch_id, payment_mode, 'FinanceFeeCollection',
                                  ff.fee_collection_id, #{tbl_name}.school_id)) digest"

    filtered_options[:group] = "date, master_fee_particular_id, fee_account_id, student_id, batch_id, payment_mode, school_id"

    data = klass.all(filtered_options)
    data = data.map(&:attributes)

    return data
  end

  # Transport Fee
  def fetch_transport_fee_master_particular_data options = {}

    tran_id = finance_transaction_id
    fee_id = transaction.finance_id
    klass = transaction_type.constantize
    tbl_name = klass.table_name
    is_fine_only = (transaction.amount - transaction.fine_amount).to_f == 0.0
    mfp = MasterFeeParticular.fine.try(:last)
    ## raise if transaction is fine only and there is fine master particular found

    if is_fine_only and !mfp
      @logger.info("TRS:#{self.id} :: Master Particular for fine not found")
      raise "Master Particular for fine not found"
    end

    is_active = transaction_type == 'FinanceTransaction'
    filtered_options = options.slice(:joins, :conditions)
    filtered_options[:joins] ||= ""
    filtered_options[:conditions] ||= [""]
    filtered_options[:conditions][0] += " AND " if filtered_options[:conditions][0].length > 0
    filtered_options[:conditions][0] += "#{tbl_name}.#{transaction_type == 'FinanceTransaction' ? 'id' : 'finance_transaction_id'} = ?"
    filtered_options[:conditions] << tran_id
    filtered_options[:joins] += " INNER JOIN finance_transaction_receipt_records ftrr
                                        ON ftrr.finance_transaction_id = #{tran_id}
                          INNER JOIN transport_fees tf ON tf.id = #{tbl_name}.finance_id"
    filtered_options[:joins] += " INNER JOIN transport_fee_collections tfc ON tfc.id = tf.transport_fee_collection_id
                           LEFT JOIN tax_payments tp ON tp.taxed_fee_id = tf.id AND tp.taxed_fee_type = 'TransportFee' and tp.is_active = #{is_active}
                          INNER JOIN master_fee_particulars mfp ON mfp.id = tfc.master_fee_particular_id"  #unless is_fine_only
    filtered_options[:joins] += " LEFT JOIN transport_transaction_discounts ttd
                                         ON ttd.finance_transaction_id = #{tran_id} and ttd.is_active = #{is_active}"

    filtered_options[:select] = "#{tbl_name}.transaction_date date, 'TransportFeeCollection' AS collection_type,
                                 tf.transport_fee_collection_id AS collection_id, mfp.id AS master_fee_particular_id,
                                 ftrr.fee_account_id, payee_id AS student_id, tf.groupable_id batch_id,
                                 #{tbl_name}.payment_mode mode_of_payment, #{tran_id} ft_id,
                                 IFNULL(#{tbl_name}.fine_amount,0) AS fine_amount,"
    # filtered_options[:select] += is_fine_only ? "0 amount, 0 discount_amount, 0 tax_amount," :
    #     "SUM(#{tbl_name}.amount - IFNULL(#{tbl_name}.fine_amount,0)) AS amount,
    #                              SUM(IFNULL(ttd.discount_amount,0)) AS discount_amount,
    #                              SUM(round(IFNULL(tp.tax_amount,0), ftrr.precision_count)) tax_amount,"
    filtered_options[:select] += "(#{tbl_name}.amount - IFNULL(#{tbl_name}.fine_amount,0)) AS amount,
                                  SUM(IFNULL(ttd.discount_amount,0)) AS discount_amount,
                                  (round(IFNULL(tp.tax_amount,0), ftrr.precision_count)) tax_amount,"
    filtered_options[:select] += " #{tbl_name}.school_id, CRC32(concat(#{tbl_name}.transaction_date,"
    filtered_options[:select] += is_fine_only ? "#{mfp.id}," : "mfp.id,"
    filtered_options[:select] += "IFNULL(ftrr.fee_account_id,''), payee_id, tf.groupable_id, payment_mode, 'TransportFeeCollection',
                                  tf.transport_fee_collection_id, #{tbl_name}.school_id)) digest"

    filtered_options[:group] = "tf.id"
    # filtered_options[:group] = "date, master_fee_particular_id, fee_account_id, student_id, batch_id, payment_mode, school_id"

    data = klass.all(filtered_options)
    _data = []
    data.each do |d|
      _attr = d.attributes
      # _attr['amount'] = d['net_amount'].to_f - d['discount_amount'].to_f + d['tax_amount'].to_f
      _data << _attr
    end
    return _data
  end

  # Hostel Fee
  def fetch_hostel_fee_master_particular_data options = {}
    tran_id = finance_transaction_id
    fee_id = transaction.finance_id
    klass = transaction_type.constantize
    tbl_name = klass.table_name
    is_fine_only = (transaction.amount - transaction.fine_amount).to_f == 0.0
    mfp = MasterFeeParticular.fine.try(:last)
    ## raise if transaction is fine only and there is fine master particular found

    if is_fine_only and !mfp
      @logger.info("TRS:#{self.id} :: Master Particular for fine not found")
      raise "Master Particular for fine not found"
    end

    is_active = transaction_type == 'FinanceTransaction'
    filtered_options = options.slice(:joins, :conditions)
    filtered_options[:joins] ||= ""
    filtered_options[:conditions] ||= [""]
    filtered_options[:conditions][0] += " AND " if filtered_options[:conditions][0].length > 0
    filtered_options[:conditions][0] += "#{tbl_name}.#{transaction_type == 'FinanceTransaction' ? 'id' : 'finance_transaction_id'} = ?"
    filtered_options[:conditions] << tran_id
    filtered_options[:joins] += " INNER JOIN finance_transaction_receipt_records ftrr
                                          ON ftrr.finance_transaction_id = #{tran_id}
                                  INNER JOIN hostel_fees hf ON hf.id = #{tbl_name}.finance_id"
    filtered_options[:joins] += " INNER JOIN hostel_fee_collections hfc ON hfc.id = hf.hostel_fee_collection_id
                                   LEFT JOIN tax_payments tp ON tp.taxed_fee_id = hf.id AND tp.taxed_fee_type = 'HostelFee' AND tp.is_active = #{is_active}
                                  INNER JOIN master_fee_particulars mfp ON mfp.id = hfc.master_fee_particular_id" unless is_fine_only

    filtered_options[:select] = "#{tbl_name}.transaction_date date, 'HostelFeeCollection' AS collection_type,
                                 hf.hostel_fee_collection_id AS collection_id, "
    filtered_options[:select] += "mfp.id AS master_fee_particular_id, "
    filtered_options[:select] += "ftrr.fee_account_id, payee_id AS student_id, hf.batch_id batch_id, #{tbl_name}.payment_mode mode_of_payment,
                                 #{tran_id} ft_id, IFNULL(#{tbl_name}.fine_amount,0) AS fine_amount,"
    filtered_options[:select] += is_fine_only ? "0 amount, 0 discount_amount, 0 tax_amount," :
        "SUM(#{tbl_name}.amount - IFNULL(#{tbl_name}.fine_amount,0)) AS amount, 0 AS discount_amount,
                                 SUM(IFNULL(tp.tax_amount,0)) tax_amount,"
    filtered_options[:select] += " #{tbl_name}.school_id, CRC32(concat(#{tbl_name}.transaction_date,"
    filtered_options[:select] += is_fine_only ? "#{mfp.id}," : "mfp.id,"
    filtered_options[:select] += "IFNULL(ftrr.fee_account_id,''), payee_id, hf.batch_id, payment_mode, 'HostelFeeCollection',
                                  hf.hostel_fee_collection_id, #{tbl_name}.school_id)) digest"

    filtered_options[:group] = "date, master_fee_particular_id, fee_account_id, student_id, batch_id, payment_mode, school_id"
    data = klass.all(filtered_options)
    data = data.map(&:attributes)

    return data
  end

  # Instant Fee
  def fetch_instant_fee_master_particular_data options = {}
    tran_id = finance_transaction_id
    fee_id = transaction.finance_id
    klass = transaction_type.constantize
    tbl_name = klass.table_name
    filtered_options = options.slice(:joins, :conditions)
    filtered_options[:joins] ||= ""
    filtered_options[:conditions] ||= [""]
    filtered_options[:conditions][0] += " AND " if filtered_options[:conditions][0].length > 0
    filtered_options[:conditions][0] += "#{tbl_name}.#{transaction_type == 'FinanceTransaction' ? 'id' : 'finance_transaction_id'} = ?"
    filtered_options[:conditions][0] += " AND #{tbl_name}.payee_type = 'Student'"
    filtered_options[:conditions] << tran_id
    # INNER JOIN instant_fees i_f ON i_f.id = #{tbl_name}.finance_id
    filtered_options[:joins] += " INNER JOIN finance_transaction_receipt_records ftrr
                                        ON ftrr.finance_transaction_id = #{tran_id}
                          INNER JOIN instant_fee_details ifd ON ifd.instant_fee_id = #{tbl_name}.finance_id
                          INNER JOIN master_fee_particulars mfp ON mfp.id = ifd.master_fee_particular_id"
    filtered_options[:select] = "#{tbl_name}.transaction_date date, 'InstantFee' AS collection_type,
                                 ifd.instant_fee_id AS collection_id, mfp.id AS master_fee_particular_id, ftrr.fee_account_id,
                                 #{tbl_name}.payee_id AS student_id, #{tbl_name}.batch_id batch_id,
                                 #{tbl_name}.payment_mode mode_of_payment, #{tran_id} ft_id, 0 AS fine_amount,
                                 SUM(ifd.net_amount) amount,
                                 SUM(ifd.amount - IFNULL(ifd.net_amount,0) + IFNULL(ifd.tax_amount,0)) discount_amount,
                                 SUM(IFNULL(ifd.tax_amount,0)) tax_amount, #{tbl_name}.school_id,
                                 CRC32(concat(#{tbl_name}.transaction_date, mfp.id, IFNULL(ftrr.fee_account_id,''),
                                              #{tbl_name}.payee_id, #{tbl_name}.batch_id, payment_mode,
                                       'InstantFee', ifd.instant_fee_id, #{tbl_name}.school_id)) digest"
    filtered_options[:group] = "date, master_fee_particular_id, fee_account_id, student_id, batch_id, payment_mode, 'InstantFee',
                                ifd.instant_fee_id, school_id"

    data = klass.all(filtered_options)
    data = data.map(&:attributes)

    return data
  end

  # Applicant Fee
  # Note(1):: this sync will be triggered only after an applicant is alloted to a batch and a student record is created
  # Note(2):: this also depends on presence of student id in applicant record,
  #           since otherwise we cannot uniquely identify a student just based on name and batch id of student
  def fetch_registration_course_master_particular_data
    options = {}
    tran_id = finance_transaction_id
    fee_id = transaction.finance_id
    klass = transaction_type.constantize
    tbl_name = klass.table_name
    filtered_options = options.slice(:joins, :conditions)
    filtered_options[:joins] ||= ""
    filtered_options[:conditions] ||= [""]
    filtered_options[:conditions][0] += " AND " if filtered_options[:conditions][0].length > 0
    filtered_options[:conditions][0] += "#{tbl_name}.id = ?"
    filtered_options[:conditions] << tran_id
    filtered_options[:joins] += " INNER JOIN finance_transaction_receipt_records ftrr
                                        ON ftrr.finance_transaction_id = #{tran_id}
                          INNER JOIN registration_courses rc ON rc.id = #{tbl_name}.finance_id
                          INNER JOIN applicants a ON a.id = #{tbl_name}.payee_id
                          INNER JOIN master_fee_particulars mfp ON mfp.id = rc.master_fee_particular_id"
    filtered_options[:select] = "#{tbl_name}.transaction_date date, 'RegistrationCourse' AS collection_type,
                                 rc.id AS collection_id, mfp.id AS master_fee_particular_id, ftrr.fee_account_id,
                                 a.student_id AS student_id, a.batch_id batch_id,
                                 #{tbl_name}.payment_mode mode_of_payment, #{tran_id} ft_id, 0 AS fine_amount,
                                 rc.amount amount, 0 AS discount_amount, 0 AS tax_amount, #{tbl_name}.school_id,
                                 CRC32(concat(#{tbl_name}.transaction_date, mfp.id, IFNULL(ftrr.fee_account_id,''),
                                              a.student_id, a.batch_id, payment_mode, 'RegistrationCourse',
                                       rc.id, #{tbl_name}.school_id)) digest"

    data = klass.all(filtered_options)
    data = data.map(&:attributes)

    return data
  end

  def build_report_sync_job
    ## Queue:: master_particular_reports
    ## change queue name only for testing purpose
    # queue_name = 'master_particular_reports_test'

    ## NOTE:: Disabling queue and adding row lock mechanism
    # queue_name = 'master_particular_reports'
    # Delayed::Job.enqueue(self, {:queue => queue_name}) if valid_for_sync

    Delayed::Job.enqueue(self) if valid_for_sync
  end

  def valid_for_sync
    finance_transaction = self.transaction
    finance_transaction_id = finance_transaction.send transaction_type == 'FinanceTransaction' ? :id : :finance_transaction_id
    is_active_data = (transaction_type == 'FinanceTransaction')
    return false unless finance_transaction
    is_fine_only = (finance_transaction.amount - finance_transaction.fine_amount).to_f == 0
    if TRANSACTION_TYPES_TO_SYNC.include?(finance_transaction.finance_type)
      fee_type = finance_transaction.finance_type
      fee_id = finance_transaction.finance_id
      payee_type = finance_transaction.payee_type
      payee_id = finance_transaction.payee_id
      tbl_name = self.transaction_type.tableize
      case fee_type
        when 'FinanceFee'
          # fine only paid transaction
          return !(finance_transaction.finance.finance_fee_particulars.map(&:master_fee_particular_id).include?(nil)) if is_fine_only

          return (ParticularPayment.count(:conditions => ["ffp.master_fee_particular_id IS NOT NULL and finance_transaction_id = ?
                                                           and is_active = ?", finance_transaction_id, is_active_data],
                                          :joins => "INNER JOIN finance_fee_particulars ffp
                                 ON ffp.id = particular_payments.finance_fee_particular_id") > 0)
        when 'InstantFee'
          return false unless FedenaPlugin.can_access_plugin? 'fedena_instant_fee'
          res = InstantFeeDetail.all(:select => "IF(count(instant_fee_details.id) =
                                                    sum(IF(instant_fee_details.master_fee_particular_id IS NOT NULL,1,0)),
                                                    true,false) as if_valid",
                                     # :joins => "INNER JOIN instant_fees i_f ON i_f.id = instant_fee_details.instant_fee_id",
                                     :joins => "INNER JOIN #{tbl_name} tr ON tr.id = #{transaction_id} AND tr.payee_type = 'Student'",
                                     :group => "instant_fee_id",
                                     :conditions => ["instant_fee_id = ?", fee_id])
          return (res.present? ? res.try(:first).try(:if_valid).to_i == 1 : false)
        # return (InstantFeeDetail.count(:conditions => ["instant_fee_details.master_fee_particular_id IS NOT NULL AND
        #                                                 i_f.payee_type = 'Student' AND i_f.id = ?", fee_id],
        #                                :joins => "INNER JOIN instant_fees i_f ON i_f.id = instant_fee_details.instant_fee_id") > 0)
        when 'TransportFee'
          return false unless FedenaPlugin.can_access_plugin? 'fedena_transport'
          return (TransportFeeCollection.count(:conditions => ["transport_fee_collections.master_fee_particular_id IS NOT NULL AND
                                                                tf.id = ? AND tf.receiver_type = 'Student'", fee_id],
                                               :joins => "INNER JOIN transport_fees tf
                                            ON tf.transport_fee_collection_id = transport_fee_collections.id") > 0)
        when 'HostelFee'
          return false unless FedenaPlugin.can_access_plugin? 'fedena_hostel'
          return (HostelFeeCollection.count(:conditions => ["hostel_fee_collections.master_fee_particular_id IS NOT NULL"],
                                            :joins => "INNER JOIN hostel_fees tf ON tf.id = #{fee_id} AND
                                                    tf.hostel_fee_collection_id = hostel_fee_collections.id") > 0)
        when 'RegistrationCourse'
          ## Trigger happens only when applicant is admitted / alloted
          # return false unless FedenaPlugin.can_access_plugin? 'fedena_applicant_registration'
          return Applicant.last(:conditions => ["applicants.id = ? AND student_id IS NOT NULL AND
                                                 registration_courses.master_fee_particular_id IS NOT NULL", payee_id],
                                :joins => :registration_course).present?
        # return false
        # return (RegistrationCourse.last(:conditions => ['registration_courses.id = ? AND
        #                                                  registration_courses.master_fee_particular_id IS NOT NULL',
        #                                                 fee_id]).present?)
        else
          return false
      end
    end
    return false
  end

  class << self
    def string_to_crc str
      Zlib::crc32 str
    end

    def create_for_transaction transaction
      return true if transaction.transaction_report_sync.present?

      permitted_finance_types = ['FinanceFee', 'TransportFee', 'HostelFee', 'InstantFee', 'RegistrationCourse']
      return unless permitted_finance_types.include?(transaction.finance_type)

      trs = transaction.build_transaction_report_sync({:is_income => transaction.category.is_income})
      return if !trs.valid_for_sync && transaction.finance_type != 'RegistrationCourse'

      trs.save
    end

    def trigger_report_sync_job transaction
      if transaction.present?
        trs = transaction.transaction_report_sync
        ## TO DO :: add code to create a job for report updation
        if trs.present?
          trs.build_report_sync_job if trs.valid_for_sync
        end
      end
    end
    
    def get_master_particular_report(rec)
      MasterParticularReport.find_by_digest_and_student_id_and_collection_id_and_collection_type(rec[:digest], rec[:student_id], rec[:collection_id], rec[:collection_type])
    end
    
  end

end
