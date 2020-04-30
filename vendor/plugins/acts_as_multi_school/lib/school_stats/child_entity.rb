module SchoolStats

  class ChildEntity

    attr_reader :name, :parent, :foreign_key, :entity, :conditions
    
    def initialize(name,parent,opts={})

      options_proc = proc do |*a|
        name = a[0]
        parent = a[1]
        {
          :foreign_key => "#{parent.table_name.singularize}_id",
          :entity=>name.to_sym,
          :conditions=>nil
        }
      end

      options = options_proc.call(name,parent)
      options.merge! opts
      @name = name
      @parent = parent
      options.each{|attr,val| (self.class.method_defined? "#{attr}") ? instance_variable_set("@#{attr}",val) : (raise NoMethodError,"undefined method #{attr}")}      
    end

    def entity
      unless @entity.is_a?(DataEntity)
        @entity = DataEntity.find_by_name(@entity)
      end
      @entity
    end

    def url_path (parent_id)
      parent_id = [parent_id].flatten.uniq
      "#{foreign_key}/#{parent_id.join('-')}/#{entity.name}"
    end
    
  end
  
end
