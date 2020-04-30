class InventoriesController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
  end

  def search
    
  end

  def taxable_discount_settings
    @saved = false
    if params[:inventory_tax_mode]
      mode = (params[:inventory_tax_mode].to_i == 0 ) ? :old : :new
      FedenaInventory.tax_mode = mode
      @saved = true
    end
    respond_to do |format|
      format.js { render :action => 'taxable_discount_settings' }
    end
  end 

  def search_ajax
    if params[:search_inventory]=="Indent"
      unless params[:query] == ''
        @indents = Indent.active.find(:all,
          :conditions => ["indent_no LIKE ?  OR status LIKE ? " ,"%#{params[:query]}%","%#{params[:query]}%"],
          :order => "indent_no asc" ).paginate :page => params[:page],:per_page => 20
      else
        @indents = Indent.active.find(:all).paginate :page => params[:page],:per_page => 20
      end
      unless params[:paginate] == "true"
        render :partial => 'indent_search'
      else
        render :update do |page|
          page.replace_html "information",:partial => "indent_search"
        end
      end
    elsif params[:search_inventory]== "Purchase_order"
      unless params[:query] == ''
        @purchase_orders = PurchaseOrder.active.find(:all,
          :conditions => ["po_no LIKE ? ", "%#{params[:query]}%"],
          :order => "po_no asc" ).paginate :page => params[:page],:per_page => 20
      else
        @purchase_orders = PurchaseOrder.active.find(:all).paginate :page => params[:page],:per_page => 20
      end
      unless params[:paginate] == "true"
        render :partial => 'po_search'
      else
        render :update do |page|
          page.replace_html "information",:partial => "po_search"
        end
      end
    elsif params[:search_inventory]== "GRN"
      unless params[:query] == ''
        @grns = Grn.active.find(:all,
          :conditions => ["grn_no LIKE ? ", "%#{params[:query]}%"],
          :order => "grn_no asc" ).paginate :page => params[:page],:per_page => 20
      else
        @grns = Grn.active.find(:all).paginate :page => params[:page],:per_page => 20
      end
      unless params[:paginate] == "true"
        render :partial => 'grn_search'
      else
        render :update do |page|
          page.replace_html "information",:partial => "grn_search"
        end
      end
    end
  end

  def reports
    if request.xhr?
      @sort_order=params[:sort_order]
      if params[:status][:type]=="indent"
        if @sort_order.nil?
          if params[:status][:sort_type]=="all"
            @indents=Indent.paginate(:select=>"indents.*,users.first_name,users.last_name,managers_indents.first_name as m_first_name,managers_indents.last_name as m_last_name",:joins=>"LEFT OUTER JOIN `users` ON `users`.id = `indents`.user_id LEFT OUTER JOIN `users` managers_indents ON `managers_indents`.id = `indents`.manager_id",:conditions=>["indents.created_at >= ? and indents.created_at <= ? and indents.is_deleted='0'",params[:status][:from].to_date.beginning_of_day,params[:status][:to].to_date.end_of_day],:per_page=>15,:page=>params[:page],:order=>'indent_no')
          else
            @indents=Indent.paginate(:select=>"indents.*,users.first_name,users.last_name,managers_indents.first_name as m_first_name,managers_indents.last_name as m_last_name",:joins=>"LEFT OUTER JOIN `users` ON `users`.id = `indents`.user_id LEFT OUTER JOIN `users` managers_indents ON `managers_indents`.id = `indents`.manager_id",:conditions=>["indents.status LIKE ? and indents.created_at >= ? and indents.created_at <= ? and indents.is_deleted='0'",params[:status][:sort_type,],params[:status][:from].to_date.beginning_of_day,params[:status][:to].to_date.end_of_day ],:per_page=>15,:page=>params[:page],:order=>'indent_no')
          end
        else
          if params[:status][:sort_type]=="all"
            @indents=Indent.paginate(:select=>"indents.*,users.first_name,users.last_name,managers_indents.first_name as m_first_name,managers_indents.last_name as m_last_name",:joins=>"LEFT OUTER JOIN `users` ON `users`.id = `indents`.user_id LEFT OUTER JOIN `users` managers_indents ON `managers_indents`.id = `indents`.manager_id",:conditions=>["indents.created_at >= ? and indents.created_at <= ? and indents.is_deleted='0'",params[:status][:from].to_date.beginning_of_day,params[:status][:to].to_date.end_of_day],:per_page=>15,:page=>params[:page],:order=>@sort_order)
          else
            @indents=Indent.paginate(:select=>"indents.*,users.first_name,users.last_name,managers_indents.first_name as m_first_name,managers_indents.last_name as m_last_name",:joins=>"LEFT OUTER JOIN `users` ON `users`.id = `indents`.user_id LEFT OUTER JOIN `users` managers_indents ON `managers_indents`.id = `indents`.manager_id",:conditions=>["indents.status LIKE ? and indents.created_at >= ? and indents.created_at <= ? and indents.is_deleted='0'",params[:status][:sort_type,],params[:status][:from].to_date.beginning_of_day,params[:status][:to].to_date.end_of_day ],:per_page=>15,:page=>params[:page],:order=>@sort_order)
          end
        end
        render :update do |page|
          page.replace_html "information",:partial => "indent_details"
        end
      elsif params[:status][:type]=="purchase_order"
        if @sort_order.nil?
          if params[:status][:sort_type]=="all"
            @purchase_orders=PurchaseOrder.paginate(:select=>"purchase_orders.*,stores.name as store_name,stores.code as store_code",:joins=>[:store],:conditions=>["purchase_orders.created_at >= ? and purchase_orders.created_at <= ? and purchase_orders.is_deleted='0'",params[:status][:from].to_date.beginning_of_day,params[:status][:to].to_date.end_of_day],:per_page=>15,:page=>params[:page],:order=>'po_no ASC')
          else
            @purchase_orders=PurchaseOrder.paginate(:select=>"purchase_orders.*,stores.name as store_name,stores.code as store_code",:joins=>[:store],:conditions=>["purchase_orders.po_status=? and purchase_orders.created_at >= ? and purchase_orders.created_at <= ? and purchase_orders.is_deleted='0'",params[:status][:sort_type],params[:status][:from].to_date.beginning_of_day,params[:status][:to].to_date.end_of_day],:per_page=>15,:page=>params[:page],:order=>'po_no ASC')
          end
        else
          if params[:status][:sort_type]=="all"
            @purchase_orders=PurchaseOrder.paginate(:select=>"purchase_orders.*,stores.name as store_name,stores.code as store_code",:joins=>[:store],:conditions=>["purchase_orders.created_at >= ? and purchase_orders.created_at <= ? and purchase_orders.is_deleted='0'",params[:status][:from],params[:status][:to]],:per_page=>15,:page=>params[:page],:order=>@sort_order)
          else
            @purchase_orders=PurchaseOrder.paginate(:select=>"purchase_orders.*,stores.name as store_name,stores.code as store_code",:joins=>[:store],:conditions=>["purchase_orders.po_status=? and purchase_orders.created_at >= ? and purchase_orders.created_at <= ? and purchase_orders.is_deleted='0'",params[:status][:sort_type],params[:status][:from].to_date.beginning_of_day,params[:status][:to].to_date.end_of_day],:per_page=>15,:page=>params[:page],:order=>@sort_order)
          end
        end
        render :update do |page|
          page.replace_html "information",:partial => "purchase_order_details"
        end
      else
        if @sort_order.nil?
          @grn=Grn.paginate(:select=>"grns.*,po_no,suppliers.name as supplier,stores.name as store",:joins=>"INNER JOIN `purchase_orders` ON `purchase_orders`.id = `grns`.purchase_order_id LEFT OUTER JOIN `suppliers` ON `suppliers`.id = `purchase_orders`.supplier_id INNER JOIN `stores` ON `stores`.id = `purchase_orders`.store_id",:conditions=>["grns.created_at >= ? and grns.created_at <= ? and grns.is_deleted='0'" ,params[:status][:from].to_date.beginning_of_day,params[:status][:to].to_date.end_of_day],:per_page=>15,:page=>params[:page],:order=>'grn_no ASC')
        else
          @grn=Grn.paginate(:select=>"grns.*,po_no,suppliers.name as supplier,stores.name as store",:joins=>"INNER JOIN `purchase_orders` ON `purchase_orders`.id = `grns`.purchase_order_id LEFT OUTER JOIN `suppliers` ON `suppliers`.id = `purchase_orders`.supplier_id INNER JOIN `stores` ON `stores`.id = `purchase_orders`.store_id",:conditions=>["grns.created_at >= ? and grns.created_at <= ? and grns.is_deleted='0'" ,params[:status][:from].to_date.beginning_of_day,params[:status][:to].to_date.end_of_day],:per_page=>15,:page=>params[:page] ,:order=>@sort_order)
        end
        render :update do |page|
          page.replace_html "information",:partial => "grn_details"
        end
      end
    end
  end

  def select_sort_order
    if params[:category]=="grn"
      render :update do |page|
        page.replace_html "sort_type",:text => ""
      end
    else
      render :update do |page|
        page.replace_html "sort_type",:partial => "select_sort_order"
      end
    end
  end

  def indent_report_csv
    parameters={:sort_order=>params[:sort_order],:status=>params[:status]}
    csv_export('indent','indent_details',parameters)
  end

  def purchase_order_csv
    parameters={:sort_order=>params[:sort_order],:status=>params[:status]}
    csv_export('purchase_order','purchase_order_details',parameters)
  end

  def grn_report_csv
    parameters={:sort_order=>params[:sort_order],:status=>params[:status]}
    csv_export('grn','grn_details',parameters)
  end

end


def csv_export(model,method,parameters)
  csv_report=AdditionalReportCsv.find_by_model_name_and_method_name(model,method)
  if csv_report.nil?
    csv_report=AdditionalReportCsv.new(:model_name => model, :method_name => method, :parameters => parameters, :status => true)
    if csv_report.save
      Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
    end
  else
    unless csv_report.status
      if csv_report.update_attributes(:parameters => parameters, :csv_report => nil, :status => true)
        Delayed::Job.enqueue(DelayedAdditionalReportCsv.new(csv_report.id),{:queue => "additional_reports"})
      end
    end 
  end
  flash[:notice]="#{t('csv_report_is_in_queue')}"
  redirect_to :controller=>:report,:action=>:csv_reports,:model=>model,:method=>method
end
