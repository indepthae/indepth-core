class BookAdditionalField < ActiveRecord::Base
  has_many :book_additional_field_options, :dependent=>:destroy
  validates_presence_of :name
  validates_uniqueness_of :name,:case_sensitive => false
  validates_format_of     :name, :with => /^[^~`@%$*()\-\[\]{}"':;\/.,\\=+|]*$/i,
    :message => :must_contain_only_letters_numbers_space
  validate :options_check
  accepts_nested_attributes_for :book_additional_field_options, :allow_destroy=>true
  named_scope :active,:conditions => {:is_active => true}

  def options_check
    unless self.input_type=="text"
      all_valid_options=self.book_additional_field_options.reject{|o| (o._destroy==true if o._destroy)}
      unless all_valid_options.present?
        errors.add_to_base(:create_atleast_one_option)
      end
      if all_valid_options.map{|o| o.field_option.strip.blank?}.include?(true)
        errors.add_to_base(:option_name_cant_be_blank)
      end
    end
  end
end
