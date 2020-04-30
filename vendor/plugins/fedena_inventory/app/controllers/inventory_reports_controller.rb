class InventoryReportsController < ApplicationController
  before_filter :login_required
  filter_access_to :all

  def index
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

  def item_wise_report
    @stores = Store.find(:all, :joins => :store_items, :conditions => ["stores.is_deleted = ? AND store_items.item_category_id is not null",false]).uniq
    @currency = currency
    if request.xhr?
      joins = "INNER JOIN invoices ON invoices.id = sold_items.invoice_id
               INNER JOIN store_items ON store_items.id = sold_items.store_item_id
          LEFT OUTER JOIN finance_transactions ft On ft.finance_id = invoices.id AND ft.finance_type = 'Invoice'
          LEFT OUTER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
          LEFT OUTER JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
      cond = "(fa.id IS NULL OR fa.is_deleted = false) AND invoices.date BETWEEN ? AND ? AND store_items.store_id = ? AND
               store_items.item_category_id = ? "
      cond_vars = [params[:status][:from],params[:status][:to],params[:status][:store],params[:status][:item_category]]
      unless params[:status][:is_paid] == "all"
        cond += " AND invoices.is_paid = ?"
        cond_vars << params[:status][:is_paid]
      end
      @sold_items = SoldItem.paginate(:page => params[:page], :per_page => 10, :joins => joins,
                                      :conditions => [cond] + cond_vars, :group => "sold_items.store_item_id",
                                      :select => "sold_items.*,sum(sold_items.rate) as total_rate,
                                                  sum(sold_items.quantity) as total_quantity")

      render :update do |page|
        page.replace_html "update_report",:partial => "item_report"
      end
    end
  end

  def invoice_report
    @stores = Store.active.all
    @currency = currency
    if request.xhr?
      joins = "LEFT OUTER JOIN sold_items On sold_items.invoice_id = invoices.id
                    LEFT OUTER JOIN discounts ON discounts.invoice_id = invoices.id
                    LEFT OUTER JOIN additional_charges ON additional_charges.invoice_id = invoices.id
                    LEFT OUTER JOIN finance_transactions ft On ft.finance_id = invoices.id AND ft.finance_type = 'Invoice'
                    LEFT OUTER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
                    LEFT OUTER JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
      group = "discounts.invoice_id,additional_charges.invoice_id,sold_items.invoice_id"
      select = "invoices.*,(select sum(discounts1.amount) from discounts discounts1
                             where find_in_set(id,group_concat(discounts.id))limit 1) as discount,
                           (select sum(additional_charges1.amount) from  additional_charges additional_charges1
                             where find_in_set(id,group_concat(additional_charges.id)) limit 1) as add_charges,
                           (select sum(sold_items1.rate) from sold_items sold_items1
                             where find_in_set(id,group_concat(sold_items.id)) limit 1)  as grand_total"
      cond = "(fa.id IS NULL OR fa.is_deleted = false) AND invoices.store_id = ? AND invoices.date BETWEEN ? AND ?"
      cond_vars = [params[:status][:store], params[:status][:from], params[:status][:to]]
      unless params[:status][:is_paid] == "all"
        cond += " AND invoices.is_paid = ?"
        cond_vars << params[:status][:is_paid]
      end

      @report_data = Invoice.paginate(:page => params[:page], :per_page => 10, :conditions => [cond] + cond_vars,
                                      :joins => joins, :group => group, :select => select, :order => "invoices.id desc")

      render :update do |page|
        page.replace_html "update_report", :partial => "invoice_report"
      end
    end
  end

  def day_wise_report
    @stores = Store.active.all
    @currency = currency
    if request.xhr?
      joins = "LEFT OUTER JOIN finance_transactions ft On ft.finance_id = invoices.id AND ft.finance_type = 'Invoice'
               LEFT OUTER JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = ft.id
               LEFT OUTER JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
      cond = "(fa.id IS NULL OR fa.is_deleted = false) AND invoices.store_id = ? AND invoices.date BETWEEN ? AND ? "
      cond_vars = [params[:status][:store],params[:status][:from],params[:status][:to]]
      unless params[:status][:is_paid] == "all"
        cond += " AND invoices.store_id = ?"
        cond_vars << params[:status][:is_paid]
      end

      @report_data = Invoice.paginate(:page => params[:page],:per_page => 10, :joins => joins, :conditions => [cond] + cond_vars)

      render :update do |page|
        page.replace_html "update_report",:partial => "day_wise_report"
      end
    end
  end

  def sales_report
  end

  def update_item_wise_report
    render :update do |page|
      page.replace_html "update_report",:partial => "item_report"
    end
  end

  def select_store_item
    @store_items = StoreItem.find(:all, :conditions => {:store_id => params[:category]})
    render :update do |page|
      page.replace_html "sort_type",:partial => "select_store_item"
    end
  end

  private

  def currency
    return Configuration.find_by_config_key("CurrencyType").config_value
  end
end
