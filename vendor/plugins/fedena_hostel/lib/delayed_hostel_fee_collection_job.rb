class DelayedHostelFeeCollectionJob
  include Notifier
  def initialize(user,batch,hostel_fee_params)
    @user=user
    @batch=batch
    @params=hostel_fee_params
  end
  include I18n
  include DateFormater
  def t(obj)
    I18n.t(obj)
  end
  def perform
    @params.delete("batch_ids")
    transaction_category = FinanceTransactionCategory.find_by_name 'Hostel'
    master_particular = MasterFeeParticular.find_by_particular_type 'HostelFee'
    account = transaction_category.get_multi_config[:account]
    account_id = (account.is_a?(Fixnum) ? account : (account.is_a?(FeeAccount) ? account.try(:id) : nil))
    @hostel_fee_collection = HostelFeeCollection.new(@params)
    @hostel_fee_collection.financial_year_id = "0" unless @hostel_fee_collection.financial_year_id.present?
    @hostel_fee_collection.master_fee_particular_id = master_particular.id if master_particular.present?
    @hostel_fee_collection.fee_account_id = account_id
    allocation = RoomAllocation.find(:all, :conditions => ["is_vacated is false"])
    HostelFeeCollection.transaction do
      @hostel_fee_collection.invoice_enabled = (Configuration.get_config_value('EnableInvoiceNumber').to_i == 1)
      if @hostel_fee_collection.save
        tax_enabled = @hostel_fee_collection.tax_enabled
        if tax_enabled
          # tax was enabled when hostel collection job was created
          tax_slab = TaxSlab.find(@params[:tax_slab_id]) if @params[:tax_slab_id].present?
          @hostel_fee_collection.collectible_tax_slabs.create({ :tax_slab_id => tax_slab.try(:id),
              :collectible_entity_id => @hostel_fee_collection.id, :collectible_entity_type => 'HostelFeeCollection' 
            }) if tax_slab.present?          
        end
        #        @event=Event.find_by_title('Hostel Fee', :conditions => ["description=?", "'Fee name: #{@params[:name]}' and start_date='#{@params[:due_date]}' and end_date='#{@params[:due_date]}'"])
        batch_event_attributes = {}
        sub_params = {}
        @batch.each do |batch|
          batch_event_attributes = sub_params.merge({batch.id =>{:batch_id => batch.id, :selected => "1"}})
          sub_params = batch_event_attributes
        end
        params = {:event=>{:title => "#{t('hostel_fee_text')}", :description => "#{t('fee_name')}: #{@params[:name]}", :is_common => false, :start_date => @params[:due_date], :end_date => @params[:due_date], :is_due => true, :origin => @hostel_fee_collection, :batch_events_attributes => batch_event_attributes}}
        #        @event = Event.create(:title => "#{t('hostel_fee_text')}", :description => "#{t('fee_name')}: #{@params[:name]}", :start_date => @params[:due_date], :end_date => @params[:due_date], :is_due => true, :origin => @hostel_fee_collection)
        @event = Event.new(params[:event]) 
        @event.save
        @batch.each do |b|
          recipients = []
          #          @batch_event = BatchEvent.create(:event_id => @event.id, :batch_id => b)
          allocation.each do |a|
            unless a.student.nil?
              if a.student.batch_id == b.to_i
                @hostel_fee = HostelFee.new()
                @hostel_fee.student_id = a.student_id
                @hostel_fee.hostel_fee_collection_id = @hostel_fee_collection.id
                @hostel_fee.rent = a.room_detail.rent
                @hostel_fee.batch_id = b
                @hostel_fee.tax_enabled = @hostel_fee_collection.tax_enabled
                
                if tax_enabled
                  tax_slab = @hostel_fee_collection.collection_tax_slabs.try(:last)
                  if tax_slab.present?
                    taxable_amount = @hostel_fee.rent.to_f
                    tax_amount = taxable_amount > 0 ? (taxable_amount *  tax_slab.rate).to_f / 100.0  : 0.0                    
                    tax_collection = @hostel_fee.tax_collections.build({:tax_amount => tax_amount,
                        :slab_id => tax_slab.id })
                    tax_collection.taxable_entity = @hostel_fee_collection                              
                    @hostel_fee.tax_amount = tax_amount
                  end        
                end
                @hostel_fee.invoice_number_enabled = @hostel_fee_collection.invoice_enabled
                @hostel_fee.save
                
                recipients << a.student.user_id
                UserEvent.create(:event_id => @event.id, :user_id => a.student.user.id)
              end
            end
          end
          send_reminder(@hostel_fee_collection, recipients,@user)
        end
        prev_record = Configuration.find_by_config_key("job/HostelFeeCollection/1")
        if prev_record.present?
          prev_record.update_attributes(:config_value=>Time.now)
        else
          Configuration.create(:config_key=>"job/HostelFeeCollection/1", :config_value=>Time.now)
        end
      else
        @error = true
        @hostel_fee_collection.errors.full_messages.inspect
        raise ActiveRecord::Rollback
      end
    end
  end
  def send_reminder(hostel_fee_collection,recipients,user)
    @sender_id = user.id
    @recipient_ids = recipients.flatten.uniq
    body = "#{t('hostel_text')} #{t('fee_collection_date_for')} <b> #{hostel_fee_collection.name} </b> #{t('has_been_published')} #{t('by')} <b>#{user.full_name}</b>, #{t('start_date')} : #{format_date(hostel_fee_collection.start_date)}  #{t('due_date')} :  #{format_date(hostel_fee_collection.due_date)}"
    links = {:target=>'view_fees',:target_param=>'student_id'}
    @recipient_ids.each do |r_id|
      inform(r_id,body,'Finance',links)
    end
  end
end
