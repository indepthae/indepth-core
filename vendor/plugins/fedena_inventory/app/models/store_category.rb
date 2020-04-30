class StoreCategory < ActiveRecord::Base
  validates_presence_of :name,:code
  
  has_many :stores

  named_scope :active,{ :conditions => { :is_deleted => false }}


  def validate
    if StoreCategory.active.reject{|sc| sc.id == id}.find_by_code(code).present? and is_deleted == false
      errors.add("code","is already taken")
    end
  end

  def can_be_deleted?
    stores.active.present? ? false : true
  end

  def full_name
    "#{name}-#{code}"
  end
    
end
