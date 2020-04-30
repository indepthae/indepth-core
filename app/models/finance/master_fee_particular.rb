class MasterFeeParticular < ActiveRecord::Base

  RESERVED_PARTICULAR_NAMES = ['Fine', 'Application Fee', 'Rent', 'Bus Fare'].freeze
  PERMITTED_FEE_TYPES = ['core', 'hostel', 'transport', 'instant', 'registration'].freeze

  has_many :finance_fee_particulars
  has_many :master_particular_reports

  named_scope :core, :conditions => {:particular_type => "FinanceFee"}
  named_scope :fine, :conditions => {:particular_type => "Fine"}
  named_scope :load_dependencies, :include => :finance_fee_particulars
  named_scope :order_by_name, :order => "name ASC"
  named_scope :order_by_creation, :order => "created_at ASC"

  validates_presence_of :name, :particular_type
  validates_uniqueness_of :name, :scope => [:particular_type]
  validates_format_of :name, :with => /^[\w\s_+\-%$\/\'\"\\]+$/i

  before_validation :strip_name
  before_validation :set_particular_type, :if => Proc.new { |mfp| !mfp.particular_type.present? }
  before_destroy :validate_dependencies

  validate :reserved_names

  def reserved_names
    errors.add(:name, :reserved_name) if RESERVED_PARTICULAR_NAMES.include?(name)
  end

  def strip_name
    self.name.strip!
  end

  def set_particular_type
    self.particular_type ||= 'FinanceFee'
  end

  def validate_dependencies
    return !has_dependencies?
  end

  def has_dependencies?
    status = (finance_fee_particulars.active.last || master_particular_reports.last).present?
    status ||= (instant_fee_particulars.active.last).present? if FedenaPlugin.can_access_plugin?('instant_fee')
    status
  end

  class << self

    def fetch_unlinked_particulars args #, cat_type = 'all'
      student_id, batch_id, cat_id, cat_type = args[:student_id], args[:batch_id], args[:cat_id], args[:cat_type]
      # cat_type ||= 'all'
      batch_id ||= Student.find(student_id).try(:batch_id) if cat_type == 'all'
      fee_categories = ActiveSupport::OrderedHash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      if cat_type == 'all' || cat_type == 'core'

        cond, cond_vars = " and ff.student_id = ? and ff.batch_id = ?", [student_id, batch_id] if cat_type == 'all'
        cond, cond_vars = " and finance_fee_categories.id = ?", [cat_id] if cat_type == 'core'
        categories = FinanceFeeCategory.all(
            :select => "distinct ffp.id AS ffp_id, finance_fee_categories.name AS ffc_name, finance_fee_categories.id AS ffc_id, ffp.name AS ffp_name",
            :conditions => ["ffp.master_fee_particular_id IS NULL #{cond}"] + cond_vars,
            :joins => "INNER JOIN finance_fee_collections ffc ON ffc.fee_category_id = finance_fee_categories.id
                     INNER JOIN collection_particulars cd ON cd.finance_fee_collection_id = ffc.id
                     INNER JOIN finance_fee_particulars ffp ON ffp.id = cd.finance_fee_particular_id
                     INNER JOIN finance_fees ff ON ff.fee_collection_id = ffc.id", :limit => 500)

        if categories.present?
          categories = categories.group_by { |x| x.ffc_id }
          categories.each_pair do |k, v|
            # puts v.inspect
            # puts v[0].attributes
            # puts v[0].ffc_name
            # puts v[0].try('ffc_name')
            fee_categories['core'][k][:cat_name] = v[0].try('ffc_name')
            fee_categories['core'][k][:particulars] = v.group_by { |x| x.ffp_name }
          end
        end
      end

      if FedenaPlugin.can_access_plugin?('fedena_transport') and (cat_type == 'all' || cat_type == 'transport')
        fee_categories['transport'] = Hash.new if TransportFeeCollection.last(:conditions => ["master_fee_particular_id IS NULL"]).present?
      end

      if FedenaPlugin.can_access_plugin?('fedena_instant_fee') and (cat_type == 'all' || cat_type == 'instant')
        # cond, cond_vars = " and ff.student_id = ? and ff.batch_id = ?", [student_id, batch_id] if cat_type == 'all'
        cond, cond_vars = " and instant_fee_categories.id = ?", [cat_id] if cat_type == 'instant'
        categories = InstantFeeCategory.all(
            :select => "instant_fee_categories.name AS ffc_name, instant_fee_categories.id AS ffc_id, ffp.id AS ffp_id, ffp.name AS ffp_name",
            :conditions => ["ffp.master_fee_particular_id IS NULL #{cond}"] + cond_vars,
            :joins => "INNER JOIN instant_fee_particulars ffp
                               ON ffp.instant_fee_category_id = instant_fee_categories.id")

        if categories.present?
          categories = categories.group_by { |x| x.ffc_id }
          categories.each_pair do |k, v|
            # puts v.inspect
            # puts v[0].attributes
            # puts v[0].ffc_name
            # puts v[0].try('ffc_name')
            fee_categories['instant'][k][:cat_name] = v[0].try('ffc_name')
            fee_categories['instant'][k][:particulars] = v.group_by { |x| x.ffp_name }
          end
        end
      end

      if FedenaPlugin.can_access_plugin?('fedena_hostel') and (cat_type == 'all' || cat_type == 'hostel')
        fee_categories['hostel'] = Hash.new if HostelFeeCollection.last(:conditions => ["master_fee_particular_id IS NULL"]).present?
      end

      fee_categories
    end

    def has_unlinked_particulars? student_id, batch_id, cat_type = nil
      status = false

      return status, 'student_id_cannot_be_nil' unless student_id.present?
      return status, 'batch_id_cannot_be_nil' unless batch_id.present?

      fee_categories = FinanceFeeCategory.last(:conditions => ["ffp.master_fee_particular_id IS NULL and
                                                               ff.student_id = ? and ff.batch_id = ?", student_id, batch_id],
                                              :joins => "INNER JOIN finance_fee_collections ffc
                                                                 ON ffc.fee_category_id = finance_fee_categories.id
                                                         INNER JOIN collection_particulars cd
                                                                 ON cd.finance_fee_collection_id = ffc.id
                                                         INNER JOIN finance_fee_particulars ffp
                                                                 ON ffp.id = cd.finance_fee_particular_id
                                                         INNER JOIN finance_fees ff ON ff.fee_collection_id = ffc.id",
                                              :group => "finance_fee_categories.id")
      # status = (fee_categories.count > 0)
      status = fee_categories.present?

      if FedenaPlugin.can_access_plugin?('fedena_instant_fee') and (cat_type.present? and cat_type == 'instant') and !status

        i_categories = InstantFeeCategory.last(:conditions => ["ffp.master_fee_particular_id IS NULL"],
                                                :joins => "INNER JOIN instant_fee_particulars ffp
                                                              ON ffp.instant_fee_category_id = instant_fee_categories.id",
                                                :group => "instant_fee_categories.id")
        # status ||= (i_categories.count > 0)
        status ||= i_categories.present?
      end

      if FedenaPlugin.can_access_plugin?('fedena_transport') and !status
        status ||= TransportFeeCollection.last(
            :conditions => ["transport_fees.receiver_id = ? AND transport_fees.receiver_type = 'Student' AND
                             transport_fees.groupable_id = ? AND transport_fees.groupable_type = 'Batch' AND
                             master_fee_particular_id IS NULL AND transport_fees.is_paid = false", student_id, batch_id],
            :joins => :transport_fees).present?
      end

      if FedenaPlugin.can_access_plugin?('fedena_hostel') and !status
        status ||= HostelFeeCollection.last(
            :conditions => ["hostel_fees.student_id = ? AND hostel_fees.batch_id = ? AND hostel_fees.balance > 0 AND
                             master_fee_particular_id IS NULL", student_id, batch_id],
            :joins => :hostel_fees).present?
      end

      [status, 'linking_required']
    end

    def link_particulars data
      res_msg = 'successfully_updated'
      status = true
      particulars_count = 0
      particular_types = data.keys
      ActiveRecord::Base.transaction do
        begin
          data.each_pair do |p_type, p_data|
            next unless PERMITTED_FEE_TYPES.include?(p_type) # skip if invalid type found

            klass, particular_wise, particular_type = (
            case p_type
              when 'core'
                [FinanceFeeParticular, true, 'FinanceFee']
              when 'instant'
                [InstantFeeParticular, true, 'FinanceFee']
              when 'registration'
                particulars_count = particulars_count.next
                [RegistrationCourse, false, 'RegistrationCourse']
              when 'hostel'
                particulars_count = particulars_count.next
                [HostelFeeCollection, false, 'HostelFee']
              when 'transport'
                particulars_count = particulars_count.next
                [TransportFeeCollection, false, 'TransportFee']
            end)

            if particular_wise
              p_data.each_pair do |cat_id, particulars_info|
                particulars_info.each_pair do |mfp_id, ffp_ids|
                  particulars_count = particulars_count.next
                  klass.update_all({:master_fee_particular_id => mfp_id}, {:id => ffp_ids.split(','), :master_fee_particular_id => nil,
                                                                        :school_id => MultiSchool.current_school.id})
                end
              end
            else
              mfp = MasterFeeParticular.find_by_particular_type(particular_type)
              klass.update_all({:master_fee_particular_id => mfp.id}, {:master_fee_particular_id => nil,
                                                                       :school_id => MultiSchool.current_school.id})
            end
          end
            # puts "nefpre raise"
            # raise ActiveRecord::Rollback
            # puts 'after raise'
        rescue Exception => e
          # puts 'i am thrown to rescue'
          status = false
          res_msg = e
          raise ActiveRecord::Rollback
        end
      end

      return false, 'no_particulars_selected' unless particulars_count > 0
      return status, res_msg
    end
  end

end
