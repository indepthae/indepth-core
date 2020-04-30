class Export < ActiveRecord::Base
  serialize :structure
  serialize :associated_columns
  serialize :join_columns

  default_scope :order => "created_at DESC"

  MODELS = [["Employee Admission", "Employee"], ["Student Admission", "Student"], ["Guardian Addition", "Guardian"], ["Student Attendance", "Attendance"], ["Student Exam Scores", "ExamScore"], ["Employee Payroll", "EmployeeSalaryStructureForImport"]]

  validates_presence_of :name
  validates_uniqueness_of :name

  has_many :imports, :dependent => :destroy

  class << self
    def get_models
      models = []
      models = MODELS.dup
      if FedenaPlugin.accessible_plugins.include? "fedena_library"
        models.push(["Library Book", "Book"])
      end
      if FedenaPlugin.accessible_plugins.include? "fedena_inventory"
        models.push(["Store Item", "StoreItem"], ["Supplier", "Supplier"], ["Store", "Store"])
      end
      if FedenaPlugin.accessible_plugins.include? "fedena_hostel"
        models.push(["Student Hostel Details", "Hostel"], ["Student Room Details","RoomDetail"])
      end
      models.uniq
    end
    
    def get_attributes(model)
      attributes = if model == 'Student'
        (model.constantize.column_names - %w(id created_at updated_at class_roll_no photo_updated_at)).map{ |column| column.to_s + "|#{model}" }        

      
      else
        (model.constantize.column_names - %w(id created_at updated_at photo_updated_at)).map{ |column| column.to_s + "|#{model}" }
      end
      


      [attributes, model]
    end

    def load_yaml(model)
      if File.exists?("#{Rails.root}/vendor/plugins/fedena_custom_import/config/models/#{model.underscore}.yml")
        exports = YAML.load_file(File.join(Rails.root, "vendor/plugins/fedena_custom_import/config/models", "#{model.underscore}.yml"))
        
      end
      exports
    end

    def process_attributes(model)
      attributes = get_attributes(model)
      
      settings = load_yaml(model)
      filter_attributes = settings[model.underscore].nil? ? [] : settings[model.underscore]["filters"].map{ |filter| filter.to_s + "|#{model}" }
      attr_accessor_list = (settings[model.underscore].present? && settings[model.underscore]["attr_accessor_list"].present?) ? settings[model.underscore]["attr_accessor_list"].map{ |attr| attr.to_s + "|#{model}" } : []
 
      csv_attributes = (attributes.first + attr_accessor_list) - filter_attributes
      # putting is_father and _is_mohter before relation field for guardian csv
     
      if model.to_s == "Guardian"
        ordered_attributes = []
        csv_attributes.delete("is_father|Guardian")
        csv_attributes.delete("is_mother|Guardian")
        csv_attributes.each do|c|
          if c == "relation|Guardian"
            ordered_attributes.push "is_father|Guardian"
            ordered_attributes.push "is_mother|Guardian"
          end
          ordered_attributes.push c
        end
        return ordered_attributes
      elsif model.to_s == "EmployeeSalaryStructureForImport"
        unless Configuration.is_gross_based_payroll
          csv_attributes.map!{ |e| (e == "gross_salary|EmployeeSalaryStructureForImport" ? "auto_calculate|EmployeeSalaryStructureForImport" : e) }
        end
        return csv_attributes
      elsif model.to_s == "Employee"
        csv_attributes.push("leave_group_id|Employee")
      elsif model.to_s == "Attendance"
        config = Configuration.get_config_value('CustomAttendanceType') || "0"
        csv_attributes.delete("attendance_label_id|Attendance") if config == "0"
        attendance_lock = AttendanceSetting.is_attendance_lock
        csv_attributes.delete("attendance_save|Attendance") unless attendance_lock
        csv_attributes.delete("attendance_submit|Attendance") unless attendance_lock
        return csv_attributes
      else
        return csv_attributes
      end
    end

    def place_overrides(model)
     
      attributes = process_attributes(model)
      settings = load_yaml(model)
      override_attributes = {}
      unless settings[model.underscore].nil?
        override_attributes = settings[model.underscore]["overrides"]
      end
      attributes.each do |attribute|
        attribute_name = attribute.split('|').first
        if override_attributes.present? && override_attributes.keys.include?(attribute_name.to_s)
          if settings[model.underscore]["mandatory_columns"].present? && settings[model.underscore]["mandatory_columns"].map{|p|p.to_s}.include?(attribute_name)
            attribute_override = attribute.gsub(attribute_name, "*#{override_attributes[attribute_name]}")
          else 
            attribute_override = attribute.gsub(attribute_name, override_attributes[attribute_name])
          end
          attributes[attributes.index(attribute)] = attribute_override
        else
          if settings[model.underscore]["mandatory_columns"].present? && settings[model.underscore]["mandatory_columns"].map{|p|p.to_s}.include?(attribute_name)
            attribute_override = attribute.gsub(attribute_name, "*#{attribute_name.humanize}")
          else
            attribute_override = attribute.gsub(attribute_name, attribute_name.humanize)
          end
          attributes[attributes.index(attribute)] = attribute_override
        end
      end
      attributes
    end

    def prepare_associated_columns(model, associated_models)
      settings = load_yaml(model)
      associated_model_hash_values = settings[model.underscore]["associates"].nil? ? [] : settings[model.underscore]["associates"].select{ |key, value| associated_models.include? key }
      header = []
      associated_model_hash_values.each do |associated_model|
        header_model = associated_model.second.camelize.constantize
        if header_model.column_names.include? "name"
          header_columns = if header_model.scopes.keys.include? :active
            if model == 'Hostel'
              header_model.find(:all, :conditions=>["is_active=true and type='HostelAdditionalField'"]).map(&:name).map{ |column| column + "|hostel_additional_detail|asscoiate" }.compact.flatten
            elsif model == 'RoomDetail'
              header_model.find(:all, :conditions=>["is_active=true and type='RoomAdditionalField'"]).map(&:name).map{ |column| column + "|room_additional_detail|asscoiate" }.compact.flatten
            else
              header_model.active.all.map(&:name).map{ |column| column + "|#{associated_model.first}|asscoiate" }.compact.flatten
            end
          else
            header_model.all.map(&:name).map{ |column| column + "|#{associated_model.first}|asscoiate" }.compact.flatten
          end
        else
          raise "Name column not found in the model."
        end
        header << header_columns
      end
      header.flatten.compact
    end

    def prepare_join_columns(model, join_models)
      settings = load_yaml(model)
      join_model_hash_values = settings[model.underscore]["joins"].nil? ? [] : settings[model.downcase]["joins"].select{ |key, value| join_models.include? key }
      header = []
      join_model_hash_values.each do |join_model|
        header_model = join_model.first.singularize.camelize.constantize
        if header_model.column_names.include? "name"
          header_columns = if header_model.column_names.include? "is_active"
            header_model.all(:conditions => {:is_active => true}).map(&:name).map{ |column| column + "|#{join_model.first}|join" }.compact.flatten
          else
            header_model.all.map(&:name).map{ |column| column + "|#{join_model.first}|join" }.compact.flatten
          end
        else
          raise "Name column not found in the model."
        end
        header << header_columns
      end
      header.flatten.compact
    end

    def make_final_columns_set(model, all_columns, join_columns)
      final_columns = []
      core_columns = self.process_attributes(model)
      associated_columns = (all_columns - join_columns)
      final_columns = associated_columns.nil? ? core_columns : core_columns + associated_columns
      final_columns = join_columns.nil? ? core_columns : core_columns + join_columns
      final_columns = final_columns.flatten.compact
      associated_columns = associated_columns.flatten.compact
      join_columns = join_columns.flatten.compact
      [final_columns, associated_columns, join_columns]
    end

    def load_fastercsv(header_data, model)
      settings = load_yaml(model)
      injectable_columns = []
      additional_fields = []
      if header_data.present? && (model== "Student" || model == "Employee" || model == "Hostel" || model == "RoomDetail")
        additional_fields = settings[model.underscore]["associates"].collect{ |key,value| value if (key=="#{model.downcase}_additional_detail" || key== "hostel_room_additional_detail" )}.compact    
        header_data =  mandatory_for_additional_fields(header_data,model,additional_fields)
      end
      csv_data = FasterCSV.generate do |csv|
        core_columns = self.place_overrides(model)
        associated_columns = header_data + compulsory_associates_columns(model)
        header_column = associated_columns.nil? ? core_columns : core_columns + associated_columns
        header_column = header_column.map{ |column| "#{column.split('|').first}|#{column.split('|').second.underscore.humanize}" }.flatten.compact
        if model == "Student"
          header_column=place_overrides_for_guardian(header_column,model)
        end
        if settings[model.underscore]["inject"].present?
          injectable_columns = settings[model.underscore]["inject"].map{ |injectable_column| "*#{injectable_column.to_s.humanize}|inject" }
        end
        csv << injectable_columns + header_column
      end
      [csv_data, model]
    end

    
    def place_overrides_for_guardian(header_column,model)
      settings = load_yaml(model)
      unless settings["guardian"].nil?
        override_for_guardian = settings["guardian"]["overrides"]
      end  
      guardian = ("Guardian".constantize.column_names - %w(id created_at updated_at user_id school_id))    
      attr_accessor_list = (settings["guardian"].present? && settings["guardian"]["attr_accessor_list"].present?) ? settings["guardian"]["attr_accessor_list"] : []
      filters = settings["guardian"].nil? ? [] : settings["guardian"]["filters"].map{ |filter| filter.to_s}
      guardian = (guardian + attr_accessor_list)-filters
      guardian.delete(:is_father)
      guardian.delete(:is_mother)
      temp_1=guardian.slice(0..1)
      temp_2=guardian.slice(2..guardian.length)
      temp_1.push(:is_father,:is_mother)
      guardian=temp_1+temp_2
      guardian1 = guardian.map{|column| column.to_s + "|Guardian1" }
      guardian2 = guardian.map{|column| column.to_s + "|Guardian2" }
      attributes = guardian1+guardian2
      attributes.each do |attribute|
        attribute_name = attribute.split('|').first
        if override_for_guardian.present? && override_for_guardian.keys.include?(attribute_name.to_s)
          #if settings["guardian"]["mandatory_columns"].present? && settings["guardian"]["mandatory_columns"].map{|p|p.to_s}.include?(attribute_name)
          #attribute_override = attribute.gsub(attribute_name, "*#{override_for_guardian[attribute_name]}")
          #else 
          attribute_override = attribute.gsub(attribute_name, override_for_guardian[attribute_name])
          #end
          attributes[attributes.index(attribute)] = attribute_override
        else
          #if settings["guardian"]["mandatory_columns"].present? && settings["guardian"]["mandatory_columns"].map{|p|p.to_s}.include?(attribute_name)
          # attribute_override = attribute.gsub(attribute_name, "*#{attribute_name.humanize}")
          # else
          attribute_override = attribute.gsub(attribute_name, attribute_name.humanize)
          #end
          attributes[attributes.index(attribute)] = attribute_override
        end
      end
      header_column += attributes
      return header_column
    end
    def mandatory_for_additional_fields(header_data,model,additional_fields)
      header_data.each do |h|
        if h.split('|').second == "#{model.downcase}_additional_detail" || h.split('|').second == "#{model.underscore.split('_').first}_additional_detail"
          name = h.split('|').first
          if additional_fields.first.camelize.constantize.find_by_name(name).is_mandatory == true
            h = h.gsub!(h,"*#{h}")
          end
        end
      end
      header_data
    end
    
    def get_associated_models(model)
      model_name = model.underscore
      settings = load_yaml(model)
      associated_models = []
      unless settings[model_name]["associates"].nil?
        compulsory_associates = settings[model_name]["compulsory_associates"]
        associated_models = if compulsory_associates.present?
          settings[model_name]["associates"].keys.map{ |key| [key.humanize, key] unless compulsory_associates.map(&:to_s).include? key }.compact
        else
          settings[model_name]["associates"].keys.map{ |key| [key.humanize, key] }
        end
      end
      return associated_models
    end

    def get_join_models(model)
      model_name = model.underscore
      settings = load_yaml(model)
      join_models = []
      unless settings[model_name]["joins"].nil?
        join_models = settings[model_name]["joins"].keys.map{ |key| [key.humanize, "#{key}|join"] }
      end
      return join_models
    end

    def compulsory_associates_columns(model)
      settings = load_yaml(model)
      comp_associates = settings[model.underscore]["compulsory_associates"].nil? ? [] : settings[model.underscore]["compulsory_associates"].map(&:to_s)
      header = []
      comp_associates.each do |compulsory_model|
        search_model = settings[model.underscore]["associates"][compulsory_model].camelize.constantize
        search_column = settings[model.underscore]["associate_column_search"].nil? ? nil : settings[model.underscore]["associate_column_search"][search_model.to_s.underscore]
        if search_column.present? && search_model.method_defined?(search_column)
          header_columns = if search_model.scopes.keys.include? :active
            search_model.active.all.map(&search_column.to_sym).map{ |column| column + "|#{compulsory_model}|asscoiate" }.compact.flatten
          else
            search_model.all.map(&search_column.to_sym).map{ |column| column + "|#{compulsory_model}|asscoiate" }.compact.flatten
          end
          header << header_columns
        else
          raise "Method not defined"
        end
      end
      header.flatten.compact
    end
  end
  
  

  def is_outdated?
    payroll_fields = associated_columns.select{ |column| column =~ /\|employee_salary_structure\|/ }
    privilege_fields = associated_columns & ["HrBasics|privileges|join", "PayslipPowers|privileges|join"]
    payroll_fields.present? || privilege_fields.present?
  end

  def get_model_name
    self.class.get_models.detect{ |m| m.last == model }.first
  end
end
