class AdditionalCharge < ActiveRecord::Base
   belongs_to :invoice
   validates_numericality_of :amount, :greater_than_or_equal_to => 0, :if => lambda {|attr| attr.amount.present?}, :message => "for additional charge is not valid" #, :on => [:create, :update]
   validate :check_name_and_amount
   
  def check_name_and_amount
    if self.amount.present? and self.name.empty?
      errors.add_to_base(t("add_name_empty"))
    elsif self.name.present? and self.amount.nil?
       errors.add_to_base(t("add_amount_empty"))
    end 
  end
end
