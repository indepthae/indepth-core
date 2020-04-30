#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class FinanceFeeParticular < ActiveRecord::Base

  belongs_to :master_fee_particular, :conditions => {:particular_type => 'FinanceFee'}
  belongs_to :finance_fee_category
  belongs_to :student_category
  belongs_to :receiver, :polymorphic => true
  belongs_to :batch
  # Ensure this callback "fetch_and_set_collection" is first inline destroy callback chains,
  # in order to ensure collection information is captured, for reporting related job to function well.
  before_destroy :fetch_and_set_collection

  has_many :finance_fee_collections, :through => :collection_particulars
  has_many :collection_particulars, :dependent => :destroy
  #discount associations
  has_many :fee_discounts
  has_many :finance_fee_discounts, :dependent => :destroy
  has_many :particular_payments
  has_many :particular_wise_discounts, :class_name => 'FeeDiscount', :foreign_key => 'master_receiver_id', :conditions => "fee_discounts.master_receiver_type='FinanceFeeParticular'"
  has_many :pay_all_discounts, :class_name => "MultiFeeDiscount", :foreign_key => 'master_receiver_id', :conditions => "multi_fee_discounts.master_receiver_type='FinanceFeeParticular'"
  # tax associations
  has_many :tax_assignments, :as => :taxable
  has_many :tax_slabs, :through => :tax_assignments, :class_name => "TaxSlab"

  has_many :collectible_tax_slabs, :as => :collectible_entity, :dependent => :destroy
  has_many :collection_tax_slabs, :through => :collectible_tax_slabs, :class_name => "TaxSlab"

  has_many :tax_collections, :as => :taxable_entity, :dependent => :destroy
  has_many :tax_fees, :through => :tax_collections, :source => :taxable_fee, :source_type => "FinanceFee"

  has_many :tax_payments, :as => :taxed_entity, :dependent => :destroy
  has_many :taxed_fees, :through => :tax_payments, :source => :taxable_fee, :source_type => "FinanceFee"

  validates_presence_of :name, :amount, :finance_fee_category_id, :batch_id, :receiver_type, :receiver_id
  validates_numericality_of :amount, :greater_than_or_equal_to => 0, :message => :must_be_positive, :allow_blank => true
  named_scope :active, {:conditions => {:is_deleted => false}}
  named_scope :batch_particulars, {:conditions => {:is_deleted => false, :receiver_type => 'Batch'}, :group => ["name,receiver_type"]}
  named_scope :category_particulars, {:conditions => ["is_deleted=false and (receiver_type='Batch' or receiver_type='StudentCategory')"], :group => ["name,receiver_type"]}
  named_scope :for_category, lambda { |cat_id| {:conditions => {:finance_fee_category_id => cat_id}} }
  named_scope :without_masters, :conditions => {:master_fee_particular_id => nil}
  attr_accessor :tax_slab_id
  #  cattr_accessor :is_unlinked
  attr_accessor :collection_for_batch
  cattr_reader :per_page
  @@per_page = 10
  before_validation :set_particular_name, :if => Proc.new { |x| x.new_record? }
  before_save :verify_precision
  before_update :check_discounts
  before_update :set_particular_name, :if => Proc.new {|x| !x.new_record? and x.master_fee_particular_id_was.present? and x.master_fee_particular_id_changed? }
  after_create :apply_tax_slab
  after_create :trigger_update_collection_master_particular_reports, :if => Proc.new {|x| x.is_instant }

  after_destroy :trigger_update_collection_master_particular_reports, :if => Proc.new {|x| x.is_instant }


  def fetch_and_set_collection
    self.collection_for_batch ||= self.finance_fee_collections.all(:joins => :batches,
                                                                   :conditions => ["batches.id = ?", batch_id]).try(:last)
  end

  def trigger_update_collection_master_particular_reports
    if self.destroyed?
      Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('remove', self, {:collection => self.collection_for_batch}))
    else
      Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('insert', self))
    end
  end

  def set_particular_name
    master_fee_particular = MasterFeeParticular.find_by_id(self.master_fee_particular_id)
    self.name = master_fee_particular.name if master_fee_particular.present?
  end

  def apply_tax_slab
    unless self.tax_slab_id.present?
      self.tax_slabs = []
    else
      tax_slab = TaxSlab.find(self.tax_slab_id)
      self.tax_slabs = [tax_slab] if tax_slab.present?
    end
  end

  def update_tax_slab tax_slab_id = nil
    unless tax_slab_id.present?
      self.tax_slabs = []
    else
      tax_slab = TaxSlab.find_by_id(tax_slab_id)
      if tax_slab.present?
        self.tax_slabs = [tax_slab]
      else
        return false
      end
    end
  end

  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision self.amount
  end

  def deleted_category
    flag = false
    category = receiver if receiver_type=='StudentCategory'
    if category
      flag = true if category.is_deleted
    end
    return flag
  end

  def student_name
    if receiver_id.present?
      student = Student.find_by_id(receiver_id)
      student ||= ArchivedStudent.find_by_former_id(receiver_id)
      student.present? ? "#{student.first_name} &#x200E;(#{student.admission_no})&#x200E;" : "N.A. (N.A.)"
    end
  end

  def collection_exist
    #    collection_ids=finance_fee_category.fee_collections.collect(&:id)
    if collection_particulars.present?
      errors.add_to_base(t('collection_exists_for_this_category_cant_edit_this_particular'))
      return false
    else
      return true
    end
  end

  def delete_particular
    update_attributes(:is_deleted => true)
  end

  class << self
    def student_category_batches(name, type)
      Batch.find(:all, :joins => "INNER JOIN finance_fee_particulars
                                                     ON batches.id=finance_fee_particulars.batch_id 
                                         INNER JOIN students 
                                                     ON students.batch_id=batches.id",
                 :conditions => "finance_fee_particulars.name='#{name}' AND
                             (finance_fee_particulars.receiver_type='#{type}' AND 
                              finance_fee_particulars.is_deleted<>true)").uniq
    end

    def add_or_remove_particular_update_discounts_and_taxes(finance_fee)
      discount_mode = finance_fee.school_discount_mode
      fee_particulars = finance_fee.finance_fee_particulars

      no_of_parts = fee_particulars.length
      last_particular_id = no_of_parts > 1 ? fee_particulars.last.try(:id) : nil
      discounts = finance_fee.fee_discounts
      total_payable = fee_particulars.map(&:amount).sum.to_f
      # STEP : 1 (adjust finance fee discount of each particular w.r.t. total discounts)
      if discount_mode == "OLD"
        particular_discounts = finance_fee.finance_fee_discounts.group_by { |x| x.finance_fee_particular_id }
        total_discount_amount = discounts.map { |d| d.master_receiver_type=='FinanceFeeParticular' ?
            (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) :
            total_payable * d.discount.to_f/(d.is_amount? ? total_payable : 100)
        }.sum.to_f
        particular_ids = fee_particulars.map(&:id)
        if total_discount_amount.to_f > 0
          parts = []
          pi = 0
          fee_particulars.each do |particular|
            pi = pi.next
            break if total_discount_amount.to_f <= 0
            if total_discount_amount.to_f > 0
              if particular_discounts[particular.id].present? and particular_discounts[particular.id].length > 1
                particular_discounts[particular.id].each_with_index { |ffd, i| next if i == 0; ffd.destroy }
              end
              p_discount = particular_discounts[particular.id].try(:first)
              p_discount = FinanceFeeParticular.create_finance_fee_discount(finance_fee, particular) unless p_discount.present?
              p_amount = particular.amount.to_f
              p_discount_amt = total_discount_amount > p_amount ? p_amount : total_discount_amount
              p_discount.discount_amount = p_discount_amt
              p_discount.send(:update_without_callbacks)
              total_discount_amount -= p_discount_amt
            else
              # set finance fee discounts to 0
              FinanceFeeParticular.set_particular_finance_fee_discount_zero([particular.id], finance_fee) if particular.present?
            end
            parts << particular.id
          end
          if fee_particulars.length > pi and (particular_ids - parts).present?
            FinanceFeeParticular.set_particular_finance_fee_discount_zero((particular_ids - parts), finance_fee)
          end
        else
          # set finance fee discounts to 0
          FinanceFeeParticular.set_particular_finance_fee_discount_zero(particular_ids, finance_fee) if particular_ids.present?
        end
      elsif discount_mode == "NEW"
        FinanceFeeParticular.verify_or_create_finance_fee_discounts(finance_fee)
        discounts.map do |d|
          if d.master_receiver_type=='FinanceFeeParticular'
            sql1="UPDATE finance_fee_discounts ffd
                  INNER JOIN finance_fee_particulars ffp
                              ON ffp.id = ffd.finance_fee_particular_id
                             SET ffd.discount_amount = IF(#{d.is_amount},LEAST(ffp.amount,#{d.discount}),
                                                                          (#{d.discount.to_f} * ffp.amount * 0.01))
                        WHERE ffd.finance_fee_id=#{finance_fee.id} AND 
                                    ffd.finance_fee_particular_id=#{d.master_receiver_id} AND 
                                    ffd.fee_discount_id=#{d.id}"
            ActiveRecord::Base.connection.execute(sql1)
          else
            sql1="UPDATE finance_fee_discounts ffd
                  INNER JOIN finance_fee_particulars ffp
                              ON ffp.id = ffd.finance_fee_particular_id
                             SET ffd.discount_amount = IF(#{d.is_amount},
                                                                          ((#{d.discount.to_f}/#{total_payable.to_f}) * ffp.amount),
                                                                          (#{d.discount.to_f} * ffp.amount * 0.01))
                        WHERE ffd.finance_fee_id=#{finance_fee.id} AND 
                                    ffd.finance_fee_particular_id = ffd.finance_fee_particular_id AND 
                                    ffd.fee_discount_id=#{d.id}"
            ActiveRecord::Base.connection.execute(sql1)
          end
        end
      end
      # adjust tax collections of each particular wrt to finance fee discounts applicable
      if finance_fee.tax_enabled?
        if fee_particulars.present?
          precision_count = FedenaPrecision.get_precision_count
          sql = "UPDATE tax_collections tc
              INNER JOIN finance_fee_particulars ffp 
                          ON ffp.id=tc.taxable_entity_id AND 
                               tc.taxable_entity_type='FinanceFeeParticular'  AND			
                               tc.taxable_fee_id = #{finance_fee.id} AND
                               tc.taxable_fee_type = 'FinanceFee'
              INNER JOIN collectible_tax_slabs cts 
                          ON cts.collectible_entity_id=ffp.id AND 
                               cts.collectible_entity_type='FinanceFeeParticular' AND
                               cts.collection_id = #{finance_fee.fee_collection_id} AND
                               cts.collection_type = 'FinanceFeeCollection'
              INNER JOIN tax_slabs ts 
                          ON ts.id=cts.tax_slab_id 
                         SET tc.tax_amount = ROUND(
                                (ts.rate*0.01*GREATEST((ffp.amount - 
                                 IFNULL((SELECT SUM(discount_amount) 
                                     FROM finance_fee_discounts ffd 
                                   WHERE ffd.finance_fee_id = #{finance_fee.id} AND 
                                               ffd.finance_fee_particular_id = tc.taxable_entity_id),0)
                                  ),0)
                                 ),#{precision_count}
                              )
                   WHERE tc.taxable_fee_id = #{finance_fee.id} AND 
                               tc.taxable_fee_type='FinanceFee'"
          ActiveRecord::Base.connection.execute(sql)
        end
      end
      # set finance fee balance to particular total
      FinanceFeeParticular.set_fee_balance_to_particular_total(finance_fee)
      # minus total discount from finance fee balance, set total_discount column
      FinanceFeeParticular.subtract_discount_from_fee_balance(finance_fee)
      # add total tax to finance fee,set tax_amount column
      FinanceFeeParticular.add_tax_total_to_fee_balance(finance_fee) if finance_fee.tax_enabled?
      # subtract paid transaction amount (less fine amount) from finance fee balance
      # also update is_paid flag to true if balance is 0 and false if balance is greater than 0
      FinanceFeeParticular.subtract_paid_amount_from_fee_balance(finance_fee)
      # update particular payments & particular discounts
      # update tax payments
      # update tax amount in finance transaction records
    end

    def verify_or_create_finance_fee_discounts(fee)
      #    disc_ids = discounts.map(&:id)
      discounts = fee.fee_discounts
      particulars = fee.finance_fee_particulars
      particular_discounts = fee.finance_fee_discounts.group_by { |x| x.finance_fee_particular_id }
      ffd_initial = [fee.id]
      column_list = ['finance_fee_id', 'finance_fee_particular_id', 'fee_discount_id', 'discount_amount', 'created_at', 'updated_at']
      sql = "INSERT INTO `finance_fee_discounts` (#{column_list.join(',')}) VALUES "
      ffd_records = []
      particulars.each do |particular|
        #      puts particular.id
        particular_wise_discounts = discounts.select { |d| d.master_receiver_type == 'FinanceFeeParticular' and d.master_receiver_id == particular.id }
        common_discounts = discounts.select { |d| d.master_receiver_type != 'FinanceFeeParticular' }
        disc_ids = (particular_wise_discounts + common_discounts).map(&:id)
        discount_rec_exists = particular_discounts[particular.id]
        new_ffd = ffd_initial + [particular.id]
        discount_ids = discount_rec_exists.present? ? (disc_ids - discount_rec_exists.map(&:fee_discount_id)) : disc_ids
        #      puts discount_ids.inspect
        discount_ids.each { |d_id| ffd_records << new_ffd.dup + [d_id, 0, 'NOW()', 'NOW()'] }
      end
      if ffd_records.present?
        sql += " #{ffd_records.map { |x| "(#{x.join(',')})" }.join(',')}"
        ActiveRecord::Base.connection.execute(sql)
        fee.finance_fee_discounts.reload
      end
    end

    def create_finance_fee_discount finance_fee, particular
      finance_fee.finance_fee_discounts.create({:finance_fee_particular_id => particular.id,
                                                :discount_amount => 0})
    end

    def subtract_paid_amount_from_fee_balance finance_fee
      #    fine_amount_included
      sql="UPDATE finance_fees ff
                   SET ff.balance=ff.balance-
                                            (SELECT IFNULL(
                                                           SUM(finance_transactions.amount-
                                                                   finance_transactions.fine_amount),0)
                                                FROM finance_transactions 
                                              WHERE finance_transactions.finance_id=ff.id AND
                                                          finance_transactions.finance_type='FinanceFee'
                                            ),
                          ff.is_paid = IF(ff.balance > 0, false, true) 
              WHERE ff.id = #{finance_fee.id}"
      ActiveRecord::Base.connection.execute(sql)
    end

    def set_particular_finance_fee_discount_zero particular_ids, finance_fee
      part_condition = particular_ids.present? ? "AND ffd.finance_fee_particular_id in (#{particular_ids.join(',')})" : ""
      sql = "UPDATE finance_fee_discounts ffd
                       SET ffd.discount_amount = 0
                  WHERE ffd.finance_fee_id = #{finance_fee.id} #{part_condition}"
      ActiveRecord::Base.connection.execute(sql)
    end

    def set_fee_balance_to_particular_total(finance_fee)
      sql="UPDATE finance_fees ff
                     SET ff.particular_total=( 
                             SELECT IFNULL(SUM(finance_fee_particulars.amount),0) 
                                FROM finance_fee_particulars 
                        INNER JOIN collection_particulars 
                                    ON collection_particulars.finance_fee_particular_id=finance_fee_particulars.id  
                             WHERE collection_particulars.finance_fee_collection_id=#{finance_fee.fee_collection_id} AND 
                                         finance_fee_particulars.finance_fee_category_id='#{finance_fee.finance_fee_collection.fee_category_id}' AND 
                                         finance_fee_particulars.batch_id='#{finance_fee.batch_id}' AND
                                         (
                                            (finance_fee_particulars.receiver_type='Student' AND 
                                             finance_fee_particulars.receiver_id=ff.student_id) OR 
                                            (finance_fee_particulars.receiver_type='StudentCategory' AND 
                                             finance_fee_particulars.receiver_id=ff.student_category_id) OR 
                                            (finance_fee_particulars.receiver_type='Batch' AND 
                                             finance_fee_particulars.receiver_id=ff.batch_id)
                                        )
                             ), 
                            ff.balance = ff.particular_total
                WHERE ff.id = #{finance_fee.id}"
      ActiveRecord::Base.connection.execute(sql)
    end

    def subtract_discount_from_fee_balance(finance_fee)
      precision_count = FedenaPrecision.get_precision_count
      sql="UPDATE finance_fees ff
                     SET ff.discount_amount = ROUND(( 
                             SELECT IFNULL(SUM(ffd.discount_amount),0) 
                                FROM finance_fee_discounts ffd
                              WHERE ffd.finance_fee_id = #{finance_fee.id}
                            ),#{precision_count}),
                           ff.balance= ff.balance - IFNULL(ff.discount_amount,0)
                WHERE ff.id = #{finance_fee.id}"
      ActiveRecord::Base.connection.execute(sql)
    end

    def add_tax_total_to_fee_balance(finance_fee)
      precision_count = FedenaPrecision.get_precision_count
      sql="UPDATE finance_fees ff
                     SET ff.tax_amount = ( 
                             SELECT IFNULL(SUM(ROUND(tc.tax_amount,#{precision_count})),0) 
                                FROM tax_collections tc
                              WHERE tc.taxable_fee_type = 'FinanceFee' AND
                                          tc.taxable_fee_id = #{finance_fee.id}
                            ),
                           ff.balance= ff.balance + IFNULL(ROUND(ff.tax_amount,#{precision_count}),0)
                WHERE ff.id = #{finance_fee.id}"
      ActiveRecord::Base.connection.execute(sql)
    end

    ## function add_or_remove_particular_or_discount is deprecated after tax feature
    def add_or_remove_particular_or_discount(particular_or_discount, finance_fee_collection)
      receiver=particular_or_discount.receiver_type.underscore+"_id"

      sql1="UPDATE finance_fees ff
                     SET ff.balance=( SELECT IFNULL(sum(finance_fee_particulars.amount),0) 
                                                   FROM finance_fee_particulars 
                                           INNER JOIN collection_particulars 
                                                       ON collection_particulars.finance_fee_particular_id=finance_fee_particulars.id  
                                                WHERE collection_particulars.finance_fee_collection_id=#{finance_fee_collection.id} AND 
                                                            finance_fee_particulars.finance_fee_category_id='#{finance_fee_collection.fee_category_id}' AND 
                                                            finance_fee_particulars.batch_id='#{particular_or_discount.batch_id}' AND
                                                            (
                                                              (finance_fee_particulars.receiver_type='Student' AND 
                                                               finance_fee_particulars.receiver_id=ff.student_id) OR 
                                                              (finance_fee_particulars.receiver_type='StudentCategory' AND 
                                                               finance_fee_particulars.receiver_id=ff.student_category_id) OR 
                                                              (finance_fee_particulars.receiver_type='Batch' AND 
                                                               finance_fee_particulars.receiver_id=ff.batch_id)
                                                            )
                                            ) 
               WHERE ff.fee_collection_id=#{finance_fee_collection.id} AND 
                           ff.#{receiver}=#{particular_or_discount.receiver_id} AND 
                           ff.batch_id=#{particular_or_discount.batch_id}"
      ActiveRecord::Base.connection.execute(sql1)

      sql2="UPDATE finance_fees ff
                     SET ff.balance=ff.balance - 
                                              (SELECT 
                                                  IFNULL(
                                                             (SUM(ff.balance*(
                                                                      IF(fee_discounts.is_amount,
                                                                          (fee_discounts.discount/ff.balance),
                                                                          (fee_discounts.discount/100)
                                                                         )
                                                              ))),0
                                                   ) 
                                               FROM fee_discounts 
                                       INNER JOIN collection_discounts 
                                                   ON collection_discounts.fee_discount_id=fee_discounts.id 
                                            WHERE collection_discounts.finance_fee_collection_id=#{finance_fee_collection.id} AND 
                                                        fee_discounts.finance_fee_category_id='#{finance_fee_collection.fee_category_id}' AND 
                                                        fee_discounts.batch_id='#{particular_or_discount.batch_id}' AND 
                                                        fee_discounts.master_receiver_type<>'FinanceFeeParticular' AND 
                                                        ((fee_discounts.receiver_type='Student' AND 
                                                          fee_discounts.receiver_id=ff.student_id) OR 
                                                         (fee_discounts.receiver_type='StudentCategory' AND 
                                                          fee_discounts.receiver_id=ff.student_category_id) OR 
                                                         (fee_discounts.receiver_type='Batch' AND 
                                                          fee_discounts.receiver_id=ff.batch_id))) 
                WHERE ff.fee_collection_id=#{finance_fee_collection.id} AND 
                            ff.#{receiver}=#{particular_or_discount.receiver_id} AND 
                            ff.batch_id=#{particular_or_discount.batch_id}"

      ActiveRecord::Base.connection.execute(sql2)

      particular_wise_discount_subtraction_sql="UPDATE finance_fees ff
                     SET ff.balance=ff.balance-
                                             (SELECT IFNULL(
                                                            SUM((finance_fee_particulars.amount)*
                                                                    (IF(fd.is_amount,
                                                                         fd.discount/finance_fee_particulars.amount,
                                                                         fd.discount/100))
                                                                   ),0) 
                                              FROM finance_fee_particulars 
                                              INNER JOIN collection_discounts cd 
                                                          ON cd.finance_fee_collection_id=#{finance_fee_collection.id} 
                                              INNER JOIN fee_discounts fd 
                                                          ON fd.id=cd.fee_discount_id AND 
                                                                fd.master_receiver_type='FinanceFeeParticular' 
                                            WHERE finance_fee_particulars.id=fd.master_receiver_id AND 
                                                        finance_fee_particulars.finance_fee_category_id='#{finance_fee_collection.fee_category_id}' AND 
                                                        finance_fee_particulars.batch_id='#{particular_or_discount.batch_id}' AND 
                                                        ((fd.receiver_type='Student' AND fd.receiver_id=ff.student_id) OR 
                                                         (fd.receiver_type='StudentCategory' AND fd.receiver_id=ff.student_category_id) OR 
                                                         (fd.receiver_type='Batch' and fd.receiver_id=ff.batch_id))
                                             ) 
                     WHERE ff.fee_collection_id=#{finance_fee_collection.id} AND 
                                 ff.#{receiver}=#{particular_or_discount.receiver_id} AND 
                                 ff.batch_id=#{particular_or_discount.batch_id}"
      ActiveRecord::Base.connection.execute(particular_wise_discount_subtraction_sql)

      paid_fees_deduction_sql="Update finance_fees ff
                     SET ff.balance=ff.balance-
                                            (SELECT IFNULL(
                                                           SUM(finance_transactions.amount-
                                                                   finance_transactions.fine_amount),0) 
                                             FROM finance_transactions 
                                           WHERE finance_transactions.finance_id=ff.id) 
                     WHERE ff.fee_collection_id=#{finance_fee_collection.id} AND 
                                 ff.#{receiver}=#{particular_or_discount.receiver_id} AND 
                                 ff.batch_id=#{particular_or_discount.batch_id}"
      ActiveRecord::Base.connection.execute(paid_fees_deduction_sql)

      sql3="UPDATE finance_fees ff
                     SET ff.is_paid=(ff.balance<=0) 
                WHERE ff.fee_collection_id=#{finance_fee_collection.id} AND 
                            ff.#{receiver}=#{particular_or_discount.receiver_id} AND 
                            ff.batch_id=#{particular_or_discount.batch_id}"
      ActiveRecord::Base.connection.execute(sql3)
    end


    def has_unlinked_particulars? category_id = nil
      conditions = ["master_fee_particular_id IS NULL"]
      if category_id.present?
        conditions[0] += " AND finance_fee_category_id = ?"
        conditions << category_id
      end
      FinanceFeeParticular.count(:conditions => conditions) > 0
    end
  end

  def additional_ammount(c_id, start_date, end_date, particular_ids)
    amount=ParticularPayment.find(:all, :joins => [:finance_fee, :finance_transaction],
                                  :conditions => {:particular_payments => {:finance_fee_particular_id => particular_ids, :is_active => true},
                                                  :finance_fees => {:fee_collection_id => c_id, :is_paid => false},
                                                  :finance_transactions => {:transaction_date => start_date..end_date}},
                                  :select => "SUM(particular_payments.amount) as amount").sum.amount.to_f
  end

  private

  def check_discounts
    if FeeDiscount.find(:all, :conditions => "is_deleted = '#{false}' and finance_fee_category_id=#{finance_fee_category_id} and
                                              batch_id=#{batch_id}").present? and (amount_changed? or name_changed?)
      errors.add_to_base(t('discounts_exists_for_this_category_cant_delete_or_edit_this_particular'))

      return false
    end
  end


end
