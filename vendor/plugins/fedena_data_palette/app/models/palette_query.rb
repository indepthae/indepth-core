class PaletteQuery < ActiveRecord::Base

  @@usable_keys = [:all, :count, :sum]
  
  belongs_to :palette

  serialize :query
  serialize :user_roles

  Later = Struct.new(:method_string)

  def later (method_string)
    Later.new(method_string)
  end
  
  validates_presence_of :user_roles,:query
  def validate
    errors.add(:user_roles,"duplicate roles for same Palette") if palette_id.present? and ((palette.palette_queries-[self]).collect(&:user_roles).flatten & user_roles).present?
  end

  def after_initialize
    self.query ||= []
  end

  def with (&block)
    hsh = {}
    self.query << hsh
    @current_query = hsh
    instance_eval &block if block_given?
  end
  
  private

  def method_missing(name, *args, &block)
    if @@usable_keys.include? name.to_sym
      @current_query.delete_if{|k,v| @@usable_keys.include? k}
      @current_query[name.to_sym] = args
      self
    elsif name.to_s == "search"
      @current_query[name.to_sym] = args
      self
    else
      super(name, *args, &block)
    end
  end
end 