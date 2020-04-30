class DonationAdditionalField < ActiveRecord::Base
  belongs_to :finance_donation
  has_many :donation_additional_details
  has_many :donation_additional_field_options, :dependent=>:destroy
  accepts_nested_attributes_for :donation_additional_field_options, :allow_destroy=>true
  validates_presence_of :name
  validates_format_of :name, :with => /^[^~`@%$*()\-\[\]{}"':;\/.,\\=+|]*$/i,:message => :must_contain_only_letters_numbers_space
  validates_uniqueness_of :name,:case_sensitive => false
  validate :options_check
  named_scope :active,:conditions => {:status => true}
  named_scope :inactive,:conditions => {:status => false}
  def options_check
    unless self.input_type=="text" or self.input_type=="text_area"
      all_valid_options=self.donation_additional_field_options.reject{|o| (o._destroy==true if o._destroy)}
      unless all_valid_options.present?
        errors.add_to_base(:create_atleast_one_option)
      end
      if all_valid_options.map{|o| o.field_option.strip.blank?}.include?(true)
        errors.add_to_base(:option_name_cant_be_blank)
      end
    end
  end
end
