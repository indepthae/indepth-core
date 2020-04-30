require 'i18n'
include I18n


module FedenaDataExport
  
  class Parser

    
    def self.t(obj)
      I18n.t(obj)
    end

    attr_reader :hash, :child_hash,:sub_hash, :parent_keys, :result_hash
    
    def initialize
      
      @hash = {}
      @child_hash = {}
      @sub_hash = {}
      @parent_keys = []
      @result_hash = {}
    end

    
    
    def method_missing (action, *args, &block)
     
      if block
        
        unless @parent_keys.empty?
          if @parent_keys.length > 1
            alternate_key = @parent_keys.pop
            @child_hash = Parser.hash_operation(@parent_keys.last,@sub_hash,@child_hash) unless @sub_hash.blank?
            @parent_keys.push alternate_key
            @sub_hash.clear
          end
        end
        
        @child_hash = Parser.hash_operation(@parent_keys.last,@sub_hash,@child_hash) unless @sub_hash.blank?
        @parent_keys.push action 
        @sub_hash.clear
        @sub_hash = {action => {}}
        self.hash.clear
        
        yield block
        
        @parent_keys.pop if @parent_keys.length > 1
        @child_hash = Parser.hash_operation(@parent_keys.last,@sub_hash,@child_hash) unless @sub_hash.blank?
        
        if @parent_keys.length  == 1
          if @result_hash.blank?
            @result_hash = Marshal.load(Marshal.dump(@child_hash)) 
          else
            unless @child_hash[@parent_keys.last].blank?
              @result_hash.update(Marshal.load(Marshal.dump(@child_hash))){|k1,v1,v2| [v1,v2].flatten}
            end
          end
          @child_hash[@parent_keys.last].clear
        end
        
        @sub_hash.clear
        self.hash.clear
        
      else        
        
        @hash[action] = [] unless @hash[action].is_a? Array
        @hash[action] << args.first
        key = @sub_hash.keys.first unless @sub_hash.blank?
        key = @parent_keys.last if key.nil?
        @sub_hash[key] = self.hash.dup
        
      end 
      
    end
    
    
    
    def self.hash_operation(super_key,sub_hash,child_hash)
      
      if child_hash.blank?
        child_hash = sub_hash.dup
      else
        child_hash.each do |key,value|
          unless sub_hash.keys.first == key
            unless super_key == key
              if value.is_a?(Hash)
                child_hash[key] = Parser.hash_operation(super_key,sub_hash,value)
              else
                next
              end
              next
            else
              child_hash[super_key] = Parser.sum_hashes(child_hash[super_key],sub_hash)
            end
            break;
          else
            child_hash = Parser.sum_hashes(child_hash,sub_hash)
            break;
          end
        end
      end
      child_hash.dup
      
    end
    
    
    
    def self.sum_hashes(a,b)
      a.update(b) {|k,v1,v2| v1.is_a?(Hash) ? (Parser.sum_hashes(v1,v2)) : [v1,v2].flatten}
    end
    
    def self.make_array(a)
      a.map{|k,v| a[k]=[v]}
    end
    
    def get_keys(object)
      
      if object.is_a? Hash
        (object.keys + get_keys(object.values)).flatten.uniq
      elsif object.is_a? Array 
        object.collect{|value| get_keys value}
      else
        []
      end
      
    end
    
    
    def get_headers(hash,key)
      
      if hash.is_a? Hash
        hash[key].keys
      else
        []
      end
    end
    
  end

  # MultiSchool.current_school = School.find 83
  # @batches = Batch.all
  # es = ExportStructure.find(3)
  # template_file = ERB.new File.new("#{Rails.root}/app/views#{es.template}").read, 0, ">"
  # @xml = FedenaDataExport::Parser.new
  # template_file.result binding


    # def initialize
    #   @values = {}
    #   @keys = []
    #   @level = -1
    #   @current_block = nil
    # end
    #
    # def resolve_key
    #   key = ""
    #   i = 0
    #   while(i==0)
    #     key += @keys[i]
    #     i += 1
    #   end
    # end
    #
    # def method_missing (action, arg = nil, &block)
    #   if methods.include? action
    #     super && return
    #   end
    #
    #   @level += 1
    #   @keys[@level] = action
    #   if block_given?
    #     yield
    #   else
    #
    #   end
    #   @level -= 1
    # end

  # end
end