class Import < ActiveRecord::Base
  require 'set'
  require 'fileutils'
  include EditCustomImport
  attr_accessor :file_path, :job_type, :row_counter,:extraction_number

  has_attached_file :csv_file,
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:basename.:extension",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types => [] # add correct csv file format

  belongs_to :export
  has_many :import_log_details, :dependent => :destroy

  default_scope :order => "created_at DESC"
  named_scope :editable_imports, :conditions => {:is_edit => true}

  def perform    
    # access_lock : remove later
    raise 'Application is being updated. Please try again later.' if ['Employee', 'EmployeeSalaryStructureForImport'].include?(export.model) && FeatureLock.feature_locked?(:hr_enhancement)
    self.job_count = self.current_job_count
    if is_edit
      build_core_data_on_edit(self.csv_file.to_file.path)
    else
      build_core_data(self.csv_file.to_file.path)
    end
    prev_record = Configuration.find_by_config_key("job/Import/#{self.job_type}")
    if prev_record.present?
      prev_record.update_attributes(:config_value => Time.now)
    else
      Configuration.create(:config_key => "job/Import/#{self.job_type}", :config_value => Time.now)
    end
  end
  
  def current_job_count
    self.class.find(self.id).job_count
  end

  def csv_save(upload)
    self.csv_file = upload
    self.save
  end

  def build_core_data(file)  
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
        g = g+1
        break if (temp_row.count == 0)
      end
      inject_rows = csv_row.select{ |element| element.split('|').second.to_s.downcase.tr(' ', '_').to_s == "inject" }
       
      ext_number = self.extraction_number
      (ext_number..ext_number+199).each do |i|
        begin
          error_present = false
          csv_row = csv_arr[i] 
          if csv_row.blank?
            break
          end
          database_row_name_array = []
          new_model_instance = model_name.new #new employee instance for eg.
          value_hash = {}
          csv_row.map!{|cr| cr.try(:strip)}   
          core_rows.each do |core_row|
            self.row_counter = i + 1
            index = header_row.index(core_row)
            database_row_name = settings[model_name.to_s.underscore]["overrides"].select{ |key, value| value.to_s == core_row.split('|').first.to_s }.first.nil? ? nil : settings[model_name.to_s.underscore]["overrides"].select{ |key, value| value.to_s == core_row.split('|').first.to_s }.first.first unless settings[model_name.to_s.underscore]["overrides"].nil?
            database_row_name = core_row.split('|').first.downcase.tr(' ', '_') if database_row_name.nil?
            process_row = database_row_name.dup
            process_row.slice! "_id"
            associations = settings[model_name.to_s.underscore]["associations"]
            map_combination = settings[model_name.to_s.underscore]["map_combination"]
            assoc = associations.present? ? associations.find{ |assoc| process_row.pluralize.index(assoc.to_s) == 0 } : []
            process_row = assoc ? assoc : process_row
            if associations.present? && associations.include?(process_row.to_sym)
              if map_combination.present? && map_combination.keys.include?(process_row.to_s)
                map_method = map_combination[process_row.to_s]
                klass = process_row.to_s.camelize.constantize
                scope_to_apply = klass.scopes.keys.include? :active
                all_data = scope_to_apply == true ? klass.active.map{ |data| [data.id, data.send(map_method)] } : klass.all.map{ |data| [data.id, data.send(map_method)] }
                associated_id = all_data.select{ |data| data.second == csv_row[index] }.first.nil? ? nil : all_data.select{ |data| data.second == csv_row[index] }.first.first
                if associated_id == nil && csv_row[index].present?
                  error_present = true
                  database_row_name_array<<database_row_name
                end
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
                if !associated_id and csv_row[index].present?
                  error_present = true
                  database_row_name_array << database_row_name
                end
              end
              value_hash = value_hash.merge(database_row_name.to_sym => associated_id)
            else
              if settings[model_name.to_s.underscore]["booleans"].present? && settings[model_name.to_s.underscore]["booleans"].include?(database_row_name.to_sym)
                value_hash = if csv_row[index].present?
                  value_hash.merge(database_row_name.to_sym => 1)
                else
                  value_hash.merge(database_row_name.to_sym => 0)
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
          
          new_model_instance = model_name.new(value_hash)

          # TODO workaround to handle multiple entry creation in the case of books
          if settings[model_name.to_s.underscore]["mandatory_joins"].present?
            new_model_instance = build_join_data(new_model_instance, csv_row, header_row)
          end

          build_nested_associate_data(new_model_instance, csv_row, header_row)
                        
          model_valid = new_model_instance.valid?
          if new_model_instance.present? && model_valid
            new_model_instance.transaction do
              if new_model_instance.save
                unless guardians.blank?
                  @error = add_guardians(new_model_instance,guardians,header_row,csv_row,i,from_edit = false)    
                  raise ActiveRecord::Rollback if @error.present?
                end
                build_associate_data(new_model_instance, csv_row, header_row)
              else
                unless settings[model_name.to_s.underscore]["mandatory_joins"].present?
                  self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => new_model_instance.errors.full_messages.join(" \n")) unless new_model_instance.nil?
                end
              end
            end
            unless @error.blank?
              self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => @error.join(" \n"))                
            end
          else
            if error_present  #error should be Attribute format is incorrect if the csv column is not empty
              change_error_message(new_model_instance,database_row_name_array)
            end
            unless settings[model_name.to_s.underscore]["mandatory_joins"].present?
              self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => new_model_instance.errors.full_messages.join(" \n")) unless new_model_instance.nil?
            end
          end
        rescue Exception => ex
          self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => "#{t('imports.invalid_row')} : #{ex.message}")
          next
        end
      end
      
      self.job_count = current_job_count - 1
      
      if self.job_count == 0  
        self.status = if import_log_details.all.select{ |ild| ild.status == 'failed' }.blank?
          'success'
        else
          'completed_with_errors'
        end
        self.csv_file = nil
      end
      
      self.save
      #else
      #self.status = 'succes_with_no_data'
      #        self.csv_file = nil
      # self.save
      # end
    else
      self.status = 'failed'
      #      self.csv_file = nil
      self.save
      self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => t('import_log_details.export_format_not_matching'))
    end
  rescue Exception => e
    self.status = "failed : #{e.message}"
    self.save
  end

  def change_error_message(new_model_instance,database_row_name_array)
    database_row_name_array.each do|d|
      e = new_model_instance.errors.instance_variable_get(:@errors)
      e[d].first.message = t('format_is_incorrect') if e[d].present?
    end
  end
  
  def build_associate_data(new_model_instance, csv_row, header_row)
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
          search_model.search({search_column.to_sym => search_row}).first.try(:id)
        else
          search_model.search({search_column.to_sym => search_row}).scoped(:conditions => column_condition).first.try(:id)
        end
        new_associate_record = new_model_instance.send(associated_model.pluralize).new(insert_column.to_sym => csv_row[index].nil? ? nil : csv_row[index].gsub('|', ', '), (child_associate_column).to_sym => associate_value_id)
        if new_associate_record.valid?
          new_associate_record.save
        else
          flag = 1
          self.import_log_details.create(:status => 'failed', :model => self.row_counter, :description => new_associate_record.errors.full_messages.join(" \n"))
        end
      end
    end
    if flag == 0
      unless settings[new_model_instance.class.name.to_s.underscore]["mandatory_joins"].present?
        build_join_data(new_model_instance, csv_row, header_row)
      end
    elsif flag == 1
      associated_models.map{ |associated_model| new_model_instance.send(associated_model.pluralize).all.map{ |element| element.destroy } }
      if settings[new_model_instance.class.name.underscore]["dependent"].present?
        new_model_instance.send(settings[new_model_instance.class.name.underscore]["dependent"]).try(:destroy)
      end
      new_model_instance.destroy
    end
  end

  def self.default_time_zone_present_time(time_stamp)
    server_time = time_stamp
    server_time_to_gmt = server_time.getgm
    local_tzone_time = server_time
    time_zone = Configuration.find_by_config_key("TimeZone")
    unless time_zone.nil?
      unless time_zone.config_value.nil?
        zone = TimeZone.find_by_id(time_zone.config_value)
        if zone.present?
          local_tzone_time = if zone.difference_type == "+"
            server_time_to_gmt + zone.time_difference
          else
            server_time_to_gmt - zone.time_difference
          end
        end
      end
    end
    return local_tzone_time
  end

  def self.strip_star(main_columns)
    main_columns.each do |s|
      if s.first=="*"
        s = s.gsub!(s,s.split('*').second)
      end
    end
    main_columns
  end
  
  def build_nested_associate_data(new_model_instance, csv_row, header_row)
    settings = load_yaml
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
        if nested_associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).present? && nested_associated_model_name.reflect_on_association(search_model.to_s.underscore.to_sym).macro == :has_one
          new_model_instance.send("build_" + nested_associate_model.to_s, {insert_column.to_sym => csv_row[index].nil? ? nil : csv_row[index].gsub('|', ', '), (child_associate_column).to_sym => associate_value_id})
        else
          new_model_instance.send(nested_associate_model.pluralize).build(insert_column.to_sym => csv_row[index].nil? ? nil : csv_row[index].gsub('|', ', '), (child_associate_column).to_sym => associate_value_id)
        end
      end
    end
  end
end