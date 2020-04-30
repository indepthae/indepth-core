require 'dispatcher'
# FedenaHostel
require 'finance_transaction_extension'
module FedenaHostel
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_hostel do
      ::Employee.instance_eval { has_many :wardens, :dependent => :destroy }
      ::FinanceTransaction.instance_eval { include FinanceTransactionExtension }
      ::Student.instance_eval { include StudentExtension }
      ::ArchivedStudent.instance_eval { include ArchivedStudentExtension }
      ::Batch.instance_eval { include BatchExtension }
      ::TaxSlab.instance_eval { include TaxSlabExtension }
      ::TaxPayment.instance_eval { include TaxPaymentExtension }
      ::FinancialYear.instance_eval { has_many :hostel_fee_collections }
      ::MasterFeeParticular.instance_eval { include MasterFeeParticularExtension }
    end
  end

  def self.dependency_delete(student)
    student.room_allocations.destroy_all
    student.hostel_fees.destroy_all
  end

  def self.dependency_check(record,type)
    if type == "permanant"
      if record.class.to_s == "Student"
        return true if record.room_allocations.all(:conditions=>"is_vacated=0").present?
        return true if record.hostel_fees.active.present?
      elsif record.class.to_s == "Employee"
        return true if record.wardens.all.present?
      end
    end
    return false
  end

  def self.student_profile_fees_hook
    "hostel_fee/student_profile_fees"
  end
  def self.student_profile_fees_by_batch_hook
    "hostel_fee/student_profile_fees"
  end

  def self.mobile_student_profile_fees_hook
    "hostel_fee/mobile_student_profile_fees"
  end

  module StudentExtension
    def self.included(base)
      base.instance_eval do
        has_many :room_allocations, :dependent => :destroy
        has_many :hostel_fees
        accepts_nested_attributes_for :hostel_fees
        DependencyHook.make_dependency_hook(:hostel_batch_fee, :student,:warning_message=>:hostel_fee_are_already_assigned ) do
          self.batch_hostel_fees_exist
        end
        DependencyHook.make_dependency_hook(:hostel_batch_fee_value, :student ) do
          self.hostel_fee_collections
        end
        DependencyHook.make_dependency_hook(:fedena_hostel_dependency, :student,:warning_message=>:hostel_allotted ) do
          self.hostel_dependencies
        end
      end
      #TODO implement logic
      def has_pending_hostel_fees?
        pending_count=HostelFee.count(:all,
          :joins=>[:student],
          :conditions=>{
            :students=>{:id=>self.id},
            :finance_transaction_id=>nil
          }
        )
        pending_count >0
      end
    end

    def hostel_dependencies
      return false if self.room_allocations.all(:conditions=>"is_vacated=0").present? or self.hostel_fees.active.present?
      return true
    end

    def current_allocation
      RoomAllocation.find_by_student_id(self.id,:conditions=>"is_vacated=0")
    end

    def hostel_fee_transactions(fee_collection)
      HostelFee.find_by_hostel_fee_collection_id_and_student_id(fee_collection.id,self.id)
    end

    def hostel_fee_balance(fee_collection_id)
      fee_collection= HostelFeeCollection.find(fee_collection_id)
      hostelfee = self.hostel_fee_transactions(fee_collection)

      return hostelfee.balance
    end

    def hostel_fee_collections
      HostelFeeCollection.find(:all,
        :joins => "INNER JOIN hostel_fees ON hostel_fee_collections.id = hostel_fees.hostel_fee_collection_id
                    LEFT JOIN fee_accounts fa ON fa.id = hostel_fee_collections.fee_account_id",
        :conditions => "hostel_fees.student_id = #{self.id} AND hostel_fee_collections.is_deleted = 0 AND
                        hostel_fees.is_active = 1 AND (fa.id IS NULL OR fa.is_deleted = false)")
    end
    def hostel_fee_collections_with_dues
      HostelFeeCollection.find(:all,
        :joins => "INNER JOIN hostel_fees ON hostel_fee_collections.id = hostel_fees.hostel_fee_collection_id
                    LEFT JOIN fee_accounts fa ON fa.id = hostel_fee_collections.fee_account_id",
        :conditions => "hostel_fees.student_id = #{self.id} AND hostel_fee_collections.is_deleted = 0 AND
                        hostel_fees.is_active = 1 AND hostel_fees.balance <> 0 AND (fa.id IS NULL OR fa.is_deleted = false)")
    end

    def hostel_fee_collections_exists
      hostel_fee_collections.empty?
    end

    def batch_hostel_fees_exist
      hostel_fees.select{|h| h.try(:hostel_fee_collection).try(:batch_id) == batch_id and !h.try(:hostel_fee_collection).try(:is_deleted)}.empty?
    end
    def hostel_fees_by_batch(batch_id,order=nil)
      return [] unless batch_id.present?
      unless order.present?
        order = "finance_transaction_id"
      end

      HostelFee.all(:joins => "INNER JOIN hostel_fee_collections hfc ON hfc.id = hostel_fees.hostel_fee_collection_id
                               LEFT JOIN fee_accounts fa ON fa.id = hfc.fee_account_id",
        :conditions => ["hostel_fees.student_id = ? AND hostel_fees.batch_id = ? AND hostel_fees.is_active = ? AND
                         (fa.id IS NULL OR fa.is_deleted = false)", id, batch_id, true],
        :order => order)
    end
  end

  module ArchivedStudentExtension
    def hostel_fees_by_batch(batch_id,order=nil)
      return [] unless batch_id.present?
      unless order.present?
        order = "finance_transaction_id"
      end

      HostelFee.all(:joins => "INNER JOIN hostel_fee_collections hfc ON hfc.id = hostel_fees.hostel_fee_collection_id
                               LEFT JOIN fee_accounts fa ON fa.id = hfc.fee_account_id",
        :conditions => ["hostel_fees.student_id = ? AND hostel_fees.batch_id = ? AND hostel_fees.is_active = ? AND
                         (fa.id IS NULL OR fa.is_deleted = false)", former_id, batch_id, true],
        :order => order)
    end
  end
  
  module MasterFeeParticularExtension
    def self.included(base)
      base.instance_eval do
        has_many :hostel_fee_collections
      end
    end
  end

  module BatchExtension
    def self.included(base)
      base.instance_eval do
        has_many :room_allocations, :through => :students
        has_many :hostel_fees
      end
    end

    def room_allocations_present
      flag = false
      unless self.room_allocations.blank?
        self.room_allocations.each do |room|
          flag = true unless room.is_vacated
        end
      end
      return flag
    end
  end
  
  module TaxSlabExtension
    def self.included(base)
      base.instance_eval do 
        #        has_many :hostel_fee_collections, :through => :taxable_slabs, :source => :taxable, 
        #          :source_type => 'HostelFeeCollection'
        
        has_many :hostel_fee_collections, :through => :collectible_tax_slabs, :source => :collection,
          :source_type => "HostelFeeCollection"
      end
    end
  end
  
  module TaxPaymentExtension
    def self.included(base)
      base.class_eval do
        def self.hostel_fee_tax_payments(start_date, end_date)
          TaxPayment.all(:conditions => ["transaction_date 
            BETWEEN '#{start_date}' AND '#{end_date}' AND finance_type = 'HostelFee' AND
            (ftrr.fee_account_id IS NULL OR fa.is_deleted = false)"],
            :select => "DISTINCT tax_payments.id as tax_payment_id, 
                           tax_payments.tax_amount AS tax_amount, ts.name AS slab_name, 
                           ts.rate AS slab_rate,ts.id AS slab_id, hfc.id AS collection_id, 
                           hfc.name AS collection_name, fts.transaction_date as transaction_date",
            :joins => "INNER JOIN finance_transactions fts ON fts.id = tax_payments.finance_transaction_id
                       INNER JOIN finance_transaction_receipt_records ftrr
                                  FORCE INDEX (index_by_transaction_and_receipt)
                               ON ftrr.finance_transaction_id = fts.id
                        LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id
                       INNER JOIN hostel_fees hf
                               ON hf.id = tax_payments.taxed_fee_id AND tax_payments.taxed_fee_type = 'HostelFee'
                       INNER JOIN hostel_fee_collections hfc ON hfc.id = hf.hostel_fee_collection_id
                       INNER JOIN collectible_tax_slabs cts
                                       ON cts.collection_id = hfc.id AND cts.collection_type = 'HostelFeeCollection'
                       INNER JOIN tax_slabs ts ON ts.id = cts.tax_slab_id")
        end
      end
    end
  end
end




#
