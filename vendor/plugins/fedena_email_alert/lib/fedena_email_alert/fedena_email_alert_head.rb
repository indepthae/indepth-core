module FedenaEmailAlert
  class FedenaEmailAlertHead
    attr_accessor :name,:model,:hook,:plugin,:conditions,:fields,:modifications,:mail_to

    def initialize(*args)
      hsh = args.extract_options!
      hsh.each{|k,v| instance_variable_set("@#{k.to_s}",v)}
    end

    def to(*args)
      mail_to << FedenaEmailAlertBody.new(args.extract_options!)
    end
    
  end
end