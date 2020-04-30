
class StoreItem < ActiveRecord::Base
  belongs_to :store
  has_many :indent_items
  has_many :purchase_items
  has_many :grn_items
  has_many :sold_items
  belongs_to :item_category
  validates_presence_of :item_name,:quantity,:unit_price
  validates_presence_of :store_id,:message=>:not_present
  validates_numericality_of  :quantity, :greater_than_or_equal_to => 0
  validates_numericality_of  :unit_price,:greater_than => 0, :less_than_or_equal_to => 10000000
  validates_numericality_of :tax, :greater_than_or_equal_to => 0, :less_than => 100

  validates_presence_of :item_category_id, :if => Proc.new{|f| f.sellable == true }
  named_scope :active,{ :conditions => { :is_deleted => false }}

  before_save :verify_precision
  
  def verify_precision
    #    self.unit_price = FedenaPrecision.set_and_modify_precision self.unit_price
    #    self.tax = FedenaPrecision.set_and_modify_precision self.tax
  end

  def validate
    if StoreItem.active.reject{|si| si.id == id}.find_by_item_name(item_name).present? and is_deleted == false
      errors.add("item_name","is already taken")
    end

#    if StoreItem.active.reject{|si| si.id == id}.find_by_batch_number(batch_number).present? and is_deleted == false
#      errors.add("batch_number","is already taken")
#    end
  end
  
  def can_be_deleted?
    (indent_items.active.present? or purchase_items.active.present? or grn_items.active.present?) ? false : true
  end

  def can_edit_store(user_in_question)
    user_in_question.privileges.map(&:name).include?('Inventory') or user_in_question.admin?
  end

  def self.store_items_data(params)
    data = []
    stores = Store.active
    if params[:search_store] == 'All'
      store_items = StoreItem.find(:all,:conditions => [" is_deleted=false and item_name LIKE ? ", "#{params[:query]}%" ])
    else
      store_items = StoreItem.find(:all, :include=>:store,:conditions => [" store_items.is_deleted=false and store_id LIKE ? and item_name LIKE ?  ", params[:search_store],"%#{params[:query]}%" ] )
    end
    unless store_items.blank?
      data << ["Item Name","#{t('name')}","#{t('item_category')}","#{t('store_items.batch_no')}","Quantity", "Unit Price","Tax"]
      store_items.each_with_index do |store, i|
        row_data = [store.item_name]
        row_data << store.store.name  unless store.store.nil?
        row_data << ((store.item_category.nil? or store.sellable==false) ? "-" : store.item_category.name)
        row_data << store.batch_number
        row_data << store.quantity << precision_label(store.unit_price) << precision_label(store.tax)
        data << row_data
      end
    end
    return data
  end
    
  def self.precision_label(val)
    if defined? val and val != '' and !val.nil?
      return sprintf("%0.#{precision_count}f",val)
    else
      return
    end
  end

  def self.precision_count
    precision_count = Configuration.get_config_value('PrecisionCount')
    precision = precision_count.to_i < 2 ? 2 : precision_count.to_i > 9 ? 8 : precision_count.to_i
    precision
  end
    

    
end
