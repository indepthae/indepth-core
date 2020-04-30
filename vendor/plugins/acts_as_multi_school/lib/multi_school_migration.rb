module MultiSchoolMigration
  
  class MakeMigration    

    attr_accessor :all_models, :pending_models, :pending_tables, :pending_tables_hash, :migration_name
    
    @@app_migration_destination = "#{RAILS_ROOT}/db/migrate/"
    @@migration_destination = File.dirname(__FILE__)+"/../db/migrate/"
    @@migration_template = ERB.new File.new(File.dirname(__FILE__)+"/../templates/school_id_mass_migration.erb").read, 0, ">"
    @@multi_school_hash = YAML.load_file(File.dirname(__FILE__)+"/../config/multi_school_models.yml")
    @@number_in_english = {5=>"Five", 0=>"Zero", 6=>"Six", 1=>"One", 7=>"Seven", 2=>"Two", 8=>"Eight", 3=>"Three", 9=>"Nine", 4=>"Four"}

    def initialize
      @all_models = @@multi_school_hash["multi_school_models"]
    end

    def make_migration
      puts "== Beginning multi school migrations =="
      get_pending_models
      filepath = migration_file_path
      unless pending_models.blank?
        puts "== making migration file #{migration_file_name}"
        puts "== saved file - #{filepath}" if make
      else
        puts "== no new models to for migrations"
      end
    end
    
    def get_pending_models
      @pending_models = []
      @pending_tables_hash = {}
      @pending_tables = []
      @all_models.each do |model|
        ms_model = MultiSchoolModel.new(model)
        unless ms_model.school_id_exists?
          @pending_models << model
          @pending_tables_hash[model] = ms_model.table_name
          @pending_tables << ms_model.table_name
        end
      end
      @pending_tables.uniq!
    end
    
    def existing_migrations
      arr = Dir.glob("#{@@migration_destination}[0-9]*_*.rb").grep(/[0-9]+_add_school_id_+[a-z_]+.rb$/)
      arr += Dir.glob("#{@@app_migration_destination}[0-9]*_*.rb").grep(/[0-9]+_add_school_id_+[a-z_]+.rb$/)
      arr
    end
    
    def migration_name
      count=existing_migrations.length + 1
      migration_class_name="AddSchoolId#{num_to_eng(count)}"
      all_migrations = existing_migrations.map{|a| "#{File.basename(a).gsub((File.basename(a).split("_")[0]+"_"),'').split(".")[0].titleize.gsub(' ','')}"}
      while all_migrations.include?(migration_class_name) do
        count+=1
        migration_class_name="AddSchoolId#{num_to_eng(count)}"
      end
      return migration_class_name
    end

    def migration_file_name
      "#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_#{migration_name.underscore}.rb"
    end

    def migration_file_path
      "#{@@migration_destination}#{migration_file_name}"
    end

    def get_binding
      binding
    end

    private

    def make
      result = @@migration_template.result(get_binding)
      num = File.open(migration_file_path,"w") do |f|
        f.write(result)
      end
      true if num
    end
    
    def num_to_eng(num)
      arr = num.to_s.split("")
      arr.map{|n| @@number_in_english[n.to_i]}.join
    end
  end

  class MultiSchoolModel
    attr_accessor :model_name, :model_class, :table_name
    def initialize(modelname)
      @model_name = modelname
      @model_class = @model_name.constantize
      @model_class.reset_column_information
      @table_name = @model_class.table_name if @model_class.table_exists?
    end

    def school_id_exists?
      @model_class.reset_column_information
      @model_class.columns_hash.has_key? "school_id"
    end

    class << self
      def make(modelname)
        
      end
    end
  end
end
