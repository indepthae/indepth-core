class DelayedCollectionMasterParticularReport < Struct.new(:op_type, :object, :object_args)
  ########################################
  ## initialize / new expects 3 parameters
  # op_type     -> insert (adding new records to CollectionMasterParticularReport)
  #             -> remove (removes records from CollectionMasterParticularReport)
  # object      -> FinanceFee / FeeDiscount / FinanceFeeParticular / HostelFee / TransportFee / TransportFeeDiscount
  # object_args -> collection information for a fee / particular / discount when removed for reverse sync
  #                of CollectionMasterParticularReport
  ########################################


  def perform
    @logger = Logger.new('log/delayed_job.log')
    @object_args = object_args || {}
    @object = object
    if op_type == 'insert'
      insert_fee_data
    elsif op_type == 'remove'
      remove_fee_data
    else
      # error
    end
  end

  def job_run_at
    5.minutes.from_now
  end

  def job_queue_name
    'finance_report'
  end

  # inserts new records to CollectionMasterParticularReport
  def insert_fee_data
    # @logger.info @object.inspect
    # @logger.info @object_args.inspect
    # res = has_master_particular_id
    # @logger.info "insert has_master_particular_id : #{res.try(:id)}"
    CollectionMasterParticularReport.build_and_record_data(@object, @object_args) if has_master_particular_id
  end

  # removes / substracts amounts from CollectionMasterParticularReport records
  def remove_fee_data
    # @logger.info @object.inspect
    # @logger.info @object_args.inspect
    # res = has_master_particular_id
    # @logger.info "remove has_master_particular_id : #{res}"
    CollectionMasterParticularReport.remove_and_update_records(@object, @object_args) #if res
  end

  # Verify if created / destroyed object is linked
  # with master particular for associated collection
  def has_master_particular_id
    klass = @object.class.name

    (case klass
       when 'FinanceFee'
         @object_args[:collection] ||= @object.finance_fee_collection
         @object.finance_fee_particulars.collect(&:master_fee_particular_id).compact.present?
       when 'FinanceFeeParticular'
         @object_args[:collection] ||= @object.
             finance_fee_collections.all(:conditions => ["collection_particulars.finance_fee_particular_id = ? and batches.id = ?",
                                                         @object.id, @object.batch_id], :joins => :batches, :limit => 1,
                                         :order => "finance_fee_collections.id desc").try(:last)
       when 'FeeDiscount'
         @object_args[:collection] ||= @object.
             finance_fee_collections.all(:conditions => ["collection_discounts.fee_discount_id = ? and batches.id = ?",
                                                         @object.id, @object.batch_id], :joins => :batches, :limit => 1,
                                         :order => "finance_fee_collections.id desc").try(:last)
       when 'HostelFee'
         @object_args[:collection] ||= @object.hostel_fee_collection
         @object_args[:collection].master_fee_particular_id.present?
       when 'TransportFee'
         @object_args[:collection] ||= @object.transport_fee_collection
         @object_args[:collection].master_fee_particular_id.present?
       when 'TransportFeeDiscount'
         @object_args[:collection] ||= @object.transport_fee.transport_fee_collection
         @object_args[:collection].master_fee_particular_id.present?
     end rescue false)
  end
end