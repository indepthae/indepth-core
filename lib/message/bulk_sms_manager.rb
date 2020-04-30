class BulkSmsManager
  attr_accessor :method_name, :argument_list
  
  def initialize (method_name, argument_list)
     @method_name = method_name
     @argument_list = argument_list
  end
  
  def perform
    SmsManager.send method_name, *argument_list
  end
  
end
