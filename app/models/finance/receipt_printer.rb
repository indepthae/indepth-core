# ReceiptPrinter configuration class

class ReceiptPrinter
  attr_accessor :receipt_printer_type,:receipt_printer_header_height,:receipt_printer_header_type,:receipt_printer_template
  RECEIPT_PRINTER_TYPES ={
    0=> "Normal",
    1=> "Dot Matrix",
    2=> "Thermal",
  }
  RECEIPT_PRINTER_TEMPLATES = {
    0 => "A4",
    1 => "A5 Portrait",
    2 => "A5 Landscape",
    3 => "Thermal Responsive",
  }
  RECEIPT_PRINTER_HEADER_TYPES = {
    0 => "Default Header",
    1 => "Header Placeholder",
  }
  RECEIPT_PRINTER_BUTTONS = {
    0 =>"pdf",
    1 =>"print and pdf",
    2 =>"print"
  }
  ##
  # Map printer type to templates available for it
  # * Normal => A4 , A5 portrait,A5 landscape
  # * Dot Matrix => A4 , A5 portrait,A5 landscape
  # * Thermal => Thermal responsive
  AVAILABLE_TEMPLATE_OPTIONS = {
    0=>[0,1,2],
    1=>[0,1,2],
    2=>[3]
  }

  #Map Receipt Printer template to dimenstions
  TEMPLATE_DIMENSIONS ={
    0=> "8.27 × 11.69",
    1=> "5.83 × 8.27",
    2=> "8.27 x 5.83",
    3=> ""
  }

  #Deafult values for each config value
  DEFAULT_VALUES = {
    :ReceiptPrinterType => 0,
    :ReceiptPrinterTemplate => 0,
    :ReceiptPrinterHeaderType => 0,
    :ReceiptPrinterHeaderHeight => 20,
  }

  def initialize(options={})
    @receipt_printer_type=options[:receipt_printer_type] || DEFAULT_VALUES[:ReceiptPrinterType]
    @receipt_printer_header_height=options[:receipt_printer_header_height]|| DEFAULT_VALUES[:ReceiptPrinterHeaderHeight]
    @receipt_printer_header_type=options[:receipt_printer_header_type]|| DEFAULT_VALUES[:ReceiptPrinterHeaderType]
    @receipt_printer_template=options[:receipt_printer_template]|| DEFAULT_VALUES[:ReceiptPrinterTemplate]
    # define_methods()
  end

  # Returns ReceiptPrinter object with current settings
  def self.current_settings_object
    receipt_printer=ReceiptPrinter.new()
    receipt_printer.receipt_printer_type=receipt_printer_type
    receipt_printer.receipt_printer_header_height=receipt_printer_header_height
    receipt_printer.receipt_printer_header_type=receipt_printer_header_type
    receipt_printer.receipt_printer_template=receipt_printer_template
    receipt_printer
  end

  # Save receipt configuration settings
  def save
    return false unless self.valid?
    self.class.receipt_printer_type=receipt_printer_type
    self.class.receipt_printer_header_height=receipt_printer_header_height
    self.class.receipt_printer_header_type=receipt_printer_header_type
    self.class.receipt_printer_template=receipt_printer_template
    self
  end

  # Validate fee receipt settings object
  def valid?
    (RECEIPT_PRINTER_TEMPLATES.keys.include? receipt_printer_template.to_i) &&
    (RECEIPT_PRINTER_HEADER_TYPES.keys.include? receipt_printer_header_type.to_i) &&
    (RECEIPT_PRINTER_TYPES.keys.include? receipt_printer_type.to_i)
  end

  # List available templates for the selected printer type
  def available_templates
    ActiveSupport::OrderedHash[AVAILABLE_TEMPLATE_OPTIONS[receipt_printer_type].map { |id|
      {id=>RECEIPT_PRINTER_TEMPLATES[id]}
    }.inject(:merge).invert.sort]
  end
  
  def all_templates exclude_templates = []
    ActiveSupport::OrderedHash[RECEIPT_PRINTER_TEMPLATES.map do |k,v|
      [k,v] unless exclude_templates.include?(v)
    end]
  end

  def get_receipt_printer_template
    RECEIPT_PRINTER_TEMPLATES[receipt_printer_template] || ''
  end

  # Gives dot matrix info messages for the selected template
  def dot_matrix_info_message
    if thermal_template?  #FIXME temporary fix
      thermal_info_message
    else
      I18n.t('dot_matrix_info_message',:template=>get_receipt_printer_template,:dimension=>template_dimension)
    end
  end

  # Thermal info message
  def thermal_info_message
    I18n.t('thermal_info_message')
    # "If you face issues with the margins of the print output, go to your printer preferences and create a custom page size."
  end

  #Info message
  def info_message
    if thermal?
      thermal_info_message
    elsif dot_matrix?
      dot_matrix_info_message
    end
  end

  #Get template dimension
  def template_dimension
    TEMPLATE_DIMENSIONS[receipt_printer_template]
  end
  # Gives the preview url for the selected receipt template
  def preview_url
    "#{Fedena.hostname}/finance_settings/fees_receipt_preview?printer_type=#{self.receipt_printer_template}"
  end

  # Gives the dotmatrix info message url for the selected receipt template
  def dot_matrix_info_message_url
    "#{Fedena.hostname}/finance/get_printer_message?printer_type=#{self.receipt_printer_template}"
  end

  # Check whether currently selected printer type is dot matrix
  def dot_matrix?
    receipt_printer_type==1
  end

  # Check whether currently selected printer type is thermal
  def thermal?
    receipt_printer_type==2
  end

  # Check whether currently selected printer type is thermal
  def thermal_template?
    receipt_printer_template==3
  end

  # Returns array of methods in the
  def attribute_names
    instance_variables.map { |variable| variable.gsub("@","").to_sym }
  end

  # Alias to instance method attribute names
  def self.attribute_names
    new.attribute_names
  end

  # Return attributes hash
  def attributes
    #stub
  end

  ##
  # Define attribute specific class methods
  # * attribute_config_value() => returns the config value of the attribute for current settings ,fallback to default value if it is not available
  # * attribute=() => Setter method for an attribute
  # * get_attribute() => Get human readable value of an attribute
  # * attribute() => Alias to attribute config_value
  class << self
    attribute_names=[:receipt_printer_type,:receipt_printer_header_height,:receipt_printer_header_type,:receipt_printer_template]
    attribute_names.each do |attribute|
      camelized_attribute=attribute.to_s.camelize
      constant_name=attribute.to_s.pluralize.upcase
      # Define config value method
      config_value_method_name=(attribute.to_s+"_config_value").to_sym
      define_method(config_value_method_name) {
        (Configuration.find_by_config_key(camelized_attribute).try(:config_value) || DEFAULT_VALUES[camelized_attribute.to_sym]).to_i
      }
      # Define setter methods
      setter_method_name=(attribute.to_s+"=").to_sym
      define_method(setter_method_name) do | type|
        Configuration.set_value(camelized_attribute, type)
      end
      # Define value mapper method (?)
      map_method_name=("get_"+attribute.to_s).to_sym
      define_method(map_method_name) {
        type=send(config_value_method_name)
        const_get(constant_name)[type]
      }
      # Define getter method ( use alias instead)
      get_method_name=attribute
      define_method(get_method_name) {
        send(config_value_method_name)
      }
    end
  end

  # Check whether header should be hidden
  def self.hide_header?
    receipt_printer_header_type == 1
  end
end
