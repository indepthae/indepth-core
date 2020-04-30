class RemarkBank < ActiveRecord::Base
  
  has_many :remark_templates, :dependent => :destroy
  validates_presence_of :name
  accepts_nested_attributes_for :remark_templates, :allow_destroy=>true
  
end
