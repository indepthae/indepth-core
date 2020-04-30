module FedenaEmailAlert
  def self.attach_overrides
    Dispatcher.to_prepare :fedena_email_alert do
      load File.join(File.dirname(__FILE__), 'fedena_email_alert', 'alert_data.rb')
      attach_alerts
      Student.instance_eval { has_one :email_subscription ,:dependent=>:destroy }
      FinanceTransaction.instance_eval {include FedenaEmailAlert::TransactionOverride}
    end
  end
  
  mattr_accessor :alert_bodies
  @@alert_bodies=[]

  def self.attach_alerts
    alert_bodies.select{|e| e.hook==:after_update}.collect(&:model).uniq.each do|update_model|
      update_model.to_s.camelize.constantize.send :include,EmailAlertOnUpdate if EmailAlert.defined_model(update_model)
    end if EmailAlert.connection.tables.include? "email_alerts"
    alert_bodies.select{|e| e.hook==:after_create}.collect(&:model).uniq.each do|create_model|
      create_model.to_s.camelize.constantize.send :include,EmailAlertOnCreate if EmailAlert.defined_model(create_model)
    end if EmailAlert.connection.tables.include? "email_alerts"

  end
  
  def self.make(&block)
    module_eval(&block)
  end

  def self.alert(name,model,hook,plugin,conditions,fields,modifications,&block)
    alert = FedenaEmailAlertHead.new(:name=>name,:model=>model,:hook=>hook,:plugin=>plugin,:conditions=>conditions,:fields=>fields,:modifications=>modifications,:mail_to=>[])
    alert.instance_eval(&block)
    @@alert_bodies << alert
  end

  def self.alerts_for_model (model_name, options={})
    callback_opts = {}
  end

  module TransactionOverride
    def self.included(base)
      base.class_eval do
        def name_of_collection
          if self.finance_type == 'FinanceFee'
            return self.finance.finance_fee_collection.name
          elsif self.finance_type == 'HostelFee'
            return self.finance.hostel_fee_collection.name
          elsif self.finance_type == 'TransportFee'
            return self.finance.transport_fee_collection.name
          else
            return nil
          end
        end
      end
    end
  end

end
