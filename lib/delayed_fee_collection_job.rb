require 'i18n'
class DelayedFeeCollectionJob
  include I18n
  include DateFormater
  include Notifier
  attr_accessor :user,:collection,:fee_collection
  
  def initialize(user,collection,fee_collection)
    @user = user
    @collection=collection
    @fee_collection=fee_collection
  end
    
  def t(obj)
    I18n.t(obj)
  end
  
  def perform
    user = Authorization.current_user
    Authorization.current_user = @user
    make_fee_collection
    make_batch_fees
  ensure
    Authorization.current_user = user
  end
  
  def make_fee_collection
    unless @fee_collection.nil?
      ffc = FinanceFeeCategory.find_by_id(@collection[:fee_category_id])
      account = ffc.present? ? ffc.get_multi_config[:account] : nil
      account_id = (account.is_a?(Fixnum) ? account : (account.is_a?(FeeAccount) ? account.try(:id) : nil))
      @finance_fee_collection = FinanceFeeCollection.new(
        :name => @collection[:name], :start_date => @collection[:start_date],        
        :due_date => @collection[:due_date], :fee_category_id => @collection[:fee_category_id],
        :fine_id => @collection[:fine_id], :financial_year_id => @collection[:financial_year_id],
        :tax_enabled => Configuration.get_config_value('EnableFinanceTax').to_i,
        :invoice_enabled => (Configuration.get_config_value('EnableInvoiceNumber').to_i == 1),
        :fee_account_id => account_id
      )
      if FedenaPlugin.can_access_plugin? 'fedena_reminder'
        @finance_fee_collection.event_alerts_attributes = @collection[:event_alerts_attributes]
      end      
      @finance_fee_collection.save     
    end
  end
  
  def make_batch_fees
    unless @finance_fee_collection.new_record?
      @fee_category = FinanceFeeCategory.find_by_id(@collection[:fee_category_id])
      fetch_invoice_config if @finance_fee_collection.invoice_enabled
      batch_ids = @fee_collection[:category_ids]                  
      batch_ids.each do |batch_id|        
        @fee_collection_batch = FeeCollectionBatch.create(
          :finance_fee_collection_id => @finance_fee_collection.id,
          :batch_id => batch_id, :tax_mode => @finance_fee_collection.tax_enabled)            
        make_batch_fee_collection(batch_id) unless @fee_collection_batch.new_record?
      end
    
      prev_record = Configuration.find_by_config_key("job/FinanceFeeCollection/1")
      prev_record.present? ? prev_record.update_attributes(:config_value=>Time.now) : Configuration.
        create(:config_key=>"job/FinanceFeeCollection/1", :config_value=>Time.now)
    end
  end
  
  def fetch_invoice_config    
    @invoice_no_config = FeeInvoice.invoice_config
  end
  
  def make_batch_fee_collection batch_id
    recipient_ids = []
    students = fetch_batch_students batch_id        
    students.each do |student|
      unless student.has_paid_fees        
        fee = make_student_fee student
        make_fee_invoice fee if @finance_fee_collection.invoice_enabled && !fee.new_record?
        unless fee.new_record?
          recipient_ids << student.user.id if student.user
          recipient_ids << student.immediate_contact.user_id if student.immediate_contact.present?
        end
      end
    end if students.present?
    batch_fee_collection_event_on_create batch_id
    fee_collection_notify_on_create recipient_ids.compact    
  end
  
  def make_student_fee student    
    FinanceFee.new_student_fee(@finance_fee_collection,student, false) # disable invoice generation on after create     
  end
  
  def make_fee_invoice fee
    fee.add_invoice_number @invoice_no_config
  end
  
  def fetch_batch_students batch_id
    students = Student.find(:all, :include => :user,
      :conditions=>["batch_id = ? AND has_paid_fees = 0 AND has_paid_fees_for_batch = 0", batch_id])   

    unless @fee_category.fee_particulars.all(
        :conditions=>["is_deleted = false and batch_id = ?",batch_id]).
        collect(&:receiver_type).include?"Batch"
      cat_ids = @fee_category.fee_particulars.select do |s| 
        s.receiver_type == "StudentCategory"  and (!s.is_deleted and s.batch_id == batch_id.to_i)
      end.collect(&:receiver_id)
      
      student_ids = @fee_category.fee_particulars.select do |s| 
        s.receiver_type=="Student" and (!s.is_deleted and s.batch_id==batch_id.to_i)
      end.collect(&:receiver_id)
      
      students.select { |s| (cat_ids.include?s.student_category_id or student_ids.include?s.id) }
    else
      students
    end
  end
  
  def fee_collection_notify_on_create recipient_ids
    body = "#{t('fee_collection_date_for')} <b> #{@finance_fee_collection.name} </b> 
                 #{t('has_been_published')}, #{t('start_date')} : 
                 #{format_date(@finance_fee_collection.start_date)}  #{t('due_date')} :  
                 #{format_date(@finance_fee_collection.due_date)} "    
    links = {:target=>'view_fees',:target_param=>'student_id'}    
    inform(recipient_ids,body,"Finance",links)    
  end
  
  def batch_fee_collection_event_on_create batch_id 
    params = {:event => {:title=> "Fees Due", :description => @collection[:name], 
        :start_date => @finance_fee_collection.due_date.to_datetime, :is_common => false, 
        :end_date => @finance_fee_collection.due_date.to_datetime, :is_due => true , 
        :origin=>@finance_fee_collection, 
        :batch_events_attributes =>{1=>{:batch_id => batch_id, :selected => "1"}}}}
    begin
      Event.create(params[:event])
    rescue Exception => e
      
    end
  end
  
end

