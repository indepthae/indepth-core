class FeeImportsController < ApplicationController
  lock_with_feature :finance_multi_receipt_data_updation
  before_filter :login_required
  filter_access_to :all

  def import_fees
    @student = Student.find_by_id(params[:id])
    @fee_collection_dates = FinanceFeeCollection.current_active_financial_year.all(:select=>"distinct finance_fee_collections.*",
      :joins=>" LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
               INNER JOIN fee_collection_batches
                       ON fee_collection_batches.finance_fee_collection_id=finance_fee_collections.id
          LEFT OUTER JOIN finance_fees
                       ON finance_fees.fee_collection_id=finance_fee_collections.id AND
                          finance_fees.student_id='#{@student.id}' AND
                          finance_fees.is_paid=false
               INNER JOIN finance_fee_particulars
                       ON finance_fee_particulars.finance_fee_category_id=finance_fee_collections.fee_category_id",
      :conditions => "(fa.id IS NULL OR fa.is_deleted = false) AND (finance_fee_collections.is_deleted=false and
                             (finance_fees.id is not null) or
                             fee_collection_batches.batch_id='#{@student.batch.id}') AND 
                             ((finance_fee_particulars.receiver_type='Batch' AND 
                               finance_fee_particulars.receiver_id='#{@student.batch.id}') or 
                              (finance_fee_particulars.receiver_type='Student' and 
                               finance_fee_particulars.receiver_id='#{@student.id}') or 
                              (finance_fee_particulars.receiver_type='StudentCategory' and 
                               finance_fee_particulars.receiver_id='#{@student.student_category_id}'))")
           
    if @fee_collection_dates.blank?
      flash[:notice] = t('add_the_additional_details')
      redirect_to :controller => "student", :action => "admission4", :id => @student.id,:imported=>'1'
    end
    if request.post?
      unless params[:fees].nil?
        dates = FinanceFeeCollection.find(params[:fees][:collection_ids])
        unless (@student.has_paid_fees or @student.has_paid_fees_for_batch)
          dates.each do |date|            
            FinanceFee.new_student_fee(date,@student)
          end
        end
        flash[:notice] = "#{t('add_the_additional_details')}"
        redirect_to :controller => "student", :action => "admission4", :id => @student.id, :imported=>'1'
      else
        flash[:notice] = "#{t('please_select_fee_collection')}"
        redirect_to :action => 'import_fees', :id=>@student.id
      end
    end
  end

  def select_student
    @batches = Batch.active
    if request.post?
      if params[:fees_list].present?
        @student = Student.find_by_id(params[:fees_list][:student_id])
        @batch_selected=@student.batch
        collection_dates
        discount_disabled_fees
        fetch_student_fees
        dates = []
        dates = params[:fees_list][:collection_ids].to_a unless params[:fees_list].nil?
        disabled_collection_ids = @discounted_fees.map {|x| x.collection_id.to_i }
        @fee_collection_dates.each do |date|
          if @student_fees.include?(date.id)
            unless dates.include?(date.id.to_s)
              fee = FinanceFee.find_by_student_id_and_fee_collection_id(@student.id, date.id)
              fee.destroy if fee.finance_transactions.empty? and !(disabled_collection_ids.include?(date.id))
              flash[:notice]="#{t('fee_collections_are_updated_to_the_student_successfully')}"
            end
          else

            if dates.include?(date.id.to_s)
              FinanceFee.new_student_fee(date,@student)
              flash[:notice]="#{t('fee_collections_are_updated_to_the_student_successfully')}"
            end

          end
        end
        flash[:notice]="#{t('no_changes_are_done')}" if flash[:notice].nil?
        flash.discard(:notice)
        @students = Student.find_all_by_batch_id(@student.batch_id, :order => 'first_name ASC')
        fetch_student_fees
      end
    end
  end

  def list_students_by_batch
    @students = Student.find_all_by_batch_id(params[:batch_id],
      :conditions=>"has_paid_fees=#{false} and has_paid_fees_for_batch=false", :order => 'first_name ASC')
    unless @students.blank?
      @student = @students.first
      collection_dates
      discount_disabled_fees
      fetch_student_fees
    end
    render :update do |page|
      page.replace_html 'students', :partial => 'batch_student_list'
      page.replace_html 'financial_year_details', :partial => 'finance/financial_year_info'
    end
  end

  def list_fees_for_student
    @student = Student.find_by_id(params[:student])
    collection_dates
    discount_disabled_fees
    fetch_student_fees
    render :update do |page|
      page.replace_html 'fees_list', :partial => 'fees_list'
      page.replace_html 'financial_year_details', :partial => 'finance/financial_year_info'
    end
  end
  
  def fetch_student_fees
    @finance_fees = FinanceFee.find_all_by_student_id(@student.id)
    @student_fees = @finance_fees.map{|s| s.fee_collection_id}
    @payed_fees = FinanceFee.find(:all,
      :joins=>"INNER JOIN fee_transactions on fee_transactions.finance_fee_id=finance_fees.id 
                    INNER JOIN finance_fee_collections on finance_fee_collections.id=finance_fees.fee_collection_id",
      :conditions=>"finance_fees.student_id=#{@student.id}",:select=>"finance_fees.fee_collection_id").
      map{|s| s.fee_collection_id}
    
    @payed_fees ||= []
  end
  
  def collection_dates
    @fee_collection_dates=[]
    @fee_collection_dates+=FinanceFeeCollection.current_active_financial_year.all(
      :select=>"distinct finance_fee_collections.*",
      :joins=>"LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
           INNER JOIN fee_collection_batches ON fee_collection_batches.finance_fee_collection_id=finance_fee_collections.id
           LEFT OUTER JOIN finance_fees 
                        ON finance_fees.fee_collection_id=finance_fee_collections.id and
                           finance_fees.student_id='#{@student.id}' and finance_fees.is_paid=false
                INNER JOIN finance_fee_particulars ON finance_fee_particulars.finance_fee_category_id=finance_fee_collections.fee_category_id",
      :conditions=>"(finance_fee_collections.fee_account_id IS NULL OR fa.is_deleted = false) and
                    (
                      finance_fee_collections.is_deleted=false and
                      (
                        finance_fees.id is not null
                      ) or
                      fee_collection_batches.batch_id='#{@student.batch.id}'
                    )
                    and
                    (
                      (
                        finance_fee_particulars.receiver_type='Batch' and
                        finance_fee_particulars.receiver_id='#{@student.batch.id}'
                      ) or
                      (
                        finance_fee_particulars.receiver_type='Student' and
                        finance_fee_particulars.receiver_id='#{@student.id}'
                      ) or
                      (
                        finance_fee_particulars.receiver_type='StudentCategory' and
                        finance_fee_particulars.receiver_id='#{@student.student_category_id}'
                      )
                    )"
    )
    @fee_collection_dates += @fee_collection_date = FinanceFeeCollection.current_active_financial_year.all(
      :select=>"distinct finance_fee_collections.*",
      :joins=>"LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
              INNER JOIN fee_collection_batches on fee_collection_batches.finance_fee_collection_id=finance_fee_collections.id
         LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id
              INNER JOIN finance_fee_particulars on finance_fee_particulars.finance_fee_category_id=finance_fee_collections.fee_category_id",
      :conditions => "(finance_fee_collections.fee_account_id IS NULL OR
                       (finance_fee_collections.fee_account_id IS NOT NULL AND fa.is_deleted = false)) and
                      (finance_fee_collections.is_deleted=false and
                       (finance_fees.student_id='#{@student.id}' and finance_fees.is_paid=false)) and
                      finance_fees.student_id='#{@student.id}'")
    @fee_collection_dates.uniq!
  end
  
  def discount_disabled_fees    
    @discounted_fees = @fee_collection_dates.present? ? FinanceFee.all(
      :select => "DISTINCT mfd.id AS mfd_id, mfd.master_receiver_type AS discounted_type, 
                          mfd.master_receiver_id AS discounted_id, finance_fees.fee_collection_id AS collection_id", 
      :conditions => "finance_fees.fee_collection_id IN (#{@fee_collection_dates.map(&:id).join(',')}) AND
                              fd.is_instant = true AND fd.multi_fee_discount_id IS NOT NULL AND                                                               
                              finance_fees.batch_id = #{@student.batch_id} AND 
                              finance_fees.student_id = #{@student.id}", 
      :joins => "INNER JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id 
                      INNER JOIN collection_discounts cd ON cd.finance_fee_collection_id = finance_fees.fee_collection_id
                      INNER JOIN fee_discounts fd ON fd.id=cd.fee_discount_id
                      INNER JOIN multi_fee_discounts mfd ON mfd.id = fd.multi_fee_discount_id AND mfd.receiver_id = #{@student.id}") : []    
  end
end
