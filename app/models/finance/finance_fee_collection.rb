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

class FinanceFeeCollection < ActiveRecord::Base
  belongs_to :batch
  has_many :finance_fees, :foreign_key => "fee_collection_id", :dependent => :destroy
  has_many :finance_transactions, :through => :finance_fees
  has_many :students, :through => :finance_fees
  has_many :fee_collection_particulars, :dependent => :destroy
  has_many :fee_collection_discounts, :dependent => :destroy
  belongs_to :fee_category, :class_name => "FinanceFeeCategory"
  has_one :event, :as => :origin, :dependent => :destroy
  belongs_to :fine, :conditions => "fines.is_deleted is false"
  has_many :batches, :through => :fee_collection_batches
  has_many :fee_collection_batches
  has_many :fee_discounts, :through => :collection_discounts
  has_many :collection_discounts, :dependent => :destroy
  has_many :finance_fee_particulars, :through => :collection_particulars
  has_many :collection_particulars, :dependent => :destroy
  has_many :refund_rules
  belongs_to :financial_year
  attr_accessor :invoice_number_enabled
  has_many :master_particular_reports, :as => :collection
  has_many :collection_master_particular_reports, :as => :collection
  # tax associations
  has_many :collectible_tax_slabs, :as => :collection, :dependent => :destroy
  has_many :collection_tax_slabs, :through => :collectible_tax_slabs, :class_name => "TaxSlab"
  belongs_to :fee_account

  named_scope :active, {:conditions => "finance_fee_collections.is_deleted = false"}
  named_scope :current_active_financial_year, lambda { |x|
                 {:conditions => ["finance_fee_collections.financial_year_id #{FinancialYear.current_financial_year_id.present? ? '=' : 'IS'} ?",
                                   FinancialYear.current_financial_year_id]} }

  include CsvExportMod

  validates_presence_of :name, :start_date, :fee_category_id, :due_date

  before_create :check_and_apply_discount_mode # sets/corrects discount mode before creating collection
  #  after_create :create_associates

  def validate
    if self.start_date.present? && self.due_date.present?
      errors.add_to_base :start_date_cant_be_after_due_date if self.start_date > self.due_date
      #      errors.add_to_base :start_date_cant_be_after_due_date if self.start_date > self.due_date
      #      errors.add_to_base :end_date_cant_be_after_due_date if self.end_date > self.due_date
      if self.financial_year_id == '0'
        if (FinancialYear.last(:conditions => ["start_date BETWEEN ? AND ? OR end_date BETWEEN ? AND ?",
                                               self.start_date, self.due_date, self.start_date, self.due_date])).present?

        end
        self.financial_year_id = nil
      elsif self.financial_year_id.present?
        fy = FinancialYear.find_by_id(self.financial_year_id)
        errors.add_to_base :financial_year_must_be_set unless fy.present?
        errors.add_to_base :date_range_must_be_within_financial_year if fy.present? and
            !(self.start_date >= fy.try(:start_date) && self.due_date <= fy.try(:end_date))
      else
        # errors.add_to_base :financial_year_must_be_set
      end
    else

    end
  end

  def full_name
    "#{name} - #{format_date(start_date).to_s}"
  end

  def fee_transactions(student_id)
    FinanceFee.find_by_fee_collection_id_and_student_id(self.id, student_id)
  end

  def check_transaction(transactions)
    transactions.finance_fees_id.nil? ? false : true
  end

  def fee_table
    self.finance_fees.all(:conditions => "is_paid = 0")
  end

  def self.shorten_string(string, count)
    if string.length >= count
      shortened = string[0, count]
      splitted = shortened.split(/\s/)
      words = shortened.length
      splitted[0, words-1].join(" ") + ' ...'
    else
      string
    end
  end

  def check_fee_category(batch)
    !has_paid_fees_for_the_batch?(batch)
  end

  def check_multi_discount(batch)
    collection_discounts.map do |cd|
      fd = cd.fee_discount
      next unless fd.batch_id == batch.id
      fd.multi_fee_discount.present? ? 1 : 0
    end.flatten.compact.sum > 0
  end

  def has_paid_fees_for_the_batch?(batch)
    FinanceTransaction.find(:all,
                            :joins => "INNER JOIN fee_transactions on finance_transactions.id = fee_transactions.finance_transaction_id
              INNER JOIN finance_fees on finance_fees.id=fee_transactions.finance_fee_id
              INNER JOIN students on students.id=finance_fees.student_id",
                            :conditions => ["finance_fees.fee_collection_id=#{id} and finance_fees.batch_id=#{batch}"]
    ).present?

  end

  #    finance_fees = FinanceFee.find_all_by_fee_collection_id(self.id)
  #    flag = 1
  #    finance_fees.each do |f|
  #      flag = 0 unless f.transaction_id.nil?
  #    end
  #    flag == 1 ? true : false
  #  end

  #  def no_transaction_present
  #    f = FinanceFee.find_all_by_fee_collection_id(self.id)
  #    f.reject! {|x|x.transaction_id.nil?} unless f.nil?
  #    f.blank?
  #  end

  def create_associates

    #    discounts=FeeDiscount.find_all_by_finance_fee_category_id(self.fee_category_id,:conditions=>"is_deleted=0")
    #    discounts.each do |discount|
    #      CollectionDiscount.create(:fee_discount_id=>discount.id,:finance_fee_collection_id=>id)
    #    end
    #    particlulars = FinanceFeeParticular.find_all_by_finance_fee_category_id(self.fee_category_id,:conditions=>"is_deleted=0")
    #    particlulars.each do |particular|
    #      CollectionParticular.create(:finance_fee_particular_id=>particular.id,:finance_fee_collection_id=>id)
    #    end
    #
    #    batch_discounts = BatchFeeDiscount.find_all_by_finance_fee_category_id(self.fee_category_id)
    #    batch_discounts.each do |discount|
    #      discount_attributes = discount.attributes
    #      discount_attributes.delete "type"
    #      discount_attributes.delete "finance_fee_category_id"
    #      discount_attributes["finance_fee_collection_id"]= self.id
    #      BatchFeeCollectionDiscount.create(discount_attributes)
    #    end
    #    category_discount = StudentCategoryFeeDiscount.find_all_by_finance_fee_category_id(self.fee_category_id)
    #    category_discount.each do |discount|
    #      discount_attributes = discount.attributes
    #      discount_attributes.delete "type"
    #      discount_attributes.delete "finance_fee_category_id"
    #      discount_attributes["finance_fee_collection_id"]= self.id
    #      StudentCategoryFeeCollectionDiscount.create(discount_attributes)
    #    end
    #    student_discount = StudentFeeDiscount.find_all_by_finance_fee_category_id(self.fee_category_id)
    #    student_discount.each do |discount|
    #      discount_attributes = discount.attributes
    #      discount_attributes.delete "type"
    #      discount_attributes.delete "finance_fee_category_id"
    #      discount_attributes["finance_fee_collection_id"]= self.id
    #      StudentFeeCollectionDiscount.create(discount_attributes)
    #    end
    #    particlulars = FinanceFeeParticular.find_all_by_finance_fee_category_id(self.fee_category_id,:conditions=>"is_deleted=0")
    #    particlulars.each do |p|
    #      particlulars_attributes = p.attributes
    #      particlulars_attributes.delete "finance_fee_category_id"
    #      particlulars_attributes["finance_fee_collection_id"]= self.id
    #      FeeCollectionParticular.create(particlulars_attributes)
    #    end
  end

  def fees_particulars(student)
    FeeCollectionParticular.find_all_by_finance_fee_collection_id(self.id,
                                                                  :conditions => ["((student_category_id IS NULL AND admission_no IS NULL )OR(student_category_id = '#{student.student_category_id}'AND admission_no IS NULL) OR (student_category_id IS NULL AND admission_no = '#{student.admission_no}')) and is_deleted=0"])
  end

  def transaction_total(start_date, end_date, batch_id)
    total=0
    FinanceFee.find(:all, :joins => "INNER JOIN students on finance_fees.student_id=students.id ", :conditions => ["students.batch_id='#{batch_id}' and finance_fees.fee_collection_id='#{id}'"]).each do |ff|
      total =total+ff.finance_transactions.all(:conditions => "transaction_date >= '#{start_date}' AND transaction_date <= '#{end_date}'").map { |t| t.amount }.sum
    end
    #trans=finance_fees.map{|ff| ff.finance_transactions.all(:conditions=>"transaction_date >= '#{start_date}' AND transaction_date <= '#{end_date}'")}
    #trans = self.finance_transactions.all(:conditions=>"transaction_date >= '#{start_date}' AND transaction_date <= '#{end_date}'")
    #total = trans.map{|t|t.amount}.sum
    return total
  end

  def student_fee_balance(student)
    #    particulars= self.fees_particulars(student)
    student_type = student.class.name
    financefee = self.fee_transactions(student.id) if student_type == 'Student'
    financefee = self.fee_transactions(student.former_id) if student_type == 'ArchivedStudent'
    particulars=finance_fee_particulars.all(:conditions => "batch_id=#{financefee.batch_id}").select { |par| (par.receiver.present?) and (par.receiver==student or par.receiver==student.student_category or par.receiver==financefee.batch) }
    paid_fees = financefee.finance_transactions if financefee.present?

    discounts=fee_discounts.all(:conditions => "batch_id=#{financefee.batch_id}").select { |par| (par.receiver.present?) and (par.receiver==student or par.receiver==student.student_category or par.receiver==financefee.batch) }
    total_discount = 0
    total_fees=particulars.map { |s| s.amount }.sum.to_f
    total_discount =discounts.map { |d| total_fees * d.discount.to_f/(d.is_amount? ? total_fees : 100) }.sum.to_f unless discounts.nil?

    total_fees -= total_discount

    unless paid_fees.nil?
      paid = 0
      fine = 0
      paid += paid_fees.collect { |x| x.amount.to_f }.sum
      total_fees -= paid
      #trans = FinanceTransaction.find(financefee.transaction_id)
      fine += paid_fees.collect { |f| f.fine_amount.to_f }.sum
      total_fees += fine
      #unless trans.nil?
      #total_fees += trans.fine_amount.to_f if trans.fine_included
      # end
    end
    return total_fees
  end

  def fee_collection_emails
    emails=[]
    emails<<self.students.collect(&:email)
    self.students.each do |s|
      emails<<s.guardians.collect(&:email);
    end
    emails.flatten.reject! { |e| e.blank? }
  end

  def self.fetch_finance_fee_collection_data(params)
    finance_fee_collection_data(params)
  end

  def self.fetch_finance_fee_course_wise_data(params)
    finance_fee_course_data(params)
  end

  def self.fee_collection_details(parameters)
    sort_order=parameters[:sort_order]
    batch_id=parameters[:batch_id]
    if batch_id.nil?
      if sort_order.nil?
        fee_collection= FinanceFeeCollection.all(:select => "finance_fee_collections.*,batches.name as batch_name,courses.code,finance_fee_categories.name as category_name", :joins => "INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN batches on batches.id=fee_collection_batches.batch_id INNER JOIN `finance_fee_categories` ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id", :conditions => {:batches => {:is_deleted => false, :is_active => true}, :is_deleted => false}, :order => 'name ASC')
      else
        fee_collection= FinanceFeeCollection.all(:select => "finance_fee_collections.*,batches.name as batch_name,courses.code,finance_fee_categories.name as category_name", :joins => "INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN batches on batches.id=fee_collection_batches.batch_id INNER JOIN `finance_fee_categories` ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id", :conditions => {:batches => {:is_deleted => false, :is_active => true}, :is_deleted => false}, :order => sort_order)
      end
    else
      if sort_order.nil?
        fee_collection= FinanceFeeCollection.all(:select => "finance_fee_collections.*,batches.name as batch_name,courses.code,finance_fee_categories.name as category_name", :joins => "INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN batches on batches.id=fee_collection_batches.batch_id INNER JOIN `finance_fee_categories` ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id", :conditions => {:batches => {:is_deleted => false, :is_active => true, :id => batch_id[:batch_ids]}, :is_deleted => false}, :order => 'name ASC')
      else
        fee_collection= FinanceFeeCollection.all(:select => "finance_fee_collections.*,batches.name as batch_name,courses.code,finance_fee_categories.name as category_name", :joins => "INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id INNER JOIN batches on batches.id=fee_collection_batches.batch_id INNER JOIN `finance_fee_categories` ON `finance_fee_categories`.id = `finance_fee_collections`.fee_category_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id", :conditions => {:batches => {:is_deleted => false, :is_active => true, :id => batch_id[:batch_ids]}, :is_deleted => false}, :order => sort_order)
      end
    end
    data=[]
    col_heads=["#{t('no_text')}", "#{t('fee_collection')} #{t('name')}", "#{t('batch_name')}", "#{t('category_name')}", "#{t('start_date')}", "#{t('due_date')}"]
    data << col_heads
    fee_collection.each_with_index do |f, i|
      col=[]
      col<< "#{i+1}"
      col<< "#{f.name}"
      col<< "#{f.code}-#{f.batch_name}"
      col<< "#{f.category_name}"
      col<< "#{format_date(f.start_date)}"
      #      col<< "#{format_date(f.end_date)}"
      col<< "#{format_date(f.due_date)}"
      col=col.flatten
      data<< col
    end
    return data
  end

  def self.batch_fee_collections(parameters)
    batch_id = parameters[:batch_id]
    fee_collections = FinanceFeeCollection.all(:select => "finance_fee_collections.id,finance_fee_collections.name,
      finance_fee_collections.start_date,finance_fee_collections.end_date,finance_fee_collections.due_date,
      sum(IF(students.id IS NOT NULL AND finance_fee_collections.is_deleted = false AND
      finance_fee_collections.due_date < '#{Date.today}' AND finance_fees.balance > 0.0,finance_fees.balance,0)) as balance,
      count(IF(finance_fees.balance!='0.0' and students.id IS NOT NULL,finance_fees.id,NULL)) as students_count",
     :joins => "INNER JOIN `finance_fees` ON finance_fees.fee_collection_id = finance_fee_collections.id
                INNER JOIN `batches` ON `batches`.id = `finance_fees`.batch_id
                INNER JOIN students on students.id=finance_fees.student_id
                 LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id",
     :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND finance_fees.batch_id=? and
      finance_fee_collections.is_deleted=? and finance_fee_collections.due_date < ? and finance_fees.balance> ?",
                     batch_id, false, Date.today, 0.0], :group => "id", :order => "balance DESC")

    if FedenaPlugin.can_access_plugin?("fedena_transport")
      fee_collections_transport = TransportFeeCollection.all(
        :select => "transport_fee_collections.id,transport_fee_collections.name,transport_fee_collections.start_date,
                    transport_fee_collections.end_date,transport_fee_collections.due_date,
                    sum(IF(receiver_type='Student' and students.id IS NOT NULL and
                           transport_fee_collections.is_deleted = false and
                           transport_fee_collections.due_date<'#{Date.today}' and transport_fees.balance > 0.0,
                           transport_fees.balance,NULL)) as balance,
                    count(DISTINCT IF(receiver_type='Student' and transport_fees.balance!='0.0' and
                          students.id IS NOT NULL,transport_fees.id,NULL)) as students_count",
        :joins => "INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id
                   INNER JOIN students on students.id=transport_fees.receiver_id and transport_fees.receiver_type='Student'
                   INNER JOIN batches on students.batch_id=batches.id
                    LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id",
        :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND batches.id=? and
                          transport_fee_collections.is_deleted=? and receiver_type='Student' and
                          students.id IS NOT NULL and transport_fee_collections.due_date<'#{Date.today}' and
                          transport_fees.balance > ? AND `transport_fees`.`is_active` = ?",
          batch_id, false, 0.0,true], :group => "transport_fee_collections.id", :order => "balance DESC")
      fee_collections += fee_collections_transport
    end

    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      fee_collections_hostel = HostelFeeCollection.all(:select => "hostel_fee_collections.id,hostel_fee_collections.name,
         hostel_fee_collections.start_date,hostel_fee_collections.end_date,hostel_fee_collections.due_date,
         sum(IF(students.id IS NOT NULL and hostel_fee_collections.is_deleted = false and
         hostel_fee_collections.due_date < '#{Date.today}' and hostel_fees.balance > 0.0,hostel_fees.balance,0)) as balance,
         count(DISTINCT IF(students.id IS NOT NULL and hostel_fees.balance!='0.0',hostel_fees.id,NULL)) as students_count",
        :joins => "INNER JOIN hostel_fees on hostel_fees.hostel_fee_collection_id=hostel_fee_collections.id
                   INNER JOIN students on hostel_fees.student_id=students.id
                   INNER JOIN batches on students.batch_id=batches.id
                    LEFT JOIN fee_accounts fa ON fa.id = hostel_fee_collections.fee_account_id",
        :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND batches.id=? and
          hostel_fee_collections.is_deleted = ? and hostel_fee_collections.due_date < ? and hostel_fees.balance > ? AND
          `hostel_fees`.`is_active` = ?", batch_id, false, Date.today, 0, true], :group => "hostel_fee_collections.id",
        :order => "balance DESC")

      fee_collections += fee_collections_hostel
    end

    data=[]
    col_heads=["#{t('no_text')}", "#{t('name')}", "#{t('start_date')}", "#{t('due_date')}", "#{t('students')}", "#{t('balance')}(#{Configuration.currency})"]
    data << col_heads
    total=0
    fee_collections.each_with_index do |b, i|
      col=[]
      col<< "#{i+1}"
      col<< "#{b.name}"
      col<< "#{format_date(b.start_date.to_date)}"
      #      col<< "#{format_date(b.end_date.to_date)}"
      col<< "#{format_date(b.due_date.to_date)}"
      col<< "#{b.students_count}"
      balance=b.balance.nil? ? 0 : b.balance
      total+=balance.to_f
      col<< "#{balance}"
      col=col.flatten
      data<< col
    end
    data << ["#{t('total_amount')}", "", "", "", "", total]
    return data
  end

  def self.get_particular_student_number(start_date, end_date)
    conditions = "finance_fees.is_paid = 1 and
                          particular_payments.id is NULL and
                          ((finance_fee_particulars.receiver_type='Batch' and
                            finance_fee_particulars.receiver_id=finance_fees.batch_id) or
                           (finance_fee_particulars.receiver_type='StudentCategory' and
                            finance_fee_particulars.receiver_id=finance_fees.student_category_id) or
                           (finance_fee_particulars.receiver_type='Student' and
                            finance_fee_particulars.receiver_id=finance_fees.student_id)) and
                          finance_transactions.transaction_date >= '#{start_date}' and
                          finance_transactions.transaction_date <='#{end_date}' and
                          finance_fees.batch_id=finance_fee_particulars.batch_id"
    particualrs=FinanceFeeCollection.all(
        :joins => "#{joins}",
        :conditions => "#{conditions}",
        :select => "count(distinct finance_fees.id) AS student_count,
                         finance_fees.fee_collection_id AS collection_id,
                         finance_fee_particulars.id AS particular_id,
                         finance_fee_particulars.amount AS amount,
                         finance_fee_particulars.name AS name",
        :group => "finance_fee_collections.id,finance_fee_particulars.id",
        :order => "collection_id"
    )
    return particualrs
  end

  def self.joins
    "#{collection_particular_inner_join}
    #{collection_particulars_join_finance_fee_particulars}
    #{fee_collection_inner_join_finance_fee} #{fee_transcation_inner_join_finance_fee}
    #{fee_payments_inner_join_fee_transactions}
    #{particular_payments_left_outer_join_transactions}"
  end

  def self.collection_particular_inner_join
    "INNER JOIN `collection_particulars`
                 ON (`finance_fee_collections`.`id` = `collection_particulars`.`finance_fee_collection_id`)"
  end

  def self.collection_particulars_join_finance_fee_particulars
    "INNER JOIN `finance_fee_particulars`
                 ON (`finance_fee_particulars`.`id` = `collection_particulars`.`finance_fee_particular_id`)"
  end

  def self.fee_collection_inner_join_finance_fee
    "INNER JOIN `finance_fees`
                 ON  finance_fees.fee_collection_id = finance_fee_collections.id"
  end

  def self.fee_transcation_inner_join_finance_fee
    "INNER JOIN `fee_transactions`
                 ON finance_fees.id= `fee_transactions`.finance_fee_id"
  end

  def self.fee_payments_inner_join_fee_transactions
    "INNER JOIN `finance_transactions`
                 ON `finance_transactions`.id = `fee_transactions`.finance_transaction_id"
  end

  def self.particular_payments_left_outer_join_transactions
    "LEFT OUTER JOIN particular_payments
                          ON particular_payments.finance_transaction_id = finance_transactions.id AND
                                finance_fees.is_paid=0"
  end

  def delete_collection(batch)
    FeeCollectionBatch.destroy_all(:finance_fee_collection_id => id, :batch_id => batch)
    batch_event=BatchEvent.find(:first,
                                :joins => "INNER JOIN events on events.id=batch_events.event_id",
                                :conditions => "batch_events.batch_id=#{batch} and
                               events.origin_id=#{id} and
                               events.origin_type='FinanceFeeCollection'")
    batch_event.destroy if batch_event
    #update_attributes(:is_deleted => true)
    unless fee_collection_batches.present?
      Event.destroy_all(:origin_type => "FinanceFeeCollection", :origin_id => id)
      update_attributes(:is_deleted => true)
      CollectionParticular.destroy_all(:finance_fee_collection_id => id)
    end
  end


  def fine_to_pay(student)
    financefee = student.finance_fee_by_date(self)
    fee_particulars = finance_fee_particulars.all(:conditions => "batch_id=#{financefee.batch_id}").
        select do |par|
      (par.receiver.present?) and
          (par.receiver==student or
              par.receiver==financefee.student_category or
              par.receiver==financefee.batch)
    end
    discounts=fee_discounts.all(:conditions => "batch_id=#{financefee.batch_id}").
        select do |par|
      (par.receiver.present?) and ((par.receiver==financefee.student or
          par.receiver==financefee.student_category or
          par.receiver==financefee.batch) and
          (par.master_receiver_type!='FinanceFeeParticular' or
              (par.master_receiver_type=='FinanceFeeParticular' and
                  (par.master_receiver.receiver==financefee.student or
                      par.master_receiver.receiver==financefee.student_category or
                      par.master_receiver.receiver==financefee.batch))))
    end
    # discounts=fee_discounts.all(:conditions=>"batch_id=#{financefee.batch_id}").select{|par|  (par.receiver.present?) and (par.receiver==student or par.receiver==financefee.student_category or par.receiver==financefee.batch) }

    total_discount = 0
    fine_amount = 0
    total_payable=fee_particulars.map { |s| s.amount }.sum.to_f
    total_discount =discounts.map do |d|
      d.master_receiver_type=='FinanceFeeParticular' ?
          (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ?
              d.master_receiver.amount : 100)) : total_payable * d.discount.to_f/(d.is_amount? ?
          total_payable : 100)
    end.sum.to_f unless discounts.nil?
    bal=(total_payable-total_discount).to_f
    payment_date=financefee.is_paid_with_fine? ? financefee.finance_transactions.last.
        try(:transaction_date) : Date.today
    automatic_fine_paid=financefee.finance_transactions.all(
        :conditions => "description='fine_amount_included'").collect(&:fine_amount).sum.to_f
    days=(payment_date-due_date.to_date).to_i
    auto_fine=fine
    if days > 0 and auto_fine and !financefee.is_fine_waiver
      if Configuration.is_fine_settings_enabled? && financefee.balance == 0 && financefee.is_paid == false && financefee.balance_fine.present?
            fine_amount = financefee.balance_fine
      else
      fine_rule=auto_fine.fine_rules.find(:last,
                                          :conditions => ["fine_days <= '#{days}' and created_at <= '#{created_at}'"],
                                          :order => 'fine_days ASC')
      fine_amount=fine_rule.is_amount ? fine_rule.fine_amount : (bal*fine_rule.fine_amount)/100 if fine_rule
      fine_amount= fine_amount-automatic_fine_paid
      end
    else
      fine_amount = 0.0
    end
    return (fine_amount)
  end

  def has_linked_unlinked_masters check_all_fees = true, student_id = nil
    status = has_unlinked_particulars?(check_all_fees, student_id) && has_linked_particulars?(check_all_fees, student_id)
    status ||= has_unlinked_discounts?(check_all_fees, student_id) && has_linked_discounts?(check_all_fees, student_id)
  end

  def has_unlinked_particulars?(check_all_fees, student_id)
    joins = "INNER JOIN collection_particulars cp ON cp.finance_fee_particular_id = finance_fee_particulars.id
             INNER JOIN finance_fee_collections ffc ON ffc.id = cp.finance_fee_collection_id"
    conditions = "ffc.id = ? AND finance_fee_particulars.master_fee_particular_id IS NULL"
    condition_vars = [self.id]
    unless check_all_fees
      joins += " INNER JOIN finance_fees ff ON ff.fee_collection_id = ffc.id"
      conditions += " AND ff.student_id = ?"
      condition_vars << student_id
    end

    FinanceFeeParticular.count(:joins => joins, :conditions => [conditions] + condition_vars) > 0
  end

  def has_linked_particulars?(check_all_fees, student_id)
    joins = "INNER JOIN collection_particulars cp ON cp.finance_fee_particular_id = finance_fee_particulars.id
             INNER JOIN finance_fee_collections ffc ON ffc.id = cp.finance_fee_collection_id"
    conditions = "ffc.id = ? AND finance_fee_particulars.master_fee_particular_id IS NOT NULL"
    condition_vars = [self.id]
    unless check_all_fees
      joins += " INNER JOIN finance_fees ff ON ff.fee_collection_id = ffc.id"
      conditions += " AND ff.student_id = ?"
      condition_vars << student_id
    end

    FinanceFeeParticular.count(:joins => joins, :conditions => [conditions] + condition_vars) > 0
  end

  def has_unlinked_discounts?(check_all_fees, student_id)
    joins = "INNER JOIN collection_discounts cd ON cd.fee_discount_id = fee_discounts.id
             INNER JOIN finance_fee_collections ffc ON ffc.id = cd.finance_fee_collection_id"
    conditions = "ffc.id = ? AND fee_discounts.master_fee_discount_id IS NULL"
    condition_vars = [self.id]
    unless check_all_fees
      joins += " INNER JOIN finance_fees ff ON ff.fee_collection_id = ffc.id"
      conditions += " AND ff.student_id = ?"
      condition_vars << student_id
    end

    FeeDiscount.count(:joins => joins, :conditions => [conditions] + condition_vars) > 0
  end

  def has_linked_discounts?(check_all_fees, student_id)
    joins = "INNER JOIN collection_discounts cd ON cd.fee_discount_id = fee_discounts.id
             INNER JOIN finance_fee_collections ffc ON ffc.id = cd.finance_fee_collection_id"
    conditions = "ffc.id = ? AND fee_discounts.master_fee_discount_id IS NOT NULL"
    condition_vars = [self.id]
    unless check_all_fees
      joins += " INNER JOIN finance_fees ff ON ff.fee_collection_id = ffc.id"
      conditions += " AND ff.student_id = ?"
      condition_vars << student_id
    end

    FeeDiscount.count(:joins => joins, :conditions => [conditions] + condition_vars) > 0
  end

  private

  def check_and_apply_discount_mode
    valid_discount_modes = ['OLD_DISCOUNT', 'NEW_DISCOUNT']
    new_school_check = Configuration.get_config_value('SchoolDiscountMarker')
    if new_school_check.present? and new_school_check == "NEW_DISCOUNT_MODE"
      self.discount_mode = "NEW_DISCOUNT_MODE"
    else
      discount_mode = Configuration.get_config_value('FinanceDiscountMode') || "OLD_DISCOUNT"
      self.discount_mode = valid_discount_modes.include?(discount_mode) ? discount_mode : "OLD_DISCOUNT"
    end
  end

end
