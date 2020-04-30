class MasterFeeDiscount < ActiveRecord::Base

  RESERVED_PARTICULAR_NAMES = [].freeze
  PERMITTED_FEE_TYPES = ['core', 'transport'].freeze

  has_many :fee_discounts
  named_scope :core, :conditions => {:discount_type => "FinanceFee"}
  named_scope :load_dependencies, :include => :fee_discounts
  named_scope :order_by_name, :order => "name ASC"
  named_scope :order_by_creation, :order => "created_at ASC"

  validates_presence_of :name, :discount_type
  validates_uniqueness_of :name, :scope => [:discount_type]
  validates_format_of :name, :with => /^[\w\s_+\-%$\/\'\"\\]+$/i

  before_validation :strip_name
  before_validation :set_discount_type, :if => Proc.new { |mfd| !mfd.discount_type.present? }

  def strip_name
    self.name.strip!
  end

  def set_discount_type
    self.discount_type ||= 'FinanceFee'
  end

  def has_dependencies?
    fee_discounts.last.present?
  end

  class << self

    def fetch_unlinked_discounts args
      student_id, batch_id, cat_id, cat_type = args[:student_id], args[:batch_id], args[:cat_id], args[:cat_type]
      cat_type ||= 'all'
      batch_id ||= Student.find(student_id).try(:batch_id) if cat_type == 'all'
      fee_categories = ActiveSupport::OrderedHash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      if cat_type == 'all' || cat_type == 'core'
        cond, cond_vars = " and ff.student_id = ? and ff.batch_id = ?", [student_id, batch_id] if cat_type == 'all'
        cond, cond_vars = " and finance_fee_categories.id = ?", [cat_id] if cat_type == 'core'
        categories = FinanceFeeCategory.all(
            :select => "distinct fd.id AS fd_id, finance_fee_categories.name AS ffc_name, finance_fee_categories.id AS ffc_id, fd.name AS fd_name",
            :conditions => ["fd.master_fee_discount_id IS NULL #{cond}"] + cond_vars,
            :joins => "INNER JOIN finance_fee_collections ffc ON ffc.fee_category_id = finance_fee_categories.id
                     INNER JOIN collection_discounts cd ON cd.finance_fee_collection_id = ffc.id
                     INNER JOIN fee_discounts fd ON fd.id = cd.fee_discount_id
                     INNER JOIN finance_fees ff ON ff.fee_collection_id = ffc.id", :limit => 500)

        if categories.present?
          categories = categories.group_by { |x| x.ffc_id }
          # categories.each_pair { |k, v| fee_categories['core'][k] = v.group_by { |x| x.fd_name } }
          categories.each_pair do |k, v|
            # puts v.inspect
            # puts v[0].attributes
            fee_categories['core'][k][:cat_name] = v[0].try(:ffc_name)
            fee_categories['core'][k][:discounts] = v.group_by { |x| x.fd_name }
          end
        end
      end

      if FedenaPlugin.can_access_plugin?('fedena_transport') and (cat_type == 'all' || cat_type == 'transport')
        # fee_categories['transport'] = Hash.new if TransportFeeCollection.last(:conditions => ["master_fee_particular_id IS NULL"]).present?
        fee_categories['transport'] = Hash.new if TransportFeeDiscount.last(:conditions => ["master_fee_discount_id IS NULL"]).present?
      end

      fee_categories
    end

    def has_unlinked_discounts? student_id, batch_id
      status = false

      return status, 'student_id_cannot_be_nil' unless student_id.present?
      return status, 'batch_id_cannot_be_nil' unless batch_id.present?


      # fees = FinanceFee.all(:conditions => ["student_id = ? and batch_id = ?", student_id, batch_id])
      fee_categories = FinanceFeeCategory.all(
          :conditions => ["fd.master_fee_discount_id IS NULL and ff.student_id = ? and ff.batch_id = ?", student_id, batch_id],
          :joins => "INNER JOIN finance_fee_collections ffc ON ffc.fee_category_id = finance_fee_categories.id
                     INNER JOIN collection_discounts cd ON cd.finance_fee_collection_id = ffc.id
                     INNER JOIN fee_discounts fd ON fd.id = cd.fee_discount_id
                     INNER JOIN finance_fees ff ON ff.fee_collection_id = ffc.id",
          :group => "finance_fee_categories.id")
      status = (fee_categories.count > 0)

      if FedenaPlugin.can_access_plugin?('fedena_transport') and !status
        status ||= TransportFeeDiscount.last(
            :conditions => ["transport_fees.receiver_id = ? AND transport_fees.receiver_type = 'Student' AND
                             transport_fees.groupable_id = ? AND transport_fees.groupable_type = 'Batch' AND
                             transport_fees.is_paid = false AND master_fee_discount_id IS NULL", student_id, batch_id],
            :joins => :transport_fee).present?
      end

      [status, 'linking_required']
    end

    def link_discounts data
      res_msg = 'successfully_updated'
      status = true
      discounts_count = 0
      discount_types = data.keys
      ActiveRecord::Base.transaction do
        begin
          data.each_pair do |p_type, p_data|
            next unless PERMITTED_FEE_TYPES.include?(p_type) # skip if invalid type found

            klass, discount_wise, discount_type = (
            case p_type
              when 'core'
                [FeeDiscount, true, 'FinanceFee']
              # when 'instant'
              #   [InstantFeediscount, true, 'FinanceFee']
              # when 'registration'
              #   discounts_count = discounts_count.next
              #   [RegistrationCourse, false, 'RegistrationCourse']
              # when 'hostel'
              #   discounts_count = discounts_count.next
              #   [HostelFeeCollection, false, 'HostelFee']
              when 'transport'
                discounts_count = discounts_count.next
                [TransportFeeCollection, true, 'TransportFee']
            end)

            if discount_wise
              p_data.each_pair do |cat_id, discounts_info|
                discounts_info.each_pair do |mfd_id, fd_ids|
                  discounts_count = discounts_count.next
                  klass.update_all({:master_fee_discount_id => mfd_id}, {:id => fd_ids.split(','),
                                                                         :master_fee_discount_id => nil,
                                                                         :school_id => MultiSchool.current_school.id})
                end
              end
            else
              mfd = MasterFeeDiscount.find_by_discount_type(discount_type)
              klass.update_all({:master_fee_discount_id => mfd.id}, {:master_fee_discount_id => nil,
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

      return false, 'no_discounts_selected' unless discounts_count > 0
      return status, res_msg
    end
  end
end
