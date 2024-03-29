#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class AdditionalField < ActiveRecord::Base
  extend AdditionalFields
  has_many :additional_field_options, :dependent=>:destroy
  validates_presence_of :name
  validates_format_of     :name, :with => /^[^~`@%$*()\-\[\]{}"':;\/.,\\=+|]*$/i,
    :message => :must_contain_only_letters_numbers_space
  validates_uniqueness_of :name,:case_sensitive => false
  validate :options_check

  named_scope :active,:conditions => {:status => true}
  named_scope :inactive,:conditions => {:status => false}
  
  def options_check
    unless self.input_type=="text" or self.input_type=="text_area"
      all_valid_options=self.additional_field_options.reject{|o| (o._destroy==true if o._destroy)}
      unless all_valid_options.present?
        errors.add_to_base(:create_atleast_one_option)
      end
      if all_valid_options.map{|o| o.field_option.strip.blank?}.include?(true)
        errors.add_to_base(:option_name_cant_be_blank)
      end
    end
  end

  accepts_nested_attributes_for :additional_field_options, :allow_destroy=>true

  class << self
    def get_additional_field_methods
      active.map{|a| "additional_detail_#{a.id}"}
    end
  end
end
