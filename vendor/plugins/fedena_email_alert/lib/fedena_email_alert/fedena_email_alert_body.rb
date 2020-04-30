module FedenaEmailAlert
  class FedenaEmailAlertBody
    attr_accessor :recipient,:to,:subject,:message,:stud_name,:footer,:other_details

    def initialize(*args)
      hsh = args.extract_options!
      hsh.each{|k,v| instance_variable_set("@#{k.to_s}",v)}
    end
    
  end
end