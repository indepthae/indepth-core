class PaymentAccount < ActiveRecord::Base
  
  serialize :account_params
  
  belongs_to :custom_gateway
  belongs_to :collection, :polymorphic=>true
  
  
end
