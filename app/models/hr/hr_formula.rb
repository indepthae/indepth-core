class HrFormula < ActiveRecord::Base
  xss_terminate
  
  attr_accessor :default_value_valid, :cat_list
  belongs_to :formula, :polymorphic => true
  has_many :formula_and_conditions, :dependent => :destroy

  validates_presence_of :value_type, :message => :value_type_is_required #, :if => "formula_type == 'PayrollCategory'"
  validates_presence_of :default_value, :if => "value_type == 1"
  validates_numericality_of :default_value, :greater_than_or_equal_to => 0, :if => :value_type_is_numeric, :message => :please_enter_a_value_greater_than_zero
  accepts_nested_attributes_for :formula_and_conditions, :allow_destroy => true

  before_save :check_value_type
  before_validation :set_numeric_default_value
  VALUE_TYPE = {
    1 => "numeric",
    2 => "formulas",
    3 => "conditions_with_formulas"
  }

  OPERATIONS = {
    1 => "is_greater_than",
    2 => "is_lesser_than",
    3 => "is_equal_to",
    4 => "is_not_equal_to",
    5 => "is_greater_than_or_equal_to",
    6 => "is_less_than_or_equal_to",
  }

  OPERATIONS_OPERATOR = {
    1 => ">",
    2 => "<",
    3 => "=",
    4 => "!=",
    5 => ">=",
    6 => "<="
  }

  def validate
    if value_type == 2 or value_type == 3
      self.default_value = default_value.upcase.gsub(/\n/," ").gsub(/\r/," ").squeeze(" ")
      if formula_type == 'PayrollCategory'
        error_messages = HrFormula.validate_formula(default_value, false, formula.try(:code))
      elsif formula_type == "LopProratedFormula"
        error_messages = HrFormula.validate_formula(default_value, true, nil, cat_list, 1)
      else
        error_messages = HrFormula.validate_formula(default_value, true, nil, cat_list)
      end
      self.default_value_valid = true if error_messages.empty?
      errors.add(:default_value,error_messages.join('<br/>')) unless error_messages.empty?
    end
  end

  def set_numeric_default_value
    self.default_value = HrFormula.precision_label(0) if value_type == 1 and !default_value.present?
  end

  def value_type_is_numeric
    return (self.value_type.present? && self.value_type == 1)
  end

  def value_type_is_formula
    return (self.value_type.present? && self.value_type == 3)
  end

  def formula_display
    formula = case value_type
    when 1
      HrFormula.precision_label(default_value)
    when 2
      default_value
    when 3
      form = []
      formula_and_conditions.each_with_index do |cond, i|
        form << "#{t('condition')} #{i+1}: If #{cond.expression1} #{OPERATIONS_OPERATOR[cond.operation]} #{cond.expression2} Then #{cond.value}"
      end
      form << "#{t('default_value')}: #{default_value}"
      form.join('<br/>')
    end
    return formula
  end

  def formula_html_display
    formula = case value_type
    when 1
      HrFormula.precision_label(default_value)
    when 2
      "<div class='formula'>#{default_value}</div>"
    when 3
      form = []
      formula_and_conditions.each_with_index do |cond, i|
        form << "<div class='condition'><div class='condition_text'>#{t('condition')} #{i+1} :</div> <div class='formula'>If #{cond.expression1} #{OPERATIONS_OPERATOR[cond.operation]} #{cond.expression2} Then #{cond.value}</div></div>"
      end
      form << "<div class='condition_text'>#{t('default_value')} :</div> <div class='formula'>#{default_value}</div>"
      form.join(' ')
    end
    return formula
  end

  def self.validate_formula(formula, is_lop, code = nil, selected_cats = nil, cat_formula = nil)
    formula = formula.upcase.gsub(/\n/," ").gsub(/\r/," ").squeeze(" ")
    begin
      errors = []
      if formula.present?
        unless formula.match(/^[0-9A-Za-z\s\.\+\-\*\/\%\(\)]*$/).nil?
          available_codes =  selected_cats.present? ? selected_cats.split(",")+["GROSS", "NWD"] : is_lop ? ["GROSS", "NWD"] : PayrollCategory.available_tags
          if is_lop
            available_codes << "NET" 
            available_codes += ["LOPA" , "LOPD" , "NDW"] if cat_formula.present?
          end
          c = Dentaku::Calculator.new
          dependencies =	c.dependencies(formula)
          if dependencies.present?
            errors << t('same_category_code_error') if code.present? and dependencies.include? code
            remaining_codes = dependencies - available_codes
            errors << "#{t('invalid_codes')}" unless remaining_codes.empty?
            d_hash = {}
            dependencies.each{|dep| d_hash[dep]=1 }
            c.evaluate(formula,d_hash).present?
          else
            val = c.evaluate(formula)
            errors << t('please_enter_a_value_or_expression_greater_than_zero') if val < 0
          end
        else
          errors << t('must_contain_only_specified_characters')
        end
      else
        errors << t('please_enter_a_value_or_expression')
      end
    rescue Exception => e
      errors << t('formula_created_is_invalid')
    end
    return errors
  end

  def check_value_type
    formula_and_conditions.destroy_all if [1,2].include? value_type
  end

  def value_type_text
    t(VALUE_TYPE[value_type])
  end
  
  class << self
    def precision_label(val)
      if defined? val and val != '' and !val.nil?
        return sprintf("%0.#{precision_count}f",val)
      else
        return
      end
    end

    def precision_count
      precision_count = Configuration.get_config_value('PrecisionCount')
      precision = precision_count.to_i < 2 ? 2 : precision_count.to_i > 9 ? 8 : precision_count.to_i
      precision
    end
  end
end