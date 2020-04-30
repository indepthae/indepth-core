class PurchaseOrder < ActiveRecord::Base
  belongs_to :store
  belongs_to :indent
  belongs_to :supplier
  belongs_to :supplier_type
  has_many :purchase_items, :dependent => :destroy
  has_many :grns

  validates_presence_of :store_id, :po_no
  validates_inclusion_of :po_status,  :in => %w(Pending Issued Rejected)

  named_scope :active,{ :conditions => { :is_deleted => false }}
  named_scope :inactive,{ :conditions => { :is_deleted => true }}

  accepts_nested_attributes_for :purchase_items, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true

  
  def validate
    if PurchaseOrder.active.reject{|po| po.id == id}.find_by_po_no(po_no).present? and is_deleted == false
      errors.add("po_no","is already taken")
    end
    to_check = purchase_items.reject{|ii| ii._destroy == true}
    unless to_check.present?
      errors.add('purchase_items',"can't be blank")
    end
    if indent.present?
      errors.add("po_date","cannot be less than indent date") if po_date < indent.expected_date.to_date
    end
  end

  def can_be_deleted?
    (po_status == "Issued" or grns.active.present? ) ? false :true
  end

  def can_be_rejected?
    grns.present? ? false : true
  end

  def self.purchase_order_details(parameters)
    sort_order=parameters[:sort_order]
    status=parameters[:status]
    if sort_order.nil?
      if status[:sort_type]=="all"
        purchase_orders=PurchaseOrder.all(:select=>"purchase_orders.*,stores.name as store_name,stores.code as store_code",:joins=>[:store],:conditions=>["purchase_orders.created_at >= ? and purchase_orders.created_at <= ? and purchase_orders.is_deleted='0'",status[:from].to_date.beginning_of_day,status[:to].to_date.end_of_day],:order=>'po_no ASC')
      else
        purchase_orders=PurchaseOrder.all(:select=>"purchase_orders.*,stores.name as store_name,stores.code as store_code",:joins=>[:store],:conditions=>["purchase_orders.po_status=? and purchase_orders.created_at >= ? and purchase_orders.created_at <= ? and purchase_orders.is_deleted='0' ",status[:sort_type],status[:from].to_date.beginning_of_day,status[:to].to_date.end_of_day],:order=>'po_no ASC')
      end
    else
      if status[:sort_type]=="all"
        purchase_orders=PurchaseOrder.all(:select=>"purchase_orders.*,stores.name as store_name,stores.code as store_code",:joins=>[:store],:conditions=>["purchase_orders.created_at >= ? and purchase_orders.created_at <= ? and purchase_orders.is_deleted='0'",status[:from].to_date.beginning_of_day,status[:to].to_date.end_of_day],:order=>sort_order)
      else
        purchase_orders=PurchaseOrder.all(:select=>"purchase_orders.*,stores.name as store_name,stores.code as store_code",:joins=>[:store],:conditions=>["purchase_orders.po_status=? and purchase_orders.created_at >= ? and purchase_orders.created_at <= ? and purchase_orders.is_deleted='0'",status[:sort_type],status[:from].to_date.beginning_of_day,status[:to].to_date.end_of_day],:order=>sort_order)
      end
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('purchase_orders.purchase_order_no')}","#{t('purchase_orders.store_name') }","#{t('purchase_orders.purchase_date') }","#{t('status')}"]
    data << col_heads
    purchase_orders.each_with_index do |s,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.po_no}"
      col<< "#{s.store_name}"
      col<< "#{s.po_date.to_date}"
      col<< "#{s.po_status}"
      col=col.flatten
      data<< col
    end
    return data
  end
  
end
