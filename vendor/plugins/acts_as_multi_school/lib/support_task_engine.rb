module SupportTaskEngine

  @@current_script = nil
  @@scripts = []
 
  def self.config(&block)
    module_eval(&block)
  end
 
  def self.support_task(name, description, params = {}, instruction = {}, &block)
    script = TaskEngineScript.new(name, description, params, instruction)   
    @@scripts << script
    @@current_script = script
    module_eval(&block)
  end
 
  def self.check(&block)
    @@current_script.check_script = block
  end

  def self.run(&block)
    @@current_script.run_script = block
  end
 
  def self.current_script
    @@current_script
  end
 
  def self.scripts
    @@scripts
  end
  
  def self.log_it(log_task, details)
    logit = Logger.new(log_task.log)
    logit.info(details)
  end
  
#  def self.log_it
#    log_task.log += "\n"
#    log_task.log += details
#    log_task.save
#  end
  
  def update_status(task, stats)
    
  end
 

  class TaskEngineScript
 
    attr_accessor :name, :description, :params_list, :instruction, :check_script, :run_script
 
    def initialize(name, description, params, instruction)
      @name = name
      @description = description
      @params_list = params
      @instruction = instruction
    end

    def check(params = {}, stats = nil)
      check_script.call(params, stats)
    end
 
    def run(params = {}, stats = nil)
      run_script.call(params, stats)
    end 
   
    def resolve_params(params = {})
      @params_list.each_pair do |name, type|
        validate_key = params[name].present? ? validate_params(type, params[name]) : false
        unless validate_key
          return false
        end
      end
      return true
    end
   
    def validate_params(type, value)
      case type
      when "string"
        return true
      when "date"
        begin
          Date.parse(value)
          return true
        rescue ArgumentError
          return false
        end
      when "integer"
        r_value = value.to_i.to_s == value ? true : false
        return r_value
      when "file"
        count = `wc -l #{value}`.to_i
        status = count > 500 ? false : true
        return status
      end
    end
 
  end
 
end