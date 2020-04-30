class GatewayAssignee < ActiveRecord::Base
  belongs_to :custom_gateway
  belongs_to :assignee, :polymorphic=>true

  validates_presence_of :custom_gateway_id

  before_destroy :check_school_gateway

  def check_school_gateway
    if self.assignee_type=="School"
      MultiSchool.current_school = School.find(self.assignee_id)
      gateway_key = PaymentConfiguration.find_by_config_key("fedena_gateway")
      if gateway_key.present?
        gateway_id = gateway_key.config_value
        if gateway_id.present? and (gateway_id.include? self.custom_gateway_id.to_s)
          gateway_id = gateway_id - self.custom_gateway_id.to_s.to_a
          gateway_key.update_attributes(:config_value=>gateway_id)
        end
      end
    end
  end
end
