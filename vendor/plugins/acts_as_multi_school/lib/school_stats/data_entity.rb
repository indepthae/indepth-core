module SchoolStats
  
  class DataEntity

    attr_reader :name, :model, :fetch_query, :filters, :child_entities, :fields, :type,:fetch_query_proc

    @@all_entities = []

    def initialize (*opts)
      opts = opts.extract_options!
      opts.each{|attr,val| (self.class.method_defined? "#{attr}") ?
          instance_variable_set("@#{attr}",val) : (raise NoMethodError,"undefined method #{attr}")}
      self.class.unique?(self.name)
      @child_entities = []
      @@all_entities << self
    end

    class << self

      def all
        @@all_entities
      end

      def reset
        @@all_entities = []
        load(File.join(File.dirname(__FILE__), 'stats_config.rb'))
      end

      def find_by_name (name)
        @@all_entities.detect{|entity| entity.name == name.to_sym} || (raise EntityNotFound, "Could not find entity with name #{name}")
      end

      def live_entities
        @@all_entities.select{|entity| entity.type == :live} || []
      end

      def attendance_entities
        @@all_entities.select{|entity| entity.type == :attendance} || []
      end

      def find_all_by_name(names)
        entity_list=[]
        names.each do |name|
          entity_list <<  @@all_entities.detect{|entity| entity.name == name.to_sym} || (raise EntityNotFound, "Could not find entity with name #{name}")
        end
        entity_list
      end

      def unique? (name)
        raise "Entity named #{name} already exist." unless @@all_entities.select{|de| de.name.to_sym == name.to_sym}.blank?
      end

      def load_schools(path,options={})
        entity, entity_ids, foreign_key, parent_ids = process_path path
        school_ids = options[:school_id] || []
        entity = find_by_name(entity)
        model=entity.model
        conditions = {}
        conditions.merge! :id=>entity_ids.split('-') if entity_ids.present?
        conditions.merge! foreign_key=>parent_ids.split('-') if foreign_key.present? && parent_ids.present?
        conditions.merge!(entity.model=="school" ? {:id=>school_ids} : {:school_id=>school_ids}) if school_ids.present?
        unless entity.model=="school"
          model.camelize.constantize.all(:select=>"schools.name as school_name",:joins=>"INNER JOIN schools ON #{model.pluralize}.school_id=schools.id",:conditions=>conditions,:skip_multischool=>true).collect(&:school_name).uniq
        end
      end

      def load_entity (path,options={})
        entity, entity_ids, foreign_key, parent_ids = process_path path
        school_ids = options[:school_id] || []
        entity = find_by_name(entity)
        conditions = {}
        conditions.merge! :id=>entity_ids.split('-') if entity_ids.present?
        conditions.merge! foreign_key=>parent_ids.split('-') if foreign_key.present? && parent_ids.present?
        conditions.merge!(entity.model=="school" ? {:id=>school_ids} : {:school_id=>school_ids}) if school_ids.present?
        entity.paginate(:conditions=>conditions,:page=>(options[:page]||1) ,:per_page=>(options[:per_page]||10))
      end

      def load_live_entity(name,options={})
        if name.present?
          entities= find_all_by_name(name)
          stats_hash={}
          entities.each do |entity|
            stats_hash[entity.name]=entity.retrieve_data(options)
          end
          stats_hash
        else
          stats_hash={}
        end
      end

      def load_live_data_rows (name,options={})
        entity = find_by_name(name)
        entity.retrieve_data(options)
      end

      private

      def process_path (path)
        path = (path.is_a? Array)? path : path.split('/')
        entity = entity_ids = foreign_key = parent_ids = nil
        case path.length
        when 1,2
          entity,entity_ids = path
        when 3,4
          foreign_key,parent_ids,entity,entity_ids = path
        end
        [entity,entity_ids,foreign_key,parent_ids]
      end

    end

    def retrieve_data (options={})
      start_date=options[:start_date]|| Date.today
      end_date=options[:end_date] ||  Date.today
      page=options[:page] || 1
      per_page=options[:per_page] || 30
      school_ids=options[:school_ids] || []
      start_date=start_date.to_date.beginning_of_day.to_formatted_s(:db)
      end_date=end_date.to_date.end_of_day.to_formatted_s(:db)
      query_proc=fetch_query_proc
      result=skip_multischool do
        query_proc.call(start_date,end_date,school_ids,page,per_page)
      end
      result.is_a?(Array) ? to_data_collection(result) : to_data_row(result)
    end
      
    def all (opts={})
      query_options, fetch_options = process_options opts
      fetch_data :find,:all,{:query=>query_options,:fetch=>fetch_options}
    end

    def find (id,opts={})
      query_options, fetch_options = process_options opts
      fetch_data :find,id,{:query=>query_options,:fetch=>fetch_options}
    end

    def count (opts={})
      query_options, fetch_options = process_options opts
      fetch_data :count,:all,{:query=>query_options,:fetch=>fetch_options}
    end

    def paginate (opts={})
      query_options, fetch_options = process_options opts
      fetch_options.merge! :finder=>:find
      fetch_data :paginate,:all,{:query=>query_options,:fetch=>fetch_options}
    end

    def value (row,field_name)
      row.attributes[field_name.to_s]
    end

    def model
      @model ||= name.to_s.singularize
    end

    def has_child (child_name,options={})
      child_name = child_name.to_sym      
      child_entity = ChildEntity.new(child_name,self,options)
      @child_entities.delete_if{|child| child.name.to_sym == child_name.to_sym}
      @child_entities << child_entity
    end

    def fields
      if @field_objects.nil?
        process_fields
      end
      @field_objects
    end

    def klass
      @klass ||= model.classify.constantize
    end

    def table_name
      @table_name ||= klass.table_name
    end

    private
    
    def fetch_data (method=:find,scheme=:all,options={})
      query_options = options[:query]||{}
      if fetch_query_proc.present?
        query_proc=fetch_query_proc
        result=skip_multischool do
          query_proc.call
        end
      else
        query = fetch_query.clone
        result = skip_multischool do
          klass.instance_eval do
            with_scope(:find=>{:conditions=>query_options[:conditions]||{}}) do
              send method,scheme,query.merge!(options[:fetch]||{})
            end
          end
        end
      end
      result.is_a?(Array) ? to_data_collection(result) : to_data_row(result)
    end

    

    def skip_multischool
      Thread.current[:skip_multischool]=true
      yield
    ensure
      Thread.current[:skip_multischool]=nil
    end

    def to_data_row (row)
      DataRow.new(row,self)
    end
    
    def to_data_collection (collection)
      collection.each_with_index do |row,i|
        collection[i] = DataRow.new(row,self)
      end
      DataCollection.new(collection,self)
    end

    def process_options (opts)
      fetch_opts = {}
      query_opts = {}
      opts.each{|k,v| query_opts[k]=v if [:conditions,:include].include? k}
      opts.each{|k,v| fetch_opts[k]=v if [:page,:per_page].include? k}
      [query_opts,fetch_opts]
    end

    def process_fields
      @field_objects = []
      (@fields||[]).each{|field| @field_objects << DataField.new(field.to_sym,self) }
      @field_objects = @field_objects.group_by(&:name)
    end

    def method_missing (method,*args)
      if method.to_s =~ /([\w]+)=$/ and respond_to? $1
        instance_variable_set "@#{$1}", args.shift
      else
        super
      end
    end
    
  end
  
end
