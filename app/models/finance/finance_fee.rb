require 'fee_collection_report'
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
class FinanceFee < ActiveRecord::Base

  belongs_to :finance_fee_collection, :foreign_key => 'fee_collection_id'
  delegate :name,:to=>:finance_fee_collection,:allow_nil=>true
  has_many :finance_transactions, :as => :finance
  has_many :cancelled_finance_transactions, :as => :finance
  has_many :components, :class_name => 'FinanceFeeComponent', :foreign_key => 'fee_id'
  belongs_to :student
  belongs_to :batch
  belongs_to :student_category
  has_many :finance_transactions, :through => :fee_transactions, :dependent => :destroy, :order => "finance_transactions.id DESC"
  has_many :fee_transactions
  has_one :fee_refund
  has_many :particular_payments, :dependent => :destroy
  has_many :finance_fee_particulars,:finder_sql=>'select finance_fee_particulars.* from finance_fee_particulars inner join collection_particulars cp on cp.finance_fee_collection_id=#{self.fee_collection_id} and cp.finance_fee_particular_id=finance_fee_particulars.id where finance_fee_particulars.batch_id=#{self.batch_id || 0} and ((finance_fee_particulars.receiver_type="Batch" and finance_fee_particulars.receiver_id=#{self.batch_id || 0}) or (finance_fee_particulars.receiver_type="StudentCategory" and finance_fee_particulars.receiver_id=#{self.student_category_id|| 0}) or (finance_fee_particulars.receiver_type="Student" and finance_fee_particulars.receiver_id=#{self.student_id}))'
  has_many :fee_discounts,:finder_sql=>'select fee_discounts.* from fee_discounts inner join collection_discounts cd on cd.finance_fee_collection_id=#{self.fee_collection_id} and cd.fee_discount_id=fee_discounts.id where fee_discounts.batch_id=#{self.batch_id || 0} and ((fee_discounts.receiver_type="Batch" and fee_discounts.receiver_id=#{self.batch_id || 0}) or (fee_discounts.receiver_type="StudentCategory" and fee_discounts.receiver_id=#{self.student_category_id || 0}) or (fee_discounts.receiver_type="Student" and fee_discounts.receiver_id=#{self.student_id || 0}))'

  #invoice associations
  has_many :fee_invoices, :as => :fee
  #discount associations
  has_many :finance_fee_discounts, :dependent => :destroy
  has_one :multi_fee_discount, :as => :fee, :dependent => :destroy
  #tax associations
  has_many :tax_payments, :as => :taxed_fee, :dependent => :destroy
  has_many :taxed_particulars, :through => :tax_payments, :source => :taxed_entity, :source_type => "FinanceFeeParticular"

  has_many :tax_collections, :as => :taxable_fee, :dependent => :destroy
  has_many :tax_particulars, :through => :tax_collections, :source => :taxable_entity, :source_type => "FinanceFeeParticular"
  has_one :fine_cancel_tracker, :as => :fine_tracker
  accepts_nested_attributes_for :particular_payments
  named_scope :active, :joins => [:finance_fee_collection], :conditions => {:finance_fee_collections => {:is_deleted => false}}
  attr_accessor :invoice_number_enabled
  attr_accessor :enable_invoice_generation
  after_create :add_invoice_number, :if => Proc.new { |fee| fee.enable_invoice_generation &&
      fee.invoice_number_enabled.present? }
  after_create :trigger_update_collection_master_particular_reports
  after_destroy :trigger_update_collection_master_particular_reports
  before_destroy :mark_invoice_number_deleted

  validates_uniqueness_of :fee_collection_id,:scope=>:student_id

  def trigger_update_collection_master_particular_reports
    if self.destroyed?
      clean_associated_data
      Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('remove', self))
      # Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('remove', self, {:collection => self.collection_for_batch}))
    else
      Delayed::Job.enqueue(DelayedCollectionMasterParticularReport.new('insert', self))
    end
  end

  def paid_auto_fine
    finance_transactions.all(
      :conditions => ["description=?", 'fine_amount_included']).map do |x|
      x.auto_fine.to_f > 0 ? x.auto_fine.to_f : x.fine_amount.to_f
    end.sum.to_f
  end
  
  def check_transaction_done
    unless self.transaction_id.nil?
      return true
    else
      return false
    end
  end
  
  def can_add_instant_particular?
    !(fee_discounts.select {|x| x.multi_fee_discount_id.present? }.present?)
  end

  def invoice_no
    fee_invoices.present? ? fee_invoices.try(:first).try(:invoice_number) : ""
  end

  def add_invoice_number invoice_no_config = nil
    FeeInvoice.create_with_failsafe(self, invoice_no_config)
  end

  def mark_invoice_number_deleted
    fee_invoice = fee_invoices.try(:last)
    fee_invoice.mark_deleted if fee_invoice.present?
  end

  def former_student
    ArchivedStudent.find_by_former_id(self.student_id)
  end

  def due_date
    format_date(finance_fee_collection.due_date, :format => :long)
  end

  def payee_name
    if student
      "#{student.full_name} - #{student.admission_no}"
    elsif former_student
      "#{former_student.full_name} - #{former_student.admission_no}"
    else
      "#{t('user_deleted')}"
    end
  end

  def school_discount_mode
    new_discount_modes = ["NEW_DISCOUNT", "NEW_DISCOUNT_MODE"]
    old_discount_modes = ["OLD_DISCOUNT"]

    return "OLD" if old_discount_modes.include?(self.finance_fee_collection.discount_mode)
    return "NEW" if new_discount_modes.include?(self.finance_fee_collection.discount_mode)
  end

  def self.new_student_fee(date, student, trigger_invoice_generation = true)
    tax_enabled = date.tax_enabled?
    if tax_enabled
      particular_tax_slab = {}
      collection_tax_slabs = date.collectible_tax_slabs.all(:include => [:collection_tax_slab, :collectible_entity])
      collection_tax_slabs.each {|cts| particular_tax_slab[cts.collectible_entity_id] = cts.collection_tax_slab }
    end

    include_particular_associations = []
    fee_particulars = date.finance_fee_particulars.all(:include => include_particular_associations,
      :conditions => "batch_id=#{student.batch_id}").select { |par| (par.receiver.present?) and
        (par.receiver==student or par.receiver==student.student_category or
          par.receiver==student.batch) }
    discounts=date.fee_discounts.all(:conditions => "batch_id=#{student.batch_id}").
      select { |par| (par.receiver.present?) and (
        (par.receiver== student or par.receiver == student.student_category or
            par.receiver== student.batch) and
          (par.master_receiver_type!='FinanceFeeParticular' or
            (par.master_receiver_type=='FinanceFeeParticular' and
              (par.master_receiver.receiver.present? and par.master_receiver.is_deleted==false) and
              (par.master_receiver.receiver== student or
                par.master_receiver.receiver == student.student_category or
                par.master_receiver.receiver== student.batch)))) }

    finance_fee = FinanceFee.new(:student_id => student.id, :fee_collection_id => date.id,
      :batch_id => student.batch_id, :student_category_id => student.student_category_id,
      :tax_enabled => date.tax_enabled, :invoice_number_enabled => date.invoice_enabled
    )

    finance_fee.enable_invoice_generation = trigger_invoice_generation

    total_discount = 0
    total_tax = 0 if tax_enabled
    tax_arr = [] if tax_enabled
    total_payable =fee_particulars.map { |l| l.amount }.sum.to_f

    particular_discounts = {}
    common_discounts = []
    #discount mode
    discount_mode = finance_fee.school_discount_mode

    total_discount_amount = discounts.map { |d| d.master_receiver_type=='FinanceFeeParticular' ?
        (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) :
        total_payable * d.discount.to_f/(d.is_amount? ? total_payable : 100)
    }.sum.to_f if discount_mode == "OLD" and discounts.present?

    # extract discounts for batch/student/student_category or particular level
    if fee_particulars.present? and discount_mode == "NEW"
      discounts.map do |d|
        if d.master_receiver_type=='FinanceFeeParticular'
          p_amount = d.master_receiver.amount
          discount_amount = d.is_amount? ? d.discount.to_f  : (p_amount * d.discount.to_f * 0.01)
          finance_fee.finance_fee_discounts.build({ :discount_amount => discount_amount,
              :fee_discount_id => d.id, :finance_fee_particular_id => d.master_receiver_id })
          particular_discounts[d.master_receiver_id] = particular_discounts[d.master_receiver_id].to_f +
            discount_amount
          total_discount += discount_amount
        else
          common_discounts << d
        end
      end
    end

    # build applicable discount & tax amount records
    fixed_discounts = []
    no_of_parts = fee_particulars.length
    fee_particulars.each_with_index do |particular,pi|
      p_amount = particular.amount.to_f
      taxable_particular_amount = nil
      if discount_mode == "OLD"
        discount_amount = nil
        if total_discount_amount.to_f > 0
          discount_amount = (total_discount_amount >= p_amount) ? p_amount : total_discount_amount
          total_discount_amount -= discount_amount.to_f
          taxable_particular_amount = p_amount - discount_amount.to_f
          finance_fee.finance_fee_discounts.build({
              :discount_amount => discount_amount,
              :finance_fee_particular_id => particular.id
            })
          total_discount += discount_amount.to_f
        else
          taxable_particular_amount = p_amount
        end

      elsif discount_mode == "NEW"
        common_discounts.each do |disc|
          if disc.is_amount?
            fixed_discounts[disc.id] ||= {:real_amount => disc.discount.to_f,
              :applied_sum => 0}
            discount_ratio_amt = (disc.discount.to_f / total_payable.to_f) * p_amount
            fixed_discounts[disc.id][:applied_sum] += discount_ratio_amt
            if no_of_parts == (pi+1)
              disc_diff = fixed_discounts[disc.id][:real_amount] - fixed_discounts[disc.id][:applied_sum]
              discount_ratio_amt += disc_diff if disc_diff > 0
            end
          end
          discount_amount = disc.is_amount? ? discount_ratio_amt  : (p_amount * disc.discount.to_f * 0.01)
          finance_fee.finance_fee_discounts.build({
              :discount_amount => discount_amount, :fee_discount_id => disc.id,
              :finance_fee_particular_id => particular.id
            })
          total_discount += discount_amount
          particular_discounts[particular.id] = particular_discounts[particular.id].to_f + discount_amount
        end
        taxable_particular_amount = p_amount.to_f - particular_discounts[particular.id].to_f
      end
      if tax_enabled
        tax_slab = particular_tax_slab[particular.id]
        if tax_slab.present?
          tax_amount = taxable_particular_amount.to_f > 0 ? (taxable_particular_amount.to_f *  tax_slab.rate * 0.01).to_f  : 0.0
          tax_collection = finance_fee.tax_collections.build({:tax_amount => tax_amount})
          tax_collection.taxable_entity = particular
          tax_collection.slab_id = tax_slab.id
          total_tax += tax_amount
          tax_arr << tax_amount
        end
      end
    end
    precisioned_total_tax = tax_arr.map { |x| FedenaPrecision.set_and_modify_precision(x).to_f }.
      sum.to_f if tax_enabled
    balance= FedenaPrecision.set_and_modify_precision(total_payable-total_discount +
        (tax_enabled ? precisioned_total_tax : 0.0))
    finance_fee.balance = balance
    finance_fee.particular_total = total_payable
    finance_fee.discount_amount = total_discount
    finance_fee.tax_amount = precisioned_total_tax
    finance_fee.is_paid = (balance.to_f<=0)
    finance_fee.save
    finance_fee
  end

  def self.csv_batch_fees_head_wise_report(parameters)
    batch_ids=parameters[:batch_ids] if parameters[:batch_ids].present?
    joins = "INNER JOIN finance_fees ON finance_fees.student_id = students.id 
             INNER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id
             INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id
              LEFT JOIN fee_accounts fa On fa.id = finance_fee_collections.fee_account_id"
    cond = "(fa.id IS NULL OR fa.is_deleted = false)"
    if batch_ids.present?
      students=Student.all(:select => "DISTINCT students.*",
        :conditions => ["#{cond} AND finance_fees.batch_id IN (?)", batch_ids], :joins => joins,
        :include => [{:finance_fees => [{:finance_fee_collection => [:fee_account, {:collection_particulars =>
                      {:finance_fee_particular => :receiver}}, {:collection_discounts =>
                      {:fee_discount=>:receiver}}]}, :finance_transactions, { :batch=> :course}, :student_category,
              {:tax_collections => :tax_slab}]}], :order => 'first_name ASC')
    else
      students=Student.all(:select => "DISTINCT students.*", :conditions => cond, :joins => joins,
        :include => [{:finance_fees => [{:finance_fee_collection => [:fee_account, {:collection_particulars =>
                      {:finance_fee_particular => :receiver }}, {:collection_discounts =>
                      {:fee_discount => :receiver }}]}, :finance_transactions, { :batch=> :course}, :student_category,
              {:tax_collections => :tax_slab}]}], :order => 'first_name ASC')
    end

    # filter deleted collections and inactive fee account linked collections
    all_fees = students.map { |s| s.finance_fees.select do |ff|
        fee_account_active = !(ff.finance_fee_collection.fee_account.try(:is_deleted))
        !ff.finance_fee_collection.is_deleted && fee_account_active && (batch_ids.present? ? (batch_ids.include? ff.batch_id.to_s) : true)
      end
    }.flatten

    student_fees = all_fees.group_by { |f| f.student_id }
    is_tax_enabled = all_fees.map {|ff| ff.tax_enabled and ff.tax_collections.present? }.uniq.include?(true)
    col_heads=["#{t('no_text')}", "#{t('student_name')}", "#{t('batch_name')}",
      "#{t('fee_collection')} #{t('name')}", "#{t('particulars')}", "#{t('discount')}"]
    col_heads << "#{t('tax_text')}" if is_tax_enabled
    col_heads += ["#{t('amount_to_pay')}(#{Configuration.currency})",
      "#{t('paid')} #{t('amount')}(#{Configuration.currency})"]
    return FinanceFee.csv_make_data(students,col_heads, student_fees, is_tax_enabled, parameters)
  end


  def self.precision_label(val)
    @precision_count ||= FedenaPrecision.get_precision_count
    return sprintf("%0.#{@precision_count}f",val)
  end

  def self.csv_collection_report(parameters)
    
    if parameters[:start_date].present? and parameters[:end_date].present?
      start_date=parameters[:start_date].to_date
      end_date=parameters[:end_date].to_date
    else
      start_date=Date.today
      end_date=Date.today
    end
    
    if parameters[:active].present? && parameters[:active].to_i == 2
      active_batches_selection=false
    else
      active_batches_selection=true
    end

    total_tax_enabled = false

    columns = JSON.parse(parameters[:columns] || "{}")
    additional_fields = StudentAdditionalField.get_fields
    
    if start_date <= end_date
      if parameters[:batch_ids].present?
        batch_ids=parameters[:batch_ids]
        batch_ids= batch_ids.map{|b_id| b_id.to_i}
      else
        batch_ids = []
      end
      report = CollectionReport.new(start_date, end_date, batch_ids, active_batches_selection , nil, nil)
      report_values = report.get_report()
      table = report_values[:table]
      collection_names = report_values[:collection_names]
      students = report_values[:students]
      students_count = report_values[:students_count]
      fee_collection_present = report_values[:fee_collection_present]
      total_tax_enabled = report_values[:total_tax_enabled]
    end

    #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    #Grouping based on collection name 
    new_collection_names = []
    grouped_collection_names =  collection_names.group_by{|e| [e[:collection_type],e[:name].downcase.split.join]}
    grouped_collection_names.each{|key,val| new_collection_names<< {:collection_type=>key[0], :name=>key[1], :original_name=> val.first[:name], :g_ids=> val.collect{|t| t[:id]}, :tax_enabled=> val.select{|t| t[:tax_enabled] == true}.count == val.count } }
    
    #build new value set based on -- new collection names 
    new_table=[]
    log_in_csv = []
    table.each_with_index do |row, index|
      if !new_table[index].present?
        new_table[index]={}
      end
      
      new_table[index][:name] = row[:name]
      new_table[index][:admn_no] = row[:admn_no]
      new_table[index][:batch_name] = row[:batch_name]
      new_table[index][:student_mobile_phone] = row[:student_mobile_phone]
      new_table[index][:immediate_contact_first_name] = row[:immediate_contact_first_name]
      new_table[index][:immediate_contact_mobile_phone] = row[:immediate_contact_mobile_phone]
      new_table[index][:father_first_name] = row[:father_first_name]
      new_table[index][:father_mobile_phone] = row[:father_mobile_phone]
      new_table[index][:mother_first_name] = row[:mother_first_name]
      new_table[index][:mother_mobile_phone] = row[:mother_mobile_phone]
      (columns["additional_details"]||[]).each do |details|
        new_table[index][details.to_sym] = row[details.to_sym]
      end
      new_table[index][:additional_details] = row[:additional_details]
      new_table[index][:total_fees] = row[:total_fees]
      new_table[index][:total_discount_given] = row[:total_discount_given]
      new_table[index][:total_tax_amount] = row[:total_tax_amount]
      new_table[index][:total_tax_paid] = row[:total_tax_paid]
      new_table[index][:fees_paid] = row[:fees_paid]
      new_table[index][:fees_due] = row[:fees_due]
      new_table[index][:total_expected_fine] = row[:total_expected_fine]
      new_table[index][:total_fine_paid] = row[:total_fine_paid]
      
      new_collection_names.each do |collection_name|
        collection_type = collection_name[:collection_type]
        name = collection_name[:name]
        g_ids = collection_name[:g_ids]
        
        if !new_table[index][collection_type].present?
          new_table[index][collection_type]={}
        end
        new_table[index][collection_type][name]={}
        fees=0.0; discount=0.0; paid=0.0; due=0.0; fine_paid=0.0; fine=0.0; tax_amount=0.0; tax_paid=0.0; tax_enabled=false;
        g_ids.each do |id|
          collection_values = row[collection_type][id] if row[collection_type].present?
          if collection_values.present?
            #copy collection values to new_table -- with addition of values for same collection name
            fees = fees + collection_values[:fees]
            discount = discount + collection_values[:discount]  
            tax_amount = tax_amount + collection_values[:tax_amount]
            tax_paid = tax_paid + collection_values[:tax_paid]
            paid = paid + collection_values[:paid]
            due = due + collection_values[:due]
            fine = fine + collection_values[:fine]
            fine_paid = fine_paid + collection_values[:fine_paid] 
          end 
        end
        new_table[index][collection_type][name]={:fees => fees, :discount => discount, :tax_amount => tax_amount, :tax_paid => tax_paid, :paid => paid, :due => due, :fine => fine, :fine_paid => fine_paid }
      end
    end
    
    
    
    #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    #CSV creation portion
    data=[]
    
    
    if start_date.present? && end_date.present?
      data << [""]
      data << ["#{t('start_date')}", start_date.to_s]
      data << ["#{t('end_date')}", end_date.to_s]
      data << ["#{t('batch_type')}", (active_batches_selection ? t('active') : t('inactive'))]
      data << [""]
    end

    head=["#{t('no_text')}", "#{t('name')}", "#{t('admission_no')}", "#{t('batch_name')}"]
    
    (columns["guardian_details"]||[]).each do |details|
      head << t(details)
    end
    (columns["additional_details"]||[]).each do |details|
      head << additional_fields[details.to_sym]
    end
    head += ["#{t('total_fees')}", "#{t('total_discount')}"]
    if total_tax_enabled
      head = head + ["#{t('total_tax_amount')}","#{t('total_tax_paid')}"]
    end

    head = head +["#{t('fees_paid')}", "#{t('fees_due')}","#{t('expected_fine')}", "#{t('total_fine_paid')}"]

    new_collection_names.each do |collection_name|
      head << collection_name[:original_name] + " #{t('fees_text')}"
      head << collection_name[:original_name] + " #{t('discount')}"
      if collection_name[:tax_enabled]
        head << collection_name[:original_name] + " #{t('tax_amount')}"
        head << collection_name[:original_name] + " #{t('tax_paid')}"
      end
      head << collection_name[:original_name] + " #{t('paid')}"
      head << collection_name[:original_name] + " #{t('due')}"
      head << collection_name[:original_name] + "#{t('expected_fine')}"
      head << collection_name[:original_name] + " #{t('fine_paid')}"
    end

    data << head
    i =  1
    #     grand_total={}
    new_table.each do |col|
      row=[]
      row<<i
      i=i+1
      row << col[:name]
      row << col[:admn_no]
      row << col[:batch_name]
      (columns["guardian_details"]||[]).each do |details|
        row << col[details.to_sym]
      end
      (columns["additional_details"]||[]).each do |details|
        row << col[details.to_sym]
      end
      row << FinanceFee.precision_label(col[:total_fees])
      row << FinanceFee.precision_label(col[:total_discount_given])
      if total_tax_enabled
        row << FinanceFee.precision_label(col[:total_tax_amount])
        row << FinanceFee.precision_label(col[:total_tax_paid])
      end
      row << FinanceFee.precision_label(col[:fees_paid])
      row << FinanceFee.precision_label(col[:fees_due])
      row << FinanceFee.precision_label(col[:total_expected_fine])
      row << FinanceFee.precision_label(col[:total_fine_paid])
      new_collection_names.each do |collection_name|
        if col[collection_name[:collection_type]][collection_name[:name]].present?
          collection_values=col[collection_name[:collection_type]][collection_name[:name]]
          row << FinanceFee.precision_label(collection_values[:fees])
          row << FinanceFee.precision_label(collection_values[:discount])
          if collection_name[:tax_enabled]
            row << FinanceFee.precision_label(collection_values[:tax_amount])
            row << FinanceFee.precision_label(collection_values[:tax_paid])
          end
          row << FinanceFee.precision_label(collection_values[:paid])
          row << FinanceFee.precision_label(collection_values[:due])
          row << FinanceFee.precision_label(collection_values[:fine])
          row << FinanceFee.precision_label(collection_values[:fine_paid])
        else
          row << "-"
          row << "-"
          if collection_name[:tax_enabled]
            row << "-"
            row << "-"
          end
          row << "-"
          row << "-"
          row << "-"
          row << "-"
        end
      end
      data << row
    end

    #   grand_total_row = []
    #   grand_total_row << ""
    #   grand_total_row << ""
    #   grand_total_row << ""


    return data
  end


  def self.csv_fee_collection_fees_head_wise_report(parameters)
    joins = "INNER JOIn finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id
              LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id"
    cond = "(fa.id IS NULL OR fa.is_deleted = false)"
    students=Student.all(:select => "DISTINCT students.*",
      :conditions => ["finance_fees.fee_collection_id=? and finance_fees.batch_id = ? AND #{cond}",
        parameters[:fee_collection_id], parameters[:batch_id]],
      :joins => "INNER JOIN finance_fees ON finance_fees.student_id = students.id #{joins}",
      :include => {:batch => :course}, :order => 'first_name ASC')

    all_fees = FinanceFee.all( :joins => joins,
      :conditions => ["#{cond} AND student_id IN (?) AND fee_collection_id = ?", students.map(&:id),
        parameters[:fee_collection_id] ], :include => [ :finance_transactions,
        {:finance_fee_collection => [:fee_account, {:collection_particulars => {:finance_fee_particular =>:receiver}},
            {:collection_discounts => {:fee_discount=>:receiver}}]}, {:tax_collections => :tax_slab},
        :batch,:student_category])
    is_tax_enabled = all_fees.map {|x| x.tax_enabled? and x.tax_collections.present? }.uniq.include?(true)
    student_fees = all_fees.group_by {|ff| ff.student_id }
    col_heads = ["#{t('no_text')}", "#{t('student_name')}", "#{t('batch_name')}", "#{t('particulars')}",
      "#{t('discount')}"]
    col_heads << "#{t('tax_text')}" if is_tax_enabled
    col_heads += ["#{t('amount_to_pay')}(#{Configuration.currency})",
      "#{t('paid')} #{t('amount')}(#{Configuration.currency})"]

    #    col_heads=["#{t('no_text')}", "#{t('student_name')}", "#{t('batch_name')}", "#{t('particulars')}",
    #      "#{t('discount')}", "#{t('amount_to_pay')}(#{Configuration.currency})",
    #      "#{t('paid')} #{t('amount')}(#{Configuration.currency})",]
    return FinanceFee.csv_make_data(students,col_heads, student_fees, is_tax_enabled, parameters)
    #    return FinanceFee.csv_make_data(students,col_heads,parameters)
  end


  def self.csv_make_data(students, col_heads, students_fees, is_tax_enabled, parameters)
    data=[]
    data << col_heads
    students.each_with_index do |student, i|
      student_fees = students_fees[student.id]
      total_bal= student_fees.present? ? student_fees.map {|x| x.balance.to_f }.sum.to_f : 0
      total_paid=0
      #      if col_heads.include? "#{t('fee_collection')} #{t('name')}"
      #        finance_fees=student.finance_fees.select{|ff| !ff.finance_fee_collection.is_deleted}
      #      else
      #        finance_fees = student_fees[student.id]
      #        finance_fees=student.finance_fees.find(:all, :conditions => "fee_collection_id='#{parameters[:fee_collection_id]}'").select{|ff| !ff.finance_fee_collection.is_deleted}
      #      end
      j = 0
      student_fees.each do |finance_fee|
        total_paid=total_paid+finance_fee.finance_transactions.uniq.compact.map(&:amount).sum.to_f
        ffc=finance_fee.finance_fee_collection
        particulars=ffc.collection_particulars.select { |cp| cp.finance_fee_particular.present? and
            ((cp.finance_fee_particular.batch_id==finance_fee.batch_id and
                cp.finance_fee_particular.receiver.present?) and
              (cp.finance_fee_particular.receiver==finance_fee.student_category or
                cp.finance_fee_particular.receiver==finance_fee.batch or
                cp.finance_fee_particular.receiver==student)) }
        discounts=ffc.collection_discounts.select { |cd| cd.fee_discount.present? and
            ((cd.fee_discount.batch_id==finance_fee.batch_id and cd.fee_discount.receiver.present?) and
              (cd.fee_discount.receiver==finance_fee.student_category or
                cd.fee_discount.receiver==finance_fee.batch or cd.fee_discount.receiver==student)) }

        tax_slabs = finance_fee.tax_collections.map {|tc| tc.tax_slab }.uniq if is_tax_enabled

        count= is_tax_enabled ? [particulars.length, discounts.length, tax_slabs.length].max :
          [particulars.length, discounts.length].max
        k=0
        student_no = "(#{student.admission_no})"
        while k<count
          col=[]
          if j == 0
            col<< "#{i+1}"
          else
            col<< ""
          end
          col<< "#{student.full_name}#{student_no}"
          col<< "#{student.batch.full_name}"
          col<< "#{ffc.name}" if col_heads.include? "#{t('fee_collection')} #{t('name')}"
          col<< "#{(particulars[k].present?) ? (particulars[k].finance_fee_particular.name+':'+
          FedenaPrecision.set_and_modify_precision(particulars[k].finance_fee_particular.amount.to_f)) : '-' }"
          col<< "#{(discounts[k].present?) ? (discounts[k].fee_discount.name+':'+
          FedenaPrecision.set_and_modify_precision(discounts[k].fee_discount.discount.to_f)+
          (discounts[k].fee_discount.is_amount? ? '' : '%')) : '-' }"
          if is_tax_enabled
            col << "#{tax_slabs[k].present? ? (tax_slabs[k].name + ':' +
            FedenaPrecision.set_and_modify_precision(tax_slabs[k].rate)) : '-' }"
          end
          if k==0
            col<< "#{finance_fee.balance.nil? ? FedenaPrecision.set_and_modify_precision(0) :
            FedenaPrecision.set_and_modify_precision(finance_fee.balance)}"
            col<< "#{FedenaPrecision.set_and_modify_precision(finance_fee.finance_transactions.uniq.compact.
            map(&:amount).sum.to_f)}"
          else
            col<<""
            col<<""
          end
          col=col.flatten
          data<< col
          k=k+1
          j = j+1
        end
      end
      if col_heads.include? "#{t('fee_collection')} #{t('name')}" #batch wise report
        d_col = ["", "", "", "TOTAL", "", ""]
        d_col << "" if is_tax_enabled
        d_col += [FedenaPrecision.set_and_modify_precision(total_bal),
          FedenaPrecision.set_and_modify_precision(total_paid)]
        data<< d_col
      else #fee collection wise report
        # data<< ["", "", "TOTAL", FedenaPrecision.set_and_modify_precision(total_bal), FedenaPrecision.set_and_modify_precision(total_paid), "", ""]
      end

    end
    return data
  end
  # currently is_paid flag is not properly used in the case of fees with fine, this is a workaround for that
  def is_paid_with_fine?
    return true if is_paid?
    return false if finance_transactions.empty?
    last_payment_date=finance_transactions.last.transaction_date
    days=(last_payment_date-finance_fee_collection.due_date.to_date).to_i
    auto_fine=finance_fee_collection.fine
    fine_balance = (balance_fine.present? && balance_fine > 0) ? false : true
    if days > 0 && auto_fine.present? && !is_fine_waiver
