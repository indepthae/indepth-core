module MasterFeesHelper

  def fees_type_options
    ## TO DO :: additional conditions needed to check only if a fee type has unlinked collection / particular should be listed
    fees_types = []
    fees_types << [t('master_fees.finance_fee'), 'core'] if FinanceFeeParticular.has_unlinked_particulars?
    fees_types << [t('master_fees.transport_fee'), 'transport'] if FedenaPlugin.can_access_plugin?('fedena_transport') and TransportFeeCollection.has_unlinked_collections?
    fees_types << [t('master_fees.hostel_fee'), 'hostel'] if FedenaPlugin.can_access_plugin?('fedena_hostel') and HostelFeeCollection.has_unlinked_collections?
    fees_types << [t('master_fees.instant_fee'), 'instant'] if FedenaPlugin.can_access_plugin?('fedena_instant_fee') and InstantFeeParticular.has_unlinked_particulars?
    fees_types << [t('master_fees.application_fee'), 'registration'] if FedenaPlugin.can_access_plugin?('fedena_applicant_registration') and RegistrationCourse.has_unlinked_courses?
    fees_types
  end

  def string_to_underscore str
    str.split(' ').join('_').underscore
  end

  def categorized_particulars_discounts particulars_hash = {}, discounts_hash = {}
    unlinked_data_hash = ActiveSupport::OrderedHash.new { |h, k| h[k] = Hash.new(&h.default_proc) }

    cat_ids = (particulars_hash.keys + discounts_hash.keys).uniq
    cat_ids.each do |cat_id|
      # puts "-------------------"
      # puts cat_id
      unlinked_data_hash[cat_id][:cat_name] = particulars_hash[cat_id][:cat_name] || discounts_hash[cat_id][:cat_name]
      # puts h[cat_id].inspect
      unlinked_data_hash[cat_id][:particulars] = particulars_hash[cat_id][:particulars] if (particulars_hash[cat_id][:particulars] rescue nil).present?
      # puts h[cat_id].inspect
      unlinked_data_hash[cat_id][:discounts] = discounts_hash[cat_id][:discounts] if (discounts_hash[cat_id][:discounts] rescue nil).present?
      # puts h[cat_id].inspect
      unlinked_data_hash.delete(cat_id) unless (unlinked_data_hash[cat_id].keys & [:particulars, :discounts]).present?
      # puts h[cat_id].inspect
    end
    # puts h.inspect
    unlinked_data_hash
  end
end
