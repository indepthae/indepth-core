class DependencyHook
  
  attr_accessor :hook_name, :target_class, :warning_message

  def initialize (*args)
    opts = args.extract_options!
    opts.each do |key,val|
      (self.class.method_defined?(key)) ? instance_variable_set("@#{key}",val) : (raise NoMethodError,"undefined method #{key}")
    end
  end

  def check_dependency_for (object)
    dr = DependencyResult.new()
    dr.hook_name = hook_name
    dr.result = object.send hook_name
    dr.warning = make_warning(dr.result)
    dr
  end

  def make_warning (result)
    unless result
      case warning_message.class.to_s
      when "String"
        warning_message
      when "Symbol"
        I18n.t(warning_message)
      else
        "Have dependencies for #{hook_name}."
      end
    end
  end


  class << self
    
    attr_reader :hooks
    
    def make_dependency_hook (hook_name,target_class,*opts, &block)

      options= opts.extract_options!
      default_options = {:warning_message=>nil}
      default_options.merge! options
      default_options.merge!(:hook_name=>hook_name, :target_class=>target_class)

      hook = new(default_options)
      klass = hook.target_class.to_s.classify.constantize

      if block_given?
        klass.send(:define_method, hook.hook_name, &block)
      end

      @hooks ||= []
      @hooks << hook

      hook
      
    end

    def hooks
      @hooks || []
    end

    def hooks_for (klass,*opts)
      options = opts.extract_options!
      if options.present?
        if options.has_key? :only
          return hooks.select{|h| h.target_class.to_s == klass.to_s and options[:only].collect{|o| o.to_s}.include? h.hook_name.to_s }
        elsif options.has_key? :except
          return hooks.select{|h| h.target_class.to_s == klass.to_s and !options[:except].collect{|o| o.to_s}.include? h.hook_name.to_s }
        end
      else
        return hooks.select{|h| h.target_class.to_s == klass.to_s }
      end
    end

    def check_dependency_for (object, *opts)
      valid_options = [:only, :except]
      options = opts.extract_options!


      klass = object.class
      klass_hooks = hooks_for(klass.to_s.underscore,options)

      result_array = []

      klass_hooks.each do |hook|
        result_array << hook.check_dependency_for(object)
      end

      result_array
      
    end

    def check_reflections (klass, *opts)
      options = opts.flatten
      unless options.empty?
        options.each_with_index do |k,i|
          case k.class.to_s
          when "Symbol"
            if klass.reflect_on_association(k).nil?
              options[i]=nil
            end
          when "Hash"
            k.each do |key,va|
              unless klass.reflect_on_association(key).nil?
                if va.kind_of?(Symbol)
                  if key.to_s.classify.constantize.reflect_on_association(va).nil?
                    k[key]=nil
                  end
                else
                  k[key]=check_reflections(key.to_s.classify.constantize,va)
                end
              else
                k.delete(key)
              end
            end
          else
          end
        end
      end
      return options
    end
  end

  DependencyResult = Struct.new(:hook_name,:result,:warning)

end


