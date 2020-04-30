
class ExamFormula

  Fraction = Struct.new(:numerator, :denominator)
  Expr = Struct.new(:function,:parts,:count,:modifier,:operation)

  Fraction.class_eval do

    def value
      self.numerator/self.denominator
    end

    def into (factor)
      (self.numerator*factor)/(self.denominator)
    end

    def to_s
      "#{self.numerator}/#{self.denominator}"
    end

  end

  attr_accessor :formula, :formula_type, :max_marks, :obtained_marks, :errors

  DEFAULT_OPTIONS = {:obtained_marks=>{}, :max_marks=>{}, :mode => :cdm, :sum=>false}

  def initialize (formula,opts = {})
    @formula = formula
    opts = DEFAULT_OPTIONS.merge opts

    @formula_type = opts[:mode]
    @max_marks = opts[:max_marks]
    @obtained_marks = opts[:obtained_marks]
    @sum_mode = opts[:sum]
  end

  def to_s
    "#{self.formula} :#{self.formula_type}"
  end

  def calculate (opts = {})
    read_marks(opts)
    parts = parse
    parts = parts.collect do |part|
      case part
      when /^avg\((.*)\)/i
        avg(break_expression(:avg,$1))
      when /^best\((.*)\)/i
        best(break_expression(:best,$1))
      else
        key(break_expression(:key,part))
      end
    end

    Fraction.new(parts.collect(&:numerator).sum, parts.collect(&:denominator).sum)
  end

  def validate
    @errors = []
    parts = formula.split('').grep(/^[A-Z]$/).uniq
    @errors << :key_miss_match unless obtained_marks.keys.uniq.sort == max_marks.keys.uniq.sort
    @errors << :invalid_key_in_formula unless (parts & (max_marks.keys.uniq & obtained_marks.keys.uniq)) == parts
  end

  def valid? (opts={})
    read_marks(opts)
    validate
    @errors.blank?
  end

  class << self

    def formula_validate(formula,formula_type)
      parts = parse(formula)
      if parts.count > formula.count('+')
        if formula_type == "1"
          parts.each do |piece|
            if (piece.match(/^(avg{1}\([A-Z]{1}(,[A-Z]){1,}((,@[0-9]+{1}))\))$/).present? or piece.match(/^best{1}\([0-9]+(,[A-Z]){2,}((,@[0-9]+{1})(((,:sum)|(,:avg)){1})?)\)$/).present? or piece.match(/^[A-Z]$/).present?) == false
              return false
            end
          end
          return true
        else
          parts.each do |piece|
            if (piece.match(/^(avg{1}\([A-Z]{1}(,[A-Z]){1,}((,@[0-9]+{1})?)\))$/).present? or piece.match(/^best{1}\([0-9]+(,[A-Z]){2,}((,@[0-9]+{1})?(((,:sum)|(,:avg)){1})?)\)$/).present? or piece.match(/^[A-Z]$/).present?) == false
              return false
            end
          end
          return true
        end
      else
        return false
      end
    end

    def parse(formula)
      formula.gsub(' ','').split('+')
    end
  end

  private

  def read_marks (opts)
    @max_marks = opts[:max_marks] if opts[:max_marks].present?
    @obtained_marks = opts[:obtained_marks] if opts[:obtained_marks].present?
  end

  def parse
    formula.gsub(' ','').split('+')
  end

  def key (expr)
    fraction = expr.parts.first
    if formula_type == :cdm
      Fraction.new(fraction.value,1)
    else
      fraction
    end
  end

  def avg (expr)
    if formula_type == :cdm
      avg_for_cdm(expr)
    else
      avg_for_tmm(expr)
    end
  end

  def avg_for_tmm (expr)
    values = expr.parts.collect do |part|
      part.into(expr.modifier)
    end
    Fraction.new(values.sum / values.length,expr.modifier)
  end

  def avg_for_cdm (expr)
    values = expr.parts.collect do |part|
      part.value
    end
    Fraction.new(values.sum/values.length,1)
  end

  def best (expr)
    if formula_type == :cdm
      best_for_cdm(expr)
    else
      best_for_tmm(expr)
    end
  end

  def best_for_tmm (expr)
    values = expr.parts.collect do |part|
      part.into(expr.modifier)
    end
    values = values.sort[-expr.count..-1]
    expr.operation == :sum ? Fraction.new(values.sum,values.length*expr.modifier) : Fraction.new(values.sum/values.length,expr.modifier)
  end

  def best_for_cdm (expr)
    values = expr.parts.collect do |part|
      part.value
    end
    values = values.sort[-expr.count..-1]
    expr.operation == :sum ? Fraction.new(values.sum,values.length) : Fraction.new(values.sum/values.length,1)
  end

  def break_expression (func,expr)
    expression = Expr.new
    expression.function = func
    expression.operation = :avg
    parts = expr.split(',')

    if key = parts.find{ |x| x =~ /@(\d*)/ }
      parts.delete(key)
      expression.modifier = $1.to_f
    end

    if key = parts.find{ |x| x =~ /:sum/ }
      parts.delete(key)
      expression.operation = :sum
    end

    if func == :best
      expression.count = parts[0].to_f
      expression.parts = parts[1..-1]
    else
      expression.parts = parts
    end

    expression.parts = keys_to_fraction(expression.parts)
    expression.modifier = get_highest_factor(expression.parts) if [nil,0].include? expression.modifier
    expression.operation = :sum if @sum_mode
    expression
  end

  def keys_to_fraction (keys)
    keys.collect do |key|
      key_to_fraction(key)
    end
  end

  def key_to_fraction (key)
    f = Fraction.new
    f.numerator = obtained_marks[key] ? obtained_marks[key].to_f : 0.0
    f.denominator = max_marks[key] ? max_marks[key].to_f : 1.0
    f
  end

  def get_highest_factor (parts)
    parts.collect(&:denominator).sort.last || 1.0
  end