#    =====  Included condition to manage fine on settings enabled =====
      if Configuration.is_fine_settings_enabled? && balance <= 0 && is_paid == false && balance_fine.present?
          fine_amount = balance_fine
      else
      fine_rule=auto_fine.fine_rules.find(:last, :conditions =>
          ["fine_days <= '#{days}' and created_at <= '#{finance_fee_collection.created_at}'"],
        :order => 'fine_days ASC')
      fine_amount=fine_rule.is_amount ? fine_rule.fine_amount :
        (_amount*fine_rule.fine_amount)/100 if fine_rule.present?
      end
    end
    fine_amount ||= 0
    FedenaPrecision.set_and_modify_precision(balance.to_f +
        fine_amount)==FedenaPrecision.set_and_modify_precision(0)
  end
  #FIXME use sql instead of ruby select
  #TODO tempoaray hack using underscore to make backward compatiable
  def _total_payable
    fee_particulars = finance_fee_collection.finance_fee_particulars.all(
      :conditions=>"batch_id=#{batch_id}").select{|par|  (par.receiver.present?) and
        (par.receiver==student or par.receiver==student_category or par.receiver==batch) }
    total_payable=fee_particulars.map{|s| s.amount}.sum.to_f
  end
  def _total_discount
    discounts=finance_fee_collection.fee_discounts.all(:conditions => "batch_id=#{batch_id}").
      select { |par|
      (par.receiver.present?) and (
        (par.receiver==student or par.receiver==student_category or par.receiver==self.batch) and
          (par.master_receiver_type!='FinanceFeeParticular' or
            (par.master_receiver_type=='FinanceFeeParticular' and
              (
              par.master_receiver.receiver==self.student or
                par.master_receiver.receiver==self.student_category or
                par.master_receiver.receiver==self.batch
            )
          )
        )
      )
    }
    total_discount = discounts.map { |d|
      d.master_receiver_type=='FinanceFeeParticular' ?
        (d.master_receiver.amount * d.discount.to_f/(d.is_amount? ? d.master_receiver.amount : 100)) :
        _total_payable * d.discount.to_f/(d.is_amount? ? _total_payable : 100) }.sum.to_f unless discounts.nil?
  end
  def _amount
    _total_payable-_total_discount
  end

  def _paid_amount
    finance_transactions.sum(:amount).to_f
  end
  
  
  def self.fetch_total_fine(collections,fee_type_val,fee_finance_ids,fee_transport_ids,transaction_date,batch_id)
    fine_waiver_amt = 0
    precision_count = FedenaPrecision.get_precision_count
    precision_count = 2 if precision_count.to_i < 2
    balance_fine_cond = Configuration.is_fine_settings_enabled? ? "IF(finance_fees.balance_fine IS NOT NULL AND finance_fees.balance = 0.0 AND finance_fees.is_paid = false,finance_fees.balance_fine, " : "("
    joins="INNER JOIN `finance_fee_collections` 
                   ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id
            LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
              INNER JOIN `fines` 
                           ON `fines`.id = `finance_fee_collections`.fine_id AND fines.is_deleted is false
                 LEFT JOIN `fine_rules` 
                           ON `fine_rules`.fine_id = fines.id  AND 
                                 `fine_rules`.id= (SELECT id 
                                                             FROM fine_rules ffr 
                                                          WHERE ffr.fine_id=fines.id AND 
                                                                      ffr.created_at <= finance_fee_collections.created_at AND 
                                                                      ffr.fine_days <= DATEDIFF(COALESCE(
                                                                                                  Date('#{transaction_date.to_date}'), CURDATE()),
                                                                                                  finance_fee_collections.due_date)
                                                      ORDER BY ffr.fine_days DESC LIMIT 1)"
    
    case fee_type_val
    when "finance_fee"
      conditions = "(fa.id IS NULL OR fa.is_deleted = false) AND "
      conditions += batch_id.present? ? "finance_fees.batch_id=#{batch_id.to_i} and finance_fees.is_paid=false " : "finance_fees.is_paid=false "
      if collections.present?
        conditions+= "and finance_fees.id in (?)"
        conditions=conditions.to_a << collections.to_i
      end
      waiver_cond = "IF(finance_fees.is_fine_waiver = true, 0.0, #{balance_fine_cond}"
      fine_waiver_amt = FinanceFee.all(:joins => joins,
        :select => "SUM(#{waiver_cond} IF(fine_rules.is_amount, fine_rules.fine_amount,
                         ((finance_fees.balance - 
                           IF(finance_fees.tax_enabled,IFNULL(finance_fees.tax_amount,0),0) + 
                              (SELECT IFNULL(SUM(finance_transactions.amount - 
                                             IF(finance_fees.tax_enabled,
                                                finance_transactions.tax_amount,0) - 
                                                finance_transactions.fine_amount),0) 
                                 FROM finance_transactions
                                WHERE finance_transactions.finance_id = finance_fees.id AND 
                                      finance_transactions.finance_type='FinanceFee') 
                              ) * fine_rules.fine_amount / 100
                          )
                         ) - 
                         (SELECT IFNULL(SUM(finance_transactions.fine_amount),0) 
                            FROM finance_transactions  
                           WHERE finance_transactions.finance_id = finance_fees.id AND 
                                 finance_transactions.finance_type = 'FinanceFee' AND 
                                 description= 'fine_amount_included')
                         ))) AS fine_amount",      
        :conditions => conditions,
        :group => "finance_fees.student_id").first.try(:fine_amount).to_f  
    when "transport_fee"
      transport_fine_cond = balance_fine_cond.gsub('finance_fees','transport_fees')
      joins="INNER JOIN `transport_fee_collections` 
                     ON `transport_fee_collections`.id = `transport_fees`.transport_fee_collection_id
              LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id
             INNER JOIN `fines` ON `fines`.id = `transport_fee_collections`.fine_id AND fines.is_deleted is false
              LEFT JOIN `fine_rules`
                     ON `fine_rules`.fine_id = fines.id  AND
                         `fine_rules`.id= (SELECT id
                                             FROM fine_rules ffr
                                            WHERE ffr.fine_id=fines.id AND
                                                  ffr.created_at <= transport_fee_collections.created_at AND
                                                  ffr.fine_days <= DATEDIFF(COALESCE(
                                                                             Date('#{transaction_date.to_date}'), CURDATE()),
                                                                             transport_fee_collections.due_date)
                                         ORDER BY ffr.fine_days DESC LIMIT 1)"
      conditions = batch_id.present? ? "transport_fees.groupable_id=#{batch_id.to_i} and transport_fees.groupable_type='Batch' and transport_fees.is_paid <> true AND (fa.id IS NULL OR fa.is_deleted = false) " :
        "transport_fees.is_paid <> true AND (fa.id IS NULL OR fa.is_deleted = false)"
      
      if collections.present?
        conditions+= " and transport_fees.id in (?)"
        conditions=conditions.to_a << collections.to_i
      end
      waiver_cond = "IF(transport_fees.is_fine_waiver = true, 0.0, #{transport_fine_cond}"
      fine_waiver_amt = TransportFee.all(:joins => joins,
        :select => "SUM(#{waiver_cond} IF(fine_rules.is_amount,
                           fine_rules.fine_amount,
                           ((transport_fees.balance - 
                             IF(transport_fees.tax_enabled,IFNULL(transport_fees.tax_amount,0),0) + 
                                (SELECT IFNULL(SUM(finance_transactions.amount - 
                                         IF(transport_fees.tax_enabled,
                                            finance_transactions.tax_amount,0) - 
                                            finance_transactions.fine_amount),0) 
                                   FROM finance_transactions
                                  WHERE finance_transactions.finance_id = transport_fees.id AND 
                                        finance_transactions.finance_type='TransportFee') 
                               ) * fine_rules.fine_amount / 100
                             )
                           ) - 
                           (SELECT IFNULL(SUM(finance_transactions.fine_amount),0) 
                              FROM finance_transactions  
                             WHERE finance_transactions.finance_id = transport_fees.id AND 
                                   finance_transactions.finance_type = 'TransportFee' AND 
                                   description= 'fine_amount_included')
                       ))) AS tf_fine_amount",      
        :conditions => conditions,
        :group => "transport_fees.receiver_id").map {|x| x.tf_fine_amount.to_f }.sum
    else
      if fee_finance_ids.present?
      conditions = "(fa.id IS NULL OR fa.is_deleted = false) AND "
      conditions += batch_id.present? ? "finance_fees.batch_id=#{batch_id.to_i} and finance_fees.is_paid=false " : "finance_fees.is_paid=false "
      
        conditions+= " and finance_fees.id in (?) "
        conditions=conditions.to_a << fee_finance_ids.map{|i| i.to_i}
      
      waiver_cond = "IF(finance_fees.is_fine_waiver = true, 0.0, #{balance_fine_cond}"
      fine_waiver_amt = FinanceFee.all(:joins => joins,
        :select => "SUM(#{waiver_cond} IF(fine_rules.is_amount, fine_rules.fine_amount,
                         ((finance_fees.balance - 
                           IF(finance_fees.tax_enabled,IFNULL(finance_fees.tax_amount,0),0) + 
                              (SELECT IFNULL(SUM(finance_transactions.amount - 
                                             IF(finance_fees.tax_enabled,
                                                finance_transactions.tax_amount,0) - 
                                                finance_transactions.fine_amount),0) 
                                 FROM finance_transactions
                                WHERE finance_transactions.finance_id = finance_fees.id AND 
                                      finance_transactions.finance_type='FinanceFee') 
                              ) * fine_rules.fine_amount / 100
                          )
                         ) - 
                         (SELECT IFNULL(SUM(finance_transactions.fine_amount),0) 
                            FROM finance_transactions  
                           WHERE finance_transactions.finance_id = finance_fees.id AND 
                                 finance_transactions.finance_type = 'FinanceFee' AND 
                                 description= 'fine_amount_included')
                         ))) AS fine_amount",      
        :conditions => conditions,
        :group => "finance_fees.student_id").first.try(:fine_amount).to_f
      end
      if fee_transport_ids.present?
      transport_fine_cond = balance_fine_cond.gsub('finance_fees','transport_fees')
      waiver_cond = "IF(transport_fees.is_fine_waiver = true, 0.0, #{transport_fine_cond}"
      joins="INNER JOIN `transport_fee_collections` 
                     ON `transport_fee_collections`.id = `transport_fees`.transport_fee_collection_id
              LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id
             INNER JOIN `fines` ON `fines`.id = `transport_fee_collections`.fine_id AND fines.is_deleted is false
              LEFT JOIN `fine_rules`
                     ON `fine_rules`.fine_id = fines.id  AND
                         `fine_rules`.id= (SELECT id
                                             FROM fine_rules ffr
                                            WHERE ffr.fine_id=fines.id AND
                                                  ffr.created_at <= transport_fee_collections.created_at AND
                                                  ffr.fine_days <= DATEDIFF(COALESCE(
                                                                             Date('#{transaction_date.to_date}'), CURDATE()),
                                                                             transport_fee_collections.due_date)
                                         ORDER BY ffr.fine_days DESC LIMIT 1)"
      conditions = batch_id.present? ? "transport_fees.groupable_id=#{batch_id.to_i} and transport_fees.groupable_type='Batch' and transport_fees.is_paid <> true AND (fa.id IS NULL OR fa.is_deleted = false) " :
        "transport_fees.is_paid <> true AND (fa.id IS NULL OR fa.is_deleted = false)"
      
        conditions+= " and transport_fees.id in (?)"
        conditions=conditions.to_a << fee_transport_ids.map{|i| i.to_i}
      
      fine_waiver_amt += TransportFee.all(:joins => joins,
        :select => "SUM(#{waiver_cond} IF(fine_rules.is_amount,
                           fine_rules.fine_amount,
                           ((transport_fees.balance - 
                             IF(transport_fees.tax_enabled,IFNULL(transport_fees.tax_amount,0),0) + 
                                (SELECT IFNULL(SUM(finance_transactions.amount - 
                                         IF(transport_fees.tax_enabled,
                                            finance_transactions.tax_amount,0) - 
                                            finance_transactions.fine_amount),0) 
                                   FROM finance_transactions
                                  WHERE finance_transactions.finance_id = transport_fees.id AND 
                                        finance_transactions.finance_type='TransportFee') 
                               ) * fine_rules.fine_amount / 100
                             )
                           ) - 
                           (SELECT IFNULL(SUM(finance_transactions.fine_amount),0) 
                              FROM finance_transactions  
                             WHERE finance_transactions.finance_id = transport_fees.id AND 
                                   finance_transactions.finance_type = 'TransportFee' AND 
                                   description= 'fine_amount_included')
                       ))) AS tf_fine_amount",      
        :conditions => conditions,
        :group => "transport_fees.receiver_id").map {|x| x.tf_fine_amount.to_f }.sum
      end
    end
    return fine_waiver_amt
  end
  
  def track_fine_calculation(finance_type, amount, finance_id, transaction_id = nil)
    user_id = Fedena.present_user.id
    date = format_date(Date.today_with_timezone.to_date, :format => :long)
    FineCancelTracker.create(:user_id=> user_id, :amount => amount, :date=>date, :finance_id => finance_id, :finance_type => finance_type, :transaction_id=> transaction_id)
  end

  private
  def clean_associated_data
    self.instance_variables.each do |instance_var|
      object_data = ['@attributes_cache','@attributes','@changed_attributes']
      self.send('remove_instance_variable', instance_var) unless object_data.include?(instance_var)
    end
  end
end
