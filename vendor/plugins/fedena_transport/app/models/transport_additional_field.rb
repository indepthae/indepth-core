class TransportAdditionalField < ActiveRecord::Base
  validates_presence_of :name
  #  validates_uniqueness_of :name,:case_sensitive => false
  validates_uniqueness_of :name, :scope => :type ,:case_sensitive => false
  validates_format_of     :name, :with => /^[^~`@%$*()\-\[\]{}"':;\/.,\\=+|]*$/i,
    :message => :must_contain_only_letters_numbers_space
  #  named_scope :active,:conditions => {:is_active => true}
  has_many :transport_additional_details
  
  named_scope :active, :conditions => {:is_active => true}, :order => "priority ASC"
  named_scope :inactive, :conditions => {:is_active => false}, :order => "priority ASC"
  named_scope :all_fields , :order=>"priority ASC"
  named_scope :include_details , :include => :transport_additional_details
  
  before_destroy :check_dependencies
   
  INPUT_TYPE = {"text" => "TextBox", "belongs_to" => "Select Box", "has_many" => "CheckBox"}
  
  #check if deatils is added
  def check_dependencies
    !TransportAdditionalDetail.exists?(:transport_additional_field_id => id)
  end
  
  #get is mandatory text
  def mandatory_text
    is_mandatory ? t('yes_text') : t('no_texts')
  end
  
  #return input type text
  def input_type_text
    INPUT_TYPE[input_type]
  end
  
  #old method
  def dependencies_present?
    TransportAdditionalDetail.all(:conditions => {:route_vehicle_additional_field_id => id}).blank?
  end
end

