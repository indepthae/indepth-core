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
class FaCriteria < ActiveRecord::Base
  has_many    :descriptive_indicators,  :as=>:describable
  has_many    :assessment_scores, :through=>:descriptive_indicators
  accepts_nested_attributes_for :descriptive_indicators
  has_many :cce_reports , :as=>:observable
  belongs_to :fa_group
  default_scope :order=>'sort_order ASC'
  named_scope :active,:conditions=>{:is_deleted=>false}
  validates_presence_of :fa_group_id,:max_marks,:formula_key
  validates_uniqueness_of :formula_key,:scope=>[:fa_group_id,:is_deleted],:if=> 'is_deleted == false'
  #  validates_format_of :formula_key,:with => /^[a-zA-Z]{0,1}$/,:message=>"should be valid single character",:allow_blank=>true
  validates_format_of :formula_key,:with => /^[A-Z]$/,:message=>"should be valid single alphabet (Capital Letter)",:allow_blank=>true
  validates_numericality_of :max_marks, :greater_than => 0

  def validate
    errors.add_to_base("Name can't be blank") if self.fa_name.blank?
    errors.add_to_base("Description can't be blank") if self.desc.blank?
  end

  def is_editable
    dis=self.descriptive_indicators.map(&:id)
    if dis.present?
      scores = AssessmentScore.find_all_by_descriptive_indicator_id(dis)
      return false if scores.present?
      return true
    else
      return true
    end
  end
end
