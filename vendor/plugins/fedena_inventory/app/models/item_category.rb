class ItemCategory < ActiveRecord::Base
  has_many :store_items
  validates_presence_of :name,:code

 
  named_scope :active,{ :conditions => { :is_deleted => false }}


  def validate
    if ItemCategory.active.reject{|sc| sc.id == id}.find_by_code(code).present? and is_deleted == false
      errors.add("code","is already taken")
    end
  end
  
  def can_be_deleted?
    store_items.active.present? ? false : true
  end

end
