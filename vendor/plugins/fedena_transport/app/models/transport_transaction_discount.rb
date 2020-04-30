class TransportTransactionDiscount < ActiveRecord::Base
  belongs_to :finance_transaction
  belongs_to :transport_fee_discount

  after_update :build_report_sync_job, :if => lambda { |x| x.is_active_changed? and !x.is_active }

  def deactivate
    finance_transaction.present? ? self.update_attribute('is_active', false) : self.destroy
  end

  def perform
    fetch_discount_and_reverse_sync
  end

  def build_report_sync_job
    ## Queue:: master_particular_reports
    ## change queue name only for testing purpose
    queue_name = 'master_particular_reports'
    # queue_name = 'master_particular_reports_test'
    Delayed::Job.enqueue(self, {:queue => queue_name}) if valid_for_sync
  end

  def valid_for_sync
    return false if is_active

    ft = self.finance_transaction
    trs = ft.transaction_report_sync
    transport_fee = ft.try(:finance)

    return (ft.present? and transport_fee.try(:receiver_type) == 'Student')
  end

  def fetch_discount_and_reverse_sync
    # should process only not an active record
    return unless valid_for_sync

    ft = self.finance_transaction
    transport_fee = ft.try(:finance)

    # ft = transport_transaction_discount.try(:finance_transaction)
    trs = ft.try(:transaction_report_sync)

    unless trs.present?
      mfp = MasterFeeParticular.find_by_particular_type 'TransportFee'
      search_data = {}
      search_data['date'] = "#{ft.transaction_date}"
      search_data['student_id'] = "#{ft.payee_id}"
      search_data['school_id'] = "#{ft.school_id}"
      search_data['batch_id'] = "#{transport_fee.groupable_id}"
      search_data['mode_of_payment'] = "#{ft.payment_mode}"
      search_data['fee_account_id'] = "#{ft.fee_account.try(:id)}"
      search_data['master_fee_particular_id'] = "#{mfp.id}"
      digest = calculate_crc(search_data)
      mpr = MasterParticularReport.find_by_digest digest
      if mpr.present?
        mpr.discount_amount -= discount_amount
        mpr.discount_amount = 0 if mpr.discount_amount < 0
        # destroy self when reverse sync is done

        TransactionReportSync.transaction do
          begin
            self.destroy if mpr.save
          rescue Exception => e
            puts e.inspect
            raise ActiveRecord::Rollback
          end
        end
      end
    end

  end

  def calculate_crc data
    str = ""
    TransactionReportSync::DIGEST_COLUMNS.each do |k|
      str += data[k]
    end
    TransactionReportSync.string_to_crc str
  end
end