end

# Example: ExamFormula.new('A+B',:obtained_marks=>{'A'=>8,'B'=>7},:max_marks=>{'A'=>10,'B'=>10},:mode=>:tmm)
#
# obtained = {'A'=>8,'B'=>7,'C'=>6,'D'=>7}
# max = {'A'=>10,'B'=>10, 'C'=>10,'D'=>10}
#
# puts 'obtained: ' + obtained.inspect
# puts 'max: ' + max.inspect
#
# puts ''
#
# puts max.keys.sort.collect{|k| "#{k}=#{obtained[k]}/#{max[k]}"}.join("  ")
#
# puts ''
#
# e=ExamFormula.new('A+best(2,B,C,D,:sum)',:obtained_marks=>obtained,:max_marks=>max)
# puts e.to_s
# puts e.calculate.to_s
#
# e=ExamFormula.new('A+best(2,B,C,D,@35,:sum)',:obtained_marks=>obtained,:max_marks=>max,:mode=>:tmm)
# puts e.to_s
# puts e.calculate.to_s
#
# e=ExamFormula.new('A+best(2,B,C,D)',:obtained_marks=>obtained,:max_marks=>max)
# puts e.to_s
# puts e.calculate.to_s
#
# e=ExamFormula.new('A+best(2,B,C,D,@35)',:obtained_marks=>obtained,:max_marks=>max,:mode=>:tmm)
# puts e.to_s
# puts e.calculate.to_s
#
# e=ExamFormula.new('A+avg(B,C,:@35)+D',:obtained_marks=>obtained,:max_marks=>max)
# puts e.to_s
# puts e.calculate.to_s
#
# e=ExamFormula.new('A+avg(B,C,:@35)+D',:obtained_marks=>obtained,:max_marks=>max,:mode=>:tmm)
# puts e.to_s
# puts e.calculate.to_s