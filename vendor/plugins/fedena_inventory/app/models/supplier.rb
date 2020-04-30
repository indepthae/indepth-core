class Supplier < ActiveRecord::Base
  belongs_to :supplier_type
  has_many :purchase_orders
  

  validates_presence_of :supplier_type_id, :name
  validates_format_of     :tin_no, :with => /^[A-Z0-9]*$/i
  validates_numericality_of :contact_no
  
  named_scope :active,{ :conditions => { :is_deleted => false }}

  def validate
    if Supplier.active.find_by_supplier_type_id_and_contact_no(supplier_type_id,contact_no).to_a.reject{|st| st.id == id}.present? and is_deleted == false
      errors.add("contact_no","is already taken")
    end
  end

  def can_be_deleted?
    purchase_orders.active.present? ? false : true
  end

  def self.supplier_data(params)
    data = []
    suppliers = Supplier.active
    unless suppliers.blank?
      data  << [t('suppliers.supplier_name'),t('suppliers.supplier_type'),t('suppliers.contact_no'),t('suppliers.tin_no'),t('suppliers.region')]
      suppliers.each_with_index do |s, i|
        row_data = [s.name]      
        row_data << s.supplier_type.name unless s.supplier_type.nil?
        row_data << s.contact_no << s.tin_no  << s.region
        data << row_data
      end
      if params[:report_format_type] == "csv"
        return data
      else
        report_data = {"data" => [],"table_header" => [{"sl_no" => "#{t('sl_no')}","sup_name" => "#{t('item_name')}","sup_type" => "Supplier Type","con_no" => "Contact no", "tin_no" => "Tin no","region" => "Region"}]}
        store_items.each_with_index do |store, i|        
          row = {"sl_no" => i+1,"sup_name" => s.name}
          row["sup_type"] = s.supplier_type.name unless s.supplier_type.nil?
          row["con_no"] = s.contact_no 
          row["tin_no"] = s.tin_no 
          row["region"] = s.region
          report_data["data"] << row
        end
        return report_data
      end
    end
    return data
  end
end
