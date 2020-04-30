module EditCustomImport
  FALSE_OPTIONS = ["0", "false"]
  NULL_OPTIONS = ["null"]
  def load_yaml
    model = export.model
    if File.exists?("#{Rails.root}/vendor/plugins/fedena_custom_import/config/models/#{model.underscore}.yml")
      exports = YAML.load_file(File.join(Rails.root, "vendor/plugins/fedena_custom_import/config/models", "#{model.underscore}.yml"))
    end
    exports
  end

  #  def primary_key_symbol_removal(file)
  #   all_rows = Array.new
  #    FasterCSV.foreach(file) do |row|
  #      all_rows << row.join(',')
  #    end
  #    all_rows[0]=all_rows[0].gsub("(*)","")
  #    return all_rows
  #  end

  def process_csv_file(file)
    settings = load_yaml
    model_name = export.model
    all_rows = []
    FasterCSV.foreach(file) do |row|
      all_rows << row.join(',')
    end

    header_row = all_rows.first.split(',')
    core_columns = header_row.select{ |row| row.split('|').second.to_s.downcase.tr(' ', '_').camelize.to_s == model_name.to_s }
    associated_columns = header_row - core_columns
    associated_columns=Import.strip_star(associated_columns)
    injected_columns = header_row.select{ |row| row.split('|').second.to_s == "inject" }
    associated_columns = associated_columns - injected_columns
        
    [core_columns, associated_columns, injected_columns]
  end

  def get_updated_header_columns
    settings = load_yaml
    model = export.model
    core_columns = Export.place_overrides(model).map{ |column| "#{column.split('|').first}|#{column.split('|').second.to_s.underscore.humanize}" }.compact.flatten
    if model== "Student"
      core_columns=Export.place_overrides_for_guardian(core_columns,model)
      guardian_columns=core_columns.collect{|c| c if (c.split('|').second =="Guardian2" || c.split('|').second =="Guardian1" )}.compact
      core_columns-=guardian_columns
    end
    associated_models = settings[model.underscore]["associates"].nil? ? [] : settings[model.underscore]["associates"].keys.map{ |key| key.to_s unless settings[model.underscore]["compulsory_associates"].present? && settings[model.underscore]["compulsory_associates"].include?(key.to_sym) }.compact.flatten
    associated_columns = Export.prepare_associated_columns(model, associated_models)
    associated_columns += Export.compulsory_associates_columns(model.to_s)
    injected_columns = settings[model.underscore]["inject"].nil? ? [] : settings[model.underscore]["inject"].map{ |inj| "#{inj.to_s.humanize}|inject" }
    join_models = settings[model.underscore]["joins"].nil? ? [] : settings[model.downcase]["joins"].keys.map{ |key| key.to_s }
    join_columns = Export.prepare_join_columns(model, join_models)
    associated_columns = [associated_columns, join_columns].compact.flatten.map{ |column| "#{column.split('|').first}|#{column.split('|').second.to_s.humanize}" }
    [core_columns, associated_columns, injected_columns,guardian_columns]
  end

  def check_header_format(file)
    self.save
    file_columns = process_csv_file(file)
    
    file_columns = file_columns.map{ |fc| fc.split('|').first }
   
    database_columns = get_updated_header_columns
    database_core_columns = Set.new(database_columns.first)
    injected_columns = Set.new(database_columns.third)
    found_core_match = file_columns.find{ |core_array| database_core_columns == Set.new(core_array) }.present?
    found_inject_match = database_columns.third.blank? ? true : file_columns.find{ |inject_array| injected_columns == Set.new(inject_array) }.present?    
    if database_columns.fourth.present?
      database_columns.fourth.each do |a|
        if a.first == "*"
          a.gsub!(a,a.split("*").second)
        end
      end
    end
    file_columns.second.reject!{|x| x unless x.split('|').second == "Student additional detail"}
    found_associate_match = (file_columns.second & database_columns.second) == file_columns.second ? true : false
    
    if found_core_match && found_associate_match && found_inject_match
      true
    else
      self.status = 'failed'
      self.import_log_details.create(:status => 'failed', :description => t('import_log_details.csv_format_error'))
      false
    end
  end

  def build_join_data(new_model_instance, csv_row, header_row)
    settings = load_yaml
    join_models = settings[new_model_instance.class.name.underscore]["joins"].try(:keys) || []
    value_hash = {}
    if join_models.blank?
      self.import_log_details.create(:status => 'success',
        :model => self.row_counter,
        :description => t('import_log_details.uploaded_to_database_successfully'))
    end
    join_models.each do |join_model|
      join_model_name = join_model.singularize.camelize.constantize
      join_search_column = settings[new_model_instance.class.name.underscore]["join_column_search"][join_model]
      parent_model_name = settings[new_model_instance.class.name.underscore]["joins"][join_model_name.to_s.downcase.pluralize].singularize.camelize.constantize
      join_rows = header_row.select{ |element| element.split('|').second.to_s.downcase.tr(' ', '_' ).pluralize.to_s == join_model_name.to_s.downcase.pluralize }
      join_values = []
      deleting_values = []
      adding_values = []
      existing_values = []
      unless new_model_instance.class.name.to_s == parent_model_name.to_s
        existing_values = new_model_instance.send(parent_model_name.to_s.downcase).send(join_model)
      end
      join_rows.each do |join_row|
        index = header_row.index(join_row)
        search_value = join_row.split('|')
        if csv_row[index].present?
          join_value = join_model_name.find(:first, :conditions => {join_search_column.to_sym => search_value})
          if csv_row[index] == 'NULL'
            deleting_values << join_value
          else
            adding_values << join_value
          end
          # join_values << join_value
        end
      end
      join_values = (existing_values - deleting_values + adding_values).uniq
      unless new_model_instance.class.name.to_s == parent_model_name.to_s
        if new_model_instance.send(parent_model_name.to_s.downcase).update_attributes(join_model.to_sym => join_values)
          self.import_log_details.create(:status => 'success', :model => self.row_counter, :description => t('import_log_details.uploaded_to_database_successfully'))
        else
          new_model_instance.send(parent_model_name.to_s.downcase).update_attributes(join_model.to_sym => [])
          # new_model_instance.destroy
          self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => t('imports.join_data_save_error'))
        end
      else
        if new_model_instance.update_attributes(join_model.to_sym => join_values)
          self.import_log_details.create(:status => 'success', :model => self.row_counter, :description => t('import_log_details.uploaded_to_database_successfully'))
        else
          # new_model_instance.send(parent_model_name.to_s.downcase).update_attributes(join_model.to_sym => [])
          self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => new_model_instance.errors.full_messages.join("\n "))
          if settings[new_model_instance.class.name.underscore]["dependent"].present?
            new_model_instance.send(settings[new_model_instance.class.name.underscore]["dependent"]).try(:destroy)
          end
          # new_model_instance.destroy
        end
      end
    end
    new_model_instance.frozen? ? nil : new_model_instance
    

    
  end

  def process_injections(model, value_hash, inject_rows, header_row, csv_row)
    settings = load_yaml
    finders = settings[model.to_s.underscore]["finders"]
    
    unless finders.nil?
      core_find = finders.select{ |key, value| value.is_a? Array }.join(',')
      
      main_hash = {}
      core_find_models = core_find.split(',').reject{ |cfm| cfm == core_find.split(',').first }
     
      core_find_models.each do |core_find_model|
        column_find = settings[model.to_s.underscore]["finders"][core_find_model]

        model_hash = {}
        column_find.each do |key, value|
          index = header_row.index("#{value.humanize}|inject")

          if settings[model.to_s.underscore]["map_column"].present? && settings[model.to_s.underscore]["map_column"].present? && settings[model.to_s.underscore]["map_column"].keys.include?(key)
            map_model = settings[model.to_s.underscore]["map_column"][key].camelize.constantize
            map_method = settings[model.to_s.underscore]["map_combination"][map_model.to_s.underscore]
      
            scope_to_apply = map_model.scopes.keys.include? :active
            get_collection = scope_to_apply == true ? map_model.active : map_model.all
            found_value = get_collection.select{ |element| element.send(map_method) == csv_row[index] }.first.try(:id)
            model_hash = model_hash.merge(key.to_sym => found_value)
          else
            model_hash = model_hash.merge(key.to_sym => csv_row[index])
          end
        end
        klass = core_find_model.camelize.constantize
        data = if klass.respond_to? :active
          klass.active.find(:first, :conditions => model_hash).try(:id)
        else
          klass.find(:first, :conditions => model_hash).try(:id)
        end
        main_hash = main_hash.merge((core_find_model.underscore + "_id").to_sym => data)
               
      end
      main_data = core_find.split(',').first.camelize.constantize.find(:first, :conditions => main_hash).try(:id)
    end
    value_hash = value_hash.merge((core_find.split(',').first + "_id").to_sym => main_data)
  end

  def build_core_data_on_edit(file)
    settings = load_yaml
    model_name = export.model.constantize
    core_rows = []
    header_row = []
    inject_rows = []
    guardians = []
    g = 1
    if check_header_format(file) == true
      csv_arr = FasterCSV.read(file)
      #if csv_arr.size > 1
      csv_row = csv_arr[0]
      csv_row = Import.strip_star(csv_row)
      header_row = csv_row
      core_rows = csv_row.select{ |element| element.split('|').second.to_s.downcase.tr(' ', '_').camelize.to_s == model_name.to_s }
      loop do
        temp_row =  csv_row.select{ |element|  element.split('|').second.to_s == "Guardian"+g.to_s }
        guardians << temp_row if (temp_row.present?)
        g=g+1
        break if (temp_row.count==0)
      end
      inject_rows = csv_row.select{ |element| element.split('|').second.to_s.downcase.tr(' ', '_').to_s == "inject" }
      ext_number = self.extraction_number
      (ext_number..ext_number+199).each do |i|
        begin
          csv_row = csv_arr[i] 
          if csv_row.blank?
            break
          end
          new_model_instance = model_name.new
          value_hash = {}
          csv_row.map!{|cr| cr.try(:strip)}
          core_rows.each do |core_row|
            self.row_counter = i + 1
            index = header_row.index(core_row)
            database_row_name = settings[model_name.to_s.underscore]["overrides"].select{ |key, value| value.to_s == core_row.split('|').first.to_s }.first.nil? ? nil : settings[model_name.to_s.underscore]["overrides"].select{ |key, value| value.to_s == core_row.split('|').first.to_s }.first.first unless settings[model_name.to_s.underscore]["overrides"].nil?
            database_row_name = core_row.split('|').first.downcase.tr(' ', '_') if database_row_name.nil?
            process_row = database_row_name.dup
            process_row.slice! "_id"           
            assciations = settings[model_name.to_s.underscore]["associations"]
            assoc = assciations.present? ? assciations.find{ |assoc| process_row.pluralize.index(assoc.to_s) == 0 } : []
            process_row = assoc ? assoc : process_row
            if assciations.present? && assciations.include?(process_row.to_sym)
              unless csv_row[index] == "NULL"
                map_combination = settings[model_name.to_s.underscore]["map_combination"]
                if map_combination.present? && map_combination.keys.include?(process_row.to_s)
                  map_method = map_combination[process_row.to_s]
                  scope_to_apply = process_row.to_s.camelize.constantize.scopes.keys.include? :active
                  all_data = scope_to_apply == true ? process_row.to_s.camelize.constantize.active.map{ |data| [data.id, data.send(map_method)] } : process_row.to_s.camelize.constantize.all.map{ |data| [data.id, data.send(map_method)] }
                    
                  associated_id = all_data.select{ |data| data.second == csv_row[index] }.first.nil? ? nil : all_data.select{ |data| data.second == csv_row[index] }.first.first
                    
                else
                  assoc_reflection = model_name.reflect_on_association(process_row.to_sym)
                  associated_model = assoc_reflection.klass
                  associated_column = settings[model_name.to_s.underscore]["associated_columns"][process_row.to_s]
                  primary_key = model_name.reflect_on_association(process_row.to_sym).options[:foreign_key] || :id
                  associated_id = case assoc_reflection.macro
                  when :belongs_to
                    associated_model.search({associated_column.to_sym => csv_row[index]}).first.try(primary_key)
                  else
                    assoc_reflection.klass.search({associated_column.to_sym => csv_row[index]}).first.try(primary_key)
                  end
                end
              else
                associated_id = "NULL"
              end
              
              value_hash = value_hash.merge(database_row_name.to_sym => associated_id)
              
                

            else
              if settings[model_name.to_s.underscore]["booleans"].present? && settings[model_name.to_s.underscore]["booleans"].include?(database_row_name.to_sym)
                element = csv_row[index]
                if element.nil? || NULL_OPTIONS.include?(element.to_s.underscore)
                  # Just keep the value as it is
                elsif FALSE_OPTIONS.include? element.to_s.underscore
                  value_hash = value_hash.merge(database_row_name.to_sym => 0)
                else
                  value_hash = value_hash.merge(database_row_name.to_sym => 1)
                end
              else
                if (settings[model_name.to_s.underscore]["attr_accessor_list"].present? && settings[model_name.to_s.underscore]["attr_accessor_list"].include?(database_row_name.to_sym))
                  value_hash = value_hash.merge(database_row_name.to_sym => csv_row[index])                    
                else
                    
                  if model_name.columns_hash[database_row_name].sql_type == "varchar(255)"
                    csv_row[index] = csv_row[index].nil? ? "" : csv_row[index]
                  end
                  value_hash = value_hash.merge(database_row_name.to_sym => csv_row[index])
                end
              end
            end
          end
          unless inject_rows.blank?
            if settings[model_name.to_s.underscore]["inject"].present? && settings[model_name.to_s.underscore]["finders"].present?
              value_hash = process_injections(model_name, value_hash, inject_rows, header_row, csv_row)
            end
          end

          primary_keys_hash = settings[model_name.to_s.underscore]["primary_keys"]
          new_model_instance = []
          unless primary_keys_hash.nil?
            primary_keys = primary_keys_hash.keys
            condition = ""
            primary_keys.each{|pk|
              # handling special case for guardian relation
              if (model_name.to_s == "Guardian" and pk == "relation" and (value_hash[:is_father].present? or value_hash[:is_mother].present?))
                if value_hash[:is_father].present?
                  value = "father"
                elsif value_hash[:is_mother].present?
                  value = "mother"
                end
              else
                value = value_hash[pk.to_sym].to_s
              end
              # Workaround to handle different date formats
              if pk.end_with? "date"
                begin
                  value = "'#{Date.parse(value)}'"
                rescue Exception => e
                  value = "'#{value}'"
                end
              else
                value = ActiveRecord::Base::sanitize(value)
              end
              condition = condition + " and #{pk}=#{value}"
            }
            condition.slice! " and "
            # condition=ActiveRecord::Base::sanitize(condition)
            new_model_instance = if model_name.scopes.keys.include? :active
              model_name.active.find(:first, :conditions => condition)
            else
              model_name.find(:first, :conditions => condition)
            end

          end
            
          if new_model_instance.present?
            value_hash = value_hash.delete_if { |k, v| !v.present? }
            value_hash.each{ |k, v| value_hash[k] = '' if v == "NULL" }
            new_model_instance.attributes = value_hash
           
            unless guardians.blank?
              @error=add_guardians(new_model_instance,guardians,header_row,csv_row,i,from_edit = true)    

            end
          end

          if settings[model_name.to_s.underscore]["mandatory_joins"].present?
            new_model_instance = build_join_data(new_model_instance, csv_row, header_row)
          end
             

          if new_model_instance.present?
            build_nested_associate_data_on_edit(new_model_instance, csv_row, header_row)
           
            unless @error.blank?
              self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => @error.join(" \n"))                
            else
            
              if  new_model_instance.valid? && new_model_instance.save
                build_associate_data_on_edit(new_model_instance, csv_row, header_row)
              else
                self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => "#{new_model_instance.errors.full_messages.join(" \n ")}") unless new_model_instance.nil?
              end
            
            end
          else
            self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => t('import_log_details.no_data_found'))
          end
        rescue Exception => ex
          self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => "#{t('import_log_details.invalid_row')}")
          next
        end
      end
      
      self.job_count = current_job_count - 1

      if self.job_count == 0       
        self.status = if import_log_details.all.select{ |ild| ild.status == 'failed' }.blank?
          t('imports.updated')
        else
          'completed_with_errors'
        end
        self.csv_file = nil
      end
      
      self.save
      #      else
      #        self.status = 'succes_with_no_data'
      #        self.csv_file = nil
      #        self.save
      #      end
    else
      self.status = 'failed'
      #self.csv_file = nil
      self.save
      self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => t('import_log_details.export_format_not_matching'))
    end
  rescue Exception => e
    self.status = e.message
    self.save
  end

  def build_associate_data_on_edit(new_model_instance, csv_row, header_row)

    settings = load_yaml
    flag = 0
    associated_models = settings[new_model_instance.class.name.underscore]["associates"].nil? ? [] : settings[new_model_instance.class.name.underscore]["associates"].keys.map{ |key| key unless settings[new_model_instance.class.name.underscore]["nested_associates"].present? && settings[new_model_instance.class.name.underscore]["nested_associates"].map(&:to_s).include?(key) }.compact.flatten
    associated_models.each do |associated_model|
      associated_model_name = associated_model.camelize.constantize
      if associated_model == "hostel_room_additional_detail"
        associated_rows = header_row.select{ |element| element.split('|').second.to_s.downcase.tr(' ', '_' ).to_s == "#{new_model_instance.class.name.underscore.split('_').first}_additional_detail"}
      else
        associated_rows = header_row.select{ |element| element.split('|').second.to_s.downcase.tr(' ', '_' ).to_s == associated_model.to_s }
      end
      search_model = settings[new_model_instance.class.name.underscore]["associates"][associated_model].camelize.constantize
      search_column = settings[new_model_instance.class.name.underscore]["associate_column_search"][search_model.to_s.underscore]
      insert_column = settings[new_model_instance.class.name.underscore]["associate_columns"][associated_model]
      if settings[new_model_instance.class.name.underscore]["associate_column_condition"].present?
        column_condition = settings[new_model_instance.class.name.underscore]["associate_column_condition"][search_model.to_s.underscore]
      end
      associated_rows.each do |associated_row|
        index = header_row.index(associated_row)
        search_row = associated_row.split('|').first
        child_associate_column = if associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).present? && associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).options.present? && associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).options[:foreign_key].present?
          associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).options[:foreign_key]
        else
          search_model.to_s.underscore + "_id"
        end
        associate_value_id = if column_condition.nil?
          search_model.find(:first, :conditions => {search_column.to_sym => search_row}).try(:id)
        else
          search_model.find(:first, :conditions => ["#{search_column} = ? AND #{column_condition}", search_row]).try(:id)
        end
        value_hash = {}
        value_hash.merge!(insert_column.to_sym => csv_row[index].nil? ? nil : csv_row[index].gsub('|', ', ') { |unusedlocal|  }, (child_associate_column).to_sym => associate_value_id)
        new_associate_record = ""
        primary_key_hash = settings[new_model_instance.class.name.underscore]["associate_primary_keys"]
        unless primary_key_hash.nil?
          if primary_key_hash[associated_model].present?
            primary_keys = primary_key_hash[associated_model].keys
            condition = ""
            primary_keys.each{ |pk| condition = condition + " and #{pk}='#{value_hash[pk.to_sym]}'" }
            condition.slice! " and "
            new_associate_record = new_model_instance.send(associated_model.pluralize).find(:first, :conditions => condition)
            if new_associate_record.nil?
              new_associate_record = new_model_instance.send(associated_model.pluralize).new()
            end
          end
        end
        value_hash = value_hash.delete_if { |k, v| !v.present? }
        if new_associate_record.present?
          new_associate_record.attributes = value_hash
        end

        if new_associate_record.present?
          if new_associate_record.valid?
            new_associate_record.save unless new_associate_record.frozen?
          else
            self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => new_associate_record.errors.full_messages.join(" \n"))
          end
        else
          flag = 1
          self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => "#{t('imports.data_not_found_for')} #{associated_model.to_s.camelize}")
          # self.import_log_details.create(:status => "Failed",:model => self.row_counter,:description => "#{new_associate_record.errors.full_messages.join("\n")}")
        end
      end
    end
    if flag == 0

      unless settings[new_model_instance.class.name.to_s.underscore]["mandatory_joins"].present?
        build_join_data(new_model_instance, csv_row, header_row)
      end
    end
  end

  
  def add_guardians(new_model_instance,guardians,header_row,csv_row,i,edit)
    settings = load_yaml
    value_hash_g = {}
    error=[]
    guardians.each do |guardian|
      flag=0
      #      edit = false
      new_guardian_instance=new_model_instance.guardians.new
      guardian.each do |g_r|
        self.row_counter = i + 1
        index = header_row.index(g_r)
        database_row_name = settings["guardian"]["overrides"].select{ |key, value| value.to_s == g_r.split('|').first.to_s }.first.nil? ? nil : settings["guardian"]["overrides"].select{ |key, value| value.to_s == g_r.split('|').first.to_s }.first.first unless settings["guardian"]["overrides"].nil?
        database_row_name = g_r.split('|').first.downcase.tr(' ', '_') if database_row_name.nil?
        process_row = database_row_name.dup
        process_row.slice! "_id"
        associations = settings["guardian"]["associations"]   
        assoc = associations.present? ? associations.find{ |assoc| process_row.pluralize.index(assoc.to_s) == 0 } : []
        process_row = assoc ? assoc : process_row
        if associations.present? && associations.include?(process_row.to_sym)
          assoc_reflection = Guardian.reflect_on_association(process_row.to_sym)
          associated_model = assoc_reflection.klass
          associated_column = settings["guardian"]["associated_columns"][process_row.to_s]
          associated_id = case assoc_reflection.macro
          when :belongs_to
            associated_model.search({associated_column.to_sym => csv_row[index]}).first.try(:id) 
          end 
          value_hash_g = value_hash_g.merge(database_row_name.to_sym => associated_id)
        else
          if (settings["guardian"]["attr_accessor_list"].present? && settings["guardian"]["attr_accessor_list"].include?(database_row_name.to_sym))
            value_hash_g = value_hash_g.merge(database_row_name.to_sym => csv_row[index])
          else
            if Guardian.columns_hash[database_row_name].sql_type == "varchar(255)"
              csv_row[index] = csv_row[index].nil? ? "" : csv_row[index]
            end
            value_hash_g = value_hash_g.merge(database_row_name.to_sym => csv_row[index])
          end 
        end
      end
      value_hash_g.values.each do |a|
        unless a.blank?
          flag=1
        end
      end
      if flag== 1
        new_guardian_instance = new_model_instance.guardians.new(value_hash_g)
        new_guardian_instance.ward_id = new_model_instance.id
        if edit == true 
          g = new_model_instance.guardians
          father = new_model_instance.father
          mother = new_model_instance.mother
          
          v_h_temp=value_hash_g.except(:is_father,:is_mother,:relation)
          
          v_h_temp = v_h_temp.delete_if { |k, v| !v.present? }
          v_h_temp.each{ |k, v| v_h_temp[k] = '' if v == "NULL" } 
          
          
          
          g.each do |guard|
            if (value_hash_g[:is_father].present? && value_hash_g[:is_father].downcase=="y") || (value_hash_g[:is_father].present? && value_hash_g[:is_father].downcase =="yes") || (value_hash_g[:relation].present? && value_hash_g[:relation].downcase == "father") 
              if father.present?
                father.update_attributes(v_h_temp)
              end
            elsif (value_hash_g[:is_mother].present? && value_hash_g[:is_mother].downcase=="y") || (value_hash_g[:is_mother] && value_hash_g[:is_mother].downcase=="yes" )|| (value_hash_g[:relation].present? && value_hash_g[:relation].downcase == "mother")
              if mother.present?
                mother.update_attributes(v_h_temp)
              end
            elsif guard.first_name== value_hash_g[:first_name] && guard.relation== value_hash_g[:relation] 
              guard.update_attributes(v_h_temp) 
            else
            end
          end  
          
        else 
          if new_guardian_instance.valid? 
            
            
            new_guardian_instance.save#add
          else
            error << new_guardian_instance.errors.full_messages
            
          end 
        end
      end
    end 
    return error
  end
  
  
  def build_nested_associate_data_on_edit(new_model_instance, csv_row, header_row)
    settings = load_yaml
    flag = 0
    nested_associate_models = settings[new_model_instance.class.name.underscore]["nested_associates"].nil? ? [] : settings[new_model_instance.class.name.underscore]["nested_associates"].map(&:to_s)
    nested_associate_models.each do |nested_associate_model|
      nested_associated_model_name = nested_associate_model.camelize.constantize
      nested_associated_rows = header_row.select{ |element| element.split('|').second.to_s.downcase.tr(' ', '_' ).to_s == nested_associate_model.to_s }
      search_model = settings[new_model_instance.class.name.underscore]["associates"][nested_associate_model].camelize.constantize
      search_column = settings[new_model_instance.class.name.underscore]["associate_column_search"][search_model.to_s.underscore]
      insert_column = settings[new_model_instance.class.name.underscore]["associate_columns"][nested_associate_model]
      if settings[new_model_instance.class.name.underscore]["associate_column_condition"].present?
        column_condition = settings[new_model_instance.class.name.underscore]["associate_column_condition"][search_model.to_s.underscore]
      end
      nested_associated_rows.each do |associated_row|
        index = header_row.index(associated_row)
        search_row = associated_row.split('|').first
        child_associate_column = if nested_associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).present? && nested_associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).options.present? && nested_associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).options[:foreign_key].present?
          nested_associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).options[:foreign_key]
        else
          search_model.to_s.underscore + "_id"
        end
        associate_value_id = if column_condition.nil?
          search_model.search({search_column.to_sym => search_row}).first.try(:id)
        else
          search_model.search({search_column.to_sym => search_row}).scoped(:conditions => column_condition).first.try(:id)
        end
        value_hash = {}
        value_hash.merge!(insert_column.to_sym => csv_row[index].nil? ? nil : csv_row[index].gsub('|', ', ') { |unusedlocal|  }, (child_associate_column).to_sym => associate_value_id)
        new_associate_record = ""
        primary_key_hash = settings[new_model_instance.class.name.underscore]["associate_primary_keys"]
        unless primary_key_hash.nil?
          if primary_key_hash[nested_associate_model].present?
            primary_keys = primary_key_hash[nested_associate_model].keys

            condition = ""
            primary_keys.each{ |pk| condition = condition + " and #{pk}='#{value_hash[pk.to_sym]}'" }
            condition.slice! " and "

            new_associate_record = new_model_instance.send(nested_associate_model.pluralize).find(:first, :conditions => condition)
            new_associate_record
            value_hash = value_hash.delete_if { |k, v| !v.present? }
            if new_associate_record.nil?
              if nested_associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).present? && nested_associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).macro == :has_one
                new_model_instance.send("build_" + nested_associate_model.to_s, value_hash)
              else
                new_associate_record = new_model_instance.send(nested_associate_model.pluralize).build(value_hash)
              end
            else
              nested_associate_record = new_model_instance.send(nested_associate_model.pluralize).detect { |asso| asso.id == new_associate_record.id }
              nested_associate_record.attributes = value_hash
            end

          end
        end
      end
    end
  end

  def save_data(data)
    begin
      data.save!
    rescue Exception => e
      data.errors.add_to_base e.message
    end
  end

end
