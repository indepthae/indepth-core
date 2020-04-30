class DelayedTransportFeeCollectionJob
  include Notifier
  def initialize(user,batches,employee,fee_params)
    @user=user
    @batches=batches
    @include_employee = employee
    @params=fee_params
  end
  include I18n
  include DateFormater
  def t(obj)
    I18n.t(obj)
  end
  def perform
    transaction_category = FinanceTransactionCategory.find_by_name 'Transport'
    master_particular = MasterFeeParticular.find_by_particular_type 'TransportFee'
    account = transaction_category.get_multi_config[:account]
    account_id = (account.is_a?(Fixnum) ? account : (account.is_a?(FeeAccount) ? account.try(:id) : nil))
    @transport_fee_collection = TransportFeeCollection.new(@params)
    @transport_fee_collection.fee_account_id = account_id
    @transport_fee_collection.master_fee_particular_id = master_particular.id if master_particular.present?
    @transport_fee_collection.invoice_enabled = (Configuration.get_config_value('EnableInvoiceNumber').to_i == 1)
    TransportFeeCollection.transaction do
      if @transport_fee_collection.save
        tax_enabled = @transport_fee_collection.tax_enabled
        if tax_enabled
          # tax was enabled when transport collection job was created
          tax_slab = TaxSlab.find(@params[:tax_slab_id]) if @params[:tax_slab_id].present?
          @transport_fee_collection.collectible_tax_slabs.create({ :tax_slab_id => tax_slab.try(:id),
              :collectible_entity_id => @transport_fee_collection.id, :collectible_entity_type => 'TransportFeeCollection' 
            }) if tax_slab.present?          
        end
        params = {:event => {:title => "#{t('transport_fee_text')}", :description => "#{t('fee_name')}: #{@params[:name]}", :start_date => @params[:due_date], :is_common => false, :end_date => @params[:due_date], :is_due => true, :origin => @transport_fee_collection, :batch_events_attributes => {}}}
        @event = Event.new(params[:event])
        @event.save
        #        @event= Event.create(:title => "#{t('transport_fee_text')}", :description => "#{t('fee_name')}: #{@params[:name]}", :start_date => @params[:due_date], :end_date => @params[:due_date], :is_due => true, :origin => @transport_fee_collection)
        collection_assignment_hsh = {:transport_fee_collection_id => @transport_fee_collection.id }
        unless @batches.blank?
          recipients = []
          @batches.each do |b|
            @params["batch_id"] = b
            batch = Batch.find(b)
            # link batch with transport 
            TransportFeeCollectionAssignment.create(collection_assignment_hsh.merge({
                  :assignee_type => "Batch", :assignee_id => batch.id}))
            batch.active_transports.each do |t|
              student = t.receiver
              unless student.nil?
                recipients << student.user.id
                if t.bus_fare != 0
                  @transport_fee = TransportFee.new(:receiver => student, :bus_fare => t.bus_fare, 
                    :transport_fee_collection_id => @transport_fee_collection.id,:groupable=>batch,
                    :invoice_number_enabled => @transport_fee_collection.invoice_enabled)
                  
                  @transport_fee.tax_enabled = @transport_fee_collection.tax_enabled
                  
                  if tax_enabled
                    tax_slab = @transport_fee_collection.collection_tax_slabs.try(:last)
                    if tax_slab.present?
                      taxable_amount = @transport_fee.bus_fare.to_f
                      tax_amount = taxable_amount > 0 ? (taxable_amount *  tax_slab.rate).to_f / 100.0  : 0.0                    
                      tax_collection = @transport_fee.tax_collections.build({:tax_amount => tax_amount})
                      tax_collection.taxable_entity = @transport_fee_collection          
                      tax_collection.slab_id = tax_slab.id
                      @transport_fee.tax_amount = tax_amount
                    end        
                  end
                  
                  @transport_fee.save
                  
                  UserEvent.create(:event_id => @event.id, :user_id => student.user.id)
                end
              end
            end
          end
          send_reminder(@user,@transport_fee_collection, recipients)
        end
        unless @include_employee.blank?
          @params["batch_id"]=nil
          recipients = []
          academic_year_id = AcademicYear.active.first.try(:id)
          employee_transport = Transport.in_academic_year(academic_year_id).all(
            :conditions => {:receiver_type => 'Employee'}, 
            :joins => "INNER JOIN employees e ON e.id = transports.receiver_id", 
            :select => "transports.*, e.employee_department_id AS e_dept_id")
          employee_transport.map {|x| x.e_dept_id.to_i }.uniq.each do |dept_id|
              TransportFeeCollectionAssignment.create(collection_assignment_hsh.merge({
                  :assignee_type => "EmployeeDepartment", :assignee_id => dept_id}))
          end
          employee_transport.each do |t|
            emp = t.receiver
            unless emp.nil?
              if t.bus_fare != 0
                @transport_fee = TransportFee.new(:receiver => emp, :bus_fare => t.bus_fare, :transport_fee_collection_id => @transport_fee_collection.id,:groupable=>emp.employee_department)
                @transport_fee.tax_enabled = @transport_fee_collection.tax_enabled
                
                if tax_enabled
                  tax_slab = @transport_fee_collection.collection_tax_slabs.try(:last)
                  if tax_slab.present?
                    taxable_amount = @transport_fee.bus_fare.to_f
                    tax_amount = taxable_amount > 0 ? (taxable_amount *  tax_slab.rate).to_f / 100.0  : 0.0                    
                    tax_collection = @transport_fee.tax_collections.build({:tax_amount => tax_amount,
                        :slab_id => tax_slab.id })
                    tax_collection.taxable_entity = @transport_fee_collection          
                    @transport_fee.tax_amount = tax_amount
                  end        
                end
                
                @transport_fee.save
                
                UserEvent.create(:event_id => @event.id, :user_id => emp.user.id)
                recipients << emp.user.id
              end
            end
          end
          send_reminder(@user,@transport_fee_collection, recipients)
        end
        prev_record = Configuration.find_by_config_key("job/TransportFeeCollection/2")
        if prev_record.present?
          prev_record.update_attributes(:config_value=>Time.now)
        else
          Configuration.create(:config_key=>"job/TransportFeeCollection/2", :config_value=>Time.now)
        end
      else 
        raise ActiveRecord::Rollback
      end
    end
  end
  def send_reminder(user,transport_fee_collection,recipients)
    @sender_id = user.id
    @recipient_ids = recipients.flatten.uniq
    body = "#{t('transport_text')} #{t('fee_collection_date_for')} <b> #{transport_fee_collection.name} </b> #{t('has_been_published')} #{t('by')} <b>#{user.full_name}</b>, #{t('start_date')} : #{format_date(transport_fee_collection.start_date)}  #{t('due_date')} :  #{format_date(transport_fee_collection.due_date)}"
    links = {:target=>'view_fees',:target_param=>'student_id'}
    inform(@recipient_ids,body,'Finance',links)
  end
end