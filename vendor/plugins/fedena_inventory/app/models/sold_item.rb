class SoldItem < ActiveRecord::Base
  belongs_to :invoice
  belongs_to :store_item
  attr_accessor :item_name
  #validate :rate, :quantity, :numericality => { :greater_than_or_equal_to => 0 },  :allow_nil => true
  validates_numericality_of :quantity, :only_integer => true, :greater_than => 0#,# :on => [:create, :update]
  validates_numericality_of :rate, :greater_than_or_equal_to => 0#, :on => [:create, :update]
  validates_presence_of :rate, :quantity, :store_item_id, :item_name#, :on => [:create, :update]

  validate_on_create :item_availabilty
  validate_on_update :current_item_availability

  def item_availabilty
    item = self.store_item
    unless quantity.nil?
      unless item.nil?
        if item.quantity < quantity
          errors.add("quantity","selected is more than available")
        end
      end
    end
  end

  def current_item_availability
    item = self.store_item
    unless self.changes.empty?
      unless self.changes[:quantity].nil?
        unless item.nil?
          if item.quantity + self.changes[:quantity].first < quantity
            errors.add("quantity","selected is more than available")
          end
        end
      end
    end
  end

 def total_amount
   rate.to_f
 end 
end
