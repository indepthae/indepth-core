class Store < ActiveRecord::Base
  belongs_to :store_category
  belongs_to :store_type
  has_many :store_items
  has_many :indents

  validates_presence_of:name, :code, :store_type_id , :store_category_id
  
  named_scope :active,{ :conditions => { :is_deleted => false }}
  named_scope :code_as, lambda{|store_code|{:conditions => ["stores.code = ? and is_deleted=?",store_code,false]}}
  validates_format_of  :invoice_prefix, :with => /^[A-z]+$/, :allow_blank => true

  def validate
    if Store.active.reject{|s| s.id == id}.find_by_code(code).present? and is_deleted == false
      errors.add("code","is already taken")
    end
    
    unless self.invoice_prefix.blank?
      if Store.active.reject{|s| s.id == id}.find_by_invoice_prefix(invoice_prefix).present? and is_deleted == false
        errors.add("invoice_prefix","is already taken")
      end
    end
  end

  def can_be_deleted?
    (store_items.active.present? or indents.active.present?) ? false : true
  end

  def full_name
    "#{name}-#{code}"
  end

  def self.store_data(params)
    data ||= Array.new
    data << [t('name'), t('code')]
    stores = Store.active
    stores.each do |store|
      data << [store.name,store.code.to_s]
    end
    if params[:report_format_type] == "csv"
      return data
    else
      report_data = {"table_header" => [{"name" => "Name", "code" => "Code"}], "data" => []}
      stores.each do |store|
        report_data["data"] << {"name" => store.name, "code" => store.code}
      end
      return report_data
    end
  end

end
