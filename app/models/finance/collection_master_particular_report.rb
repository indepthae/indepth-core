require 'zlib'
class CollectionMasterParticularReport < ActiveRecord::Base

  belongs_to :collection, :polymorphic => true

  CRC_COLUMNS = ['financial_year_id', 'master_fee_particular_id', 'student_id', 'batch_id', 'collection_id', 'collection_type', 'school_id'] #.freeze

  class << self
    def build_and_record_data rec_obj, obj_args
      klass = rec_obj.class.name

      case klass
        when 'FinanceFee'
          # collection = rec_obj.finance_fee_collection
          # batch_id = rec_obj.batch_id
          # student_id = rec_obj.student_id
          collection = obj_args[:collection] || rec_obj.finance_fee_collection
          data_hash = {:financial_year_id => collection.financial_year_id, :batch_id => rec_obj.batch_id,
                       :collection_id => collection.id, :collection_type => 'FinanceFeeCollection',
                       :actual_amount => 0, :amount => 0, :tax_amount => 0, :discount_amount => 0}

          particulars_data = fetch_master_particular_data_for_fees(rec_obj.to_a, data_hash)

          record_data(particulars_data)

        when 'FinanceFeeParticular'
          make_or_update_fee_data_by_particular_or_discount(rec_obj, obj_args)

        when 'FeeDiscount'
          make_or_update_fee_data_by_particular_or_discount(rec_obj, obj_args)

        when 'HostelFee'
          collection = obj_args[:collection] || rec_obj.hostel_fee_collection
          if collection.master_fee_particular_id.present?
            batch_id = rec_obj.batch_id
            student_id = rec_obj.student_id
            mfp_id = collection.master_fee_particular_id

            data_hash = {:financial_year_id => collection.financial_year_id, :student_id => student_id, :batch_id => batch_id,
                         :collection_id => collection.id, :collection_type => 'HostelFeeCollection', :actual_amount => rec_obj.rent,
                         :amount => (rec_obj.rent + rec_obj.tax_amount.to_f), :tax_amount => rec_obj.tax_amount.to_f, :discount_amount => 0,
                         :school_id => rec_obj.school_id, :master_fee_particular_id => mfp_id}


            record_data([data_hash])
          end
        when 'TransportFee'
          make_or_update_transport_fee_data rec_obj, obj_args

        when 'TransportFeeDiscount'
          make_or_update_transport_fee_data rec_obj, obj_args

          # transport_fee = rec_obj.transport_fee
          # collection = obj_args[:collection] || transport_fee.transport_fee_collection
          # if transport_fee == 'Student' and collection.master_fee_particular_id.present?
          #   batch_id = transport_fee.groupable_id
          #   student_id = transport_fee.receiver_id
          #   mfp_id = collection.master_fee_particular_id
          #   bus_fare = transport_fee.bus_fare
          #   tax_amount = rec_obj.tax_amount.to_f
          #   if mfp_id.present?
          #     discount_amount = rec_obj.is_amount ? rec_obj.discount : (bus_fare * rec_obj.discount * 0.01)
          #
          #     data_hash = {:financial_year_id => collection.financial_year_id, :student_id => student_id, :batch_id => batch_id,
          #                  :collection_id => collection.id, :collection_type => 'TransportFeeCollection', :actual_amount => bus_fare,
          #                  :amount => (bus_fare - discount_amount + tax_amount), :tax_amount => rec_obj.tax_amount,
          #                  :discount_amount => discount_amount, :school_id => rec_obj.school_id, :master_fee_particular_id => mfp_id}
          #
          #     record_data([data_hash])
          #   end
          # end
        else
          puts "else"
      end

    end


    def record_data rec_array, op_type = 'update'
      @log = Logger.new('log/collection_master_particular_report_log.log')
      rec_array.each do |rec|
        rec[:digest] = calculate_crc(rec)
        expected_rec = CollectionMasterParticularReport.new(rec)
        unless (expected_rec.save rescue nil)
          rec_obj = get_collection_master_particular_report(rec)
          if rec_obj.present?
            amt_cols = ['amount', 'actual_amount', 'tax_amount', 'discount_amount']
            update_hash = rec_obj.attributes.slice *amt_cols
            if op_type == 'update'
              update_hash['actual_amount'] = update_hash['actual_amount'].to_f + rec[:actual_amount].to_f
              update_hash['amount'] = update_hash['amount'].to_f + rec[:amount].to_f
              update_hash['discount_amount'] = update_hash['discount_amount'].to_f + rec[:discount_amount].to_f
              update_hash['tax_amount'] = update_hash['tax_amount'].to_f + rec[:tax_amount].to_f
            else
              update_hash['actual_amount'] = rec[:actual_amount]
              update_hash['amount'] = rec[:amount]
              update_hash['discount_amount'] = rec[:discount_amount]
              update_hash['tax_amount'] = rec[:tax_amount]
            end
            rec_obj.update_attributes(update_hash)
          else
            @log.info rec.inspect
            @log.info "*********************************************************"
          end  
        end
      end
    end

    # identify the object triggered for updating Expected reporting data
    # and process
    def remove_and_update_records rec_obj, args
      klass = rec_obj.class.name
      puts klass

      case klass
        when 'FinanceFee'
          search_keys = {:student_id => rec_obj.student_id, :batch_id => rec_obj.batch_id, :collection_type => 'FinanceFeeCollection',
                         :collection_id => rec_obj.fee_collection_id}
          CollectionMasterParticularReport.delete_all(search_keys)
        when 'FinanceFeeParticular'
          make_or_update_fee_data_by_particular_or_discount(rec_obj, args)

        when 'FeeDiscount'
          make_or_update_fee_data_by_particular_or_discount(rec_obj, args)

        when 'HostelFee'
          student_id = rec_obj.student_id
          batch_id = rec_obj.batch_id
          search_keys = {:student_id => student_id, :batch_id => batch_id, :collection_type => 'HostelFeeCollection',
                         :collection_id => rec_obj.hostel_fee_collection_id}
          # CollectionMasterParticularReport.delete_all(search_keys)
          flush_report_rows(search_keys)
        when 'TransportFee'
          collection = args[:collection] || rec_obj.transport_fee_collection
          if rec_obj.receiver_type == 'Student' and collection.master_fee_particular_id.present?
            student_id = rec_obj.receiver_id
            batch_id = rec_obj.groupable_id
            search_keys = {:student_id => student_id, :batch_id => batch_id, :collection_type => 'TransportFeeCollection',
                           :collection_id => collection.id}
            # CollectionMasterParticularReport.delete_all(search_keys)
            flush_report_rows(search_keys)
          end
        when 'TransportFeeDiscount'
          make_or_update_transport_fee_data rec_obj, args
          # collection = args[:collection] || rec_obj.transport_fee_collection
          # if rec_obj.receiver_type == 'Student' and rec_obj.master_fee_particular_id.present?
          #   student_id = rec_obj.receiver_id
          #   batch_id = rec_obj.groupable_id
          #   search_keys = {:student_id => student_id, :batch_id => batch_id, :collection_type => 'TransportFeeCollection',
          #                  :collection_id => collection.id}
          #   # CollectionMasterParticularReport.delete_all(search_keys)
          #   flush_report_rows(search_keys)
          # end

        else

      end
    end

    # builds data for insertion or updation for finance fee associated objects
    def make_or_update_fee_data_by_particular_or_discount rec_obj, args = {}
      # log = Logger.new('log/delayed_job.log')
      collection = args[:collection] || rec_obj.finance_fee_collections.try(:last)
      # log.info(collection.inspect)
      batch_id = rec_obj.batch_id
      # remove previous expected information for the affected collection
      master_type = ((rec_obj.class.name.underscore.match /.*(discount|particular).*/)[1] rescue nil)
      if master_type.present? and rec_obj.send("master_fee_#{master_type}_id").present?
        if rec_obj.is_instant
          fee = FinanceFee.last(:conditions => ["fee_collection_id = ? and student_id = ?", collection.id, rec_obj.receiver_id])
          student_id = fee.student_id
          data_hash = {:financial_year_id => collection.financial_year_id, :batch_id => fee.batch_id, :school_id => rec_obj.school_id,
                       # :student_id => rec_obj.receiver_id,
                       :collection_id => collection.id, :collection_type => 'FinanceFeeCollection',
                       # :master_fee_particular_id => rec_obj.master_fee_particular_id,
                       :actual_amount => 0, :amount => 0, :tax_amount => 0, :discount_amount => 0}

          search_keys = {:student_id => student_id, :batch_id => batch_id, :collection_type => 'FinanceFeeCollection',
                         :collection_id => collection.id}
          flush_report_rows(search_keys)

          particulars_data = fetch_master_particular_data_for_fees(fee.to_a, data_hash)
          record_data(particulars_data) if particulars_data.present?
        else
          fees = FinanceFee.all(:conditions => ["fee_collection_id = ? and batch_id = ?", collection.id, batch_id],
          :include => :finance_fee_collection)
          # log.info(fees.inspect)
          data_hash = {:financial_year_id => collection.financial_year_id, :batch_id => batch_id, :school_id => collection.school_id,
                       :collection_id => collection.id, :collection_type => 'FinanceFeeCollection',
                       # :student_id => student_id,
                       # :master_fee_particular_id => rec_obj.master_fee_particular_id,
                       :actual_amount => 0, :amount => 0, :tax_amount => 0, :discount_amount => 0}
          search_keys = {:batch_id => batch_id, :collection_type => 'FinanceFeeCollection', :collection_id => collection.id}
          # log.info(data_hash.inspect)
          # log.info(search_keys.inspect)

          flush_report_rows(search_keys)

          particulars_data = fetch_master_particular_data_for_fees(fees, data_hash)
          # op = 'set'
          record_data(particulars_data, 'set') if particulars_data.present?
        end
      end
    end

    # builds master particular data for insertion or updation for finance fees objects
    def fetch_master_particular_data_for_fees fees, data_hash
      particulars_data = []

      fees.each do |fee|
        c_hash = data_hash.dup
        c_hash[:student_id] = fee.student_id
        collection = fee.finance_fee_collection
        discounts = fee.fee_discounts
        particulars = fee.finance_fee_particulars
        p_total = particulars.map(&:amount).sum
        t_discount_amt = collection.discount_mode == 'OLD_DISCOUNT' ? discounts.map do |d|
          d.master_receiver_type=='FinanceFeeParticular' ?
              (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) :
              p_total * d.discount.to_f/(d.is_amount? ? p_total : 100)
        end.sum.to_f : 0
        sql = "SELECT ffp.amount actual_amount, ffp.master_fee_particular_id, ffp.id AS ffp_id,
                   IF(ffc.discount_mode = 'OLD_DISCOUNT', 0,
                      (SELECT SUM(IF(fd.is_amount, (ffp.amount / ff.particular_total * fd.discount), (ffp.amount * fd.discount * 0.01)))
                      FROM fee_discounts fd
                INNER JOIN collection_discounts cd ON cd.fee_discount_id = fd.id
                     WHERE cd.finance_fee_collection_id = ff.fee_collection_id AND
                           ((fd.receiver_id = ff.student_id AND fd.receiver_type = 'Student') OR
                            (fd.receiver_id = s.student_category_id AND fd.receiver_type = 'StudentCategory') OR
                            (fd.receiver_id = ff.batch_id AND fd.receiver_type = 'Batch')) AND
                           (fd.master_receiver_type IN ('Student','Batch','StudentCategory') OR
                            (fd.master_receiver_type = 'FinanceFeeParticular' AND fd.master_receiver_id = ffp.id)))) AS discount_amount,

                    IFNULL(tc.tax_amount, 0) as tax_amount, IFNULL(ts.rate, 0) AS slab_rate

            FROM finance_fees ff
            INNER JOIN finance_fee_collections ffc ON ffc.id = ff.fee_collection_id
            INNER JOIN collection_particulars cp ON cp.finance_fee_collection_id = ffc.id
            INNER JOIN finance_fee_particulars ffp ON ffp.id = cp.finance_fee_particular_id
            INNER JOIN students s ON s.id = ff.student_id
             LEFT JOIN tax_collections tc ON tc.taxable_entity_id = ffp.id and
                                             tc.taxable_entity_type = 'FinanceFeeParticular' AND
                                             tc.taxable_fee_id = ff.id
             LEFT JOIN tax_slabs ts ON ts.id = tc.slab_id

            WHERE ff.id = #{fee.id} AND ffp.master_fee_particular_id IS NOT NULL AND
                  ((ffp.receiver_id = ff.student_id AND ffp.receiver_type = 'Student') OR
                   (ffp.receiver_id = s.student_category_id AND ffp.receiver_type = 'StudentCategory') OR
                   (ffp.receiver_id = ff.batch_id AND ffp.receiver_type = 'Batch'))
            ORDER BY ffp.id"

        records = ActiveRecord::Base.connection.execute(sql).all_hashes

        records.each do |rec|
          rec.each_pair {|k,v| rec[k.to_sym] = rec.delete(k) }
          p_hash = c_hash.dup.merge(rec.except(:ffp_id, :slab_rate))

          if collection.discount_mode == 'OLD_DISCOUNT' and t_discount_amt > 0
            t_discount_amt -= disc_amt = p_hash[:actual_amount].to_f
            p_hash[:discount_amount] = disc_amt
            p_hash[:tax_amount] = ((p_hash[:actual_amount].to_f - disc_amt) * rec[:slab_rate].to_f * 0.01) if collection.tax_enabled
          end

          p_hash[:digest] = calculate_crc(rec)
          p_hash[:amount] = p_hash[:actual_amount].to_f - p_hash[:discount_amount].to_f + p_hash[:tax_amount].to_f
          particulars_data << p_hash
        end
      end
      particulars_data
    end

    # builds data for insertion or updation for transport fee associated object
    def make_or_update_transport_fee_data rec_obj, obj_args = {}
      transport_fee = rec_obj.is_a?(TransportFee) ? rec_obj : rec_obj.transport_fee
      collection = obj_args[:collection] || transport_fee.transport_fee_collection

      if transport_fee.receiver_type == 'Student' and collection.master_fee_particular_id.present?
        batch_id = transport_fee.groupable_id
        student_id = transport_fee.receiver_id
        mfp_id = collection.master_fee_particular_id
        bus_fare = transport_fee.bus_fare
        tax_amount = transport_fee.tax_amount.to_f
        if mfp_id.present?
          discount_amount = transport_fee.transport_fee_discounts.map { |x| x.is_amount ? x.discount : (bus_fare * x.discount * 0.01) }.sum

          data_hash = {:financial_year_id => collection.financial_year_id, :student_id => student_id, :batch_id => batch_id,
                       :collection_id => collection.id, :collection_type => 'TransportFeeCollection', :actual_amount => bus_fare,
                       :amount => (bus_fare - discount_amount + tax_amount), :tax_amount => tax_amount,
                       :discount_amount => discount_amount, :school_id => rec_obj.school_id, :master_fee_particular_id => mfp_id}

          record_data([data_hash], 'set')
        end
      end
    end

    # deletes all records based on conditions (search_keys)
    def flush_report_rows search_keys
      CollectionMasterParticularReport.delete_all(search_keys)
    end

    # computes digest based on data_hash, in order of keys in CRC_COLUMNS constant
    def calculate_crc data_hash
      data_str = ""
      CRC_COLUMNS.map(&:to_sym).each do |k|
        data_str += data_hash[k.to_sym].to_s
      end
      # digest as CRC value
      Zlib::crc32 data_str
    end

    def valid_for_reporting
      ## Add validation
    end
    
    def get_collection_master_particular_report(rec)
      CollectionMasterParticularReport.find_by_digest_and_student_id_and_collection_id_and_collection_type(rec[:digest], rec[:student_id], rec[:collection_id], rec[:collection_type])
    end  
  end
end
